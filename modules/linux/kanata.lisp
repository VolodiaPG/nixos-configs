;;nix run nixpkgs#kanata -- -c modules/linux/kanata.kbd
;; https://github.com/jtroo/kanata/blob/main/docs/locales.adoc


;; (defcfg concurrent-tap-hold yes)


(deflocalkeys-linux
  EXCL 53
  par  12 ;; Close parentheses
   ^    73
)

;; define keys that will be modified (all keys still processed)
(defsrc
  '        1     2     3     4     5     6     7     8     9     0      par    eql        bspc
  tab       a     z     e     r     t     y     u     i     o     p      ^     ;
  caps       q     s     d     f     g     h     j     k     l     m      `     bksl     ret
  lsft nubs   w     x     c     v     b     n     comm  .     EXCL         rsft
  lctl    lmet   lalt           spc                             ralt                    rctl
)

;; default/base layer modifications always active
(deflayer default
      _ _ _ _ _ _ _ _ _ _ _ _ _ _
      _ _ _ _ _ _ _ _ _ _ _ _ _
      lctl _ _ _ _ _ _ _ _ _ _ _ _
      _ _ _ _ _ _ _ _ _ _ _ _ _
      @capsd _ _ _ _ _
)

(deflayer programming
      _ _ @two @three @four @five @six @seven @eight @nine @zero @brack _ _
      _ _ _ _ _ _ _ _ _ _ _ _ _
      lctl _ _ _ _ _ _ _ _ _ _ _ _ _
      @lsd _ _ _ _ _ _ _ _ _ _ @lsd
      @capsp _ @laltd _ _ _
)

(deflayer alt-layer
      _ A-1 A-2 A-3 A-4 A-5 A-6 A-7 A-8 A-9 A-0 _ _ _
      _ _ _ _ _ _ _ _ _ _ _ _ _
      _ _ _ _ _ _ _ _ _ _ _ _ _
      _ _ _ _ _ _ _ _ _ _ _ _ _
      _ _ _ _ _ _
)


(deflayer s-layer
      _ S-1 S-2 S-3 S-4 S-5 S-6 S-7 S-8 S-9 S-0 _ _ _
      _ _ _ _ _ _ _ _ _ _ _ _ _
      _ _ _ _ _ _ _ _ _ _ _ _ _
      _ _ _ _ _ _ _ _ _ _ _ _ _
      _ _ _ _ _ _
)


(defvar
  streak-count 3
  streak-time 325
  tap-timeout 20
  hold-timeout 500
  chord-timeout 50
)

(defchordsv2
  (j k) bspc $chord-timeout all-released ()
  (k l) ret $chord-timeout all-released ()
  (d f) esc $chord-timeout all-released ()
  (s d) Delete $chord-timeout all-released ()
)


(defalias
  capsd (layer-switch programming)
  capsp (layer-switch default)
  laltd (tap-hold 100 100 lalt (layer-while-held alt-layer))
  lsd (tap-hold 100 100 lsft (layer-while-held s-layer))

  two RA-5
  three RA-4
  four 5
  five 4
  six 3
  seven par
  eight RA-eql
  nine RA-par
  zero 6
  brack 8
)
