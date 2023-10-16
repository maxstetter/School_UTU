#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int main(int argc, char **argv)
{
  int i;

  if (argc < 2)
  {
    fprintf(2, "usage: (pages, pid)\n");
    exit(1);
  }

  printf("What's the difference between a Dollar and a Pound? \n");

  for (i = 1; i < argc; i++)
    pages(atoi(argv[i]));
  exit(0);
}