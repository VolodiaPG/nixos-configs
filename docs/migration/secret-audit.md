# Secret audit (Task 5.1)

Read-only audit of the agenix secrets under `secrets/`. No secret was
decrypted; this only traces textual references through the Nix tree.

`secrets/secrets.nix` declares 15 `.age` files (13 *logical* secrets —
`ssh-remote-builder` and `ssh-remote-builder-pub` are a keypair counted as
one row in PLAN.MD but are two files). Owners/paths come from
`secrets/nixos.nix` (NixOS/darwin, `age.secrets`) and
`secrets/home-manager.nix` (Home Manager, shared across every HM user on
every host).

Two facts shape every row below and matter for sequencing later work:

- `secrets/nixos.nix`'s `age.secrets` block is imported **whole** by all
  three hosts that use it — `configurations/nixos/msi/default.nix:13`,
  `configurations/nixos/home-server/default.nix:14`, and
  `configurations/darwin/Volodias-MacBook-Pro/default.nix:13`. Declaring a
  secret there does not mean every host *consumes* it — only that Nix
  requires the `.age` file to exist for **any** of those hosts to evaluate
  (a `file = ./x.age` path literal errors at eval time if the file is
  missing).
- `secrets/home-manager.nix` is pulled into `home-manager.sharedModules` by
  `modules/nixos/home-manager.nix:33` and `modules/darwin/home-manager.nix:29`,
  so `pythong5k`, `envvars`, and `mail_inria_password` are declared for
  **every** Home Manager user on **every** host (msi, home-server, darwin),
  regardless of whether that host's shell/feature flags actually read the
  file.
- Default agenix runtime path (when no `path` is set, i.e. everything in
  `secrets/nixos.nix`) is `/run/agenix/<name>` → `/run/agenix.d/<gen>/<name>`,
  confirmed by reading the already-built darwin activation script
  `/nix/store/2gisajzj8xwvap5ql976q69zklmn0isj-activate-agenix-start` (a
  build artifact already on disk — not a decryption, just its plaintext
  shell source).

## Table

