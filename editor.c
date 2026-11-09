#define _POSIX_C_SOURCE 200809L
#include "editor.h"
#include <ctype.h>
#include <errno.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
typedef struct { char *p,*e; } B;
static const struct { int k; const char *s; } tbl[]={{K_OPEN,"F1 open"},{K_SAVE,"F2 save"},{K_QUIT,"F10 quit"},{K_UNDO,"F3 undo"},{K_REDO,"F4 redo"}};
static void say(Ed *e,const char *s){ snprintf(e->msg,sizeof e->msg,"%s",s); }
int ed_dirty(const Ed *e){ return e->id!=e->sid; }
static void clr(Ed *e)
{
	while (e->nu) rope_free(e->u[--e->nu].r);
	while (e->nv) rope_free(e->v[--e->nv].r);
}
int ed_init(Ed *e,int rows,int cols)
{
	memset(e,0,sizeof(*e));
	e->rows=rows;
	e->cols=cols;
	e->t=rope_from_string("");
	return e->t!=NULL;
}
void ed_free(Ed *e){ clr(e); rope_free(e->t); e->t=NULL; }
static size_t lstart(const Ed *e,size_t ln){ size_t s=0; rope_line_start(e->t,ln,&s); return s; }
static size_t lof(const Ed *e,size_t i){ size_t l=0; rope_line_of(e->t,i,&l); return l; }
static size_t llen(const Ed *e,size_t ln)
{
	size_t s=lstart(e,ln);
	return (ln<rope_newlines(e->t)?lstart(e,ln+1)-1:rope_length(e->t))-s;
}
static size_t col(const Ed *e){ return e->cur-lstart(e,lof(e,e->cur)); }
static int edit(Ed *e,Rope *n)
{
	if (!n) { say(e,"out of memory"); return 0; }
	while (e->nv) rope_free(e->v[--e->nv].r);
	if (e->nu==UMAX) {
		rope_free(e->u[0].r);
		memmove(e->u,e->u+1,(UMAX-1)*sizeof(*e->u));
		e->nu--;
	}
	e->u[e->nu].r=e->t;
	e->u[e->nu].cur=e->cur;
	e->u[e->nu++].id=e->id;
	e->t=n;
	e->id=++e->ctr;
	return 1;
}
static void ins(Ed *e,const char *s)
{
	if (edit(e,rope_insert(e->t,e->cur,s))) { e->cur+=strlen(s); e->goal=col(e); }
}
static void vert(Ed *e,int d)
{
	size_t ln=lof(e,e->cur),l;
	if (d<0) { if (!ln) return; ln--; }
	else { if (ln>=rope_newlines(e->t)) return; ln++; }
	l=llen(e,ln);
	e->cur=lstart(e,ln)+(e->goal<l?e->goal:l);
}
static int isw(const Ed *e,size_t i)
{
	char c=0;
	rope_char_at(e->t,i,&c);
	return isalnum((unsigned char)c)||c=='_';
}
static void swap(Ed *e,Snap *from,size_t *nf,Snap *to,size_t *nt)
{
	size_t n=rope_length(from[*nf-1].r);
	to[*nt].r=e->t;
	to[*nt].cur=e->cur;
	to[(*nt)++].id=e->id;
	e->t=from[--*nf].r;
	e->id=from[*nf].id;
	e->cur=from[*nf].cur;
	if (e->cur>n) e->cur=n;
	e->goal=col(e);
}
static int guard(Ed *e,int w,int k,const char *m)
{
	if (!ed_dirty(e) || w==k) return 0;
	e->warn=k;
	say(e,m);
	return 1;
}
static void prompt(Ed *e,int k)
{
	if (k==K_ENTER) {
		e->pr[e->pn]=0;
		if (e->mode==1) ed_open(e,e->pr);
		else if (snprintf(e->path,sizeof e->path,"%s",e->pr)>=(int)sizeof e->path) say(e,"path too long");
		else ed_save(e);
		e->mode=0;
	} else if (k==K_ESC) { e->mode=0; say(e,"cancelled"); }
	else if (k==K_BS||k==8) { if (e->pn) e->pr[--e->pn]=0; }
	else if (k>=32&&k<256&&k!=K_BS&&e->pn<sizeof e->pr-1) { e->pr[e->pn++]=(char)k; e->pr[e->pn]=0; }
}
void ed_key(Ed *e,int k)
{
	int w=e->warn;
	size_t n=rope_length(e->t),i;
	if (!k) return;
	e->warn=0;
	if (e->mode) { prompt(e,k); return; }
	e->msg[0]=0;
	switch (k) {
	case K_QUIT: if (!guard(e,w,k,"unsaved changes; F10 again to quit")) e->quit=1; break;
	case K_OPEN:
		if (guard(e,w,k,"unsaved changes; F1 again to discard")) break;
		e->mode=1; e->pn=0; e->pr[0]=0;
		break;
	case K_SAVE:
		if (e->path[0]) ed_save(e);
		else { e->mode=2; e->pn=0; e->pr[0]=0; }
		break;
	case K_UNDO: if (e->nu) swap(e,e->u,&e->nu,e->v,&e->nv); else say(e,"nothing to undo"); break;
	case K_REDO: if (e->nv) swap(e,e->v,&e->nv,e->u,&e->nu); else say(e,"nothing to redo"); break;
	case K_UP: vert(e,-1); break;
	case K_DOWN: vert(e,1); break;
	case K_LEFT: if (e->cur) { e->cur--; e->goal=col(e); } break;
	case K_RIGHT: if (e->cur<n) { e->cur++; e->goal=col(e); } break;
	case K_WLEFT:
		for (i=e->cur;i&&!isw(e,i-1);) i--;
		while (i&&isw(e,i-1)) i--;
		e->cur=i; e->goal=col(e);
		break;
	case K_WRIGHT:
		for (i=e->cur;i<n&&!isw(e,i);) i++;
		while (i<n&&isw(e,i)) i++;
		e->cur=i; e->goal=col(e);
		break;
	case K_ENTER: case 10: ins(e,"\n"); break;
	case K_BS: case 8: if (e->cur && edit(e,rope_delete(e->t,e->cur-1,1))) { e->cur--; e->goal=col(e); } break;
	case K_DEL: if (e->cur<n) edit(e,rope_delete(e->t,e->cur,1)); break;
	default:
		if (k==9||(k>=32&&k<256)) { char s[2]; s[0]=(char)k; s[1]=0; ins(e,s); }
	}
}
int ed_esc(const char *s,size_t n)
{
	char f;
	if (!n) return K_ESC;
	if (s[0]=='O'&&n==2) return s[1]=='P'?K_OPEN:s[1]=='Q'?K_SAVE:s[1]=='R'?K_UNDO:s[1]=='S'?K_REDO:0;
	if (s[0]!='[' || n<2) return 0;
	f=s[n-1];
	if (f=='~'&&n==4&&s[1]=='1'&&s[2]>='1'&&s[2]<='4') return K_OPEN+(s[2]-'1');
	if (f=='~'&&n==4&&s[1]=='2'&&s[2]=='1') return K_QUIT;
	if (f=='A') return K_UP;
	if (f=='B') return K_DOWN;
	if (f=='C') return n>2?K_WRIGHT:K_RIGHT;
	if (f=='D') return n>2?K_WLEFT:K_LEFT;
	if (f=='~'&&n==3&&s[1]=='3') return K_DEL;
	return 0;
}
int ed_open(Ed *e,const char *p)
{
	FILE *f;
	char *b=NULL,*g;
	size_t n=0,c=0,m;
	Rope *r;
	if (strlen(p)>=sizeof e->path) { say(e,"path too long"); return 0; }
	f=fopen(p,"rb");
	if (!f && errno!=ENOENT) { say(e,strerror(errno)); return 0; }
	while (f) {
		if (n+4097>c) {
			c=c?c*2:8192;
			if (!(g=realloc(b,c))) { free(b); fclose(f); say(e,"out of memory"); return 0; }
			b=g;
		}
		m=fread(b+n,1,4096,f);
		n+=m;
		if (m<4096) break;
	}
	if (f && ferror(f)) { free(b); fclose(f); say(e,"read error"); return 0; }
	if (f) fclose(f);
	if (b) b[n]=0;
	if (b && strlen(b)!=n) { free(b); say(e,"binary file refused"); return 0; }
	r=rope_from_string(b?b:"");
	free(b);
	if (!r) { say(e,"out of memory"); return 0; }
	clr(e);
	rope_free(e->t);
	e->t=r;
	e->cur=e->goal=e->top=0;
	e->id=e->sid=++e->ctr;
	snprintf(e->path,sizeof e->path,"%s",p);
	say(e,f?"opened":"new file");
	return 1;
}
int ed_save(Ed *e)
{
	FILE *f=fopen(e->path,"wb");
	char *s;
	size_t n=rope_length(e->t);
	int ok;
	if (!f) { say(e,strerror(errno)); return 0; }
	s=rope_to_string(e->t);
	if (!s) { fclose(f); say(e,"out of memory"); return 0; }
	ok=fwrite(s,1,n,f)==n;
	free(s);
	ok=fclose(f)==0&&ok;
	if (!ok) { say(e,"write error"); return 0; }
	e->sid=e->id;
	say(e,"saved");
	return 1;
}
static void put(B *b,const char *s,size_t n)
{
	size_t m=(size_t)(b->e-b->p);
	if (n>m) n=m;
	memcpy(b->p,s,n);
	b->p+=n;
}
static void pf(B *b,const char *fmt,...)
{
	char t[1200];
	va_list a;
	int n;
	va_start(a,fmt);
	n=vsnprintf(t,sizeof t,fmt,a);
	va_end(a);
	if (n>(int)sizeof t-1) n=(int)sizeof t-1;
	if (n>0) put(b,t,(size_t)n);
}
static void row(B *b,int r){ pf(b,"\x1b[%d;1H\x1b[K",r); }
static void pad(B *b,const char *s,int w)
{
	size_t n=strlen(s);
	int i;
	if (n>(size_t)w) n=(size_t)w;
	put(b,s,n);
	for (i=(int)n;i<w;i++) put(b," ",1);
}
size_t ed_render(Ed *e,char *o,size_t cap)
{
	B b;
	char hd[256]="",line[1024],st[300];
	int h=e->rows-2,i,cr,cc,w,pl=0;
	size_t ln=lof(e,e->cur),s,l,j,k;
	if (!cap) return 0;
	b.p=o; b.e=o+cap-1;
	if (h<1) h=1;
	if (ln<e->top) e->top=ln;
	if (ln>=e->top+(size_t)h) e->top=ln-(size_t)h+1;
	for (j=0;j<sizeof tbl/sizeof *tbl;j++) {
		if (j) strncat(hd,"  ",sizeof hd-strlen(hd)-1);
		strncat(hd,tbl[j].s,sizeof hd-strlen(hd)-1);
	}
	put(&b,"\x1b[?25l\x1b[H\x1b[7m",13);
	pad(&b,hd,e->cols);
	put(&b,"\x1b[0m",4);
	for (i=0;i<h;i++) {
		row(&b,i+2);
		if (e->top+(size_t)i>rope_newlines(e->t)) continue;
		s=lstart(e,e->top+(size_t)i);
		l=llen(e,e->top+(size_t)i);
		w=e->cols<(int)sizeof line?e->cols:(int)sizeof line;
		if (l>(size_t)w) l=(size_t)w;
		k=rope_copy(e->t,s,line,l);
		for (j=0;j<k;j++) if ((unsigned char)line[j]<32||(unsigned char)line[j]>126) line[j]=line[j]=='\t'?' ':'?';
		put(&b,line,k);
	}
	row(&b,e->rows);
	if (e->mode) { pl=e->mode==1?6:9; pf(&b,"%s%s",e->mode==1?"open: ":"save as: ",e->pr); }
	else if (e->msg[0]) pf(&b,"%s",e->msg);
	else { snprintf(st,sizeof st,"%s%s",e->path[0]?e->path:"[no name]",ed_dirty(e)?" *":""); pf(&b,"%s",st); }
	cr=e->mode?e->rows:(int)(ln-e->top)+2;
	cc=e->mode?pl+(int)e->pn+1:(int)col(e)+1;
	if (cc>e->cols) cc=e->cols;
	pf(&b,"\x1b[%d;%dH\x1b[?25h",cr,cc);
	*b.p=0;
	return (size_t)(b.p-o);
}
#ifndef ED_NOMAIN
#include <signal.h>
#include <sys/ioctl.h>
#include <termios.h>
#include <unistd.h>
static struct termios old;
static void wr(const char *s,size_t n){ if (write(1,s,n)<0) return; }
static void norm(void){ tcsetattr(0,TCSAFLUSH,&old); wr("\x1b[?1049l",8); }
static int rd1(unsigned char *c){ return (int)read(0,c,1); }
static int getkey(void)
{
	unsigned char c,s[8];
	int r;
	size_t n=0;
	while ((r=rd1(&c))==0);
	if (r<0) return 0;
	if (c!=27) return c;
	if (rd1(&c)<=0) return K_ESC;
	if (c!='['&&c!='O') return 0;
	s[n++]=c;
	if (s[0]=='O') { if (rd1(&c)==1) s[n++]=c; return ed_esc((char *)s,n); }
	while (n<sizeof s && rd1(&c)==1) { s[n++]=c; if (c>=0x40&&c<=0x7e) break; }
	return ed_esc((char *)s,n);
}
int main(int c,char **v)
{
	struct termios t;
	struct winsize ws;
	Ed *e=malloc(sizeof(*e));
	char *buf=NULL,*g;
	size_t n,cap=0,need;
	int k;
	FILE *lg=getenv("TE_LOG")?fopen(getenv("TE_LOG"),"w"):NULL;
	if (!e || !ed_init(e,24,80)) return 1;
	if (c>2) { fprintf(stderr,"usage: te [file]\n"); return 2; }
	if (!isatty(0)||!isatty(1)) { fprintf(stderr,"te: terminal required\n"); return 1; }
	if (c==2) ed_open(e,v[1]);
	if (e->msg[0]) fprintf(stderr,"%s\n",e->msg);
	tcgetattr(0,&old);
	t=old;
	t.c_iflag&=~(unsigned)(IXON|ICRNL|BRKINT|INPCK|ISTRIP);
	t.c_lflag&=~(unsigned)(ECHO|ICANON|ISIG|IEXTEN);
	t.c_cc[VMIN]=0;
	t.c_cc[VTIME]=1;
	tcsetattr(0,TCSAFLUSH,&t);
	wr("\x1b[?1049h",8);
	while (!e->quit) {
		if (ioctl(1,TIOCGWINSZ,&ws)==0&&ws.ws_row>2&&ws.ws_col>0) { e->rows=ws.ws_row; e->cols=ws.ws_col; }
		need=(size_t)e->rows*((size_t)e->cols+32)+512;
		if (need>cap) { if (!(g=realloc(buf,need))) break; buf=g; cap=need; }
		n=ed_render(e,buf,cap);
		wr(buf,n);
		k=getkey();
		if (lg) { fprintf(lg,"%d\n",k); fflush(lg); }
		ed_key(e,k);
	}
	norm();
	free(buf);
	ed_free(e);
	free(e);
	return 0;
}
#endif
