-- Hyprland configuration (Lua)
-- Migrated from hyprland.conf — keeps scrolling WM, all keybinds, and all settings.
-- Requires Hyprland >= 0.55.

-- luacheck: read globals hl
-- luacheck: ignore 631

local mainMod = "SUPER"

--─────────────────────────────
-- Monitors
--─────────────────────────────
local iiyama_desc = "Iiyama North America PL3461WQ 1171803800833"
local cloudium_desc = "Cloudium Systems Ltd. CSL421 0x00004210"

local known_config = {
	[iiyama_desc] = {
		mode = "3440x1440@143.92",
		position = "0x0",
		scale = 1.25,
	},
	[cloudium_desc] = {
		mode = "1280x720@59.95",
		position = "auto",
		scale = 1,
		mirror = "desc:" .. iiyama_desc,
	},
}

-- Apply a known monitor's config, optionally overriding fields (e.g. mirror).
local function apply_known(desc, override)
	local opts = { output = "desc:" .. desc }
	for k, v in pairs(known_config[desc]) do
		opts[k] = v
	end
	for k, v in pairs(override or {}) do
		opts[k] = v
	end
	hl.monitor(opts)
end

--─────────────────────────────
-- Dynamic monitor mirroring
--─────────────────────────────
-- When an unknown monitor (not the Iiyama or Cloudium) is connected, it
-- becomes the master and ALL other monitors mirror
-- it. When it's disconnected and there are no other unknown monitors, known monitors are restored (Cloudium goes
-- back to mirroring the Iiyama).

-- Strip "desc:" prefix so comparison works whether m.description includes it or not
local function norm_desc(s)
	return ((s or ""):gsub("^desc:", ""))
end

-- local function log(message)
--   local file = io.open("/tmp/logs.log", "a")
--   if file then
--     local timestamp = os.date("%Y-%m-%d %H:%M:%S")
--     file:write(string.format("[%s] %s\n", timestamp, tostring(message)))
--     file:close()
--   end
-- end