| Secret | Consumers (file:line) | Hosts that actually consume it | Deployed path + mode | Disposition | Evidence |
|---|---|---|---|---|---|
| `pythong5k` | `secrets/secrets.nix:5`; `secrets/home-manager.nix:11-15` (declares only) | none functionally — only decrypted/placed on disk | `~/.python-grid5000.yaml`, mode `400` (`secrets/home-manager.nix:13-14`) | **DROP (decided)** | Grep for `pythong5k` across all `*.nix` hits only the two declaration files. No module reads `config.age.secrets.pythong5k.path`. |
| `envvars` | `secrets/secrets.nix:6`; `secrets/home-manager.nix:16-20`; `modules/home/zsh.nix:104-105` (`source ${config.age.secrets.envvars.path}`, inside `mkIf cfg.enable` where `cfg = config.programs.zsh`) | msi, darwin (both set `my.interactive.enable = true`, which turns on `programs.zsh`); **not** home-server (`configurations/nixos/home-server/home.nix` never sets `interactive.enable`) | `~/.envvars.sh`, mode `400` (`secrets/home-manager.nix:18-19`) | **vault** | zsh.nix sources it only when `programs.zsh.enable`; home-server's home.nix only turns on `commonHome`, so the file is declared but unused there. |
| `tailscale-authkey` | `secrets/secrets.nix:7`; `secrets/nixos.nix:22-25` (declares, `rootReadable`); `modules/nixos/caddy.nix:20` (`environmentFile = config.age.secrets.tailscale-authkey.path`, inside `mkIf config.services.caddy.enable`) | **msi only** — `configurations/nixos/msi/default.nix:71` is the only place `services.caddy.enable = true` is set anywhere in the repo | `/run/agenix/tailscale-authkey` (no explicit `path`), owner root, mode `0500` | **vault** | `modules/nixos/vpn.nix` (the "vpn" module PLAN.MD attributes this to) never references `tailscale-authkey` — tailscale is enrolled interactively (`tailscale up`), no `authKeyFile` anywhere in the tree. The real consumer is caddy's tailscale-cert plugin, active only on msi. |
| `mail.inria.password` | `secrets/secrets.nix:8`; `secrets/home-manager.nix:21-25` (attr `mail_inria_password`, declares only) | none functionally | `~/.mail.inria.password.txt`, mode `0400` (`secrets/home-manager.nix:23-24`) | **DROP (decided)** | Grep for `mail_inria_password`/`mail.inria.password` outside the two declaration files finds nothing. |
| `cachix-token` | `secrets/secrets.nix:13`; `secrets/nixos.nix:47-50` (`userReadable`); `modules/nixos/common-nix-settings.nix:49,66-70,106` (`CACHIX_TOKEN_FILE=${config.age.secrets.cachix-token.path}` inside the `cachix-push` post-build-hook script, attached via `post-build-hook = "${cachixHook}"` whenever `my.nixSettings.enable`) | home-server, msi, **and darwin** (all three set `nixSettings.enable = true`: `configurations/nixos/home-server/default.nix:30`, `configurations/nixos/msi/default.nix:27`, and darwin via `modules/darwin/common-nix-settings.nix:16` importing the same module with `nixSettings.enable = true` at `configurations/darwin/Volodias-MacBook-Pro/default.nix:19`) | `/run/agenix/cachix-token`, owner `volodia`, mode `0500` | **DROP (decided)** | **Actively wired in on all three hosts today** — dropping it removes plaintext value, but `common-nix-settings.nix`'s post-build-hook script still references the (now-missing) secret path until that module is also edited to remove the cachix-push hook. Not just an unused declaration like pythong5k. |
| `ssh-remote-builder` | `secrets/secrets.nix:9`; `secrets/nixos.nix:32-35` (declares, `rootReadable`) | none found | `/run/agenix/ssh-remote-builder`, owner root, mode `0500` | **open question — likely drop** | No `nix.buildMachines`, `nix.distributedBuilds`, or any other reference anywhere in the tree. Appears to be a dead/orphaned secret (possibly a leftover from a discontinued remote-builder setup). |
| `ssh-remote-builder-pub` | `secrets/secrets.nix:10`; `secrets/nixos.nix:37-40` (declares, `rootReadable`) | none found | `/run/agenix/ssh-remote-builder-pub`, owner root, mode `0500` | **open question — likely drop** | Same as above; paired with `ssh-remote-builder`, equally unreferenced. |
| `rss-password` | `secrets/secrets.nix:11`; `secrets/nixos.nix:27-30` (declares, `rootReadable`) | none found | `/run/agenix/rss-password`, owner root, mode `0500` | **open question — likely drop** | `modules/nixos/home-lab.nix:83-91` sets up a caddy vhost for `rss.<tailname>` (reverse-proxying commafeed), but nothing in that block or elsewhere reads `config.age.secrets.rss-password`. Also: `my.homeLab.enable` is never set to `true` anywhere in the repo (only explicitly `false` on msi, `configurations/nixos/msi/default.nix:64`) — the whole `home-lab.nix` module is currently dormant. |
| `samba-user-password` | `secrets/secrets.nix:12`; `secrets/nixos.nix:42-45`; `modules/nixos/samba.nix:79` (`passwd="$(cat ${config.age.secrets.samba-user-password.path})"`, inside `mkIf cfg.enable` where `cfg = config.services.samba`) | **home-server only** (`services.samba.enable = true` set at `configurations/nixos/home-server/default.nix:70`; never set on msi or darwin) | `/run/agenix/samba-user-password`, owner root, mode `0500` | **home-server only — leave in agenix** | Confirms PLAN.MD. |
| `fizzy-env` | `secrets/secrets.nix:14`; `secrets/nixos.nix:52-55`; `modules/nixos/kubernetes.nix:47-48` (k3s manifest `fizzy-secret`, active — `my.kubernetes.enable = true` at `configurations/nixos/home-server/default.nix:53`); also `modules/nixos/home-lab.nix:39` (`environmentFiles = [ config.age.secrets.fizzy-env.path ]` for a Docker `fizzy` container) | **home-server only** — via the active k3s path (kubernetes.enable). The `home-lab.nix` Docker-container reference is currently dead code (see `rss-password` row: `homeLab.enable` is never true) | `/run/agenix/fizzy-env`, owner root, mode `0500` | **home-server only — leave in agenix** | Two separate consumers in the tree, only one (`kubernetes.nix`) is live. |
| `access-token` | `secrets/secrets.nix:15`; `secrets/nixos.nix:57-60` (`userReadable`); `modules/nixos/common-nix-settings.nix:86` (`!include ${config.age.secrets.access-token.path}` in `nix.extraOptions`, gated on `my.nixSettings.enable`) | home-server, msi, **and darwin** (same three hosts as `cachix-token` above, same gate) | `/run/agenix/access-token`, owner `volodia`, mode `0500` | **vault** — but must ALSO stay declared in `secrets/nixos.nix` for home-server, since home-server keeps needing it too | Same `nixSettings.enable` gate as cachix-token; this one is genuinely needed for Nix's `access-tokens` config (e.g. GitHub API rate limits for flake fetches) on every host, including the one staying on agenix. |
| `hetzner-token` | `secrets/secrets.nix:16`; `secrets/nixos.nix:62-65`; `configurations/nixos/home-server/default.nix:63` (`passwordFile = config.age.secrets.hetzner-token.path` for `my.backup`); `modules/nixos/backup.nix:49` (`sshpass -f ${config.age.secrets.hetzner-token.path}`) | **home-server only** (`my.backup.enable = true` set only at `configurations/nixos/home-server/default.nix:55`) | `/run/agenix/hetzner-token`, owner root, mode `0500` | **home-server only — leave in agenix** | Confirms PLAN.MD. |
| `hetzner-data-encryption-key` | `secrets/secrets.nix:17`; `secrets/nixos.nix:67-70`; `modules/nixos/backup.nix:45` (`passwordFile = config.age.secrets.hetzner-data-encryption-key.path` for restic) | **home-server only** (same `my.backup.enable` gate) | `/run/agenix/hetzner-data-encryption-key`, owner root, mode `0500` | **home-server only — leave in agenix** | Confirms PLAN.MD. |
| `hashed-password` | `secrets/secrets.nix:18`; `secrets/nixos.nix:72-75`; `modules/nixos/base.nix:171` (`hashedPasswordFile = config.age.secrets.hashed-password.path`, inside `mkIf` on `my.base.enable`) | Currently used by **both** home-server (`base.enable = true`, `configurations/nixos/home-server/default.nix:29`) and msi (`base.enable = true`, `configurations/nixos/msi/default.nix:26`) | `/run/agenix/hashed-password`, owner root, mode `0500` | **home-server only — leave in agenix (decided)** | User has decided msi doesn't need it — Nobara sets the account password interactively at install, so `roles/secrets`/ansible won't reproduce this mechanism. Recorded as decided; note that as of today's code, msi's *NixOS* config still wires it in (irrelevant once msi is decommissioned in Phase 7). |
| `tailscale-k8s-operator` | `secrets/secrets.nix:19`; `secrets/nixos.nix:77-80`; `modules/nixos/kubernetes.nix:44-45` (`manifests.tailscale-secret.source`) | **home-server only** (`my.kubernetes.enable` gate, same as `fizzy-env`) | `/run/agenix/tailscale-k8s-operator`, owner root, mode `0500` | **home-server only — leave in agenix** | Confirms PLAN.MD. |

