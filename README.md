# desheaderificador
Crea la plantilla del .cpp de una clase a partir de su .hpp. 
Deja el comentario inicial, los includes (y añade el de su propio header), y deja las funciones preparadas para implementar.
No *muy* probado.
-Compilar con make
-Ejecutar como ./desheaderificador \<fichero\>.hpp \<fichero\>.cpp
  
  
  Cambios:
    10/01/19: Añadido soporte a .hpp con tabulaciones ('\t') además de espacios
    10/01/19: Añadida cabecera al .l

Problemas:
  -No funciona con clases anidadas!
