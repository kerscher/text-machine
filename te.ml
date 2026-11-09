type r=L of string*int|N of int*int*int*r*r
let cnt s=String.fold_left(fun c x->if x='\n' then c+1 else c)0 s
let lf s=L(s,cnt s)
let len=function L(s,_)->String.length s|N(n,_,_,_,_)->n
let nl=function L(_,m)|N(_,m,_,_,_)->m
let ht=function L _->1|N(_,_,h,_,_)->h
let ch=256
let chk c=if not c then invalid_arg "te"
let rec bld s i n=if n<=ch then lf(String.sub s i n) else let m=n/2 in let a=bld s i m and b=bld s(i+m)(n-m) in N(n,nl a+nl b,1+max(ht a)(ht b),a,b)
let cat a b=if len a=0 then b else if len b=0 then a else N(len a+len b,nl a+nl b,1+max(ht a)(ht b),a,b)
let rec rd b n i k=match n with L(s,_)->Buffer.add_substring b s i(min k(String.length s-i))|N(_,_,_,l,r)->let m=len l in if i>=m then rd b r(i-m)k else(rd b l i k;if k>m-i then rd b r 0(k-m+i))
let copy t i k=let b=Buffer.create 64 in if i>=0&&k>0&&i<len t then rd b t i k;Buffer.contents b
let str t=copy t 0(len t)
let lim n=let rec h n=if n=0 then 0 else 1+h(n/2) in 2*h n+8
let fin t=if ht t<=lim(len t) then t else bld(str t)0(len t)
let of_string s=bld s 0(String.length s)
let concat a b=fin(cat a b)
let rec sp t i=match t with L(s,_)->lf(String.sub s 0 i),lf(String.sub s i(String.length s-i))|N(_,_,_,l,r)->let m=len l in if i<m then(let a,x=sp l i in a,cat x r) else(let y,b=sp r(i-m) in cat l y,b)
let split t i=chk(i>=0&&i<=len t);let a,b=sp t i in fin a,fin b
let insert t i s=chk(i>=0&&i<=len t);let a,b=sp t i in fin(cat(cat a(of_string s))b)
let delete t i k=chk(i>=0&&k>=0&&i<=len t-k);let a,y=sp t i in fin(cat a(snd(sp y k)))
let substr t i k=chk(i>=0&&k>=0&&i<=len t-k);fin(fst(sp(snd(sp t i))k))
let line_start t k=if k<0||k>nl t then None else let rec g n k o=match n with L(s,_)->let rec f i k=if k=0 then o else if s.[i]='\n' then(if k=1 then o+i+1 else f(i+1)(k-1)) else f(i+1)k in f 0 k|N(_,_,_,l,r)->if k<=nl l then g l k o else g r(k-nl l)(o+len l) in Some(g t k 0)
let line_of t i=chk(i>=0&&i<=len t);let rec g n i=match n with L(s,_)->cnt(String.sub s 0 i)|N(_,_,_,l,r)->if i<len l then g l i else nl l+g r(i-len l) in g t i
let char_at t i=if i<0||i>=len t then None else Some(copy t i 1).[0]
type s={t:r;u:(r*int*int)list;v:(r*int*int)list;id:int;sid:int;ctr:int;cur:int;goal:int;top:int;pr:string;mode:int;quit:bool;warn:int;path:string;msg:string;rows:int;cols:int}
let umax=1000
let k_enter=13 and k_bs=127 and k_up=256 and k_down=257 and k_left=258 and k_right=259 and k_wleft=260 and k_wright=261 and k_del=262 and k_esc=263 and k_open=264 and k_save=265 and k_undo=266 and k_redo=267 and k_quit=268
let init rows cols={t=of_string"";u=[];v=[];id=0;sid=0;ctr=0;cur=0;goal=0;top=0;pr="";mode=0;quit=false;warn=0;path="";msg="";rows;cols}
let say e m={e with msg=m}
let dirty e=e.id<>e.sid
let lstart e n=Option.get(line_start e.t n)
let lof e i=line_of e.t i
let llen e n=(if n<nl e.t then lstart e(n+1)-1 else len e.t)-lstart e n
let col e=e.cur-lstart e(lof e e.cur)
let mv e c=let e={e with cur=c} in{e with goal=col e}
let rec tk n=function x::t when n>0->x::tk(n-1)t|_->[]
let edit e t c=mv{e with t;u=tk umax((e.t,e.cur,e.id)::e.u);v=[];id=e.ctr+1;ctr=e.ctr+1}c
let ins e s=edit e(insert e.t e.cur s)(e.cur+String.length s)
let vert e d=let n=lof e e.cur+d in if n<0||n>nl e.t then e else{e with cur=lstart e n+min e.goal(llen e n)}
let isw e i=match char_at e.t i with Some c->c='_'||(c>='0'&&c<='9')||(c>='a'&&c<='z')||(c>='A'&&c<='Z')|None->false
let sw e(t,c,i)=mv{e with t;id=i}(min c(len t))
let undo e=match e.u with[]->say e"nothing to undo"|x::u->{(sw e x)with u;v=(e.t,e.cur,e.id)::e.v}
let redo e=match e.v with[]->say e"nothing to redo"|x::v->{(sw e x)with v;u=(e.t,e.cur,e.id)::e.u}
let op e p=if String.length p>=256 then say e"path too long" else try
 if not(Sys.file_exists p) then{(mv{e with t=of_string"";u=[];v=[];top=0;id=e.ctr+1;sid=e.ctr+1;ctr=e.ctr+1;path=p}0)with msg="new file"}
 else let s=In_channel.with_open_bin p In_channel.input_all in if String.contains s '\000' then say e"binary file refused" else{(mv{e with t=of_string s;u=[];v=[];top=0;id=e.ctr+1;sid=e.ctr+1;ctr=e.ctr+1;path=p}0)with msg="opened"}
 with Sys_error m->say e m
