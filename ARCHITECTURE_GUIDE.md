# NixOS Flake Architecture Guide for AI Agents

> Inspired from the excellent https://github.com/henrirosten/dotfiles

## Overview

This document provides a comprehensive guide for AI agents to adapt existing NixOS and nix-darwin configurations to follow this flake's efficient, minimal architecture. This architecture prioritizes:

- **Minimal flake.nix surface area** (single file, ~120 lines)
- **Module composition via simple registries**
- **Parametric, reusable modules**
- **Clear separation of concerns**
- **Single source of truth for user data**
- **Cross-platform support** (NixOS, macOS via nix-darwin, standalone home-manager)

## Architecture Principles

### 1. Lean Flake Outputs

The flake.nix should expose only essential outputs:

- `nixosModules`: Registry of NixOS system-level modules
- `darwinModules`: Registry of nix-darwin system-level modules
- `homeManagerModules`: Registry of home-manager modules (cross-platform)
- `nixosConfigurations`: NixOS host configurations
- `darwinConfigurations`: macOS host configurations
- `homeConfigurations`: Standalone home-manager configs (optional, for non-NixOS/darwin systems)
- `formatter`: Code formatting toolchain
- `checks`: Pre-commit hooks and validation
- `devShells`: Development environment

**Anti-pattern**: Avoid exposing packages, overlays, or other outputs unless truly necessary.

### 2. Input Management

All flake inputs should follow nixpkgs to prevent version conflicts:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # For macOS support
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Cross-platform home-manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    some-input = {
      url = "github:owner/repo";
      inputs.nixpkgs.follows = "nixpkgs";  # Critical!
    };
  };
}
```

**Note on nixpkgs branch**: Use `nixos-unstable` for NixOS systems and consider using the same branch for consistency across platforms. Nix-darwin works with both `nixos-unstable` and `nixpkgs-unstable`.

### 3. specialArgs Pattern

Define user and global data once in specialArgs, pass everywhere:

```nix
outputs = inputs @ {self, ...}: let
  inherit (self) outputs;

  specialArgs = {
    inherit inputs outputs;
    user = {
      name = "Full Name";
      username = "username";
      homedir = "/home/username";
      email = "email@example.com";
      keys = [ "ssh-ed25519 ..." ];
    };
  };
