\ editor.fs - keyboard-only text editor on ropes. Keys: F1 open, F2 save, F3 undo, F4 redo, F10 quit.
require rope.fs
1000 constant UMAX
13 constant K-ENTER 127 constant K-BS 256 constant K-UP 257 constant K-DOWN 258 constant K-LEFT 259 constant K-RIGHT
260 constant K-WLEFT 261 constant K-WRIGHT 262 constant K-DEL 263 constant K-ESC
264 constant K-OPEN 265 constant K-SAVE 266 constant K-UNDO 267 constant K-REDO 268 constant K-QUIT
variable t variable cur variable goal variable top variable id variable sid variable ctr variable nu variable nv
variable rows variable cols variable mode variable quit variable warn variable pn variable plen variable mlen
create us UMAX 3 * cells allot create vs UMAX 3 * cells allot
create path 256 allot create pr 256 allot create msg 96 allot create kb 1 allot create lb 1024 allot create eb 8 allot
: ed-init ( rows cols -- ) cols ! rows ! 0 t ! 0 cur ! 0 goal ! 0 top ! 0 id ! 0 sid ! 0 ctr ! 0 nu ! 0 nv !
 0 mode ! 0 quit ! 0 warn ! 0 pn ! 0 plen ! 0 mlen ! ;
: say ( a u -- ) 95 min dup mlen ! msg swap move ;
: dirty? ( -- f ) id @ sid @ <> ;
: snap ( s i -- a ) 3 * cells + ;
: spush ( r id cur s n -- ) { r d c s n } r s n @ snap ! d s n @ snap cell+ ! c s n @ snap 2 cells + ! 1 n +! ;
: spop ( s n -- r id cur ) { s n } -1 n +! s n @ snap dup @ swap cell+ dup @ swap cell+ @ ;
: sclr ( s n -- ) { s n } begin n @ while -1 n +! s n @ snap @ rope-free repeat ;
: clr ( -- ) us nu sclr vs nv sclr ;
: ed-free ( -- ) clr t @ rope-free 0 t ! ;
: tlen ( -- u ) t @ rope-len ;
: tnl ( -- k ) t @ rope-nl ;
: lstart ( ln -- i ) t @ swap rope-ls drop ;
: lof ( i -- ln ) t @ swap rope-line-of ;
: llen ( ln -- u ) { ln } ln tnl < if ln 1+ lstart 1- else tlen then ln lstart - ;
: col ( -- u ) cur @ dup lof lstart - ;
: goal! ( -- ) col goal ! ;
: edit ( n -- ) { n } vs nv sclr
 nu @ UMAX = if us 0 snap @ rope-free us 1 snap us UMAX 1- 3 * cells move -1 nu +! then
 t @ id @ cur @ us nu spush n t ! 1 ctr +! ctr @ id ! ;
: ins ( a u -- ) { a u } t @ cur @ a u rope-ins edit u cur +! goal! ;
: del ( ix k -- ) { ix k } t @ ix k rope-del edit ;
: vert ( d -- ) { d } cur @ lof { ln }
 d 0< if ln 0= if exit then ln 1- to ln else ln tnl >= if exit then ln 1+ to ln then
 ln lstart goal @ ln llen min + cur ! ;
: alnum? ( c -- f ) dup 48 58 within over 65 91 within or swap 97 123 within or ;
: isw ( i -- f ) t @ swap rope-at dup 95 = swap alnum? or ;
: wleft ( -- ) cur @ begin dup if dup 1- isw 0= else 0 then while 1- repeat
 begin dup if dup 1- isw else 0 then while 1- repeat cur ! goal! ;
: wright ( -- ) cur @ begin dup tlen < if dup isw 0= else 0 then while 1+ repeat
 begin dup tlen < if dup isw else 0 then while 1+ repeat cur ! goal! ;
