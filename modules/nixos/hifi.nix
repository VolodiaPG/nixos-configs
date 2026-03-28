# Hi-Fi Audio Configuration for External USB DAC
#
# Optimizations applied:
# - Latency: ~10ms default (512/48000) for good lip-sync
# - Quality: Resample quality 10, Kaiser window, triangular-hf dither
# - Stability: USB autosuspend disabled, threaded IRQs, larger buffers for USB DACs
# - Bit-perfect: Sample rate switching to match source (44100-192000)
#
# To verify settings: pw-top (check QUANTUM and RATE columns)
# To check for xruns: pw-metadata -n settings | grep xrun

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
    # Enable threaded IRQs and disable USB autosuspend for audio stability
    boot.kernelParams = [
      "threadirqs"
      "usbcore.autosuspend=-1"
      "intel_pstate=passive"
    ];

    # Disable USB autosuspend for audio devices to prevent crackling
    services.udev.extraRules = ''
      # Disable USB autosuspend for all USB audio devices
      ACTION=="add", SUBSYSTEM=="usb", ATTR{bInterfaceClass}=="01", ATTR{power/autosuspend}="-1", ATTR{power/control}="on"
    '';

    # Real-time audio priorities
    security.rtkit.enable = true;
    security.pam.loginLimits = [
      {
        domain = "@audio";
        item = "rtprio";
        type = "-";
        value = "99";
      }
      {
        domain = "@audio";
        item = "memlock";
        type = "-";
        value = "unlimited";
      }
      {
        domain = "@audio";
        item = "nice";
        type = "-";
        value = "-20";
      }
    ];

    # From https://github.com/Gurjaka/Dotfiles/blob/f49e7adfc815d3b2adfd2406133d53cb642ec04e/nixos/modules/sound.nix#L57
    # Look at https://github.com/bilalmirza74/Dotfiles/blob/9a6389f0b2c47baf9dc17404bbeffcfc979bda91/nixos/modules/sound.nix#L42
    services = {
      pulseaudio.enable = false;
      pipewire = {
        enable = true;
        alsa.enable = true;
        pulse.enable = true;
        alsa.support32Bit = true;
        jack.enable = true;

        # Pulse configuration optimized for low latency and quality
        extraConfig.pipewire-pulse = {
          "99-pulse-custom" = {
            pulse.properties = {
              # ~10ms default for good lip-sync, min ~5ms, max ~21ms
              "pulse.min.req" = "256/48000";
              "pulse.default.req" = "512/48000";
              "pulse.min.frag" = "256/48000";
              "pulse.default.frag" = "512/48000";
              "pulse.default.tlength" = "512/48000";
              "pulse.min.quantum" = "256/48000";
              # High quality resampling for Pulse clients
              "resample.quality" = 10;
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
                176400
                192000
              ];
              # Let PipeWire choose rate based on source (bit-perfect when possible)
              "default.clock.force-rate" = 0;
              "default.clock.quantum-floor" = 4;
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
              "default.clock.quantum" = 1024;
              "default.clock.min-quantum" = 512;
              "default.clock.max-quantum" = 2048;
              "default.clock.quantum-limit" = 8192;
              "default.clock.monotonic" = true;
              "clock.power-of-two-quantum" = true;
            };
          };

          "13-audiophile-quality" = {
            stream.properties = {
              "resample.quality" = 10;
              "resample.disable" = false;
              "resample.window" = "kaiser";
              "convert.dither.method" = "triangular-hf";
              "node.pause-on-idle" = false;
              "node.latency" = "512/48000";
              "audio.format" = "F32LE"; # 32-bit float for headroom
              "audio.allowed-rates" = "44100,48000,88200,96000,176400,192000";
              "audio.position" = "FL,FR";
              "resample.peaks" = false;
            };
          };

          "14-anti-xrun" = {
            context.modules = [
              {
                name = "libpipewire-module-rt";
                args = {
                  # 2. Prevent the core RT scheduler from fighting LAVD.
                  # Setting this to 0 disables SCHED_FIFO and lets LAVD "see" and manage the thread.
                  "nice.level" = -15;
                  "rt.prio" = 0;
                  "rt.time.soft" = -1;
                  "rt.time.hard" = -1;
                };
                flags = [
                  "ifexists"
                  "nofail"
                ];
              }
            ];
          };
        };

        # ALSA optimizations for USB DAC stability
        wireplumber = {
          enable = true;
          extraConfig = {
            "10-alsa-headroom" = {
              "monitor.alsa.rules" = [
                {
                  matches = [
                    { "node.name" = "~alsa_output.*"; }
                  ];
                  actions = {
                    update-props = {
                      "api.alsa.headroom" = 1024;
                    };
                  };
                }
              ];
            };
            # USB DAC-specific rules to prevent crackling
            "51-usb-dac-config" = {
              "monitor.alsa.rules" = [
                {
                  matches = [
                    {
                      "device.bus-path" = "usb";
                    }
                  ];
                  actions = {
                    update-props = {
                      # Larger period size for USB stability
                      "api.alsa.period-size" = 1024;
                      # Headroom to prevent underruns
                      "api.alsa.headroom" = 1024;
                      # Disable batch mode for lower latency
                      "api.alsa.disable-batch" = true;
                      # Enable mmap (better for USB)
                      "api.alsa.disable-mmap" = false;
                      # Support all hi-res rates
                      "audio.allowed-rates" = "44100,48000,88200,96000,176400,192000";
                      # Never idle - keeps DAC active
                      "session.suspend-timeout-seconds" = 0;
                    };
                  };
                }
              ];
            };

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

    };
    environment.systemPackages = with pkgs; [
      pavucontrol
      helvum
      qpwgraph
      alsa-utils
      pulseaudio
      pipewire # for pw-top, pw-metadata, pw-config
      easyeffects # optional: for room correction/EQ if needed
    ];
  };
}
