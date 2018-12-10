#pragma once

char *pg_query_nodes_to_json(const void *obj);

void print_pg_parse_tree(List* node);
