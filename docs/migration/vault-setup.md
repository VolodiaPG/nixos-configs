# ansible-vault setup — phase 5.2

Companion to PLAN.MD task 5.2 and `ansible/roles/secrets`. That role and this
doc together are the *mechanism* for user-scope secrets: nothing in
`ansible/` ever contains a real secret value, the vault password does not
exist yet, and every step below that touches a real secret is something only
a human runs, by hand, outside of any agent session.

Task 5.1 (`docs/migration/secret-audit.md`, written concurrently) is the
audit of which of the 13 agenix secrets survive the migration and where each
one ends up (vault vs. staying in `secrets/` for `home-server`). Read that
file for the authoritative disposition list before running anything below —
this doc assumes its conclusions but doesn't re-derive them.

## What survives into the vault, today

Per PLAN.MD task 5.1 (and the user's own edit to that section), of the
former `secrets/*.age` files only these are still slated for
`ansible/inventory/group_vars/all/vault.yml`:

| Secret               | Vault var               | Written by                     | Destination                    |
| --------------------- | ------------------------ | ------------------------------- | -------------------------------- |
| `tailscale-authkey`   | `vault_tailscale_authkey` | `ansible/roles/vpn`             | `tailscale up --authkey=...` (not a file) |
| `envvars`             | `vault_envvars`           | `ansible/roles/secrets`         | `~/.envvars.sh` (mode `0400`)  |
| `access-token`        | `vault_access_token`      | `ansible/roles/nix`             | `/etc/nix/nix.access-tokens.conf` (root, mode `0600`), `!include`d by `nix.custom.conf` |

Dropped by user decision during the 5.1 audit: `pythong5k`
(`~/.python-grid5000.yaml`), `mail.inria.password`
(`~/.mail.inria.password.txt`) and `cachix-token`. None of these three
should be re-encrypted into the vault — `ansible/roles/secrets`'s
`secrets_files` list (see `ansible/roles/secrets/defaults/main.yml`)
intentionally only has one entry (`envvars`) for exactly this reason.

`hashed-password` is dropped too (Nobara sets the password at install, not
via a secrets file).

`access-token` **is kept** (user decision, phase 5). It is a `nix.conf`
concern rather than a `$HOME` dotfile, so `roles/nix` owns it, not
`roles/secrets`: it writes the fragment to `/etc/nix/nix.access-tokens.conf`
(root, `0600`) and `nix.custom.conf` pulls it in with `!include`. The value
is the token entry, `github.com=<token>`. `roles/nix` adds the
`access-tokens = ` key itself. A full `access-tokens = github.com=<token>`
line, as agenix served it, is also accepted: the role strips the key and
re-adds it. (This doc originally required the full line. The vault then
held the bare value, the role wrote it verbatim, and nix-daemon
crash-looped. That is why the role owns the syntax now.) Without it, GitHub flake/tarball fetches fall back to the
unauthenticated 60-requests/hour limit.

`cachix-token` **stays in agenix** and is not migrated. `home-server` still
runs the `cachix-push` post-build-hook that consumes it
(`modules/nixos/common-nix-settings.nix:49,66-70,106`), and leaving that
module untouched is strictly less work than surgically removing the hook.
The migrated hosts simply never get the hook, because `roles/nix` writes
only `nix.custom.conf` and never touches `extraOptions`.

`hetzner-token`, `hetzner-data-encryption-key`, `samba-user-password`,
`tailscale-k8s-operator`, `fizzy-env`, `rss-password`, and the
`ssh-remote-builder{,-pub}` pair stay in `secrets/` and keep being served to
`home-server` via agenix — out of scope for this doc entirely (PLAN.MD:
"Both coexist until phase 7").

## 1. Create the vault password

This file must never be committed — it isn't, and shouldn't ever be, tracked
by git or chezmoi.

```sh
mkdir -p ~/.config/ansible
umask 077
openssl rand -base64 32 > ~/.config/ansible/vault-pass
chmod 0600 ~/.config/ansible/vault-pass
```

Store the value of `~/.config/ansible/vault-pass` in Bitwarden (a new item,
e.g. "ansible-vault password — nixos-configs") so it survives a lost
machine. Anyone reprovisioning a host needs both this password *and* a
clone of the repo to reproduce the secret files — see the verification
section below.

## 2. Decrypt each surviving secret from agenix, re-encrypt into the vault

This is a one-time migration per surviving secret. It needs `ragenix` (or
`agenix`) to read the old `secrets/*.age` files, and `ansible-vault` to
write the new one. Run this from a host that already has an identity in
`secrets/secrets.nix`'s `publicKeys` (i.e. one of the keys under
`age.identityPaths` in `secrets/home-manager.nix`).