in {
  # Pass to all configurations
  nixosConfigurations.hostname = inputs.nixpkgs.lib.nixosSystem {
    inherit specialArgs;
    modules = [ ... ];
  };
}
```

### 4. Module Registry Pattern

Use simple default.nix files as module registries:

**nix-modules/default.nix** (for NixOS):

```nix
{
  common-nix = import ./common-nix.nix;
  gui = import ./gui.nix;
  laptop = import ./laptop.nix;
  ssh-access = import ./ssh-access.nix;
}
```

**darwin-modules/default.nix** (for macOS):

```nix
{
  common-darwin = import ./common-darwin.nix;
  homebrew = import ./homebrew.nix;
  preferences = import ./preferences.nix;
}
```

**home-modules/default.nix** (cross-platform):

```nix
{
  bash = import ./bash.nix;
  git = import ./git.nix;
  vim = import ./vim.nix;
  zsh = import ./zsh.nix;
}
```

Then expose in flake.nix:

```nix
{
  nixosModules = import ./nix-modules;
  darwinModules = import ./darwin-modules;
  homeManagerModules = import ./home-modules;
}
```

**Important**: Home-manager modules should be platform-agnostic where possible. Platform-specific configuration should be in nix-modules/ or darwin-modules/.

### 5. Parametric Module Pattern

Modules should be functions that accept parameters and return configurations:

```nix
# nix-modules/common-nix.nix
{
  pkgs,
  user,
  ...
}: {
  # Configuration using pkgs and user
  users.users."${user.username}" = {
    isNormalUser = true;
    home = "/home/${user.username}";
  };
}
```

```nix
# home-modules/git.nix
{
  pkgs,
  user,
  ...
}: {
  programs.git = {
    enable = true;
    settings.user = {
      inherit (user) name email;
    };
  };
}
```

### 6. Host Configuration Structure

Each host has three files:

```
hosts/hostname/
├── configuration.nix      # System config, imports shared modules
├── home.nix              # Home Manager integration
└── hardware-configuration.nix  # Auto-generated hardware config
```

**configuration.nix pattern**:

```nix
{
  inputs,
  outputs,
  user,
  lib,
  pkgs,
  ...
}: {
  imports = lib.flatten [
    (with outputs.nixosModules; [
      (common-nix {inherit pkgs user;})
      laptop
      gui
    ])
    (with inputs.nixos-hardware.nixosModules; [
      lenovo-thinkpad-t480
    ])
    (import ./home.nix {inherit inputs outputs user pkgs lib;})
    ./hardware-configuration.nix
  ];

  # Host-specific configuration
  boot.loader.systemd-boot.enable = true;
  # ...
}
```

**home.nix pattern**:

```nix
{
  inputs,
  outputs,
  user,
  pkgs,
  ...
}: {
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  home-manager.users."${user.username}" = {lib, ...}: {
    imports = pkgs.lib.flatten [
      (with outputs.homeManagerModules; [
        bash
        (git {inherit pkgs user;})
        vim
        zsh
      ])
    ];
  };
}
```

### 7. Module Categories

**NixOS Modules (nix-modules/)**: System-level configuration

- `common-nix.nix`: Base system config (nix settings, users, networking)
- `laptop.nix`: Laptop-specific (battery, touchpad, bluetooth)
- `gui.nix`: Desktop environment
- `ssh-access.nix`: SSH server configuration
- Feature-specific modules

**Home Manager Modules (home-modules/)**: User-level configuration (cross-platform)

- `common-home.nix`: Base home config (packages, fonts)
- Program-specific configs (git, vim, bash, zsh, etc.)
- Should be platform-agnostic where possible

**Darwin Modules (darwin-modules/)**: macOS system-level configuration

- `common-darwin.nix`: Base macOS config (system settings, nix daemon)
- `homebrew.nix`: Homebrew package management
- `preferences.nix`: macOS system preferences
- `security.nix`: macOS security settings
- Feature-specific modules

### 8. Integrated Home Manager

Home Manager should be integrated as a NixOS or nix-darwin module, not standalone:

**For NixOS** (in host's home.nix):

```nix
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  home-manager.users."${user.username}" = { ... };
}
```

**For nix-darwin** (in host's home.nix):

```nix
{
  imports = [
    inputs.home-manager.darwinModules.home-manager
  ];

  home-manager.users."${user.username}" = { ... };
}
```

This ensures home-manager runs as part of `nixos-rebuild` or `darwin-rebuild`, not separately.

**Standalone home-manager** is only needed for:

- Non-NixOS Linux distributions
- Systems where you don't have root access
- Shared user environments

## Migration Procedure for AI Agents

When adapting an existing NixOS configuration, follow these steps:

### Phase 1: Analysis

1. **Identify current structure**:
   - Locate all configuration files
   - Map dependencies between files
   - Identify system vs. user configurations
   - Note all user-specific data (username, email, SSH keys)

2. **Categorize modules**:
   - System-level: goes to nix-modules/
   - User-level: goes to home-modules/
   - Host-specific: stays in hosts/

3. **Extract user data**:
   - Collect all user-specific values
   - Plan specialArgs structure

### Phase 2: Restructure

1. **Create directory structure**:

```
.
├── flake.nix
├── nix-modules/
│   └── default.nix
├── home-modules/
│   └── default.nix
└── hosts/
    └── hostname/
        ├── configuration.nix
        ├── home.nix
        └── hardware-configuration.nix
