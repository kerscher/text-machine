#include "editor.h"
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
static Ed e;
static char fb[8192];
static void typ(const char *s){ while (*s) ed_key(&e,(unsigned char)*s++); }
static void txt(const char *m){ char *t=rope_to_string(e.t); assert(t && strcmp(t,m)==0); free(t); }
static void top(void)
{
	char *a,*b;
	ed_render(&e,fb,sizeof fb);
	a=strstr(fb,"\x1b[H");
	b=strstr(fb,"\x1b[2;1H");
	assert(a && b && a<b);
	*b=0;
	assert(strstr(a,"F1 open") && strstr(a,"F2 save") && strstr(a,"F10 quit"));
}
int main(void)
{
	FILE *f;
	char *t;
	assert(ed_init(&e,10,40));
	top();
	typ("hello world");
	txt("hello world");
	assert(ed_dirty(&e));
	ed_key(&e,K_ENTER);
	typ("ab");
	ed_key(&e,K_UP);
	assert(e.cur==2);
	ed_key(&e,K_DOWN);
	assert(e.cur==14);
	ed_key(&e,K_UP);
	ed_key(&e,K_WLEFT);
	assert(e.cur==0);
	ed_key(&e,K_WRIGHT);
	assert(e.cur==5);
	ed_key(&e,K_WRIGHT);
	assert(e.cur==11);
	ed_key(&e,K_BS);
	txt("hello worl\nab");
	ed_key(&e,K_DEL);
	txt("hello worlab");
	ed_key(&e,K_UNDO);
	txt("hello worl\nab");
	ed_key(&e,K_UNDO);
	txt("hello world\nab");
	ed_key(&e,K_REDO);
	txt("hello worl\nab");
	while (e.nu) ed_key(&e,K_UNDO);
	txt("");
	assert(!ed_dirty(&e));
	while (e.nv) ed_key(&e,K_REDO);
	txt("hello worlab");
	while (e.nu>11) ed_key(&e,K_UNDO);
	txt("hello world");
	ed_key(&e,17);
	ed_key(&e,17);
	assert(!e.quit && !e.mode);
	ed_key(&e,K_QUIT);
	assert(!e.quit && strstr(e.msg,"unsaved"));
	ed_key(&e,0);
	ed_key(&e,K_QUIT);
	assert(e.quit);
	e.quit=0;
	ed_key(&e,K_SAVE);
	assert(e.mode==2);
	typ("te_test.tmp");
	ed_key(&e,K_ENTER);
	assert(e.mode==0 && !ed_dirty(&e));
	f=fopen("te_test.tmp","rb");
	assert(f);
	t=calloc(64,1);
	assert(fread(t,1,63,f)==11 && strcmp(t,"hello world")==0);
	fclose(f);
	free(t);
	typ("!");
	assert(ed_dirty(&e));
	ed_key(&e,K_UNDO);
	assert(!ed_dirty(&e));
	ed_key(&e,K_REDO);
	ed_key(&e,K_OPEN);
	assert(e.mode==0 && strstr(e.msg,"unsaved"));
	ed_key(&e,K_OPEN);
	assert(e.mode==1);
	ed_key(&e,K_ESC);
	assert(e.mode==0);
	ed_key(&e,K_SAVE);
	assert(!ed_dirty(&e));
	ed_key(&e,K_OPEN);
	typ("te_test.tmp");
	ed_key(&e,K_ENTER);
	txt("hello world!");
	assert(!ed_dirty(&e) && e.nu==0);
	typ("x");
	ed_key(&e,K_QUIT);
	ed_key(&e,K_LEFT);
	ed_key(&e,K_QUIT);
	assert(!e.quit);
	remove("te_test.tmp");
	assert(ed_open(&e,"te_missing.tmp") && strstr(e.msg,"new"));
	txt("");
	assert(ed_esc("OP",2)==K_OPEN && ed_esc("OQ",2)==K_SAVE && ed_esc("OR",2)==K_UNDO && ed_esc("OS",2)==K_REDO);
	assert(ed_esc("[11~",4)==K_OPEN && ed_esc("[14~",4)==K_REDO && ed_esc("[21~",4)==K_QUIT && ed_esc("[15~",4)==0);
	assert(ed_esc("[A",2)==K_UP && ed_esc("[D",2)==K_LEFT && ed_esc("[3~",3)==K_DEL);
	assert(ed_esc("[1;5C",5)==K_WRIGHT && ed_esc("[1;5D",5)==K_WLEFT && ed_esc("",0)==K_ESC && ed_esc("[Z",2)==0);
	{
		int i;
		for (i=0;i<30;i++) { typ("line"); ed_key(&e,K_ENTER); }
		ed_render(&e,fb,sizeof fb);
		assert(e.top==23 && strstr(fb,"\x1b[10;1H") && !strstr(fb,"\x1b[11;1H"));
		for (i=0;i<30;i++) ed_key(&e,K_UP);
		ed_render(&e,fb,sizeof fb);
		assert(e.top==0);
		for (i=0;i<2000;i++) typ("a");
		assert(e.nu<=UMAX);
	}
	ed_free(&e);
	return 0;
}