local elect_master_or_restore_known = function()
	local has_unknown = false
	local connected_descs = {}
	local first_known_desc = nil
	local unknown_master = nil

	-- Get if any monitors are unknown
	for _, mon in ipairs(hl.get_monitors()) do
		table.insert(connected_descs, norm_desc(mon.description))
		if not known_config[norm_desc(mon.description)] then
			has_unknown = true
			unknown_master = norm_desc(mon.description)
		elseif not first_known_desc then
			first_known_desc = norm_desc(mon.description)
		end
	end

	local target
	-- log("Electing master: " .. (unknown_master or "none") .. " (" .. (has_unknown and "unknown" or "known") .. ")")
	if not has_unknown then
		-- all connected monitors are known, restore them
		target = first_known_desc

		-- hl.timer(function()
		for desc, _ in pairs(known_config) do
			apply_known(desc)
		end
	-- log("Applied known config")
	else
		target = unknown_master
		hl.monitor({ output = "desc:" .. unknown_master, mode = "preferred", position = "0x0", scale = 1 })

		for desc, _ in pairs(known_config) do
			apply_known(desc, { mirror = "desc:" .. unknown_master })
		end

		-- log("Applied unknown config to " .. unknown_master)
	end

	-- log("Target: " .. (target or "none"))

	-- Reclaim workspaces orphaned onto the FALLBACK monitor when the master
	-- was removed (mirrors can't hold workspaces, so Hyprland parks them there).
	if target then
		-- Revert window gaps back after 200ms
		hl.timer(function()
			for _, ws in ipairs(hl.get_workspaces()) do
				if ws.monitor == nil or ws.monitor.id == -1 or ws.monitor.name == "FALLBACK" then
					hl.dispatch(hl.dsp.workspace.move({ workspace = ws.id, monitor = "desc:" .. target }))
				end
			end
		end, { timeout = 1000, type = "oneshot" })
	end
end

-- Apply monitors at first and subsequent loads of config
elect_master_or_restore_known()

hl.on("monitor.added", function(_)
	hl.dispatch(hl.dsp.exec_cmd("hyprctl reload"))
end)

hl.on("monitor.removed", function(_)
	hl.dispatch(hl.dsp.exec_cmd("hyprctl reload"))
end)

--─────────────────────────────
-- Autostart
--─────────────────────────────
hl.on("hyprland.start", function()
	hl.exec_cmd('swayidle -w before-sleep "noctalia msg session lock"')
	-- ponytail: noctalia starts as a systemd user service (programs.noctalia.systemd.enable)
	-- via graphical-session.target now that greetd launches through uwsm; don't double-start.
end)

--─────────────────────────────
-- Environment
--─────────────────────────────
hl.env("XCURSOR_SIZE", "18")

--─────────────────────────────
-- Input
--─────────────────────────────
hl.config({
	input = {
		kb_layout = "fr",
		follow_mouse = 1,
		scroll_method = "2fg",
		accel_profile = "flat",
		touchpad = {
			natural_scroll = true,
			scroll_factor = 0.1,
			tap_to_click = true,
			disable_while_typing = true,
		},
	},
})

--─────────────────────────────
-- General / layout
--─────────────────────────────
hl.config({
	general = {
		gaps_in = 6,
		gaps_out = 12,
		layout = "scrolling",
		allow_tearing = false,
		border_size = 2,
		col = {
			active_border = { colors = { "rgba(8839efff)", "rgba(dc8a78ff)" }, angle = 45 },
		},
	},
})

--─────────────────────────────
-- Scrolling layout (native in hyprland core since mid-2025)
--─────────────────────────────
hl.config({
	scrolling = {
		fullscreen_on_one_column = true,
		focus_fit_method = 1,
		follow_focus = true,
		follow_min_visible = 0.4,
		wrap_focus = true,
		wrap_swapcol = true,
	},
})

--─────────────────────────────
-- XWayland
--─────────────────────────────
hl.config({
	xwayland = {
		force_zero_scaling = true,
	},
})

--─────────────────────────────
-- Workspace names (mapped to numbered workspaces)
--─────────────────────────────
local ws_names = {
	"browser",
	"terminal",
	"social",
	"fizzy",
	"misc",
	"music",
	"zotero",
	"misc2",
	"misc3",
}
for i, name in ipairs(ws_names) do
	hl.workspace_rule({ workspace = tostring(i), default_name = name })
end

--─────────────────────────────
-- Cursor
--─────────────────────────────
hl.config({
	cursor = {
		sync_gsettings_theme = true,
		-- no_hardware_cursors = 2,
	},
})

--─────────────────────────────
-- Animations
--─────────────────────────────
hl.config({
	animations = {
		enabled = false,
	},
})

-- Gestures: defaults (workspace swipe disabled; no hot corners in hyprland)

--─────────────────────────────
-- Decoration
--─────────────────────────────
hl.config({
	decoration = {
		rounding = 12,
		active_opacity = 1.0,
		inactive_opacity = 1.0,
		blur = {
			enabled = true,
			passes = 5,
			noise = 0.05,
			vibrancy = 1.5,
			xray = false,
			new_optimizations = true,
			ignore_opacity = false,
		},
		shadow = {
			enabled = true,
			range = 4,
			render_power = 3,
			color = "rgba(1a1a1aee)",
		},
	},
})

--─────────────────────────────
-- Binds
--─────────────────────────────
-- Window management
hl.bind(mainMod .. " + Space", hl.dsp.exec_cmd("fuzzel"))
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exit())

-- Window focus (scrolling layout)
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "d" }))

-- Window movement (scrolling layout)
hl.bind(mainMod .. " + left", hl.dsp.layout("swapcol l"))
hl.bind(mainMod .. " + right", hl.dsp.layout("swapcol r"))
hl.bind(mainMod .. " + up", hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + down", hl.dsp.window.move({ direction = "d" }))

-- Window actions
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + F", hl.dsp.layout("colresize 1.0"))
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.layout("colresize 0.5"))
-- hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + CTRL + SHIFT + F", hl.dsp.window.fullscreen_state({ internal = 2, client = -1 }))

-- Workspaces (French AZERTY keysyms)
local azerty_keys = {
	"ampersand",
	"eacute",
	"quotedbl",
	"apostrophe",
	"parenleft",
	"minus",
	"egrave",
	"underscore",
	"ccedilla",
	"agrave",
}
for i, key in ipairs(azerty_keys) do
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
	hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Screenshot
hl.bind(
	mainMod .. " + SHIFT + S",
	hl.dsp.exec_cmd(
		[[grim -g "$(slurp -c '#ff0000ff')" -t ppm - | satty --filename - --output-filename ~/Pictures/satty-$(date '+%Y%m%d-%H%M:%S').png]]
	)
)
hl.bind("Print", hl.dsp.exec_cmd("grim - | wl-copy"))

