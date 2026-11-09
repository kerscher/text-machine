#ifndef ROPE_H
#define ROPE_H
#include <stddef.h>
typedef struct Rope Rope;
Rope *rope_from_string(const char *text);
Rope *rope_concat(const Rope *left, const Rope *right);
size_t rope_length(const Rope *rope);
int rope_char_at(const Rope *rope, size_t index, char *out);
char *rope_to_string(const Rope *rope);
int rope_split(const Rope *rope,size_t index,Rope **left,Rope **right);
Rope *rope_insert(const Rope *rope,size_t index,const char *text);
Rope *rope_delete(const Rope *rope,size_t index,size_t count);
Rope *rope_substr(const Rope *rope,size_t index,size_t count);
size_t rope_copy(const Rope *rope,size_t index,char *out,size_t count);
size_t rope_newlines(const Rope *rope);
int rope_line_start(const Rope *rope,size_t line,size_t *out);
int rope_line_of(const Rope *rope,size_t index,size_t *out);
void rope_free(Rope *rope);
#endif