Two practical notes before you start:

- **`ragenix` comes from the dev shell** (`flake.nix` puts `pkgs.ragenix`
  in it), so you need `nix develop` for these commands. `nix develop`
  reinstalls pre-commit.com's hook shim over prek's — afterwards, re-run
  `prek install -f --hook-type pre-commit` and
  `prek install -f --hook-type commit-msg` or commits will behave oddly.
- **`ragenix`/`agenix` resolve secret paths relative to the rules file,
  `secrets/secrets.nix`**, which names its entries as bare basenames
  (`"envvars.age"`, not `"secrets/envvars.age"`). So these commands must
  be run from inside `secrets/`, with a bare filename — `ragenix -d
  ../secrets/envvars.age` from elsewhere will not find a matching rule.

First, create the vault file if it doesn't exist yet — `ansible-vault
create` both creates and encrypts in one step, so never write plaintext to
`vault.yml` with an editor first:

```sh
cd ansible
ansible-vault create --vault-password-file ~/.config/ansible/vault-pass \
  inventory/group_vars/all/vault.yml
```

That opens `$EDITOR` on a scratch plaintext buffer; leave it as an empty
YAML doc (`---`) for now and save — the loop below edits it properly.

For each surviving secret, decrypt with `ragenix` to a variable (never to a
file on disk) and pipe it straight into `ansible-vault edit` via a small
helper, so the plaintext value never touches an unencrypted file or your
shell history:

```sh
# decrypt from secrets/ (that is where secrets.nix lives)
cd secrets

# tailscale-authkey -> vault_tailscale_authkey
ragenix -d tailscale-authkey.age

# envvars -> vault_envvars (this one is a multi-line shell script; use a
# YAML block scalar so newlines survive)
ragenix -d envvars.age

# access-token -> vault_access_token (a nix.conf fragment, keep it whole)
ragenix -d access-token.age
```

Then, in a second shell, paste each value into the vault. `ansible-vault
edit` decrypts to a temporary file, opens `$EDITOR`, and re-encrypts on
save, so the plaintext never lands in the repo:

```sh
cd ansible
ansible-vault edit --vault-password-file ~/.config/ansible/vault-pass \
  inventory/group_vars/all/vault.yml
```

```yaml
# add/update, inside that editor session:
vault_tailscale_authkey: "<a FRESH key from the tailnet admin console — see below>"
vault_envvars: |
  <paste each decrypted line here, indented to match>
vault_access_token: "github.com=<token>"
```

**`tailscale-authkey` is not a migration.** The audit
(`docs/migration/secret-audit.md`) found its only consumer is
`modules/nixos/caddy.nix:20`, caddy's `environmentFile` for the
caddy-tailscale plugin, on msi only — and caddy is dropped. `vpn.nix` never
used it; tailscale was always enrolled interactively. So the old `.age` file
is an env-file (`TS_AUTHKEY=...`) for a service that no longer exists, and
auth keys expire anyway. Generate a **new** key at
<https://login.tailscale.com/admin/settings/keys> and put that in
`vault_tailscale_authkey`; do not decrypt the old one.

`ansible-vault edit` re-encrypts the whole file on save, so it's safe to run
it once per secret rather than trying to batch everything into a single
sitting. When every surviving secret has a `vault_*` key, `vault.yml`
should contain exactly:

```yaml
---
vault_tailscale_authkey: "<from bitwarden / decrypted from tailscale-authkey.age>"
vault_envvars: |
  <from bitwarden / decrypted from envvars.age>
