_: {
  config.nixos.desktop =
    {
      pkgs,
      lib,
      ...
    }:
    with lib;
    {
      boot.kernelParams = [
        "threadirqs"
        "usbcore.autosuspend=-1"
        "intel_pstate=passive"
      ];

      services.udev.extraRules = ''
        ACTION=="add", SUBSYSTEM=="usb", ATTR{bInterfaceClass}=="01", ATTR{power/autosuspend}="-1", ATTR{power/control}="on"
      '';

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

      services = {
        pulseaudio.enable = false;
        pipewire = {
          enable = true;
          alsa.enable = true;
          pulse.enable = true;
          alsa.support32Bit = true;
          jack.enable = true;

          extraConfig.pipewire-pulse = {
            "99-pulse-custom" = {
              pulse.properties = {
                "pulse.min.req" = "256/48000";
                "pulse.default.req" = "512/48000";
                "pulse.min.frag" = "256/48000";
                "pulse.default.frag" = "512/48000";
                "pulse.default.tlength" = "512/48000";
                "pulse.min.quantum" = "256/48000";
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
                "audio.format" = "F32LE";
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

          wireplumber = {
            enable = true;
            extraConfig = {
              "10-alsa-headroom" = {
                "monitor.alsa.rules" = [
                  {
                    matches = [ { "node.name" = "~alsa_output.*"; } ];
                    actions.update-props = {
                      "api.alsa.headroom" = 1024;
                    };
                  }
                ];
              };
              "51-usb-dac-config" = {
                "monitor.alsa.rules" = [
                  {
                    matches = [ { "device.bus-path" = "usb"; } ];
                    actions.update-props = {
                      "api.alsa.period-size" = 1024;
                      "api.alsa.headroom" = 1024;
                      "api.alsa.disable-batch" = true;
                      "api.alsa.disable-mmap" = false;
                      "audio.allowed-rates" = "44100,48000,88200,96000,176400,192000";
                      "session.suspend-timeout-seconds" = 0;
                    };
                  }
                ];
              };
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
        qpwgraph
        alsa-utils
        pulseaudio
        pipewire
        easyeffects
      ];
    };
}