let sv e=try Out_channel.with_open_bin e.path(fun o->output_string o(str e.t));{e with sid=e.id;msg="saved"} with Sys_error m->say e m
let gd e w k m f=if dirty e&&w<>k then{e with warn=k;msg=m} else f e
let prompt e k=let n=String.length e.pr in
 if k=k_enter then{(if e.mode=1 then op e e.pr else if n>=256 then say e"path too long" else sv{e with path=e.pr})with mode=0}
 else if k=k_esc then{e with mode=0;msg="cancelled"}
 else if k=k_bs||k=8 then{e with pr=String.sub e.pr 0(max 0(n-1))}
 else if k>=32&&k<256&&n<255 then{e with pr=e.pr^String.make 1(Char.chr k)} else e
let rec lw p i=if i>0&&p(i-1) then lw p(i-1) else i
let rec rw p n i=if i<n&&p i then rw p n(i+1) else i
let key e k=let w=e.warn in if k=0 then e else let e={e with warn=0} in if e.mode>0 then prompt e k else let e={e with msg=""} and n=len e.t in
 if k=k_quit then gd e w k"unsaved changes; F10 again to quit"(fun e->{e with quit=true})
 else if k=k_open then gd e w k"unsaved changes; F1 again to discard"(fun e->{e with mode=1;pr=""})
 else if k=k_save then(if e.path<>"" then sv e else{e with mode=2;pr=""})
 else if k=k_undo then undo e else if k=k_redo then redo e
 else if k=k_up then vert e(-1) else if k=k_down then vert e 1
 else if k=k_left then(if e.cur>0 then mv e(e.cur-1) else e)
 else if k=k_right then(if e.cur<n then mv e(e.cur+1) else e)
 else if k=k_wleft then mv e(lw(isw e)(lw(fun i->not(isw e i))e.cur))
 else if k=k_wright then mv e(rw(isw e)n(rw(fun i->not(isw e i))n e.cur))
 else if k=k_enter||k=10 then ins e"\n"
 else if k=k_bs||k=8 then(if e.cur>0 then edit e(delete e.t(e.cur-1)1)(e.cur-1) else e)
 else if k=k_del then(if e.cur<n then edit e(delete e.t e.cur 1)e.cur else e)
 else if k=9||(k>=32&&k<256) then ins e(String.make 1(Char.chr k)) else e
