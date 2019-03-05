X=desheaderificador

all: $X

$X: lex.yy.c
	gcc lex.yy.c -lfl -o $X #-Wall
lex.yy.c: $X.l
	flex $X.l
