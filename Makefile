CFLAGS=-I.

all: list.o value.o makefuncs.o keywords.o sql_parser.tab.o sql_parser.yy.o main.o parser.o print_parse_tree.o stringinfo.o
	gcc -g $^ $(CFLAGS) -o a.out
	rm -f $^ 


print_parse_tree.o:
	gcc -c -g util/print_parse_tree.c $(CFLAGS)  -o $@
stringinfo.o:
	gcc -c -g util/stringinfo.c $(CFLAGS)  -o $@
makefuncs.o:
	gcc -c -g nodes/makefuncs.c  $(CFLAGS)  -o $@ 
parser.o:
	gcc -c -g parser/parser.c  $(CFLAGS)  -o $@
list.o:
	gcc -c -g nodes/list.c $(CFLAGS) -o list.o
value.o:
	gcc -c -g nodes/value.c $(CFLAGS) -o value.o
keywords.o:
	gcc -c -g nodes/keywords.c $(CFLAGS) -o keywords.o
sql_parser.tab.o: sql_parser.tab.c
	gcc -c -g sql_parser.tab.c $(CFLAGS) -o sql_parser.tab.o
sql_parser.yy.o: sql_parser.yy.c
	gcc -c -g sql_parser.yy.c $(CFLAGS) -o sql_parser.yy.o
main.o:
	gcc -c -g main.c $(CFLAGS) -o main.o

clean:
	rm -f list.o value.o makefuncs.o keywords.o sql_parser.tab.o sql_parser.yy.o main.o parser.o a.out print_parse_tree.o stringinfo.o
	rm -f sql_parser.yy.c sql_parser.tab.h sql_parser.tab.c


fb:
	bison -d sql_parser.y
	flex -o sql_parser.yy.c sql_parser.l 