-- Lock screen
hl.bind(mainMod .. " + Escape", hl.dsp.exec_cmd("noctalia msg session lock"))

-- Scratchpad (replaces nirius toggle-follow-mode)
hl.bind(mainMod .. " + P", hl.dsp.workspace.toggle_special("scratch"))

-- VRR toggle (per-monitor)
hl.bind(
	mainMod .. " + Tab",
	hl.dsp.exec_cmd('hyprctl keyword monitor "Iiyama North America PL3461WQ 1171803800833",preferred,auto,1,vrr,1')
)
hl.bind(
	mainMod .. " + SHIFT + Tab",
	hl.dsp.exec_cmd('hyprctl keyword monitor "Iiyama North America PL3461WQ 1171803800833",preferred,auto,1,vrr,0')
)

-- Volume control
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("noctalia msg volume-up"), { locked = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("noctalia msg volume-down"), { locked = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("noctalia msg volume-mute"), { locked = true })

-- Brightness control
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("noctalia msg brightness-up"), { locked = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("noctalia msg brightness-down"), { locked = true })

-- Media control
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("noctalia msg media next"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("noctalia msg media previous"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("noctalia msg media toggle"), { locked = true })

-- Keyboard brightness
hl.bind("XF86KbdBrightnessUp", hl.dsp.exec_cmd("brightnessctl --device kbd_backlight set 10%+"), { locked = true })
hl.bind("XF86KbdBrightnessDown", hl.dsp.exec_cmd("brightnessctl --device kbd_backlight set 10%-"), { locked = true })

-- Move floating windows
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })

--─────────────────────────────
-- Window rules
--─────────────────────────────
-- Workspace assignments
hl.window_rule({ match = { class = "^(brave-browser)$" }, workspace = "1" })
hl.window_rule({ match = { class = "^(kitty)$" }, workspace = "2", scrolling_width = 1.0 })
hl.window_rule({ match = { title = "^(.*Proton Mail.*)$" }, workspace = "3" })
hl.window_rule({ match = { title = "^(.*Fizzy.*|.*Home Assistant.*)$" }, workspace = "4" })
hl.window_rule({ match = { class = "^(io.github.nokse22.high-tide)$" }, workspace = "6", scrolling_width = 1.0 })
hl.window_rule({ match = { class = "^(Zotero)$" }, workspace = "7", scrolling_width = 1.0 })
hl.window_rule({ match = { class = "^(signal|legcord)$" }, workspace = "3" })

-- Bitwarden and brave/chrome extensions float when in a separate window
hl.window_rule({ match = { title = "^_crx_.*$" }, float = true })
hl.window_rule({ match = { class = "^feh$" }, float = true })

-- Picture-in-Picture (floating, 480x270, 80% opacity)
hl.window_rule({ match = { title = "^(Picture-in-Picture)$" }, float = true, size = { 480, 270 }, opacity = "0.8 0.8" })

-- Global blur (matches niri's global background-effect rule)
hl.window_rule({ match = { class = "^(.*)$" }, no_blur = false })

-- Block out from screen capture
hl.window_rule({
	match = { class = "^(org.keepassxc.KeePassXC|org.gnome.World.Secrets|signal|legcord)$" },
	no_screen_share = true,
})
hl.window_rule({
	match = { title = "^(Mail|mail|Bitwarden|Fizzy)$" },
	no_screen_share = true,
})

-- VRR for games
hl.window_rule({ match = { class = "^(mpv|steam_app_.*)$" }, no_vrr = false })
hl.window_rule({ match = { class = "(.*\\.exe)$" }, no_vrr = false })

--─────────────────────────────
-- Layer rules
--─────────────────────────────
-- Block out from screen capture
hl.layer_rule({
	match = { namespace = "^(notifications|noctalia-wallpaper.*|noctalia-bar-exclusion.*)$" },
	no_screen_share = true,
})

-- Blur for launcher
hl.layer_rule({ match = { namespace = "^(launcher)$" }, blur = true })
-- hl.layer_rule({ match = { namespace = "^(launcher)$" }, xray = 0 })

-- Noctalia surfaces — blur, no xray, block from capture
local noctalia_ns = '^(noctalia-(bar-[^"]+|notification|dock|panel|attached-panel|osd|window-switcher))$'
hl.layer_rule({ match = { namespace = noctalia_ns }, blur = true })
hl.layer_rule({ match = { namespace = noctalia_ns }, xray = false })
hl.layer_rule({ match = { namespace = noctalia_ns }, no_screen_share = true })
