# Brave managed policy — phase-4 spec (task 2.10 → Ansible)

Successor to `modules/home/browser.nix`'s `programs.chromium.extensions`.
Nothing here belongs to chezmoi: the policy file lives under `/etc`, so it is
an Ansible task (PLAN.MD §2 split rule). Browser choice settled in §0: the
Brave **Flatpak** `com.brave.Browser`.

## Target path — VERIFIED

`/etc/brave/policies/managed/` on the **host**, mode `0755` dir /
`0644` file, owner `root:root`. Suggested name:
`/etc/brave/policies/managed/extensions.json`.

PLAN.MD task 2.10 says the Flatpak needs a "Flatpak-scoped path,
`/var/lib/flatpak/extension/` overrides via `flatpak override --filesystem=`".
**That is wrong** — verified 2026-09-23 against the Flathub packaging:

- `flathub/com.brave.Browser` → `com.brave.Browser.yaml` `finish-args`
  already contains `--filesystem=host-etc`, commented in the manifest with
  *"To load policies on the host /etc/brave/policies"*. No
  `flatpak override` is required.
- The app's launcher `brave.sh` symlinks host policies into the sandbox
  before exec'ing the browser:

  ```sh
  for proot in "etc/brave/policies" "etc/static/brave/policies"; do
    for ptype in managed recommended enrollment; do
      if [ -d "/run/host/$proot/$ptype" ]; then
        mkdir -p "/etc/brave/policies/$ptype"
        ln -sf "/run/host/$proot/$ptype"/*.json "/etc/brave/policies/$ptype" 2>/dev/null
      fi
    done
  done
  ```

So the Flatpak reads the **same host path as the RPM build**,
`/etc/brave/policies/managed/*.json` (plus the NixOS-style
`/etc/static/brave/policies/...` fallback). Sources:
`https://raw.githubusercontent.com/flathub/com.brave.Browser/master/{com.brave.Browser.yaml,brave.sh}`
(fetched 2026-09-23). Not re-verified on msi — re-check with
`flatpak info --show-permissions com.brave.Browser` after install.

## File content

Reconstructed from the three extension IDs in `modules/home/browser.nix`
(nothing generated existed to copy: `programs.chromium` produces no output on
the macOS host). IDs are byte-identical to the module's.

```json
{
  "ExtensionInstallForcelist": [
    "nngceckbapebfimnlniiiahkandclblb;https://clients2.google.com/service/update2/crx",
    "mnjggcdmjocbbbhaepdhchncahnbgone;https://clients2.google.com/service/update2/crx",
    "phaodiidhofhdmfkjiacigibgikhfafn;https://clients2.google.com/service/update2/crx"
  ]
}
```

| ID | Extension |
| --- | --- |
| `nngceckbapebfimnlniiiahkandclblb` | Bitwarden |
| `mnjggcdmjocbbbhaepdhchncahnbgone` | SponsorBlock |
| `phaodiidhofhdmfkjiacigibgikhfafn` | Quedelix |

The `;<update_url>` suffix is optional (bare ID defaults to the Chrome Web
Store); it is written out explicitly so the entry does not depend on that
default. Brave resolves CWS update requests through its own proxy.

Commented-out entries in `browser.nix` (uBlock Origin Lite
`ddkjiahejlhfcafbddmgiahcphecmpfh`, DeArrow
`enamippconapkdmgfgjchkhakpfinmaj`) stay commented out — not installed.

## Ansible task sketch

```yaml
- name: Brave managed policy directory
  ansible.builtin.file:
    path: /etc/brave/policies/managed
    state: directory
    mode: "0755"
  become: true

- name: Brave force-installed extensions
  ansible.builtin.copy:
    dest: /etc/brave/policies/managed/extensions.json
    content: "{{ brave_policy | to_nice_json }}"
    mode: "0644"
  become: true
```

with `brave_policy` in `group_vars/desktop.yml`, so a second run is a no-op
(rule 4). Package side: `pkgs_flatpak: [com.brave.Browser]` (task 3.1);
nixpkgs `brave-origin` remains the documented fallback (§0).

## Verification after cutover

`brave://policy` must list `ExtensionInstallForcelist` with the three IDs and
status *OK*, and `brave://extensions` must show all three as
"Installed by enterprise policy".
