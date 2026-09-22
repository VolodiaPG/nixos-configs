# Audio quality configuration.
#
# The USB DAC is used in ALSA-exclusive mode, so PipeWire never touches it
# during hi-fi listening — none of this config can improve that path, and
# tuning PipeWire as if it owned the DAC (forcing a stereo channel map,
# disabling downmix, keeping every node powered) only broke everything else
# that *does* go through PipeWire: movies, games, calls, Bluetooth. This
# module instead leaves PipeWire free to negotiate channels/rate per
# source and sink, and only adds settings that are unconditionally good:
# stable USB audio, RT scheduling headroom, and rate-matching to avoid
# unnecessary resampling.
#
# To verify: pw-top (QUANTUM/RATE columns), pw-metadata -n settings | grep xrun

{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.my.hifi;
in
{
  options = {
    my.hifi = {
      enable = mkEnableOption "high-quality audio";
    };
  };

  config = mkIf cfg.enable {
    boot.kernelParams = [
      "threadirqs" # lower IRQ latency, helps avoid xruns
      "usbcore.autosuspend=-1" # avoid USB audio dropouts/crackling
    ];

    services.udev.extraRules = ''
      # Disable USB autosuspend for all USB audio devices
      ACTION=="add", SUBSYSTEM=="usb", ATTR{bInterfaceClass}=="01", ATTR{power/autosuspend}="-1", ATTR{power/control}="on"
    '';

    # Let audio threads (PipeWire/JACK, and exclusive-mode players that
    # request RT priority) get real-time scheduling.
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

        # Reasonable low-latency default for AV sync (~10ms), without
        # forcing a channel map or quality setting onto every client.
        extraConfig.pipewire-pulse = {
          "92-lowlatency" = {
            pulse.properties = {
              "pulse.min.req" = "256/48000";
              "pulse.default.req" = "512/48000";
              "pulse.min.frag" = "256/48000";
              "pulse.default.frag" = "512/48000";
              "pulse.default.tlength" = "512/48000";
              "pulse.min.quantum" = "256/48000";
            };
          };
        };

        extraConfig.pipewire = {
          "50-raop-discover" = {
            "context.modules" = [
              {
                name = "libpipewire-module-raop-discover";
                args = { };
              }
            ];
          };

          # Let the graph match its rate to the source instead of always
          # resampling to 48kHz, so playback stays bit-perfect when the
          # sink supports the source's rate.
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
            };
          };

          # Slightly better resampling for the (rare) case a client's rate
          # doesn't match the sink and PipeWire actually has to resample.
          # Channel maps and downmix/upmix are left at PipeWire's own
          # defaults so multichannel sources (e.g. a movie's 5.1 track)
          # route to however many channels the sink actually has.
          "13-resample-quality" = {
            stream.properties = {
              "resample.quality" = 7;
              "resample.window" = "kaiser";
            };
          };
        };

        wireplumber = {
          enable = true;
          extraConfig = {
            # Headroom on ALSA outputs to avoid underruns; harmless for
            # any device since it's a buffer size hint, not a rate/channel
            # override.
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

      # Enable Avahi (mdns) for network device discovery
      avahi = {
        enable = true;
        nssmdns4 = true; # Resolves .local domains
      };
    };

    # Open required local firewall ports for AirPlay discovery/streaming
    networking.firewall = {
      allowedUDPPorts = [
        5353
        6001
        6002
      ]; # mDNS and AirPlay RTP streams
    };
    environment.systemPackages = [
      pkgs.pavucontrol
      pkgs.qpwgraph
      pkgs.alsa-utils
      pkgs.pulseaudio
      pkgs.pipewire # for pw-top, pw-metadata, pw-config
      pkgs.easyeffects # optional: for room correction/EQ if needed
    ];
  };
}