let esc s=let n=String.length s in
 if n=0 then k_esc
 else if s.[0]='O' then(if n<>2 then 0 else match s.[1] with 'P'->k_open|'Q'->k_save|'R'->k_undo|'S'->k_redo|_->0)
 else if s.[0]<>'['||n<2 then 0
 else match s.[n-1] with
 '~'->if n=4&&s.[1]='1'&&s.[2]>='1'&&s.[2]<='4' then k_open+Char.code s.[2]-49 else if n=4&&s.[1]='2'&&s.[2]='1' then k_quit else if n=3&&s.[1]='3' then k_del else 0
 |'A'->k_up|'B'->k_down|'C'->if n>2 then k_wright else k_right|'D'->if n>2 then k_wleft else k_left|_->0
let hd="F1 open  F2 save  F10 quit  F3 undo  F4 redo"
let render e=
 let h=max 1(e.rows-2) and ln=lof e e.cur in
 let top=if ln<e.top then ln else if ln>=e.top+h then ln-h+1 else e.top in
 let e={e with top} in let b=Buffer.create 4096 in let p=Buffer.add_string b in
 let l=if e.mode=1 then 6 else 9 in
 p"\x1b[?25l\x1b[H\x1b[7m";p(let s=if String.length hd>e.cols then String.sub hd 0 e.cols else hd in s^String.make(e.cols-String.length s)' ');p"\x1b[0m";
 for i=0 to h-1 do Printf.bprintf b"\x1b[%d;1H\x1b[K"(i+2);if top+i<=nl e.t then p(String.map(fun c->if c='\t' then ' ' else if c<' '||c>'~' then '?' else c)(copy e.t(lstart e(top+i))(min(llen e(top+i))e.cols))) done;
 Printf.bprintf b"\x1b[%d;1H\x1b[K"e.rows;
 p(if e.mode>0 then(if e.mode=1 then"open: " else"save as: ")^e.pr else if e.msg<>"" then e.msg else(if e.path="" then"[no name]" else e.path)^if dirty e then" *" else"");
 Printf.bprintf b"\x1b[%d;%dH\x1b[?25h"(if e.mode>0 then e.rows else ln-top+2)(min e.cols(if e.mode>0 then l+String.length e.pr+1 else col e+1));
 e,Buffer.contents b
let rd1()=let b=Bytes.create 1 in try(if Unix.read Unix.stdin b 0 1=1 then Char.code(Bytes.get b 0) else -1)with Unix.Unix_error _->(-2)
let rec getkey()=match rd1() with
 -1->getkey()|27->let c=rd1() in if c<0 then k_esc else if c<>91&&c<>79 then 0 else
  let b=Buffer.create 8 in Buffer.add_char b(Char.chr c);
  let rec g()=if Buffer.length b<8 then(let c=rd1() in if c>=0 then(Buffer.add_char b(Char.chr c);if c<0x40||c>0x7e then g())) in
  if c=79 then(let c=rd1() in if c>=0 then Buffer.add_char b(Char.chr c)) else g();esc(Buffer.contents b)
 |c->if c<0 then 0 else c
let size()=try let i=Unix.open_process_in"stty size 2>/dev/null" in let x=Scanf.sscanf(input_line i)" %d %d"(fun r c->r,c) in ignore(Unix.close_process_in i);x with _->24,80
let main()=
 let a=Sys.argv in
 if Array.length a>2 then(prerr_endline"usage: te [file]";exit 2);
 if not(Unix.isatty Unix.stdin&&Unix.isatty Unix.stdout) then(prerr_endline"te: terminal required";exit 1);
 let e=ref(init 24 80) and rs=ref true in
 if Array.length a=2 then e:=op !e a.(1);
 if !e.msg<>"" then prerr_endline !e.msg;
 let o=Unix.tcgetattr Unix.stdin and w s=print_string s;flush stdout in
 Unix.tcsetattr Unix.stdin Unix.TCSAFLUSH{o with c_ixon=false;c_icrnl=false;c_brkint=false;c_inpck=false;c_istrip=false;c_echo=false;c_icanon=false;c_isig=false;c_vmin=0;c_vtime=1};
 at_exit(fun()->Unix.tcsetattr Unix.stdin Unix.TCSAFLUSH o;w"\x1b[?1049l");
 Sys.set_signal 28(Sys.Signal_handle(fun _->rs:=true));
 w"\x1b[?1049h";
 while not !e.quit do
  if !rs then(rs:=false;let r,c=size() in if r>2&&c>0 then e:={!e with rows=r;cols=c});
  let e',s=render !e in w s;
  e:=key e'(getkey())
 done
let()=if Filename.basename Sys.executable_name="te" then main()