## Do not delete yet

Because `secrets/nixos.nix` and `secrets/home-manager.nix` reference every
`.age` file unconditionally (Nix path literals must resolve at eval time),
**all 15 `.age` files are currently required for home-server to evaluate**,
not just the ones home-server functionally uses. Deleting any one of them
breaks home-server (and, until Phase 7, msi/darwin too) unless the matching
attribute is removed from `secrets.nix`/`nixos.nix`/`home-manager.nix` in
the same change.

Split by what home-server actually *reads at runtime* vs. what it merely
*carries* because the declaration is shared:

- **Functionally consumed by home-server today:** `samba-user-password`,
  `fizzy-env`, `tailscale-k8s-operator`, `hetzner-token`,
  `hetzner-data-encryption-key`, `hashed-password`, `access-token`,
  `cachix-token`.
- **Declared for home-server but not functionally read there** (shared
  module carries them regardless): `pythong5k`, `envvars`,
  `mail.inria.password`, `tailscale-authkey`, `rss-password`,
  `ssh-remote-builder`, `ssh-remote-builder-pub`.

Every one of the 15 files must stay in `secrets/` — and stay declared in
`secrets.nix`/`nixos.nix`/`home-manager.nix` — until the deletion step is
executed together with the corresponding attribute removal. This applies
even to the three secrets the user already decided to drop
(`pythong5k`, `mail.inria.password`, `cachix-token`): removing the `.age`
file alone, without also editing the declaring `.nix` file, breaks
evaluation on every host, home-server included.

