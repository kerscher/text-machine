\ test-rope.fs - run: gforth test-rope.fs
require rope.fs
: (ck) ( f line -- ) swap if drop else ." FAIL line " . cr 1 (bye) then ;
: ck ( f -- ) sourceline# postpone literal postpone (ck) ; immediate
variable sd 88172645463325252 sd !
: rnd ( n -- k ) { n } sd @ dup 13 lshift xor dup 7 rshift xor dup 17 lshift xor dup sd ! 0 n um/mod drop ;
variable m 200000 allocate throw m !
variable mn
create buf 64 allot
: mins ( ix a u -- ) { ix a u } m @ ix + dup u + mn @ ix - move a m @ ix + u move u mn +! ;
: mdel ( ix k -- ) { ix k } m @ ix + k + m @ ix + mn @ ix - k - move k negate mn +! ;
: nlm ( ix -- k ) { ix } 0 { c } ix 0 ?do m @ i + c@ 10 = if c 1+ to c then loop c ;
: lsm ( k -- ix ) { k } 0 0 { c p } k 0= if 0 exit then
 begin m @ p + c@ 10 = if c 1+ to c then p 1+ to p c k = until p ;
: eq ( a u -- ) m @ mn @ compare 0= ck ;
: cpy ( r ix -- ) { r ix } r ix buf 64 rope-copy { u } u mn @ ix - 64 min = ck buf u m @ ix + u compare 0= ck ;
: same ( r -- ) { r } r rope-len mn @ = ck
 r rope-str 2dup eq drop free throw
 r rope-nl mn @ nlm = ck
 r rope-nl 1+ 0 ?do r i rope-ls ck i lsm = ck loop
 r r rope-nl 1+ rope-ls 0= ck drop
 mn @ 1+ 0 ?do r i rope-line-of i nlm = ck r i cpy 7 +loop ;
: pw ( k -- a u ) dup 0 = if drop s" a" exit then dup 1 = if drop s\" xy\n" exit then dup 2 = if drop s\" \n" exit then
 3 = if s" lorem ipsum dolor sit amet " exit then s" " ;
: tryins ( r i -- f ) s" a" ['] rope-ins catch if 2drop 2drop -1 else rope-free 0 then ;
: trydel ( r i k -- f ) ['] rope-del catch if 2drop drop -1 else rope-free 0 then ;
: basic ( -- )
 s" hello" rope-from s"  " rope-from s" world" rope-from { h sp w } h sp rope-cat { pre } pre w rope-cat { j }
 j rope-len 11 = ck j 6 rope-at [char] w = ck
 j rope-str 2dup s" hello world" compare 0= ck drop free throw
 h rope-free sp rope-free w rope-free pre rope-free
 j rope-str 2dup s" hello world" compare 0= ck drop free throw j rope-free
 0 0 rope-cat rope-len 0= ck 0 rope-str 0= ck free throw ;
: edits ( -- )
 0 0 0 0 { r x ix k } 0 mn !
 4000 0 ?do
  3 rnd 0= mn @ 0> and if
   mn @ 1+ rnd to ix mn @ ix - 1+ 10 min rnd to k
   r ix k rope-del to x ix k mdel
  else
   mn @ 1+ rnd to ix 5 rnd pw 2>r r ix 2r@ rope-ins to x ix 2r> mins
  then
  r rope-free x to r
  i 97 mod 0= if r same then
 loop
 r same mn @ 500 > ck
 40 0 ?do
  mn @ 1+ rnd to ix
  r ix rope-split { a b } a rope-len ix = ck b rope-len mn @ ix - = ck
  a b rope-cat { z } z same z rope-free a rope-free b rope-free
  mn @ ix - 1+ rnd to k
  r ix k rope-sub { y } y rope-str 2dup m @ ix + k compare 0= ck drop free throw y rope-free
 loop
 r mn @ 1+ tryins ck r mn @ 1 trydel ck
 r rope-free ;
: appends ( -- )
 0 { r } 20000 0 ?do r i s" q" rope-ins { x } r rope-free x to r loop
 r rope-len 20000 = ck r 19999 rope-at [char] q = ck r rope-free ;
basic edits appends
." ok" cr bye