```

2. **Create flake.nix**:
   - Define inputs with follows pattern
   - Create specialArgs with user data
   - Expose module registries
   - Define nixosConfigurations
   - Add formatter, checks, devShells

3. **Create module registries**:
   - nix-modules/default.nix
   - home-modules/default.nix

### Phase 3: Module Extraction

1. **Extract NixOS modules**:
   - Create common-nix.nix with base system config
   - Extract feature modules (gui, laptop, etc.)
   - Make modules parametric (accept pkgs, user, etc.)

2. **Extract Home Manager modules**:
   - Create common-home.nix with base user config
   - Extract per-program configs
   - Parametrize with user data

3. **Create host configurations**:
   - Write configuration.nix importing shared modules
   - Create home.nix for Home Manager integration
   - Preserve hardware-configuration.nix

### Phase 4: Testing

1. **Validate syntax**:

   ```bash
   nix flake check
   ```

2. **Test build**:

   ```bash
   nixos-rebuild build --flake .#hostname
   ```

3. **Dry-run activation**:

   ```bash
   nixos-rebuild dry-activate --flake .#hostname
   ```

4. **Full switch** (after backups):
   ```bash
   nixos-rebuild switch --flake .#hostname
   ```

## Common Patterns

### Pattern: Conditional Module Import

```nix
{
  imports = lib.flatten [
    (with outputs.nixosModules; [
      (common-nix {inherit pkgs user;})
      laptop
    ])
    # Conditional import
    (lib.optional config.services.xserver.enable outputs.nixosModules.gui)
  ];
}
```

### Pattern: Module with Optional Parameters

```nix
# nix-modules/common-nix.nix
{
  pkgs,
  user,
  lib ? pkgs.lib,  # Optional with default
  ...
}: {
  # Configuration
}
```

### Pattern: Calling Parametric Modules

Non-parametric (takes no arguments):

```nix
imports = [
  outputs.nixosModules.laptop
  outputs.nixosModules.gui
];
```

Parametric (function call):

```nix
imports = [
  (outputs.nixosModules.common-nix {inherit pkgs user;})
  (outputs.homeManagerModules.git {inherit pkgs user;})
];
```

### Pattern: lib.flatten for Mixed Imports

```nix
imports = lib.flatten [
  # List of regular imports
  (with outputs.nixosModules; [
    (common-nix {inherit pkgs user;})
    laptop
  ])
  # Single import
  ./hardware-configuration.nix
  # Conditional import (may be empty list)
  (lib.optional someCondition someModule)
];
```

### Pattern: Standalone Home Manager Config

For servers or non-NixOS systems:

```nix
homeConfigurations."username" = inputs.home-manager.lib.homeManagerConfiguration {
  pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
  extraSpecialArgs = {
    inherit inputs outputs;
    inherit (specialArgs) user;
  };
  modules = [
    outputs.homeManagerModules.bash
    outputs.homeManagerModules.git
    # ...
    {
      home.username = specialArgs.user.username;
    }
  ];
};
```

## Module Design Guidelines

### NixOS Module Template

```nix
{
  pkgs,
  user,
  lib,
  config,
  ...
}: {
  # Use optionals for conditional config
  environment.systemPackages = lib.optionals config.services.xserver.enable [
    pkgs.gui-app
  ];

  # Reference user data from specialArgs
  users.users."${user.username}" = {
    # ...
  };

  # Group related configuration
  services = {
    # Related services together
  };
}
```

### Home Manager Module Template

```nix
{
  pkgs,
  user,
  lib,
  config,
  inputs,
  ...
}: {
  # Program-specific configuration
  programs.git = {
    enable = true;
    settings.user = {
      inherit (user) name email;
    };
  };

  # Package installation
  home.packages = with pkgs; [
    package1
    package2
  ];

  # Direct file management if needed
  xdg.configFile."app/config".text = ''
    # config content
  '';
}
```

## Anti-Patterns to Avoid

1. **Exposing unnecessary flake outputs**: Keep outputs minimal
2. **Not using follows for inputs**: Always follow nixpkgs
3. **Hardcoding user data in modules**: Use specialArgs
4. **Mixing system and user config**: Separate nix-modules and home-modules
5. **Standalone home-manager when not needed**: Integrate as NixOS module
6. **Complex default.nix registries**: Keep them simple attribute sets
7. **Non-parametric modules with repeated code**: Parametrize for reuse
8. **Deep nesting in flake.nix**: Keep logic in modules

## Advanced Patterns

### Multi-User Support

```nix
specialArgs = {
  inherit inputs outputs;
  users = {
    alice = {
      name = "Alice";
      username = "alice";
      email = "alice@example.com";
      # ...
    };
    bob = {
      name = "Bob";
      username = "bob";
      email = "bob@example.com";
      # ...
    };
  };
};
```

Then in configuration:

```nix
{users, ...}: {
  imports = [
    (import ./home.nix {user = users.alice; inherit inputs outputs pkgs lib;})
    (import ./home-bob.nix {user = users.bob; inherit inputs outputs pkgs lib;})
  ];
}
```

### Module Options

For more complex modules, define options:

```nix
{lib, config, pkgs, ...}: {
  options.myModule = {
    enable = lib.mkEnableOption "My module";
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.myPackage;
    };
  };

  config = lib.mkIf config.myModule.enable {
    # Configuration when enabled
  };
}
```

### System-Specific Configurations

```nix
# In flake.nix
specialArgs = rec {
  inherit inputs outputs;
  systems = {
    x86_64-linux = {
      pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
    };
    aarch64-linux = {
      pkgs = inputs.nixpkgs.legacyPackages.aarch64-linux;
    };
  };
};
```

## Development Workflow

### Formatter Integration

```nix
formatter.x86_64-linux = inputs.treefmt-nix.lib.mkWrapper
  inputs.nixpkgs.legacyPackages.x86_64-linux
  {
    projectRootFile = "flake.nix";
    programs = {
      alejandra.enable = true;  # Nix formatter
      deadnix.enable = true;    # Remove dead code
      statix.enable = true;     # Lint anti-patterns
      shellcheck.enable = true; # Shell script linting
    };
  };
