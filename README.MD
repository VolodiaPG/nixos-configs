https://github.com/Maxwell-lt/machine-configuration/tree/master/pkgs
https://github.com/xddxdd/nixos-config/tree/master/nixos/client-components
https://github.com/mrkkrp/nixos-config/tree/master/imports/symlinks

https://github.com/LunNova/nixos-configs/blob/dev/flake.nix
https://github.com/kclejeune/system/blob/master/modules/home-manager/default.nix

Migration inspired from: https://gist.github.com/misuzu/80af74212ba76d03f6a7a6f2e8ae1620

https://www.lucacambiaghi.com/nixpkgs/readme.html#orga1939e8

nix-build -E "with import <nixpkgs> {}; callPackage ./default.nix {}"

Resources:
Lan Tian: https://lantian.pub/en/article/modify-website/nixos-why.lantian/
Awesome Nix: https://nix-community.github.io/awesome-nix/#community
Hardware specifics: https://github.com/NixOS/nixos-hardware/blob/master/common/gpu/intel.nix
ZFS (encrypted) install: https://timklampe.cool/docs/example/nixos/nixos_install/ + compression https://linuxhint.com/enable-zfs-compression/

inspiration:
https://github.com/sandydoo/vapoursynth-on-nix


BTRFS
https://gist.github.com/hadilq/a491ca53076f38201a8aa48a0c6afef5 (encrypted = https://gist.github.com/walkermalling/23cf138432aee9d36cf59ff5b63a2a58)

#https://searx.be/?preferences=eJxtV0uTpDYM_jXhQs1UNntI5dCnVOWarcreKWGrQYNtsX40zfz6yEA3ppnDsu1PtixLnx6jIGLHnjBcOnTowfz2x99kocMgP4IidAorA65Lgl3AmMqwAoMXdBWkyIrtaDDipWPuDFbL2Wb0fJ8vP33CymLsWV9-_PvfzyrAFQOCV_3l9yr2aPHCQYGvPIZkYmjYNQ6nJkJ7-QdMwEozNSJkc0N_YZDlO_uuWk69hTiLIYY7UqzxVgXKtjQrnI2rFLqIvgFDnZWfm1LQN5Bn6WazZUV_JfRzQ66JFOX8Yjy5KzmKolN5NmYFNQVojRxH15ETz8E41Ja8Z980VzKL62AUU2r51iGyx0IgN9INawpNs7scfCTVNE_Pt-S6Up7X9Sp92VXfSCMLuv6_oLFNasAoO6OslVJv8VZs4BGd-DNgoWrGsbxPJW8IS0QjfoorG5sCqWV9I3BRDC-0aN3VGhefEbvDC9HzRLppWOLuZT3RQBoiHO4Qs_O_jr9Gzx5Y3WxhFFC--R7LHzSiJtjv-nYvjly152zIIyBXQ2rw5QaPWAe-xgk81po8KgnhvHnz6skNBGWwOuqEEBBiabX8isyPEAg_W_Tdtlxz5Ry5DR8NzJk6YTeylFi-ER6Ojax1GZseWg_5s93XL6e3BVnd7q4hB4WmDwo978JBPAOhMMOQKPZznZ8ZqBB8vm2i816-1opdJ1lcBs5wGyK--7BZBZ9m9qTC_giHeDuww4122-xmgP2iTGePIxfmjCCGdxQeKTCm9l0Iu61-TULcUvMCnMm1wqcoBRwJ1tJxQDOQA13nz5MtYCF74gGEnDFjrpHF_ZGHmSOL7wdw-yviRDGXryawIjC1zawWPLkgRAh9mb7Q8yFpZk4xtVgY-ESeGQxkZss5U4ttN7LIxXqidi4VW_BS9eRNh9hIR7iD0_6I5hxvmYfwCkqRFyx_N-BX4oivuwInr05orlwU5xPM84tXNan4ye6IJY1uJ3jATwf28Dz-QBwOtINbjsEO-NTOHdoHc0dE_-LqJVByxSCJOk3YFiKfbGvKvRPfaWAn9KzD7NjNFgv7Psb3cXLHqmmlvB56gxcLS2DEmDvaStAv4TPXS-EhOmsQ-rSkUoXu2Pr-6qA78XNRYsile53tfWS4v5Nk4DZTZLuFMArsuDMy795K90vrO5jURk1dt-eJ9OYQPF5L5dLAvPw80ESzdEVf96ndTIryhvngOoySEU5sL4IgUkpFYepkPoCHClns-rqtzhZdYK3bJ3dv-OFZGxZUzwZ8-RhyQhfiVFahAnsYJmZ3x5Jp6a4MJ73vsSDdCx-NIZdOkAaXG3FAGcCKSx8yqZ3SIWFr6Ed5iNIrozTeR_cddU6EfdPYS11zTyl5mTdbKLqEaBfaHI7MI5WF-ugksVVTPFFOWCpkOj5VSq0aWJL3anh6kDAMqU0upkc5TiP6FJ4OCSgOklHsqyjIFEpaJgHhVSx6zVJ669eKlt21tMNn5rJZm8HYF5OJlXS3MlzU0YMLRrxTjEjfvn__875fNLHXjoZdLn1la6D7TDqaJJkZLjmV7-_b6l2sblSPatga1S6Rct9IjAacwzO5v9bR546zLk5aeg5RCinKrC6dafXWYQNDs47yk5dx-iTeipUwRa1_kMwymxuZu77Yaa4ypF_5JBEP5vRuZHKVe2wOfCWNVUh6-R8pEd_O&q=%s


https://www.reddit.com/r/linux/comments/l1re17/psa_by_default_firefox_on_linux_doesnt_match_with/

MacOS fix
sudo chown -R volodia:staff /nix


mount -o subvol=,ssd,compress-force=zstd:2,noatime,discard=async,space_cache=v2,autodefrag /dev/disk/by-label/root /mnt