: swapst ( fs fn ts tn -- ) { fs fn ts tn } t @ id @ cur @ ts tn spush fs fn spop cur ! id ! t ! cur @ tlen min cur ! goal! ;
: guard ( w k a u -- f ) { w k a u } dirty? 0= if 0 exit then w k = if 0 exit then k warn ! a u say -1 ;
: setpath ( a u -- f ) { s n } n 255 > if s" path too long" say 0 exit then s path n move n plen ! -1 ;
: has0? ( a u -- f ) { a u } u 0 ?do a i + c@ 0= if -1 unloop exit then loop 0 ;
: slurp ( fid -- a u ) { fid } fid file-size throw d>s { n } n 1+ allocate throw { b } 0 { off }
 begin b off + n off - fid read-file throw dup while off + to off repeat drop fid close-file throw b off ;
: ed-open ( a u -- f ) { s n } 0 0 0 { b u new }
 n 255 > if s" path too long" say 0 exit then
 s n r/o bin open-file { fid ior }
 ior if s n file-status nip 0= if s" cannot open" say 0 exit then -1 to new else fid slurp to u to b then
 b u has0? if b free throw s" binary file refused" say 0 exit then
 b u rope-from { r } b ?dup if free throw then
 clr t @ rope-free r t ! 0 cur ! 0 goal ! 0 top ! 1 ctr +! ctr @ id ! id @ sid !
 s n setpath drop new if s" new file" say else s" opened" say then -1 ;
: ed-save ( -- f ) path plen @ w/o bin create-file { fid ior }
 ior if s" cannot write" say 0 exit then
 t @ rope-str { s n } s n fid write-file { w } s free throw fid close-file { c }
 w c or if s" write error" say 0 exit then id @ sid ! s" saved" say -1 ;
: prompt ( k -- ) { k }
 k K-ENTER = if mode @ 1 = if pr pn @ ed-open drop else pr pn @ setpath if ed-save drop then then 0 mode ! exit then
 k K-ESC = if 0 mode ! s" cancelled" say exit then
 k K-BS = k 8 = or if pn @ if -1 pn +! then exit then
 k 32 256 within pn @ 255 < and if k pr pn @ + c! 1 pn +! then ;
: bs ( -- ) cur @ if cur @ 1- 1 del -1 cur +! goal! then ;
: ed-key ( k -- ) { k } k 0= if exit then warn @ { w } 0 warn !
 mode @ if k prompt exit then
 0 mlen !
 k case
  K-QUIT of w k s" unsaved changes; F10 again to quit" guard 0= if 1 quit ! then endof
  K-OPEN of w k s" unsaved changes; F1 again to discard" guard 0= if 1 mode ! 0 pn ! then endof
  K-SAVE of plen @ if ed-save drop else 2 mode ! 0 pn ! then endof
  K-UNDO of nu @ if us nu vs nv swapst else s" nothing to undo" say then endof
  K-REDO of nv @ if vs nv us nu swapst else s" nothing to redo" say then endof
  K-UP of -1 vert endof
  K-DOWN of 1 vert endof
  K-LEFT of cur @ if -1 cur +! goal! then endof
  K-RIGHT of cur @ tlen < if 1 cur +! goal! then endof
  K-WLEFT of wleft endof
  K-WRIGHT of wright endof
  K-ENTER of s\" \n" ins endof
  10 of s\" \n" ins endof
  K-BS of bs endof
  8 of bs endof
  K-DEL of cur @ tlen < if cur @ 1 del then endof
  dup 9 = over 32 256 within or if dup kb c! kb 1 ins then
 endcase ;
: esc ( a u -- k ) { s n } 0 { f } n 0= if K-ESC exit then
 s c@ 79 = n 2 = and if s 1+ c@ to f f 80 = if K-OPEN exit then f 81 = if K-SAVE exit then
  f 82 = if K-UNDO exit then f 83 = if K-REDO exit then 0 exit then
 s c@ 91 <> n 2 < or if 0 exit then
 s n 1- + c@ to f
 f 126 = n 4 = and if
  s 1+ c@ 49 = s 2 + c@ 49 >= and s 2 + c@ 52 <= and if K-OPEN s 2 + c@ 49 - + exit then
  s 1+ c@ 50 = s 2 + c@ 49 = and if K-QUIT exit then 0 exit then
 f 65 = if K-UP exit then f 66 = if K-DOWN exit then
 f 67 = if n 2 > if K-WRIGHT else K-RIGHT then exit then
 f 68 = if n 2 > if K-WLEFT else K-LEFT then exit then
 f 126 = n 3 = and s 1+ c@ 51 = and if K-DEL exit then 0 ;
