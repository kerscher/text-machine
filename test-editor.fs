require editor.fs
variable fails
: ck ( f -- ) 0= if 1 fails +! ." FAIL " sourceline# . cr then ;
: keys ( a u -- ) 0 ?do dup i + c@ ed-key loop drop ;
: txt ( -- a u ) t @ rope-str ;
: is ( a u -- f ) txt { s n } s n compare 0= s free throw ;
: new ( -- ) 24 80 ed-init ;
: f1 K-OPEN ed-key ; : f2 K-SAVE ed-key ; : f3 K-UNDO ed-key ; : f4 K-REDO ed-key ; : f10 K-QUIT ed-key ;
new s" abc" keys s" abc" is ck cur @ 3 = ck dirty? ck
f3 f3 f3 s" " is ck f4 f4 f4 s" abc" is ck cur @ 3 = ck
K-LEFT ed-key K-BS ed-key s" ac" is ck
f10 quit @ 0= ck f10 quit @ ck
new s\" ab\ncd" keys K-UP ed-key cur @ 2 = ck K-DOWN ed-key cur @ 5 = ck
new s" foo bar" keys K-WLEFT ed-key cur @ 4 = ck K-WLEFT ed-key cur @ 0= ck K-WRIGHT ed-key cur @ 3 = ck
new 1 ed-key 24 ed-key 0 ed-key s" " is ck
new s" x" keys s" /tmp/te-t.txt" setpath drop ed-save ck dirty? 0= ck
new s" /tmp/te-t.txt" ed-open ck s" x" is ck
s" [11~" esc K-OPEN = ck s" [21~" esc K-QUIT = ck s" OS" esc K-REDO = ck s" [1;5C" esc K-WRIGHT = ck s" " esc K-ESC = ck s" [3~" esc K-DEL = ck
new render 2dup s" F1 open  F2 save  F10 quit" search nip nip ck drop free throw
fails @ 0= [if] .( ok) cr [then]
bye
