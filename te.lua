local min,max,byte,char,rep=math.min,math.max,string.byte,string.char,string.rep
local function cnt(s) return select(2,s:gsub("\n","")) end
local function lf(s) return{s=s,n=#s,m=cnt(s),h=1} end
local function chk(c) if not c then error("te",0) end end
local ch=256
local function nd(a,b) return{n=a.n+b.n,m=a.m+b.m,h=1+max(a.h,b.h),l=a,r=b} end
local function bld(s,i,n) if n<=ch then return lf(s:sub(i+1,i+n)) end local m=n//2 return nd(bld(s,i,m),bld(s,i+m,n-m)) end
local function cat(a,b) if a.n==0 then return b elseif b.n==0 then return a else return nd(a,b) end end
local function rd(b,n,i,k) if n.s then b[#b+1]=n.s:sub(i+1,i+min(k,n.n-i)) else local m=n.l.n if i>=m then rd(b,n.r,i-m,k) else rd(b,n.l,i,k) if k>m-i then rd(b,n.r,0,k-m+i) end end end end
local function copy(t,i,k) local b={} if i>=0 and k>0 and i<t.n then rd(b,t,i,k) end return table.concat(b) end
local function str(t) return copy(t,0,t.n) end
local function lim(n) local h=0 while n>0 do h=h+1 n=n//2 end return 2*h+8 end
local function fin(t) if t.h<=lim(t.n) then return t else return bld(str(t),0,t.n) end end
local function of_string(s) return bld(s,0,#s) end
local function concat(a,b) return fin(cat(a,b)) end
local function sp(t,i) if t.s then return lf(t.s:sub(1,i)),lf(t.s:sub(i+1)) end local m=t.l.n if i<m then local a,x=sp(t.l,i) return a,cat(x,t.r) else local y,b=sp(t.r,i-m) return cat(t.l,y),b end end
local function split(t,i) chk(i>=0 and i<=t.n) local a,b=sp(t,i) return fin(a),fin(b) end
local function insert(t,i,s) chk(i>=0 and i<=t.n) local a,b=sp(t,i) return fin(cat(cat(a,of_string(s)),b)) end
local function delete(t,i,k) chk(i>=0 and k>=0 and i<=t.n-k) local a,y=sp(t,i) local _,z=sp(y,k) return fin(cat(a,z)) end
local function substr(t,i,k) chk(i>=0 and k>=0 and i<=t.n-k) local _,y=sp(t,i) local x=sp(y,k) return fin(x) end
local function line_start(t,k)
 if k<0 or k>t.m then return nil end
 local function g(n,k,o) if n.s then if k==0 then return o end for i=1,n.n do if n.s:byte(i)==10 then k=k-1 if k==0 then return o+i end end end else if k<=n.l.m then return g(n.l,k,o) else return g(n.r,k-n.l.m,o+n.l.n) end end end
 return g(t,k,0)
end
local function line_of(t,i) chk(i>=0 and i<=t.n) local function g(n,i) if n.s then return cnt(n.s:sub(1,i)) elseif i<n.l.n then return g(n.l,i) else return n.l.m+g(n.r,i-n.l.n) end end return g(t,i) end
local function char_at(t,i) if i<0 or i>=t.n then return nil end return copy(t,i,1) end
local umax=1000
local k_enter,k_bs,k_up,k_down,k_left,k_right,k_wleft,k_wright,k_del,k_esc,k_open,k_save,k_undo,k_redo,k_quit=13,127,256,257,258,259,260,261,262,263,264,265,266,267,268
local function set(e,d) local r={} for k,v in pairs(e) do r[k]=v end for k,v in pairs(d) do r[k]=v end return r end
local function init(rows,cols) return{t=of_string"",u={},v={},id=0,sid=0,ctr=0,cur=0,goal=0,top=0,pr="",mode=0,quit=false,warn=0,path="",msg="",rows=rows,cols=cols} end
local function say(e,m) return set(e,{msg=m}) end
local function dirty(e) return e.id~=e.sid end
local function lstart(e,n) return line_start(e.t,n) end
local function lof(e,i) return line_of(e.t,i) end
local function llen(e,n) return(n<e.t.m and lstart(e,n+1)-1 or e.t.n)-lstart(e,n) end
local function col(e) return e.cur-lstart(e,lof(e,e.cur)) end
local function mv(e,c) e=set(e,{cur=c}) return set(e,{goal=col(e)}) end
local function push(l,x) local r={x} for i=1,min(#l,umax-1) do r[i+1]=l[i] end return r end
local function pop(l) return{table.unpack(l,2)} end
local function edit(e,t,c) return mv(set(e,{t=t,u=push(e.u,{e.t,e.cur,e.id}),v={},id=e.ctr+1,ctr=e.ctr+1}),c) end
local function ins(e,s) return edit(e,insert(e.t,e.cur,s),e.cur+#s) end
local function vert(e,d) local n=lof(e,e.cur)+d if n<0 or n>e.t.m then return e end return set(e,{cur=lstart(e,n)+min(e.goal,llen(e,n))}) end
local function isw(e,i) local c=char_at(e.t,i) return c~=nil and c:match("^[%w_]$")~=nil end
local function sw(e,x) return mv(set(e,{t=x[1],id=x[3]}),min(x[2],x[1].n)) end
local function undo(e) if #e.u==0 then return say(e,"nothing to undo") end return set(sw(e,e.u[1]),{u=pop(e.u),v=push(e.v,{e.t,e.cur,e.id})}) end
local function redo(e) if #e.v==0 then return say(e,"nothing to redo") end return set(sw(e,e.v[1]),{v=pop(e.v),u=push(e.u,{e.t,e.cur,e.id})}) end
local function op(e,p)
 if #p>=256 then return say(e,"path too long") end
 local f=io.open(p,"rb")
 local function ld(s,m) return set(mv(set(e,{t=of_string(s),u={},v={},top=0,id=e.ctr+1,sid=e.ctr+1,ctr=e.ctr+1,path=p}),0),{msg=m}) end
 if not f then return ld("","new file") end
 local s,m=f:read("a") f:close()
 if not s then return say(e,m or "unreadable") end
 if s:find("\0",1,true) then return say(e,"binary file refused") end
 return ld(s,"opened")
end
local function sv(e) local f,m=io.open(e.path,"wb") if not f then return say(e,m) end f:write(str(e.t)) f:close() return set(e,{sid=e.id,msg="saved"}) end
local function gd(e,w,k,m,f) if dirty(e) and w~=k then return set(e,{warn=k,msg=m}) else return f(e) end end
local function prompt(e,k) local n=#e.pr
 if k==k_enter then return set(e.mode==1 and op(e,e.pr) or n>=256 and say(e,"path too long") or sv(set(e,{path=e.pr})),{mode=0})
 elseif k==k_esc then return set(e,{mode=0,msg="cancelled"})
 elseif k==k_bs or k==8 then return set(e,{pr=e.pr:sub(1,max(0,n-1))})
 elseif k>=32 and k<256 and n<255 then return set(e,{pr=e.pr..char(k)}) else return e end
end
local function lw(p,i) while i>0 and p(i-1) do i=i-1 end return i end
local function rw(p,n,i) while i<n and p(i) do i=i+1 end return i end
local function key(e,k) local w=e.warn
 if k==0 then return e end
 e=set(e,{warn=0})
 if e.mode>0 then return prompt(e,k) end
 e=set(e,{msg=""}) local n=e.t.n
 if k==k_quit then return gd(e,w,k,"unsaved changes; F10 again to quit",function(e)return set(e,{quit=true})end)
 elseif k==k_open then return gd(e,w,k,"unsaved changes; F1 again to discard",function(e)return set(e,{mode=1,pr=""})end)
 elseif k==k_save then if e.path~="" then return sv(e) else return set(e,{mode=2,pr=""}) end
 elseif k==k_undo then return undo(e) elseif k==k_redo then return redo(e)
 elseif k==k_up then return vert(e,-1) elseif k==k_down then return vert(e,1)
 elseif k==k_left then if e.cur>0 then return mv(e,e.cur-1) else return e end
 elseif k==k_right then if e.cur<n then return mv(e,e.cur+1) else return e end
 elseif k==k_wleft then return mv(e,lw(function(i)return isw(e,i)end,lw(function(i)return not isw(e,i)end,e.cur)))
 elseif k==k_wright then return mv(e,rw(function(i)return isw(e,i)end,n,rw(function(i)return not isw(e,i)end,n,e.cur)))
 elseif k==k_enter or k==10 then return ins(e,"\n")
 elseif k==k_bs or k==8 then if e.cur>0 then return edit(e,delete(e.t,e.cur-1,1),e.cur-1) else return e end
 elseif k==k_del then if e.cur<n then return edit(e,delete(e.t,e.cur,1),e.cur) else return e end
 elseif k==9 or(k>=32 and k<256) then return ins(e,char(k)) else return e end
end
local function esc(s) local n=#s local function c(i) return s:sub(i,i) end
 if n==0 then return k_esc
 elseif c(1)=="O" then if n~=2 then return 0 end return({P=k_open,Q=k_save,R=k_undo,S=k_redo})[c(2)] or 0
 elseif c(1)~="[" or n<2 then return 0 end
 local l=c(n)
 if l=="~" then if n==4 and c(2)=="1" and c(3)>="1" and c(3)<="4" then return k_open+byte(c(3))-49 elseif n==4 and c(2)=="2" and c(3)=="1" then return k_quit elseif n==3 and c(2)=="3" then return k_del else return 0 end
 elseif l=="A" then return k_up elseif l=="B" then return k_down
 elseif l=="C" then return n>2 and k_wright or k_right elseif l=="D" then return n>2 and k_wleft or k_left else return 0 end
end
local hd="F1 open  F2 save  F10 quit  F3 undo  F4 redo"
local function render(e)
 local h,ln=max(1,e.rows-2),lof(e,e.cur)
 local top=ln<e.top and ln or ln>=e.top+h and ln-h+1 or e.top
 e=set(e,{top=top}) local b={} local function p(s) b[#b+1]=s end
 local l=e.mode==1 and 6 or 9
 p"\27[?25l\27[H\27[7m" local s=hd:sub(1,e.cols) p(s..rep(" ",e.cols-#s)) p"\27[0m"
 for i=0,h-1 do p(("\27[%d;1H\27[K"):format(i+2)) if top+i<=e.t.m then p((copy(e.t,lstart(e,top+i),min(llen(e,top+i),e.cols)):gsub("\t"," "):gsub("[^ -~]","?"))) end end
 p(("\27[%d;1H\27[K"):format(e.rows))
 p(e.mode>0 and((e.mode==1 and"open: " or"save as: ")..e.pr) or e.msg~="" and e.msg or(e.path=="" and"[no name]" or e.path)..(dirty(e) and" *" or""))
 p(("\27[%d;%dH\27[?25h"):format(e.mode>0 and e.rows or ln-top+2,min(e.cols,e.mode>0 and l+#e.pr+1 or col(e)+1)))
 return e,table.concat(b)
end
local tty
local function rd1() local c=tty:read(1) if c then return byte(c) end tty:close() tty=io.open("/dev/tty","rb") tty:setvbuf("no") return-1 end
local function getkey() local c=rd1()
 if c~=27 then return c<0 and-1 or c end
 c=rd1() if c<0 then return k_esc elseif c~=91 and c~=79 then return 0 end
 local b={char(c)}
 if c==79 then c=rd1() if c>=0 then b[2]=char(c) end else while #b<8 do c=rd1() if c>=0 then b[#b+1]=char(c) end if c>=0x40 and c<=0x7e then break end end end
 return esc(table.concat(b))
end
local function size() local i=io.popen("stty size 2>/dev/null") local r,c=(i:read("a") or""):match("(%d+)%s+(%d+)") i:close() if r then return tonumber(r),tonumber(c) end return 24,80 end
local function main(a)
 if #a>1 then io.stderr:write("usage: te [file]\n") os.exit(2) end
 if os.execute("test -t 0 -a -t 1")~=true then io.stderr:write("te: terminal required\n") os.exit(1) end
 local e=init(24,80) if a[1] then e=op(e,a[1]) end
 if e.msg~="" then io.stderr:write(e.msg,"\n") end
 local i=io.popen("stty -g") local o=i:read("l") i:close()
 local function w(s) io.stdout:write(s) io.stdout:flush() end
 os.execute("stty raw -echo min 0 time 1")
 tty=io.open("/dev/tty","rb") tty:setvbuf("no")
 w"\27[?1049h"
 local ok,m=pcall(function()
  local e2,s=render(e) w(s)
  while not e.quit do
   local k=getkey()
   if k==-1 then local r,c=size() if r>2 and c>0 and(r~=e.rows or c~=e.cols) then e=set(e,{rows=r,cols=c}) e2,s=render(e) w(s) end else e=key(e2,k) e2,s=render(e) w(s) end
  end end)
  w"\27[?1049l" os.execute("stty "..o)
 if not ok then io.stderr:write(tostring(m),"\n") os.exit(1) end
end
local M={cnt=cnt,lf=lf,len=function(t)return t.n end,nl=function(t)return t.m end,ht=function(t)return t.h end,lim=lim,str=str,copy=copy,of_string=of_string,concat=concat,split=split,insert=insert,delete=delete,substr=substr,line_start=line_start,line_of=line_of,char_at=char_at,umax=umax,init=init,key=key,render=render,esc=esc,op=op,dirty=dirty,k={enter=k_enter,bs=k_bs,up=k_up,down=k_down,left=k_left,right=k_right,wleft=k_wleft,wright=k_wright,del=k_del,esc=k_esc,open=k_open,save=k_save,undo=k_undo,redo=k_redo,quit=k_quit}}
if arg and arg[0] and arg[0]:match("te%.lua$") then main(arg) end
return M