```

Run with: `nix fmt`

### Pre-commit Checks

```nix
checks.x86_64-linux.pre-commit-check = inputs.git-hooks-nix.lib.x86_64-linux.run {
  src = self.outPath;
  hooks = {
    treefmt = {
      package = outputs.formatter.x86_64-linux;
      enable = true;
    };
    end-of-file-fixer.enable = true;
    typos.enable = true;
  };
};
```

### Dev Shell

```nix
devShells.x86_64-linux.default = inputs.nixpkgs.legacyPackages.x86_64-linux.mkShell {
  inherit (self.checks.x86_64-linux.pre-commit-check) shellHook;
  buildInputs = self.checks.x86_64-linux.pre-commit-check.enabledPackages;
};
```

Enter with: `nix develop`

## Testing Strategy

1. **Syntax validation**: `nix flake check`
2. **Build test**: `nixos-rebuild build --flake .#hostname`
3. **Dry activation**: `nixos-rebuild dry-activate --flake .#hostname`
4. **VM test**: `nixos-rebuild build-vm --flake .#hostname`
5. **Live switch**: `nixos-rebuild switch --flake .#hostname`

## File Organization Checklist

- [ ] `flake.nix`: Minimal, ~100-150 lines
- [ ] `flake.lock`: Auto-generated
- [ ] `nix-modules/default.nix`: Simple registry
- [ ] `nix-modules/*.nix`: Parametric NixOS modules
- [ ] `home-modules/default.nix`: Simple registry
- [ ] `home-modules/*.nix`: Parametric Home Manager modules
- [ ] `hosts/*/configuration.nix`: Host system config
- [ ] `hosts/*/home.nix`: Home Manager integration
- [ ] `hosts/*/hardware-configuration.nix`: Hardware-specific
- [ ] `.gitignore`: Ignore result symlinks
- [ ] Development tooling integrated (formatter, checks, devShell)

## Example Migration: Simple Configuration

**Before** (monolithic configuration.nix):

```nix
{ config, pkgs, ... }: {
  imports = [ ./hardware-configuration.nix ];

  users.users.alice = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };

  programs.git = {
    enable = true;
    config = {
      user.name = "Alice";
      user.email = "alice@example.com";
    };
  };

  environment.systemPackages = with pkgs; [ vim htop ];
}
```

**After** (flake-based):

`flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {self, ...}: let
    specialArgs = {
      inherit inputs;
      outputs = self;
      user = {
        name = "Alice";
        username = "alice";
        email = "alice@example.com";
        homedir = "/home/alice";
      };
    };
  in {
    nixosModules = import ./nix-modules;
    homeManagerModules = import ./home-modules;

    nixosConfigurations.myhost = inputs.nixpkgs.lib.nixosSystem {
      inherit specialArgs;
      modules = [ ./hosts/myhost/configuration.nix ];
    };
  };
}
```

`nix-modules/default.nix`:

```nix
{
  common-nix = import ./common-nix.nix;
}
```

`nix-modules/common-nix.nix`:

```nix
{ pkgs, user, ... }: {
  users.users."${user.username}" = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };

  environment.systemPackages = with pkgs; [ vim htop ];
}
```

`home-modules/default.nix`:

```nix
{
  git = import ./git.nix;
}
```

`home-modules/git.nix`:

```nix
{ user, ... }: {
  programs.git = {
    enable = true;
    settings.user = {
      inherit (user) name email;
    };
  };
}
```

`hosts/myhost/configuration.nix`:

```nix
{ inputs, outputs, user, lib, pkgs, ... }: {
  imports = lib.flatten [
    (with outputs.nixosModules; [
      (common-nix {inherit pkgs user;})
    ])
    (import ./home.nix {inherit inputs outputs user pkgs lib;})
    ./hardware-configuration.nix
  ];
}
```

`hosts/myhost/home.nix`:

```nix
{ inputs, outputs, user, pkgs, ... }: {
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  home-manager.users."${user.username}" = {lib, ...}: {
    imports = with outputs.homeManagerModules; [
      (git {inherit user;})
    ];
  };
}
```

## Summary

This architecture achieves:

1. **Minimal flake surface**: Only essential outputs exposed
2. **Maximum reusability**: Parametric modules shared across hosts
3. **Clear organization**: System vs. user, shared vs. host-specific
4. **Single source of truth**: User data in specialArgs
5. **Type safety**: Nix language ensures correctness
6. **Version consistency**: All inputs follow nixpkgs
7. **Development integration**: Formatter, checks, dev shell included

When migrating configurations, always:

- Extract user data to specialArgs
- Categorize modules (system vs. user)
- Make modules parametric
- Use simple registries
- Keep flake.nix minimal
- Test incrementally

This architecture scales from single-user single-host to multi-user multi-host deployments while maintaining clarity and efficiency.