## Discrepancies with PLAN.MD

1. **`tailscale-authkey` is not used by the "vpn" module at all.**
   PLAN.MD groups it under "vpn". The actual (only) consumer is
   `modules/nixos/caddy.nix:20`, gated on `services.caddy.enable`, which is
   currently `true` only on msi (`configurations/nixos/msi/default.nix:71`).
   `modules/nixos/vpn.nix` (the real tailscale/VPN module) never touches an
   authkey — tailscale is enrolled interactively. Disposition (`vault`)
   still matches PLAN.MD's guess, but the reasoning and host attribution
   were wrong: home-server does not currently consume this secret at all.

2. **`access-token` and `cachix-token` are used by darwin too**, not just
   NixOS hosts. `modules/darwin/common-nix-settings.nix:16` imports the same
   `modules/nixos/common-nix-settings.nix` that reads both secrets, and
   darwin sets `nixSettings.enable = true`
   (`configurations/darwin/Volodias-MacBook-Pro/default.nix:19`). PLAN.MD's
   table doesn't mention darwin for either of these. For `access-token`
   this means the vault copy is needed on darwin too. For `cachix-token`
   (decided drop) it means the post-build-hook needs to be disabled/removed
   on darwin as well, not just msi.

3. **`hashed-password` is currently also consumed by msi**, not just
   home-server. `modules/nixos/base.nix:171` sets `hashedPasswordFile` for
   any host with `my.base.enable = true`, which includes msi
   (`configurations/nixos/msi/default.nix:26`). This doesn't change the
   already-decided outcome (msi doesn't need it via ansible — Nobara sets
   the password at install), but PLAN.MD's phrasing ("`base.nix` users")
   undersells that msi's *current* NixOS build still actively wires this in.

4. **`fizzy-env` has two consumers, only one of which is live.**
   PLAN.MD lists it once under "home-server services". In code it's
   referenced both by the active k3s path (`modules/nixos/kubernetes.nix:48`)
   and by a dormant Docker-container path (`modules/nixos/home-lab.nix:39`)
   that never runs because `my.homeLab.enable` is never set `true` anywhere
   in the repo. Not a disposition change, just worth knowing before
   `home-lab.nix` gets touched later.

5. **`ssh-remote-builder`, `ssh-remote-builder-pub`, and `rss-password` have
   no consumer anywhere in the Nix tree** — not even on home-server. PLAN.MD
   places all three under "home-server services" / "home-server only leave
   in agenix," implying active use. Grepping the whole tree for each name
   (and for related config shapes — `nix.buildMachines`,
   `nix.distributedBuilds`, any read of
   `config.age.secrets.rss-password.path`) turns up nothing beyond the
   declarations in `secrets.nix`/`nixos.nix`. These look like dead secrets,
   not "leave in agenix, still needed" — see open questions below.

6. **File count**: PLAN.MD's task header says "13 agenix secrets"; `secrets/`
   actually has 15 `.age` files. This reconciles if `ssh-remote-builder` and
   `ssh-remote-builder-pub` are counted as one logical secret (a keypair),
   matching PLAN.MD's table which lists them as a single row
   (`ssh-remote-builder{,-pub}`). Flagging only so the count isn't a
   surprise later — not a functional discrepancy.

## Open questions for the user

