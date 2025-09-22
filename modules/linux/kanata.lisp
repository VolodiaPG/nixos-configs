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
      _ _ _ _ _ _ _ _ _ _ _ eql par _
      _ _ _ _ _ _ _ _ _ _ _ _ _
      lctl _ _ _ _ _ _ _ _ _ _ _ _
      _ _ _ _ _ _ _ _ _ _ _ _ _
      @capsd _ _ _ _ _
)

(deflayer programming
      _ _ @two @three @four @five @six @seven @eight @nine @zero @brack _ _
      _ _ _ _ _ _ _ _ _ _ _ _ _
      lctl _ _ _ _ _ _ _ _ _ _ _ _ _
      @lsd _ _ _ _ _ _ _ _ _ eql @lsd
      @capsp _ @laltd _ @raltd _
)

(deflayer alt-layer
      A-' A-1 A-2 A-3 A-4 A-5 A-6 A-7 A-8 A-9 A-0 A-par A-eql A-bspc
      A-tab A-a A-z A-e A-r A-t A-y A-u A-i A-o A-p A-^ A-;
      lctl A-q A-s A-d A-f A-g A-h A-j A-k A-l A-m A-` A-bksl A-ret
      lsft A-nubs A-w A-x A-c A-v A-b A-n A-comm A-. EXCL A-rsft
      lctl lmet lalt spc ralt rctl
)


(deflayer s-layer
      S-' S-1 S-2 S-3 S-4 S-5 S-6 S-7 S-8 S-9 S-0 S-par S-eql S-bspc
      S-tab S-a S-z S-e S-r S-t S-y S-u S-i S-o S-p S-^ S-;
      lctl S-q S-s S-d S-f S-g S-h S-j S-k S-l S-m S-` S-bksl S-ret
      lsft S-nubs S-w S-x S-c S-v S-b S-n S-comm S-. EXCL rsft
      lctl lmet lalt spc ralt rctl
)

(deflayer agr-layer
      RA-' RA-1 RA-2 RA-3 RA-4 RA-5 RA-6 RA-7 RA-8 RA-9 RA-0 RA-par RA-eql RA-bspc
      RA-tab RA-a RA-z RA-e RA-r RA-t RA-y RA-u RA-i RA-o RA-p RA-^ RA-;
      lctl RA-q RA-s RA-d RA-f RA-g RA-h RA-j RA-k RA-l RA-m RA-` RA-bksl RA-ret
      sft RA-nubs RA-w RA-x RA-c RA-v RA-b RA-n RA-comm RA-. EXCL rsft
      lctl lmet lalt spc ralt rctl
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
  raltd (tap-hold 100 100 ralt (layer-while-held agr-layer))

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