variable ob variable oc variable op
: o+ ( a u -- ) { a u } op @ u + oc @ > if exit then a ob @ op @ + u move u op +! ;
: o# ( n -- ) s>d <# #s #> o+ ;
: opos ( r c -- ) s\" \e[" o+ swap o# s" ;" o+ o# s" H" o+ ;
: orow ( r -- ) 1 opos s\" \e[K" o+ ;
: opad ( a u w -- ) { a u w } a u w min o+ w u - 0 max 0 ?do s"  " o+ loop ;
: line ( ln -- ) { ln } ln lstart { s } ln llen cols @ min 1024 min { l } t @ s lb l rope-copy { k }
 k 0 ?do lb i + c@ dup 32 < over 126 > or if 9 = if 32 else 63 then lb i + c! else drop then loop lb k o+ ;
: render ( -- a u ) rows @ cols @ 32 + * 512 + dup oc ! allocate throw ob ! 0 op !
 rows @ 2 - 1 max { h } cur @ lof { ln } 0 { pl }
 ln top @ < if ln top ! then ln top @ h + >= if ln h - 1+ top ! then
 s\" \e[?25l\e[H\e[7m" o+ s" F1 open  F2 save  F10 quit  F3 undo  F4 redo" cols @ opad s\" \e[0m" o+
 h 0 ?do i 2 + orow top @ i + dup tnl <= if line else drop then loop
 rows @ orow
 mode @ if mode @ 1 = if s" open: " else s" save as: " then dup to pl o+ pr pn @ o+
 else mlen @ if msg mlen @ cols @ min o+
  else plen @ if path plen @ else s" [no name]" then cols @ min o+ dirty? if s"  *" o+ then then then
 mode @ if rows @ pl pn @ + 1+ else ln top @ - 2 + col 1+ then cols @ min opos
 s\" \e[?25h" o+ ob @ op @ ;
: digits? ( a u -- f ) { a u } u 0= if 0 exit then u 0 ?do a i + c@ dup 48 58 within swap 32 = or 0= if 0 unloop exit then loop -1 ;
: tty-size ( -- ) s" stty size" r/o open-pipe throw { fid } lb 80 fid read-line throw drop { len }
 fid close-pipe 2drop len lb swap digits? if lb len evaluate cols ! rows ! then ;
: poll ( -- f ) rows @ cols @ tty-size rows @ cols @ d= 0= ;
: getkey ( -- k ) begin key? 0= while 150 ms poll if 0 exit then repeat key dup 27 <> if exit then drop
 20 ms key? 0= if K-ESC exit then
 key dup eb c! dup 79 = if drop 1 ms key? if key eb 1+ c! eb 2 esc else 0 then exit then
 91 <> if 0 exit then
 1 { n } begin 1 ms key? n 8 < and if key dup eb n + c! n 1+ to n 64 127 within 0= else 0 then while repeat eb n esc ;
: step ( -- ) getkey ed-key ;
: loop-ed ( -- ) begin quit @ 0= while tty-size render type ob @ free throw stdout flush-file drop
 ['] step catch if s" internal error" say then repeat ;
: tty-raw ( -- ) s" stty raw -echo" system s\" \e[?1049h" type ;
: tty-back ( -- ) s\" \e[?1049l" type s" stty sane" system ;
: te ( a u -- ) 24 80 ed-init dup if ed-open drop else 2drop s" new buffer" say then
 tty-raw ['] loop-ed catch tty-back ed-free throw ;
: main ( -- ) s" TE_FILE" getenv te bye ;
