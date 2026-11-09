#include "rope.h"
#include <assert.h>
#include <stdlib.h>
#include <string.h>
static unsigned long long sd = 88172645463325252ULL;
static size_t rnd(size_t n){ sd ^= sd << 13; sd ^= sd >> 7; sd ^= sd << 17; return (size_t)(sd % n); }
static void same(const Rope *r, const char *m)
{
	size_t i, k, e, n = strlen(m), line = 0, off;
	char *t = rope_to_string(r), buf[64];
	assert(t != NULL && strcmp(t, m) == 0 && rope_length(r) == n);
	free(t);
	for (i = 0; i < n; i++) if (m[i] == '\n') line++;
	assert(rope_newlines(r) == line);
	for (k = 0; k <= line; k++) {
		for (off = 0, i = 0, e = 0; e < k; i++) if (m[i] == '\n') { e++; off = i + 1; }
		assert(rope_line_start(r, k, &e) && e == off);
	}
	assert(!rope_line_start(r, line + 1, &e));
	for (i = 0; i <= n; i += 7) {
		for (k = 0, e = 0; k < i; k++) e += m[k] == '\n';
		assert(rope_line_of(r, i, &k) && k == e);
		k = rope_copy(r, i, buf, sizeof buf);
		assert(k == (n - i < sizeof buf ? n - i : sizeof buf) && memcmp(buf, m + i, k) == 0);
	}
}
static int edits(void)
{
	static const char *w[] = { "a", "xy\n", "\n", "lorem ipsum dolor sit amet ", "" };
	char m[200000] = "", c[512], *p;
	size_t i, k, n = 0, j;
	Rope *r = rope_from_string(""), *x, *y, *z;
	assert(r != NULL);
	for (j = 0; j < 4000; j++) {
		const char *s = w[rnd(5)];
		if (rnd(3) == 0 && n > 0) {
			i = rnd(n + 1);
			k = rnd(n - i + 1 > 40 ? 40 : n - i + 1);
			x = rope_delete(r, i, k);
			memmove(m + i, m + i + k, n - i - k + 1);
			n -= k;
		} else {
			i = rnd(n + 1);
			x = rope_insert(r, i, s);
			memmove(m + i + strlen(s), m + i, n - i + 1);
			memcpy(m + i, s, strlen(s));
			n += strlen(s);
		}
		assert(x != NULL);
		if (j % 97 == 0) same(x, m);
		rope_free(r);
		r = x;
	}
	same(r, m);
	for (j = 0; j < 40; j++) {
		i = rnd(n + 1);
		assert(rope_split(r, i, &x, &y) && rope_length(x) == i && rope_length(y) == n - i);
		z = rope_concat(x, y);
		assert(z != NULL);
		same(z, m);
		rope_free(x); rope_free(y); rope_free(z);
		k = rnd(n - i + 1);
		x = rope_substr(r, i, k);
		assert(x != NULL);
		memcpy(c, m + i, k < sizeof c ? k : sizeof c);
		p = rope_to_string(x);
		assert(p != NULL && strlen(p) == k && strncmp(p, m + i, k) == 0);
		free(p);
		rope_free(x);
	}
	assert(!rope_split(r, n + 1, &x, &y) && rope_insert(r, n + 1, "a") == NULL);
	assert(rope_delete(r, n, 1) == NULL && rope_substr(r, 0, n + 1) == NULL);
	rope_free(r);
	r = rope_from_string("");
	for (j = 0; j < 20000; j++) { x = rope_insert(r, j, "q"); assert(x != NULL); rope_free(r); r = x; }
	assert(rope_length(r) == 20000 && rope_char_at(r, 19999, &m[0]) && m[0] == 'q');
	rope_free(r);
	return 0;
}
int main(void)
{
	Rope *empty = rope_from_string("");
	Rope *hello = rope_from_string("hello");
	Rope *space = rope_from_string(" ");
	Rope *world = rope_from_string("world");
	Rope *prefix;
	Rope *joined;
	char character;
	char *text;
	assert(empty != NULL && hello != NULL && space != NULL && world != NULL);
	prefix = rope_concat(hello, space);
	assert(prefix != NULL);
	joined = rope_concat(prefix, world);
	assert(joined != NULL);
	assert(rope_length(joined) == 11);
	assert(rope_char_at(joined, 6, &character) && character == 'w');
	assert(!rope_char_at(joined, 11, &character));
	assert(!rope_char_at(joined, 0, NULL));
	text = rope_to_string(joined);
	assert(text != NULL && strcmp(text, "hello world") == 0);
	free(text);
	rope_free(hello);
	rope_free(space);
	rope_free(world);
	rope_free(prefix);
	text = rope_to_string(joined);
	assert(text != NULL && strcmp(text, "hello world") == 0);
	free(text);
	rope_free(joined);
	joined = rope_concat(empty, empty);
	assert(joined != NULL && rope_length(joined) == 0);
	text = rope_to_string(joined);
	assert(text != NULL && text[0] == '\0');
	free(text);
	rope_free(joined);
	rope_free(empty);
	assert(rope_from_string(NULL) == NULL);
	assert(rope_concat(NULL, NULL) == NULL);
	return edits();
}
