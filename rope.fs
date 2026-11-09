\ rope.fs - immutable reference-counted rope. A rope is a node address; 0 is the empty rope.
\ Every operation returns a rope the caller owns and must release with rope-free.
7 cells constant /n
256 constant CH
: n-ref ; : n-len cell+ ; : n-ht 2 cells + ; : n-nl 3 cells + ; : n-s 4 cells + ; : n-l 5 cells + ; : n-r 6 cells + ;
: rope-len ( r -- u ) dup if n-len @ then ;
: rope-nl ( r -- k ) dup if n-nl @ then ;
: unref ( n -- ) dup 0= if drop exit then -1 over n-ref +! dup n-ref @ if drop exit then
 dup n-l @ recurse dup n-r @ recurse dup n-s @ ?dup if free throw then free throw ;
: rope-free ( r -- ) unref ;
: +ref ( n -- n ) dup if 1 over n-ref +! then ;
: cnt ( a u -- k ) 0 -rot bounds ?do i c@ 10 = if 1+ then loop ;
: mk ( a u -- n ) { a u } /n allocate throw u allocate throw { n s } a s u move
 1 n n-ref ! u n n-len ! 1 n n-ht ! a u cnt n n-nl ! s n n-s ! 0 n n-l ! 0 n n-r ! n ;
: join ( l r -- n ) { l r } /n allocate throw { n } 1 n n-ref ! l n-len @ r n-len @ + n n-len !
 l n-ht @ r n-ht @ max 1+ n n-ht ! l n-nl @ r n-nl @ + n n-nl ! 0 n n-s ! l +ref n n-l ! r +ref n n-r ! n ;
: cat ( a b -- n ) { a b } a 0= if b exit then b 0= if a exit then a b join a unref b unref ;
: bld ( a u -- n ) { a u } u CH <= if a u mk exit then a u 2/ recurse a u 2/ + u u 2/ - recurse cat ;
: lim ( len -- h ) 0 swap begin dup while 1 rshift swap 1+ swap repeat drop 2* 8 + ;
: flat ( n a -- ) { n a } n n-s @ if n n-s @ a n n-len @ move exit then
 n n-l @ a recurse n n-r @ a n n-l @ n-len @ + recurse ;
: fin ( n -- n' ) { n } n 0= if 0 exit then n n-ht @ n n-len @ lim <= if n exit then
 n n-len @ allocate throw { s } n s flat s n n-len @ bld s free throw n unref ;
: splt ( n i -- a b ) { n i } 0 0 0 { x y ll }
 i 0= if 0 n +ref exit then
 i n n-len @ >= if n +ref 0 exit then
 n n-s @ if n n-s @ i mk n n-s @ i + n n-len @ i - mk exit then
 n n-l @ n-len @ to ll
 i ll < if n n-l @ i recurse to y to x x y n n-r @ +ref cat exit then
 n n-r @ i ll - recurse to y to x n n-l @ +ref x cat y ;
: cut ( n i k -- a m z ) { n i k } 0 0 0 0 { y a m z }
 n 0= if 0 0 0 exit then
 n i splt to y to a
 y if y k splt to z to m then
 y unref a m z ;
: chk ( r i k -- r i k ) 2 pick rope-len 2 pick 2 pick + u< if -24 throw then ;
: rope-from ( a u -- r ) dup 0= if 2drop 0 exit then bld ;
: rope-cat ( a b -- c ) +ref swap +ref swap cat fin ;
: rope-split ( r i -- a b ) over rope-len over u< if -24 throw then 0 cut nip fin swap fin swap ;
: rope-ins ( r i a u -- r' ) { r i a u } 0 0 0 { y x m }
 i r rope-len u> if -24 throw then
 r i 0 cut to y drop to x u if a u mk to m then x m cat y cat fin ;
: rope-del ( r i k -- r' ) chk cut >r unref r> cat fin ;
: rope-sub ( r i k -- r' ) chk cut unref swap unref fin ;
: rope-at ( r i -- c ) { n x } begin n n-s @ 0= while
 x n n-l @ n-len @ < if n n-l @ to n else x n n-l @ n-len @ - to x n n-r @ to n then repeat n n-s @ x + c@ ;
: rd ( n i a k -- u ) { n i a k } 0 { g }
 n n-s @ if n n-len @ i - k min to g n n-s @ i + a g move g exit then
 i n n-l @ n-len @ >= if n n-r @ i n n-l @ n-len @ - a k recurse exit then
 n n-l @ i a k recurse to g
 g k < if g n n-r @ 0 a g + k g - recurse + exit then g ;
: rope-copy ( r i a k -- u ) 3 pick rope-len 3 pick u<= if 2drop 2drop 0 exit then rd ;
: rope-ls ( r k -- i f ) { n k } 0 0 { off x }
 k n rope-nl > if 0 0 exit then
 k 0= if 0 -1 exit then
 begin n n-s @ 0= while
  k n n-l @ n-nl @ <= if n n-l @ to n else k n n-l @ n-nl @ - to k n n-l @ n-len @ off + to off n n-r @ to n then
 repeat
 begin n n-s @ x + c@ 10 = if k 1- to k k 0= else 0 then 0= while x 1+ to x repeat
 off x + 1+ -1 ;
: rope-line-of ( r i -- k ) { n x } 0 { c }
 n 0= if 0 exit then
 begin n n-s @ 0= while
  x n n-l @ n-len @ < if n n-l @ to n else n n-l @ n-nl @ c + to c x n n-l @ n-len @ - to x n n-r @ to n then
 repeat n n-s @ x cnt c + ;
: rope-str ( r -- a u ) { n } n rope-len { u } u 1 max allocate throw { s } n if n s flat then s u ;
