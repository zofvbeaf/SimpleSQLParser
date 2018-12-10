#include "parser/parser.h"
#include "nodes/list.h" 
#include "util/print_parse_tree.h"
#include <stdio.h>
#include <stdlib.h>

int main(int argc, char** argv) {
  char *tpchsql[23];
  char *tpcdssql[100];
  int id = argc > 1 ? atoi(argv[1]) : 0;

#include "tpchsql.c"
#include "tpcdssql.c"

  printf("%s\n", tpchsql[id]); //default test tpchsql
 
  List *result = raw_parser(tpchsql[id]);
  if(result) {
    printf("SUCCESSFUL!\n");
    print_pg_parse_tree(result);
  }
  else 
    printf("FAILED!\n");
  return 0;
 
}

