{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.services.hifi;
in
{
  options = {
    services.hifi = with types; {
      enable = mkEnableOption "high-quality audio";
    };
  };

  config = mkIf cfg.enable {
    security.rtkit.enable = true;

    # From https://github.com/Gurjaka/Dotfiles/blob/f49e7adfc815d3b2adfd2406133d53cb642ec04e/nixos/modules/sound.nix#L57
    # Look at https://github.com/bilalmirza74/Dotfiles/blob/9a6389f0b2c47baf9dc17404bbeffcfc979bda91/nixos/modules/sound.nix#L42
    services = {
      pulseaudio.enable = false;
      pipewire = {
        # Pulse configuration optimized for low-impedance IEMs
        extraConfig.pipewire-pulse = {
          "99-pulse-custom" = {
            pulse.properties = {
              "pulse.min.req" = "1024/48000";
              "pulse.default.req" = "1024/48000";
              "pulse.min.frag" = "1024/48000";
              "pulse.default.frag" = "1024/48000";
              "pulse.default.tlength" = "1024/48000";
            };
          };
        };

        extraConfig.pipewire = {
          "10-clock-rate" = {
            context.properties = {
              "default.clock.rate" = 48000;
              "default.clock.allowed-rates" = [
                44100
                48000
                88200
                96000
              ];
              "default.clock.force-rate" = 0;
            };
          };

          "11-mix-settings" = {
            stream.properties = {
              "channelmix.upmix" = false;
              "channelmix.downmix" = false;
              "channelmix.normalize" = false;
              "channelmix.mix-lfe" = false;
            };
          };

          "12-buffer-quality" = {
            context.properties = {
              "default.clock.power-of-zero" = false;
              "default.clock.quantum" = 1024;
              "default.clock.min-quantum" = 1024;
              "default.clock.max-quantum" = 1024;
              "default.clock.monotonic" = true;
              "clock.power-of-two-quantum" = true;
            };
          };

          "13-audiophile-quality" = {
            stream.properties = {
              "resample.quality" = 10;
              "resample.disable" = false;
              "convert.dither.method" = "triangular-hf"; # Better for sensitive transducers
              "node.pause-on-idle" = false;
              "node.latency" = "1024/48000";
              "audio.format" = "F24LE";
              "audio.position" = "FL,FR";
              "audio.convert" = "none";
              "resample.peaks" = false;
            };
          };

          "14-anti-xrun" = {
            context.modules = [
              {
                name = "libpipewire-module-rt";
                args = {
                  "nice.level" = -19; # Higher priority for audio thread
                  "rt.prio" = 99; # Maximum RT priority
                  "rt.time.soft" = 1000000; # 1 second soft limit
                  "rt.time.hard" = 1000000; # 1 second hard limit
                };
                flags = [
                  "ifexists"
                  "nofail"
                ];
              }
            ];
          };
        };

        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        jack.enable = true;

        # ALSA optimizations for direct hardware access
        wireplumber.extraConfig = {
          # Bluetooth codec preferences (if using wireless)
          bluetooth-monitor = {
            properties = {
              "bluez5.enable-sbc-xq" = true;
              "bluez5.enable-msbc" = true;
              "bluez5.enable-hw-volume" = true;
              "bluez5.codec.ldac.quality" = "hq";
              "bluez5.codec.aac.bitrate" = 320000;
            };
          };
        };
      };

    };
    environment.systemPackages = with pkgs; [
      pavucontrol
      helvum
      qpwgraph
      alsa-utils
      pulseaudio
    ];
  };
}
