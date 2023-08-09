#include <stdint.h>
#include <string.h>
#include <unistd.h>

struct _IO_FILE;

typedef struct _IO_FILE FILE;

extern FILE *stdin;
extern FILE *stdout;

int fgetc(FILE *stream);
int fputs(const char *restrict s, FILE *restrict stream);
int fflush(FILE *stream);
void *malloc(size_t size);

#define EOF (-1)

extern int tigermain(void);

int64_t *initArray(size_t size, int64_t init) {
  int64_t *a = malloc(size * sizeof(int64_t));

  for(size_t i=0; i<size; i++) {
    a[i] = init;
  }

  return a;
}

int64_t strCmp(const char* const s1, const char* const s2) {
  return strcmp(s1, s2);
}

void print(const char* const s) {
  fputs(s, stdout);
}

void flush() {
  fflush(stdout);
}

const char* getchar() {
  int c = fgetc(stdin);

  if(c == EOF) {
    return "";
  } else {
    char *p = malloc(2);

    p[0] = c;
    p[1] = 0;

    return p;
  }
}

int64_t ord(const char* const s) {
  if(strcmp(s, "") == 0) {
    return -1;
  } else {
    return s[0];
  }
}

const char* chr(int64_t i) {
  if (i<0 || i>255) {
    _exit(1);
  }

  char *p = malloc(2);

  p[0] = i;
  p[1] = 0;

  return p;
}

int64_t size(const char* const s) {
  return strlen(s);
}

const char* substring(const char* const s, size_t first, size_t n) {
  char *substr = malloc(n+1);

  strncpy(substr, s+first, n);
  substr[n] = 0;

  return substr;
}

const char* concat(const char* const s1, const char* const s2) {
  size_t s1_length = strlen(s1);
  size_t s2_length = strlen(s2);
  size_t length = s1_length + s2_length + 1;
  char *s = malloc(length);

  strncpy(s, s1, s1_length);
  strncpy(s, s1+s1_length, s2_length);
  s[length] = 0;

  return s;
}

int64_t not(int64_t i) {
  return i == 0;
}

void exit(int64_t i) {
  _exit(i);
}

int main() {
  tigermain();
}
