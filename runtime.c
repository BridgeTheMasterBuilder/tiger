#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>

extern int tigermain(void);

intptr_t* init_array(size_t size, intptr_t init, intptr_t elt_is_pointer) {
  intptr_t* a = (intptr_t *) malloc((size+1) * sizeof(intptr_t));

  for(size_t i=1; i<size+1; i++) {
    a[i] = init;
  }

  a[0] = elt_is_pointer;

  return a;
}

intptr_t* alloc_record(const char* const descr) {
  size_t size = strlen(descr) + 1;
  void* record = malloc(size * sizeof(intptr_t ));

  memcpy(record, descr, sizeof (intptr_t));

  return (intptr_t *) record;
}

intptr_t str_cmp(const char* const s1, const char* const s2) {
  return strcmp(s1, s2);
}

void print(const char* const s) {
  fputs(s, stdout);
}

void flush() {
  fflush(stdout);
}

const char* __wrap_getchar() {
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

intptr_t ord(const char* const s) {
  if(strcmp(s, "") == 0) {
    return -1;
  } else {
    return s[0];
  }
}

const char* chr(intptr_t i) {
  if (i<0 || i>255) {
    exit(1);
  }

  char *p = malloc(2);

  p[0] = i;
  p[1] = 0;

  return p;
}

intptr_t size(const char* const s) {
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

intptr_t not(intptr_t i) {
  return i == 0;
}

int main() {
  tigermain();
}
