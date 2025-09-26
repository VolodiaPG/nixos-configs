{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.services.hifi;
  # profiles = {
  #   audiophile = {
  #     sampleRate = 96000;
  #     bitDepth = "S24_3LE";
  #     bufferSize = 16384 * 4;
  #     resampleQuality = 15;
  #     description = "Maximum quality for critical listening";
  #   };
  #
  #   balanced = {
  #     sampleRate = 48000;
  #     bitDepth = "S24_3LE";
  #     bufferSize = 512;
  #     resampleQuality = 10;
  #     description = "Good quality with reasonable resource usage";
  #   };
  #
  #   efficient = {
  #     sampleRate = 48000;
  #     bitDepth = "S16_LE";
  #     bufferSize = 256;
  #     resampleQuality = 4;
  #     description = "Lower resource usage for battery-powered devices";
  #   };
  #
  #   studio = {
  #     sampleRate = 192000;
  #     bitDepth = "S32_LE";
  #     bufferSize = 8192;
  #     resampleQuality = 15;
  #     description = "Studio-grade quality for professional audio work";
  #   };
  # };
  #
  # selectedProfile =
  #   if cfg.profile != "custom" then
  #     profiles.${cfg.profile}
  #   else
  #     {
  #       inherit (cfg)
  #         sampleRate
  #         bitDepth
  #         bufferSize
  #         resampleQuality
  #         ;
  #     };
in
{
  options = {
    services.hifi = with types; {
      enable = mkEnableOption "high-quality audio";

      profile = mkOption {
        type = enum [
          "audiophile"
          "balanced"
          "efficient"
          "studio"
          "custom"
        ];
        default = "balanced";
        description = "Audio quality profile preset";
      };

      sampleRate = mkOption {
        type = int;
        default = 96000;
        description = "Audio sample rate (used only with custom profile)";
      };

      bitDepth = mkOption {
        type = enum [
          "S16_LE"
          "S24_3LE"
          "S32_LE"
        ];
        default = "S24_3LE";
        description = "Audio bit depth format (used only with custom profile)";
      };

      bufferSize = mkOption {
        type = int;
        default = 512;
        description = "Audio buffer size (used only with custom profile)";
      };

      resampleQuality = mkOption {
        type = int;
        default = 10;
        description = "Resampling quality 0-15 (used only with custom profile)";
      };
    };
  };

  config = mkIf cfg.enable {
    security.rtkit.enable = true;

    # From https://github.com/Gurjaka/Dotfiles/blob/f49e7adfc815d3b2adfd2406133d53cb642ec04e/nixos/modules/sound.nix#L57
    # Look at https://github.com/bilalmirza74/Dotfiles/blob/9a6389f0b2c47baf9dc17404bbeffcfc979bda91/nixos/modules/sound.nix#L42

    services.pipewire = {
      enable = true;

      # Pulse configuration optimized for low-impedance IEMs
      extraConfig.pipewire-pulse = {
        "99-pulse-custom" = {
          pulse.properties = {
            # Smaller buffer sizes for lower latency with sensitive IEMs
            "pulse.min.req" = "512/48000";
            "pulse.default.req" = "512/48000";
            "pulse.min.frag" = "512/48000";
            "pulse.default.frag" = "512/48000";
            "pulse.default.tlength" = "1024/48000";
            # Better volume handling for sensitive drivers
            "pulse.default.volume" = 0.5;
            "pulse.volume.limit" = 0.8;
          };
        };
      };

      extraConfig.pipewire = {
        "10-clock-rate" = {
          context.properties = {
            "default.clock.rate" = 48000;
            # Add hi-res rates that complement the Aria 2's capabilities
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

        "11-mix-settings" = {
          stream.properties = {
            "channelmix.upmix" = false;
            "channelmix.downmix" = false;
            "channelmix.normalize" = false;
            # Preserve dynamic range for detailed IEMs
            "stream.audio.rate" = 1.0;
            "stream.audio.volume" = 0.7; # Conservative volume for sensitive IEMs
            "channelmix.mix-lfe" = false;
          };
        };

        "12-buffer-quality" = {
          context.properties = {
            "default.clock.power-of-zero" = false;
            # Smaller quantum for responsive audio with IEMs
            "default.clock.quantum" = 512;
            "default.clock.min-quantum" = 512;
            "default.clock.max-quantum" = 1024;
            "default.clock.monotonic" = true;
            # Better timing precision
            "clock.power-of-two-quantum" = true;
          };
        };

        "13-audiophile-quality" = {
          stream.properties = {
            # Maximum resampling quality for detail retrieval
            "resample.quality" = 15;
            "resample.disable" = false;
            # 32-bit float processing for headroom
            "convert.mix.bitdepth" = 32;
            "convert.dither.method" = "triangular-hf"; # Better for sensitive transducers
            "node.pause-on-idle" = false;
            "node.latency" = "512/48000";
            "audio.format" = "F32LE";
            "audio.position" = "FL,FR";
            # Preserve audio fidelity
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

        # Additional config for IEM-specific optimizations
        "15-iem-optimizations" = {
          stream.properties = {
            # Disable unnecessary processing that can add noise
            "filter.graph" = "";
            "audio.adapt.follower" = "";
            # Ensure bit-perfect output when possible
            "audio.rate" = 48000;
            "audio.channels" = 2;
            # Optimize for stereo imaging of IEMs
            "channelmix.disable" = true;
          };
          context.properties = {
            # Reduce system audio interference
            "support.dbus" = false;
            # Optimize scheduling for audio priority
            "default.clock.force-quantum" = 512;
          };
        };

        # Low-latency profile for gaming/monitoring
        "16-low-latency-profile" = {
          context.properties = {
            "default.clock.quantum" = 256;
            "default.clock.min-quantum" = 256;
            "default.clock.max-quantum" = 512;
          };
          stream.properties = {
            "node.latency" = "256/48000";
            "resample.quality" = 4; # Lower quality but faster processing
          };
          # Uncomment the flag below to enable low-latency mode
          # flags = ["default"];
        };
      };

      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;

      # ALSA optimizations for direct hardware access
      wireplumber.extraConfig = {
        alsa-monitor = {
          properties = {
            "alsa.use-acp" = false;
            "alsa.midi" = false; # Disable if not needed
            # Better hardware parameter handling
            "api.alsa.period-size" = 512;
            "api.alsa.period-num" = 2;
            "api.alsa.headroom" = 1024;
            # Disable hardware mixing for pure output
            "api.alsa.disable-mmap" = false;
            "api.alsa.use-chmap" = false;
          };
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

    # System-level audio optimizations
    # boot.kernel.sysctl = {
    #   # Reduce audio dropouts
    #   "vm.swappiness" = 1;
    #   # Better real-time scheduling
    #   "kernel.sched_rt_runtime_us" = 950000;
    #   "kernel.sched_rt_period_us" = 1000000;
    # };

    # security.rtkit.enable = true;
    #
    # services = {
    #   pulseaudio.enable = false;
    #
    #   pipewire = {
    #     enable = true;
    #
    #     alsa = {
    #       enable = true;
    #       support32Bit = true;
    #     };
    #     pulse.enable = true;
    #     jack.enable = true;
    #
    #     extraConfig = {
    #       pipewire = {
    #         "92-hifi-quality" = {
    #           context.properties = {
    #             default.clock = {
    #               rate = selectedProfile.sampleRate;
    #               quantum = selectedProfile.bufferSize;
    #               min-quantum = selectedProfile.bufferSize;
    #               max-quantum = selectedProfile.bufferSize * 16;
    #             };
    #             core = {
    #               daemon = true;
    #               name = "pipewire-hifi";
    #             };
    #             settings = {
    #               check-quantum = false;
    #               check-rate = false;
    #             };
    #             link.max-buffers = 64;
    #             mem = {
    #               warn-mlock = false;
    #               allow-mlock = true;
    #             };
    #           };
    #         };
    #
    #         "93-hifi-nodes" = {
    #           context.objects = [
    #             {
    #               factory = "adapter";
    #               args = {
    #                 factory.name = "api.alsa.pcm.sink";
    #                 node = {
    #                   name = "hifi-sink";
    #                   description = "Hi-Fi Audio Sink";
    #                   media.class = "Audio/Sink";
    #                   audio = {
    #                     channels = 2;
    #                     position = [
    #                       "FL"
    #                       "FR"
    #                     ];
    #                   };
    #                 };
    #                 api.alsa = {
    #                   period-size = selectedProfile.bufferSize;
    #                   period-num = 3;
    #                   headroom = 0;
    #                   start-delay = 0;
    #                   disable-mmap = false;
    #                   disable-batch = false;
    #                 };
    #                 audio = {
    #                   format = selectedProfile.bitDepth;
    #                   rate = selectedProfile.sampleRate;
    #                   channels = 2;
    #                   position = [
    #                     "FL"
    #                     "FR"
    #                   ];
    #                 };
    #               };
    #             }
    #           ];
    #         };
    #       };
    #
    #       pipewire-pulse = {
    #         "92-hifi-pulse" = {
    #           context.modules = [
    #             {
    #               name = "libpipewire-module-protocol-pulse";
    #               args = {
    #                 pulse = {
    #                   min.req = "${toString selectedProfile.bufferSize}/${toString selectedProfile.sampleRate}";
    #                   default.req = "${toString selectedProfile.bufferSize}/${toString selectedProfile.sampleRate}";
    #                   max.req = "${toString (selectedProfile.bufferSize * 16)}/${toString selectedProfile.sampleRate}";
    #                 };
    #                 pulse = {
    #                   min.quantum = "${toString selectedProfile.bufferSize}/${toString selectedProfile.sampleRate}";
    #                   max.quantum = "${
    #                     toString (selectedProfile.bufferSize * 16)
    #                   }/${toString selectedProfile.sampleRate}";
    #                 };
    #                 server.address = [ "unix:native" ];
    #               };
    #             }
    #           ];
    #           stream.properties = {
    #             node.latency = "${toString selectedProfile.bufferSize}/${toString selectedProfile.sampleRate}";
    #             resample = {
    #               quality = selectedProfile.resampleQuality;
    #               disable = false;
    #             };
    #             channelmix = {
    #               normalize = false;
    #               mix-lfe = false;
    #             };
    #             audio = {
    #               channels = 2;
    #               format = selectedProfile.bitDepth;
    #               rate = selectedProfile.sampleRate;
    #             };
    #           };
    #         };
    #       };
    #     };
    #
    #     wireplumber = {
    #       enable = true;
    #       extraConfig."51-hifi-priority" = {
    #         "monitor.alsa.properties" = {
    #           "alsa.jack-device" = false;
    #           "alsa.reserve" = false;
    #         };
    #         "monitor.alsa.rules" = [
    #           {
    #             matches = [ { "device.name" = "~alsa_card.*"; } ];
    #             actions = {
    #               "update-props" = {
    #                 "device.profile.priority" = 1000;
    #                 "device.profile.pro" = true;
    #               };
    #             };
    #           }
    #         ];
    #       };
    #     };
    #   };
    # };
    #
    # environment.systemPackages = with pkgs; [
    #   pavucontrol
    #   helvum
    #   qpwgraph
    #   alsa-utils
    #   pulseaudio
    # ];
    #
    # boot.kernelParams = [
    #   "snd-hda-intel.power_save=0"
    #   "snd-ac97-codec.power_save=0"
    #   "snd-hda-intel.model=auto"
    #   "snd-hda-intel.probe_mask=1"
    #   "threadirqs"
    #   "irqaffinity=0"
    #   # "intel_idle.max_cstate=1"
    #   # "processor.max_cstate=1"
    # ];
    #
    # security.pam.loginLimits = [
    #   {
    #     domain = "@audio";
    #     item = "memlock";
    #     type = "-";
    #     value = "unlimited";
    #   }
    #   {
    #     domain = "@audio";
    #     item = "rtprio";
    #     type = "-";
    #     value = "95";
    #   }
    #   {
    #     domain = "@audio";
    #     item = "nice";
    #     type = "-";
    #     value = "-19";
    #   }
    #   {
    #     domain = "@audio";
    #     item = "nofile";
    #     type = "soft";
    #     value = "99999";
    #   }
    #   {
    #     domain = "@audio";
    #     item = "nofile";
    #     type = "hard";
    #     value = "99999";
    #   }
    # ];
    #
    # users.users.volodia.extraGroups = [ "audio" ];
    #
    # # systemd.user.services.pipewire = {
    # #   environment = {
    # #     PIPEWIRE_LATENCY = "${toString selectedProfile.bufferSize}/${toString selectedProfile.sampleRate}";
    # #     PIPEWIRE_RATE = toString selectedProfile.sampleRate;
    # #     PIPEWIRE_QUANTUM = toString selectedProfile.bufferSize;
    # #   };
    # #   serviceConfig = {
    # #     CPUSchedulingPolicy = "rr";
    # #     CPUSchedulingPriority = 88;
    # #     IOSchedulingClass = 1;
    # #     IOSchedulingPriority = 4;
    # #   };
    # # };
    #
    # environment.variables = {
    #   PIPEWIRE_LATENCY = "${toString selectedProfile.bufferSize}/${toString selectedProfile.sampleRate}";
    #   PULSE_LATENCY_MSEC = toString (selectedProfile.bufferSize * 1000 / selectedProfile.sampleRate);
    # };
  };
}
