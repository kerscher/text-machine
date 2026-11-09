local T=require"te"
local len,nl,ht,str,k=T.len,T.nl,T.ht,T.str,T.k
local function bad(f) return not pcall(f) end
local function same(r,m)
 local n=#m
 assert(str(r)==m and len(r)==n)
 local nls=T.cnt(m)
 assert(nl(r)==nls)
 for j=0,nls do
  local o,e=0,0
  for i=1,n do if m:byte(i)==10 then e=e+1 if e==j then o=i end end end
  assert(T.line_start(r,j)==(j==0 and 0 or o))
 end
 assert(T.line_start(r,nls+1)==nil)
 for j=0,n//7 do local i=7*j
  assert(T.line_of(r,i)==T.cnt(m:sub(1,i)))
  assert(T.copy(r,i,64)==m:sub(i+1,i+64))
 end
end
local function edits()
 math.randomseed(7)
 local w={"a","xy\n","\n","lorem ipsum dolor sit amet ",""} local r,m=T.of_string"",""
 for j=0,3999 do
  local n=#m local i=math.random(0,n)
  if math.random(0,2)==0 and n>0 then local c=math.random(0,math.min(40,n-i)) r=T.delete(r,i,c) m=m:sub(1,i)..m:sub(i+c+1)
  else local s=w[math.random(1,5)] r=T.insert(r,i,s) m=m:sub(1,i)..s..m:sub(i+1) end
  if j%97==0 then same(r,m) end
 end
 same(r,m)
 local n=#m
 for _=0,39 do
  local i=math.random(0,n) local x,y=T.split(r,i)
  assert(len(x)==i and len(y)==n-i)
  same(T.concat(x,y),m)
  local c=math.random(0,n-i) assert(str(T.substr(r,i,c))==m:sub(i+1,i+c))
 end
 assert(bad(function()return T.split(r,n+1)end) and bad(function()return T.insert(r,n+1,"a")end) and bad(function()return T.delete(r,n,1)end) and bad(function()return T.substr(r,0,n+1)end))
 r=T.of_string""
 for j=0,19999 do r=T.insert(r,j,"q") end
 assert(len(r)==20000 and T.char_at(r,19999)=="q" and ht(r)<=T.lim(20000))
end
local function rope()
 local h,s,w=T.of_string"hello",T.of_string" ",T.of_string"world"
 local j=T.concat(T.concat(h,s),w)
 assert(len(j)==11 and T.char_at(j,6)=="w" and T.char_at(j,11)==nil and str(j)=="hello world")
 assert(str(T.concat(T.of_string"",T.of_string""))=="")
 edits()
end
local e=T.init(10,40)
local function K(x) e=T.key(e,x) end
local function typ(s) for i=1,#s do K(s:byte(i)) end end
local function txt(m) assert(str(e.t)==m) end
local function fb() local e2,s=T.render(e) e=e2 return s end
local function has(s,p) return s:find(p,1,true)~=nil end
local function editor()
 local s=fb() assert(has(s,"F1 open") and has(s,"F2 save") and has(s,"F10 quit"))
 typ"hello world" txt"hello world" assert(T.dirty(e))
 K(k.enter) typ"ab" K(k.up) assert(e.cur==2)
 K(k.down) assert(e.cur==14)
 K(k.up) K(k.wleft) assert(e.cur==0)
 K(k.wright) assert(e.cur==5)
 K(k.wright) assert(e.cur==11)
 K(k.bs) txt"hello worl\nab"
 K(k.del) txt"hello worlab"
 K(k.undo) txt"hello worl\nab"
 K(k.undo) txt"hello world\nab"
 K(k.redo) txt"hello worl\nab"
 while #e.u>0 do K(k.undo) end
 txt"" assert(not T.dirty(e))
 while #e.v>0 do K(k.redo) end
 txt"hello worlab"
 while #e.u>11 do K(k.undo) end
 txt"hello world"
 K(17) K(17) assert(not e.quit and e.mode==0)
 K(k.quit) assert(not e.quit and has(e.msg,"unsaved"))
 K(0) K(k.quit) assert(e.quit)
 e.quit=false
 K(k.save) assert(e.mode==2)
 typ"te_test.tmp" K(k.enter)
 assert(e.mode==0 and not T.dirty(e))
 local f=io.open("te_test.tmp","rb") assert(f:read("a")=="hello world") f:close()
 typ"!" assert(T.dirty(e)) K(k.undo) assert(not T.dirty(e)) K(k.redo)
 K(k.open) assert(e.mode==0 and has(e.msg,"unsaved"))
 K(k.open) assert(e.mode==1)
 K(k.esc) assert(e.mode==0)
 K(k.save) assert(not T.dirty(e))
 K(k.open) typ"te_test.tmp" K(k.enter)
 txt"hello world!" assert(not T.dirty(e) and #e.u==0)
 typ"x" K(k.quit) K(k.left) K(k.quit) assert(not e.quit)
 os.remove"te_test.tmp"
 e=T.op(e,"te_missing.tmp") assert(has(e.msg,"new")) txt""
 local E=T.esc
 assert(E"OP"==k.open and E"OQ"==k.save and E"OR"==k.undo and E"OS"==k.redo)
 assert(E"[11~"==k.open and E"[14~"==k.redo and E"[21~"==k.quit and E"[15~"==0)
 assert(E"[A"==k.up and E"[D"==k.left and E"[3~"==k.del)
 assert(E"[1;5C"==k.wright and E"[1;5D"==k.wleft and E""==k.esc and E"[Z"==0)
 for _=1,30 do typ"line" K(k.enter) end
 s=fb() assert(e.top==23 and has(s,"\27[10;1H") and not has(s,"\27[11;1H"))
 for _=1,30 do K(k.up) end
 fb() assert(e.top==0)
 for _=1,2000 do typ"a" end
 assert(#e.u<=T.umax)
end
rope() editor()
