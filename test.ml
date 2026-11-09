open Te
let t r=str r
let bad f=try ignore(f());false with Invalid_argument _->true
let same r m=
 let n=String.length m in
 assert(t r=m&&len r=n);
 let nls=Seq.length(Seq.filter((=)'\n')(String.to_seq m)) in
 assert(nl r=nls);
 for k=0 to nls do
  let o=ref 0 and e=ref 0 in
  String.iteri(fun i c->if c='\n'&&(incr e;!e=k) then o:=i+1)m;
  assert(line_start r k=Some(if k=0 then 0 else !o))
 done;
 assert(line_start r(nls+1)=None);
 for i=0 to n/7 do let i=7*i in
  assert(line_of r i=cnt(String.sub m 0 i));
  assert(copy r i 64=String.sub m i(min 64(n-i)))
 done
let edits()=
 Random.init 7;
 let w=[|"a";"xy\n";"\n";"lorem ipsum dolor sit amet ";""|] and r=ref(of_string"") and m=ref"" in
 for j=0 to 3999 do
  let n=String.length !m in let i=Random.int(n+1) in
  if Random.int 3=0&&n>0 then(let k=Random.int(min 40(n-i)+1) in r:=delete !r i k;m:=String.sub !m 0 i^String.sub !m(i+k)(n-i-k))
  else(let s=w.(Random.int 5) in r:=insert !r i s;m:=String.sub !m 0 i^s^String.sub !m i(n-i));
  if j mod 97=0 then same !r !m
 done;
 same !r !m;
 let n=String.length !m in
 for _=0 to 39 do
  let i=Random.int(n+1) in let x,y=split !r i in
  assert(len x=i&&len y=n-i);
  same(concat x y)!m;
  let k=Random.int(n-i+1) in assert(t(substr !r i k)=String.sub !m i k)
 done;
 assert(bad(fun()->split !r(n+1))&&bad(fun()->insert !r(n+1)"a")&&bad(fun()->delete !r n 1)&&bad(fun()->substr !r 0(n+1)));
 let r=ref(of_string"") in
 for j=0 to 19999 do r:=insert !r j"q" done;
 assert(len !r=20000&&char_at !r 19999=Some 'q'&&ht !r<=lim 20000)
let rope()=
 let h=of_string"hello" and s=of_string" " and w=of_string"world" in
 let j=concat(concat h s)w in
 assert(len j=11&&char_at j 6=Some 'w'&&char_at j 11=None&&t j="hello world");
 assert(t(concat(of_string"")(of_string""))="");
 edits()
let e=ref(init 10 40)
let k x=e:=key !e x
let typ s=String.iter(fun c->k(Char.code c))s
let txt m=assert(t !e.t=m)
let nu()=List.length !e.u
let nv()=List.length !e.v
let fb()=let e',s=render !e in e:=e';s
let has s p=let n=String.length p in let rec f i=i+n<=String.length s&&(String.sub s i n=p||f(i+1)) in f 0
let editor()=
 let s=fb() in assert(has s"F1 open"&&has s"F2 save"&&has s"F10 quit");
 typ"hello world";txt"hello world";assert(dirty !e);
 k k_enter;typ"ab";k k_up;assert(!e.cur=2);
 k k_down;assert(!e.cur=14);
 k k_up;k k_wleft;assert(!e.cur=0);
 k k_wright;assert(!e.cur=5);
 k k_wright;assert(!e.cur=11);
 k k_bs;txt"hello worl\nab";
 k k_del;txt"hello worlab";
 k k_undo;txt"hello worl\nab";
 k k_undo;txt"hello world\nab";
 k k_redo;txt"hello worl\nab";
 while nu()>0 do k k_undo done;
 txt"";assert(not(dirty !e));
 while nv()>0 do k k_redo done;
 txt"hello worlab";
 while nu()>11 do k k_undo done;
 txt"hello world";
 k 17;k 17;assert(not !e.quit&& !e.mode=0);
 k k_quit;assert(not !e.quit&&has !e.msg"unsaved");
 k 0;k k_quit;assert !e.quit;
 e:={!e with quit=false};
 k k_save;assert(!e.mode=2);
 typ"te_test.tmp";k k_enter;
 assert(!e.mode=0&&not(dirty !e));
 assert(In_channel.with_open_bin"te_test.tmp"In_channel.input_all="hello world");
 typ"!";assert(dirty !e);k k_undo;assert(not(dirty !e));k k_redo;
 k k_open;assert(!e.mode=0&&has !e.msg"unsaved");
 k k_open;assert(!e.mode=1);
 k k_esc;assert(!e.mode=0);
 k k_save;assert(not(dirty !e));
 k k_open;typ"te_test.tmp";k k_enter;
 txt"hello world!";assert(not(dirty !e)&&nu()=0);
 typ"x";k k_quit;k k_left;k k_quit;assert(not !e.quit);
 Sys.remove"te_test.tmp";
 e:=op !e"te_missing.tmp";assert(has !e.msg"new");txt"";
 assert(esc"OP"=k_open&&esc"OQ"=k_save&&esc"OR"=k_undo&&esc"OS"=k_redo);
 assert(esc"[11~"=k_open&&esc"[14~"=k_redo&&esc"[21~"=k_quit&&esc"[15~"=0);
 assert(esc"[A"=k_up&&esc"[D"=k_left&&esc"[3~"=k_del);
 assert(esc"[1;5C"=k_wright&&esc"[1;5D"=k_wleft&&esc""=k_esc&&esc"[Z"=0);
 for _=1 to 30 do typ"line";k k_enter done;
 let s=fb() in assert(!e.top=23&&has s"\x1b[10;1H"&&not(has s"\x1b[11;1H"));
 for _=1 to 30 do k k_up done;
 ignore(fb());assert(!e.top=0);
 for _=1 to 2000 do typ"a" done;
 assert(nu()<=umax)
let()=rope();editor()
