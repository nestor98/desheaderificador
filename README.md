# desheaderificador++
Crea la plantilla del .cpp de una clase a partir de su .hpp. \
Deja el comentario inicial, los includes (y añade el de su propio header), y deja las funciones preparadas para implementar.\
No *muy* probado.\
-Compilar con make\
-Ejecutar como _./desheaderificador++ [-v] \<fichero\>.hpp \<fichero\>.cpp _
  
  
  Cambios:\
    10/01/19: Añadido soporte a .hpp con tabulaciones ('\t') además de espacios\
    10/01/19: Añadida cabecera al .l\
    05/03/19: Traducido a c++ con Flex++. Ahora debería funcionar con clases anidadas. \
    06/03/19: Arreglados problemas con metodos que devuelven la propia clase \
    20/06/19: Vuelve a funcionar (al menos con unas pocas pruebas). \
    20/06/19: Añadida opcion -v para dejar todos los comentarios del .h en el .cc
              
Problemas:\
  -Posibles fallos con tipos de datos genéricos, no lo he probado. \
  -Lo mismo con casos raros de herencias, clases anidadas complicadas, 
  cualquier cosa que no conoczca de sintaxis... 
