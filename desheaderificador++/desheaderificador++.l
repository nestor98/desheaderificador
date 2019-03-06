%{
/******************************************************************************************
 * Fichero: desheaderificador++.l                                                         *
 * Autor: Nestor Monzon                                                                   *
 * Coms: Toma como entrada el .hpp de una clase de c++ y genera la plantilla del .cpp     *
 *       Ver README.md para más detalles                                                  *
 ******************************************************************************************/
#include <iostream>
#include <string>
//#include <string.h>
#include <fcntl.h>

using namespace std;

const int MAXNOM = 50; // Max de caracteres del nombre de una clase


string include = "";  // #include del .hpp
int nAmbito = 0;     // nº de clases definidas (más específicamente, ámbito actual: 
                     // 0->fuera de clase, 1->1ª clase, 2-> en la 2ª clase anidada...
string nomClases[MAXNOM];    // Nombres de las clases anidadas (nomClases[0] la mayor, etc.)  HE CAMBIADO ESTO 27/02
// int nAmbito > 0 = 0;     // Valdrá 1 cuando hayamos entrado en clase [MODIFICACION 28/02: Con el añadido
                            // de nAmbito no debería hacer falta
bool cabeceraLeida = false; // Valdra 1 cuando se ha leido un caracter distinto de un comentario

// Gestiona el fin de la cabecera
void finCabecera() {
    if (!cabeceraLeida) {
        cabeceraLeida = true;
        cout << "#include \"" << include << "\"" << endl; 
    }
}



// Devuelve el nombre de la clase contenido en <leido>
string obtenerNomClase (const string leido) {
    int i = 0;
    char car = leido[0];
    while (car != ' ' && car != '\t' && car != '{' && car != '\n' && car != ';' && car != '\0') {
        i++;
        car = leido[i];
    }
    return leido.substr(0, i); // Cortamos la cadena al final del nombre de la clase
}


// Devuelve el prefijo necesario según nAmbito: (como "Clase::Subclase1::")
string construirAmbito(const string nomClases[], const int nAmbito) {
    string ambito = nomClases[0] + "::";
    //cerr << "ambito : " << ambito << endl;
    for (int i = 1; i < nAmbito; i++) {
        ambito += nomClases[i] + "::";
    }
    return ambito;

/*  //////mecagoenc///// Version de C que *ni funcionaba* //////mecagoenc/////
    char* copia = strdup(nomClases[0]);
    *ambitoFin = "";
    int i;
    for (i = 0; i < nAmbito; i++) {
        strcat(*ambitoFin, nomClases[i]);
    }
    //strcat(*ambitoFin, copia);
    //*ambitoFin = strdup(copia);
    
    // Problemas aqui y en descomponerFuncion char* final[]
    
    ///////////////////////mecagoenc///////////////////////////////7
*/       
}


// Devuelve true sii la funcion en <orig> no es constructor ni destructor: hay un caracter distinto en 
// los strlen(nombreClase) primeros caracteres
bool noEsConstructorDestructor(const string orig, const string nomClase) {
    int i = 0;
    bool diferentes = false;
    int distancia = 0;
    
    if (orig[0] == '~') { // Destructor
        distancia++;
     } 
    while (i<nomClase.length() && !diferentes && i+distancia<orig.length()) {
        // Comparamos los primeros caracteres con el nomClase
        diferentes = (orig[i+distancia] != nomClase[i]);
        // Si alguno es distinto, no es constructor o destructor
        i++;
    }
    if (!diferentes) { // Caso especial: funciones que devuelven la propia clase
        while (i<orig.length() && orig[i+distancia] != '(') { // Avanzamos hasta el '('
            // Tampoco es constructor o dest si hay un caracter distinto de espacios
            diferentes = (orig[i+distancia] != ' ') || (orig[i+distancia] != '\t'); 
            i++;
        } // Avanzamos espacios
    }
    return diferentes;
}


// Devuelve la cadena de la funcion en <orig> con el formato de las cabeceras de un .cpp
// (especificando el ambito apropiado segun ambitos[] y nAmbito)
string descomponerFuncion (const string orig, const string ambitos[], const int nAmbito) {
    int numEspacios = 0;
    while (orig[numEspacios] == ' ' || orig[numEspacios] == '\t') {
        numEspacios++;   
    }
    // Le quitamos los espacios y tabulaciones del principio 
    // (tb podria arreglar la @#$! ER, pero cuesta mas)
    string original = orig.substr(numEspacios); // orig sin espacios iniciales
    string tipo = ""; // tipo de la funcion (int, void...)
    // Si nAmbito == 0, no es un constructor
    if (nAmbito == 0 || noEsConstructorDestructor(original, ambitos[nAmbito-1])) {
        // Solo si no es constructor o destructor...
        int posEsp = original.find(" "); // Posicion del 1er espacio
        tipo = original.substr(0, posEsp+1); // substr hasta " " (incluido)
        original = original.substr(posEsp+1); // original sin el tipo
    }
    string sfinal = tipo + construirAmbito(nomClases, nAmbito); // Ej: "int Tupla::"
    //sfinal += original.substr(original.length()-1); 
    // Añadimos el resto de la funcion, sin el ultimo ";" (ultimo caracter -> length-1)
    return sfinal + original.substr(0, original.length()-1) + " {\n    \n}\n";
}


/******************************* Fin funciones c++ ***********************************/
%}