```

(Shown here only as placeholder text — never fill this doc itself in with
real values.)

If `docs/migration/secret-audit.md` lands with a different disposition than
the table above (e.g. `access-token` turns out to belong in the vault too),
add its `vault_<name>` key here the same way, and add a matching entry to
`ansible/roles/secrets/defaults/main.yml`'s `secrets_files` list (or to
whichever role owns it) — that list is deliberately data-only for this
reason.

## 3. Re-enable `vault_password_file` in `ansible.cfg`

`ansible/ansible.cfg` currently has this line commented out:

```ini
# vault_password_file = ~/.config/ansible/vault-pass
```

It's commented out deliberately: Ansible hard-fails *every* command,
including `--syntax-check`, when this points at a file that doesn't exist,
and `~/.config/ansible/vault-pass` doesn't exist until step 1 above has been
done by a human. Once it does exist:

1. Uncomment that single line in `[defaults]` (leave everything else in the
   file alone).
2. Re-run the syntax checks to confirm nothing broke:
   ```sh
   cd ansible
   ansible-playbook --syntax-check playbooks/linux.yml
   ansible-playbook --syntax-check playbooks/macos.yml
   ansible-playbook --syntax-check playbooks/site.yml
   ansible-playbook --syntax-check playbooks/bootstrap.yml
   ```
3. From here on, every `ansible-playbook` run automatically decrypts
   `vault.yml` using that password file — no `--ask-vault-pass` or
   `--vault-password-file` flag needed on the command line.

Do not edit `ansible.cfg` as part of any earlier phase-5 step — it stays
commented out (and the repo stays green on `--syntax-check` against an
empty vault) until this step is done by hand.

## 4. Verify

Two checks, both from PLAN.MD's own phase-5 verification:

**No plaintext secrets anywhere in the tree:**

```sh
git grep -n 'BEGIN.*PRIVATE\|password' ansible/
```

This must find nothing. `vault.yml` is ansible-vault-encrypted (its
on-disk form is a `$ANSIBLE_VAULT;1.1;AES256` header followed by hex, not
YAML), so grepping for `password` or `BEGIN ... PRIVATE` inside it should
never match. If it does match something in `ansible/`, stop and find out
why before going further — it means a secret leaked into a task,
default, or doc in plaintext.

**A fresh clone reproduces every secret file:**

```sh
# from a clean checkout, with ~/.config/ansible/vault-pass already in place
cd ansible
ansible-playbook playbooks/linux.yml   # or macos.yml, on the right host
```

After that run, `~/.envvars.sh` should exist, mode `0400`, owned by the
user, with the same content as `secrets/envvars.age` decrypts to. If the
vault password file is missing or wrong, the play should fail loudly at the
vault-decrypt step (not silently skip) — the "skip cleanly" behaviour in
`ansible/roles/secrets/tasks/main.yml` only applies to a *vault var being
undefined*, not to a vault that fails to decrypt at all.

## Note: transcrypt is unaffected

Transcrypt (the git-crypt-alternative already in this repo for in-tree
*binary* secrets — SSH private keys, the Comic Code font archive) stays
exactly as-is. It's orthogonal to this doc: ansible-vault handles
*Ansible-consumed* scalar/text secrets (vault vars fed into tasks),
transcrypt handles *files committed to the repo* that chezmoi or another
role later copies out verbatim. Neither replaces the other, and phase 5
doesn't touch transcrypt's configuration.
