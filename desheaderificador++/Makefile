X=desheaderificador++

all: $X

$X: lex.yy.cc
	g++ lex.yy.cc -lfl -o $X #-Wall
	
lex.yy.cc: $X.l
	flex++ $X.l