1. **`ssh-remote-builder` / `ssh-remote-builder-pub`** — no consumer found
   anywhere in the tree (no `nix.buildMachines`, no `distributed-builds`,
   no `ssh-ng://` config). Is this leftover from a discontinued
   remote-builder setup? If so it's a `drop` candidate like `cachix-token`;
   if it's meant to back some future/manual `nix.conf` builders line that
   isn't tracked in this repo, say so and it should probably stay
   `home-server only — leave in agenix` instead.

2. **`rss-password`** — same situation: declared, never read anywhere,
   `home-lab.nix`'s `rss.<tailname>` caddy vhost doesn't use it. Was this
   meant to protect the commafeed/RSS reverse-proxy and never got wired up,
   or is it also dead? Confirm before deciding `drop` vs. `home-server
   only`.

3. **`home-lab.nix` is entirely dormant** (`my.homeLab.enable` is never
   `true` anywhere) — its `fizzy-env` (Docker path) and the `rss-password`
   question above only matter if this module is meant to come back. Worth
   confirming whether `home-lab.nix` is intentionally shelved (in which
   case its currently-dead secret references are moot) or should be
   deleted/finished as part of this migration.

4. **`cachix-token` and `access-token` drop/migrate on darwin** — since
   both are wired in via the shared `common-nix-settings.nix` on darwin too
   (discrepancy 2 above), please confirm the Phase 6 darwin work also needs
   to (a) remove the cachix-push post-build-hook there when `cachix-token`
   is dropped, and (b) get `access-token` from vault, not just msi.

---

## Decisions (user, phase 5)

All four open questions above were answered. This section is authoritative
where it contradicts the table.

| Secret | Final disposition |
| --- | --- |
| `ssh-remote-builder`, `ssh-remote-builder-pub` | **DROP** — confirmed dead |
| `rss-password` | **DROP** — confirmed dead |
| `access-token` | **VAULT**, kept |
| `cachix-token` | **home-server only — leave in agenix**, not dropped |
| `pythong5k`, `mail.inria.password` | DROP (decided earlier) |
| `hashed-password` | home-server only |
| `envvars` | VAULT |
| `tailscale-authkey` | **DROP** — see below; the vault gets a *new* key, not this one |
| `hetzner-token`, `hetzner-data-encryption-key`, `samba-user-password`, `fizzy-env`, `tailscale-k8s-operator` | home-server only |

1. **`ssh-remote-builder{,-pub}` and `rss-password` are dead.** Confirmed:
   no out-of-repo config depends on them. They go in the phase-7 deletion
   batch — attribute removed from `secrets/nixos.nix` and `.age` file
   deleted in the same commit, then the rule-1 `nix eval` on `home-server`.

2. **`access-token` is kept.** Implemented in `roles/nix`, not
   `roles/secrets`, because it is a `nix.conf` concern rather than a `$HOME`
   dotfile: the fragment is written to `/etc/nix/nix.access-tokens.conf`
   (root, `0600`) from `vault_access_token`, and `nix.custom.conf` pulls it
   in with `!include`. `!include` is the tolerant form — Nix ignores a
   missing file instead of erroring — so the reference is emitted
   unconditionally and the whole thing degrades gracefully while the vault
   is empty. It stays in agenix as well, for `home-server`.

3. **`cachix-token` is NOT dropped after all** — the cheaper path. It stays
   in agenix and `modules/nixos/common-nix-settings.nix` is left completely
   alone, so `home-server` keeps its `cachix-push` post-build-hook working.
   The migrated hosts never inherit the hook, because `roles/nix` writes
   only `nix.custom.conf` and never touches `nix.extraOptions`. This avoids
   the module surgery the table assumed, and avoids the risk of breaking
   `home-server`'s builds. Revisit only in phase 7, if at all.

4. **`home-lab.nix` is fully deprecated** — replaced by k3s
   (`modules/nixos/kubernetes.nix`, which is what actually consumes
   `fizzy-env` on `home-server`). It goes in the phase-7 decommission batch
   along with its dead references. Nothing in it needs porting.

5. **`tailscale-authkey` is dropped, not migrated.** Its only consumer was
   caddy on msi (discrepancy 1) and caddy is gone. `roles/vpn` needs a
   freshly generated key from the tailnet admin console instead — see
   `docs/migration/vault-setup.md`.
