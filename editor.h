#ifndef EDITOR_H
#define EDITOR_H
#include "rope.h"
#include <stddef.h>
#define UMAX 1000
enum { K_ENTER=13, K_BS=127,
	K_UP=256, K_DOWN, K_LEFT, K_RIGHT, K_WLEFT, K_WRIGHT, K_DEL, K_ESC, K_OPEN, K_SAVE, K_UNDO, K_REDO, K_QUIT };
typedef struct { Rope *r; size_t id,cur; } Snap;
typedef struct {
	Rope *t;
	Snap u[UMAX],v[UMAX];
	size_t nu,nv,id,sid,ctr,cur,goal,top,pn;
	int rows,cols,mode,quit,warn;
	char path[256],pr[256],msg[96];
} Ed;
int ed_init(Ed *e,int rows,int cols);
void ed_free(Ed *e);
void ed_key(Ed *e,int key);
int ed_esc(const char *seq,size_t n);
int ed_open(Ed *e,const char *path);
int ed_save(Ed *e);
int ed_dirty(const Ed *e);
size_t ed_render(Ed *e,char *out,size_t cap);
#endif
