%{
#include <stdio.h>
#include <string.h>
#include <fcntl.h>

char* include = "";
char* nomClase = "";
int enClase = 0; // Valdrá 1 cuando hayamos entrado en clase
int cabeceraLeida = 0; // Valdra 1 cuando se ha leido un caracter distinto de un comentario


void finCabecera() {
    if (!cabeceraLeida) {
        cabeceraLeida = 1;
        printf("#include \"%s\"\n", include);
    }
}


void obtenerNomClase (char* leido) {
    int i = 0;
    char car = leido[0];
    while (car != ' ' && car != '\t' && car != '{' && car != '\n' && car != ';' && car != '\0') {
        i++;
        car = leido[i];
    }
    leido[i] = '\0'; // Cortamos la cadena al final del nombre de la clase
}

//Devuelve 1 sii no es constructor ni destructor: hay un caracter distinto en los strlen(nombreClase) caracteres
int noEsConstructorDestructor(const char* orig, const char* nomClase) {
    int i = 0;
    int diferentes = 0;
    int distancia = 0;
    
    if (orig[0] == '~') { // Destructor
        distancia++;
     } 
    while (i<strlen(nomClase) && !diferentes && i+distancia<strlen(orig)) {
        diferentes = (orig[i+distancia] != nomClase[i]);
        i++;
    }
    
    return diferentes;
}



//strncmp(copia+numEspacios, nomClase, strlen(nomClase))!=0 || strncmp(copia+numEspacios+1, nomClase, strlen(nomClase))!=0
void descomponerFuncion (const char* orig, const char* nomClase, char** final) {
    int numEspacios = 0;
    while (orig[numEspacios] == ' ') {
        numEspacios++;   
    }
    // Le quitamos los espacios del principio (tb podria arreglar la @#$! ER, pero cuesta mas)
    char* copia = strdup(orig)+numEspacios;
    char* mismoNomClase = strdup(nomClase);
    char* token = "";
    if (noEsConstructorDestructor(copia, mismoNomClase)) {
        // Solo si no es constructor o destructor...
        if ((token = strtok(copia, " ")) != NULL) { // Toma el tipo de la funcion (char, int)...
           strcat(token, " ");   // Con " " al final...
        }

        copia = strdup(orig)+numEspacios+strlen(copia);
    }
    *final = strdup(token);
    strcat(*final, nomClase); // Le concatena el nombre de la clase
    strcat(*final, "::");       // Y "::"
    if ((token = strtok(copia, ";")) != NULL){       // Cortamos el resto de la funcion hasta ";"
        strcat(*final, token);    // Y lo concatenamos
    }
    
}


%}

%x comLinea
%x comParrafo
%x clase
%x funciones

espacios  [ \t]*
variable  [a-zA-Z][a-zA-z0-9_,.="*" ]*
using     ["using "]{variable}
funcion   [a-zA-Z~ ][a-zA-z0-9_,]*{espacios}{variable}{espacios}"("[^)\n]*")"{espacios}"const"?;

%%
    

"#ifndef"		  BEGIN (comLinea); finCabecera(); // Ignoro #defines y tal
"#define"		  BEGIN (comLinea); finCabecera();
"#endif"		  BEGIN (comLinea); finCabecera();
{using};          ECHO; finCabecera();
<comLinea>.*      {if (!cabeceraLeida) {// Ignora el comentario, excepto si es la cabecera
                        ECHO;   
                    }
                  }
<comLinea>[\n]+	  { if (!cabeceraLeida) printf("\n");
                    if(enClase){
                        BEGIN(funciones); // Añade 1 al contador de coms y finaliza el com.
                    }
                    else{
                        BEGIN(INITIAL);
                    }
                   }
"/*"		                BEGIN (comParrafo); if (!cabeceraLeida) ECHO;

<comParrafo>[^*]*           {if (!cabeceraLeida) {// Ignora el comentario, excepto si es la cabecera
                                ECHO;   
                              }
                            }
<comParrafo>"*"+[^*/\n]*    {if (!cabeceraLeida) {// Ignora los * no seguidos de / , excepto si es la cabecera
                                ECHO;
                              }
                            }
<comParrafo>"*"+"/"         {if(enClase){
                                BEGIN(funciones); // Añade 1 al contador de coms y finaliza el com.
                            }
                            else{
                                BEGIN(INITIAL);
                            }
                           }

class[ ]+                   BEGIN(clase); enClase=1; finCabecera();
<clase>{variable}[ \t\n]*  {nomClase = strdup(yytext);
                                       obtenerNomClase(nomClase);}
<clase>"{"[ \t]*\n+         BEGIN(funciones); printf("\n");              

<funciones>"private:"           ; // Ignoramos private
<funciones>"public:"           { ; // Ignoramos public
                                    }

<funciones>"/*"     BEGIN(comParrafo);
<funciones>"//"		      BEGIN (comLinea);
"//"		      BEGIN (comLinea); if (!cabeceraLeida) ECHO;




<funciones>[ \t]+                      // Se come espacios...

[ \t]+                      printf(" ");// Comprime espacios...
<funciones>{funcion}        {char* transformada = "";
                            descomponerFuncion(yytext, nomClase, &transformada);
                            printf("\n%s {\n    \n}\n", transformada);}
                            
{variable};                       
<funciones>{variable};                 // Nos las comemos tambien supongo


<funciones>"};"           BEGIN(INITIAL); enClase=0;

<funciones>[\n]+           //printf("\n");
[\n]+	                   printf("\n");
[^/\n]                     ECHO;

%%

int main(int argc, char* argv[]) {

    if (argc<3) {
        printf("Invocar como: \n%s <fichero.hpp> <fichero.cpp>\n(sin <>)", argv[0]);
    }
    else {
        int fd[2];
        close(0);
        if ( (fd[0] = open(argv[1], O_RDONLY)) == -1) {
            printf("Error al abrir el .hpp\n");
            exit(1);
        }
        if (fd[0] == 0) {
            fprintf(stderr, "Entrada redireccionada\n");
        }
        if ( (fd[1] = creat(argv[2], 0640)) == -1) {
            printf("Error en creat\n");
            exit(1);
        }
        close(fd[1]);
        close(1);
        if( (fd[1] = open(argv[2], O_WRONLY)) == 1) {
            fprintf(stderr, "Salida redireccionada\n");
        }
        include = strdup(argv[1]); // include el .hpp al principio
    	yylex();
    }
    return 0;
}
