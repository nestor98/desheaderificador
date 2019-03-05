X=desheaderificador++

all: $X

$X: lex.yy.cc
	g++ lex.yy.cc -o $X #-Wall -lfl
	
lex.yy.cc: $X.l
	flex++ -+ $X.l
