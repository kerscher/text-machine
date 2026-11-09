#include "rope.h"
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
typedef struct N N;
struct N {
	size_t ref,len,ht,nl;
	char *s;
	N *l,*r;
};
struct Rope { N *n; };
#define CH 256
static N *bld(const char *s,size_t len);
static int fin(N **p);
static void drop(N *n)
{
	if (!n || --n->ref) return;
	drop(n->l);
	drop(n->r);
	free(n->s);
	free(n);
}
static int hold(N *n)
{
	if (!n) return 1;
	if (n->ref == SIZE_MAX) return 0;
	n->ref++;
	return 1;
}
static N *join(N *l,N *r)
{
	N *n;
	if (l->len > SIZE_MAX-r->len) return NULL;
	n=malloc(sizeof(*n));
	if (!n) return NULL;
	if (!hold(l)) { free(n); return NULL; }
	if (!hold(r)) { drop(l); free(n); return NULL; }
	n->ref=1;
	n->len=l->len+r->len;
	n->nl=l->nl+r->nl;
	n->ht=(l->ht>r->ht?l->ht:r->ht)+1;
	n->s=NULL;
	n->l=l;
	n->r=r;
	return n;
}
static size_t cnt(const char *s,size_t n){ size_t c=0; while (n--) c+=*s++=='\n'; return c; }
static N *mk(const char *s,size_t len)
{
	N *n=malloc(sizeof(*n));
	if (!n) return NULL;
	n->s=malloc(len+1);
	if (!n->s) { free(n); return NULL; }
	memcpy(n->s,s,len);
	n->s[len]=0;
	n->ref=1;
	n->len=len;
	n->ht=1;
	n->nl=cnt(s,len);
	n->l=n->r=NULL;
	return n;
}
static N *cat(N *a,N *b)
{
	N *n;
	if (!a) return b;
	if (!b) return a;
	n=join(a,b);
	drop(a);
	drop(b);
	return n;
}
static int cc(N *a,N *b,N **o){ *o=cat(a,b); return *o||(!a&&!b); }
static N *bld(const char *s,size_t len)
{
	N *l,*r;
	if (len<=CH) return mk(s,len);
	l=bld(s,len/2);
	r=bld(s+len/2,len-len/2);
	if (!l||!r) { drop(l); drop(r); return NULL; }
	return cat(l,r);
}
static size_t lim(size_t len){ size_t h=0; while (len) { h++; len>>=1; } return 2*h+8; }
static int fin(N **p)
{
	N *n=*p,*m;
	Rope t;
	char *s;
	if (!n || n->ht<=lim(n->len)) return 1;
	t.n=n;
	s=rope_to_string(&t);
	m=s?bld(s,n->len):NULL;
	free(s);
	drop(n);
	*p=m;
	return m!=NULL;
}
Rope *rope_from_string(const char *s)
{
	Rope *r;
	size_t len;
	if (!s) return NULL;
	len=strlen(s);
	if (len==SIZE_MAX) return NULL;
	r=malloc(sizeof(*r));
	if (!r) return NULL;
	r->n=NULL;
	if (!len) return r;
	r->n=bld(s,len);
	if (!r->n) { free(r); return NULL; }
	return r;
}
Rope *rope_concat(const Rope *a,const Rope *b)
{
	Rope *r;
	if (!a || !b) return NULL;
	r=malloc(sizeof(*r));
	if (!r) return NULL;
	if (!a->n || !b->n) {
		r->n=a->n?a->n:b->n;
		if (!hold(r->n)) { free(r); return NULL; }
		return r;
	}
	r->n=join(a->n,b->n);
	if (!r->n || !fin(&r->n)) { free(r); return NULL; }
	return r;
}
size_t rope_length(const Rope *r){ return r&&r->n?r->n->len:0; }
int rope_char_at(const Rope *r,size_t i,char *c)
{
	N *n;
	if (!r || !c || i>=rope_length(r)) return 0;
	n=r->n;
	while (!n->s) {
		if (i<n->l->len) n=n->l;
		else { i-=n->l->len; n=n->r; }
	}
	*c=n->s[i];
	return 1;
}
char *rope_to_string(const Rope *r)
{
	N **stk;
	N *n;
	char *s;
	size_t len,sp,off;
	if (!r) return NULL;
	len=rope_length(r);
	if (len==SIZE_MAX) return NULL;
	s=malloc(len+1);
	if (!s) return NULL;
	if (!r->n) { s[0]=0; return s; }
	if (r->n->ht>SIZE_MAX/sizeof(*stk)) { free(s); return NULL; }
	stk=malloc(r->n->ht*sizeof(*stk));
	if (!stk) { free(s); return NULL; }
	sp=off=0;
	stk[sp++]=r->n;
	while (sp) {
		n=stk[--sp];
		if (n->s) { memcpy(s+off,n->s,n->len); off+=n->len; }
		else { stk[sp++]=n->r; stk[sp++]=n->l; }
	}
	s[len]=0;
	free(stk);
	return s;
}
void rope_free(Rope *r){ if (!r) return; drop(r->n); free(r); }
static int sp(N *n,size_t i,N **a,N **b)
{
	N *x;
	*a=*b=NULL;
	if (!i) { if (!hold(n)) return 0; *b=n; return 1; }
	if (i>=n->len) { if (!hold(n)) return 0; *a=n; return 1; }
	if (n->s) {
		*a=mk(n->s,i);
		*b=mk(n->s+i,n->len-i);
		if (!*a||!*b) { drop(*a); drop(*b); *a=*b=NULL; return 0; }
		return 1;
	}
	if (i<n->l->len) {
		if (!sp(n->l,i,a,&x)) return 0;
		if (!hold(n->r)) { drop(*a); drop(x); *a=NULL; return 0; }
		if (!cc(x,n->r,b)) { drop(*a); *a=NULL; return 0; }
		return 1;
	}
	if (!hold(n->l)) return 0;
	if (!sp(n->r,i-n->l->len,&x,b)) { drop(n->l); return 0; }
	if (!cc(n->l,x,a)) { drop(*b); *b=NULL; return 0; }
	return 1;
}
static int cut(N *n,size_t i,size_t k,N **a,N **m,N **z)
{
	N *y;
	*a=*m=*z=NULL;
	if (!n) return 1;
	if (!sp(n,i,a,&y)) return 0;
	if (y && !sp(y,k,m,z)) { drop(*a); drop(y); *a=NULL; return 0; }
	drop(y);
	return 1;
}
static int mkr(N *n,Rope **o)
{
	*o=malloc(sizeof(**o));
	if (!*o) { drop(n); return 0; }
	(*o)->n=n;
	return 1;
}
static Rope *fr(N *t)
{
	Rope *o;
	if (!fin(&t) || !mkr(t,&o)) return NULL;
	return o;
}
int rope_split(const Rope *r,size_t i,Rope **a,Rope **b)
{
	N *x,*y,*t;
	if (!r || !a || !b || i>rope_length(r)) return 0;
	if (!cut(r->n,i,0,&x,&t,&y)) return 0;
	if (!fin(&x)) { drop(y); return 0; }
	if (!fin(&y)) { drop(x); return 0; }
	if (!mkr(x,a)) { drop(y); return 0; }
	if (!mkr(y,b)) { rope_free(*a); *a=NULL; return 0; }
	return 1;
}
Rope *rope_insert(const Rope *r,size_t i,const char *s)
{
	N *x,*m=NULL,*y,*t,*u;
	if (!r || !s || i>rope_length(r)) return NULL;
	if (!cut(r->n,i,0,&x,&t,&y)) return NULL;
	if (*s && !(m=mk(s,strlen(s)))) { drop(x); drop(y); return NULL; }
	if (!cc(x,m,&t)) { drop(y); return NULL; }
	if (!cc(t,y,&u)) return NULL;
	return fr(u);
}
Rope *rope_delete(const Rope *r,size_t i,size_t k)
{
	N *x,*m,*y,*t;
	if (!r || i>rope_length(r) || k>rope_length(r)-i) return NULL;
	if (!cut(r->n,i,k,&x,&m,&y)) return NULL;
	drop(m);
	if (!cc(x,y,&t)) return NULL;
	return fr(t);
}
Rope *rope_substr(const Rope *r,size_t i,size_t k)
{
	N *x,*m,*y;
	if (!r || i>rope_length(r) || k>rope_length(r)-i) return NULL;
	if (!cut(r->n,i,k,&x,&m,&y)) return NULL;
	drop(x);
	drop(y);
	return fr(m);
}
static size_t rd(const N *n,size_t i,char *b,size_t k)
{
	size_t g;
	if (n->s) { g=n->len-i; if (g>k) g=k; memcpy(b,n->s+i,g); return g; }
	if (i>=n->l->len) return rd(n->r,i-n->l->len,b,k);
	g=rd(n->l,i,b,k);
	return g<k?g+rd(n->r,0,b+g,k-g):g;
}
size_t rope_copy(const Rope *r,size_t i,char *b,size_t k)
{
	if (!r || !b || i>=rope_length(r)) return 0;
	return rd(r->n,i,b,k);
}
size_t rope_newlines(const Rope *r){ return r&&r->n?r->n->nl:0; }
int rope_line_start(const Rope *r,size_t k,size_t *out)
{
	const N *n;
	size_t off=0,i;
	if (!r || !out || k>rope_newlines(r)) return 0;
	if (!k) { *out=0; return 1; }
	n=r->n;
	while (!n->s) {
		if (k<=n->l->nl) n=n->l;
		else { k-=n->l->nl; off+=n->l->len; n=n->r; }
	}
	for (i=0;;i++) if (n->s[i]=='\n' && !--k) break;
	*out=off+i+1;
	return 1;
}
int rope_line_of(const Rope *r,size_t i,size_t *out)
{
	const N *n;
	size_t c=0;
	if (!r || !out || i>rope_length(r)) return 0;
	n=r->n;
	if (n) {
		while (!n->s) {
			if (i<n->l->len) n=n->l;
			else { c+=n->l->nl; i-=n->l->len; n=n->r; }
		}
		c+=cnt(n->s,i);
	}
	*out=c;
	return 1;
}