%option c++ noyywrap


%x comLinea
%x comParrafo
%x clase
%x funciones

espacios  [ \t]*
variable  [a-zA-Z][a-zA-z0-9_,.="*":<>&\[\] ]*
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
<comLinea>[\n]+	  { if (!cabeceraLeida) cout << endl;
                    if(nAmbito > 0){
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
<comParrafo>"*"+"/"         {
                                if(nAmbito > 0){
                                    BEGIN(funciones); // Añade 1 al contador de coms y finaliza el com.
                                }
                                else{
                                    if (!cabeceraLeida) {
                                        ECHO;
                                    }
                                    BEGIN(INITIAL);
                                }
                            }

class[ ]+                       BEGIN(clase); nAmbito++; finCabecera();

<clase>{variable}[ \t\n]*       {
                                nomClases[nAmbito-1] = obtenerNomClase(yytext);
                                }
<clase>"{"[ \t]*\n+         BEGIN(funciones); cout << endl;

<funciones>class[ ]+           BEGIN(clase); nAmbito++; finCabecera();

<funciones>"private:"           ; // Ignoramos private
<funciones>"public:"           { ; // Ignoramos public
                                    }

<funciones>"/*"     BEGIN(comParrafo);
<funciones>"//"		      BEGIN (comLinea);
"//"		      BEGIN (comLinea); if (!cabeceraLeida) ECHO;




<funciones>[ \t]+                      // Se come espacios...

[ \t]+                      cout << " ";// Comprime espacios...
<funciones>{funcion}        {
                            cout << descomponerFuncion(string(yytext), nomClases, nAmbito) << endl;
                            
                            }
                            
{variable};                       
<funciones>{variable};                 // Nos las comemos tambien supongo


<funciones>"};"           {
                            if(--nAmbito == 0){ // Decrementamos un ámbito
                                // Y si estamos en el 0, volvemos al modo inicial
                                BEGIN(INITIAL);
                            }
                            else {
                                //Si no, al modo "clase" (aún estamos en una)
                                BEGIN(funciones); 
                            }
                           }
<funciones>[\n]+           //cout << endl;
[\n]+	                   cout << "\n";
[^/\n]                     ECHO;

%%


int main(int argc, char* argv[]) {

    if (argc<3) {
        cerr << "Invocar como: \n " << argv[0] << " <fichero.hpp> <fichero.cpp>\n";
    }
    else {
        int fd[2];
        close(0);
        if ( (fd[0] = open(argv[1], O_RDONLY)) == -1) {
            cerr << "Error al abrir el .hpp\n";
            exit(1);
        }
        if (fd[0] != 0) {
            cerr << "Entrada no redireccionada correctamente\n";
            exit(1);
        }
        if ( (fd[1] = creat(argv[2], 0640)) == -1) {
            cerr << "Error al crear el .cpp\n";
            exit(1);
        }
        close(fd[1]);
        close(1);
        if( (fd[1] = open(argv[2], O_WRONLY)) != 1) {
            cerr << "Salida no redireccionada\n";
            exit(1);
        }
        
        include = string(argv[1]); // include el .hpp al principio
        
        // Cosas de Flex++:
        FlexLexer* lexer = new yyFlexLexer;
        while (lexer -> yylex() != 0);
        
        
    	cerr << "Todo correcto, " << argv[2] << " creado\n";
    }
    return 0;
}
