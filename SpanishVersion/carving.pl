#!/usr/bin/perl

# Copyright (C) 2013, Juan C. Rodríguez Cruces
# This file is part of Dissection Forensic Toolkit (DFT).

# DFT is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# DFT is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with DFT.  If not, see <http://www.gnu.org/licenses/>.

my $dact = `pwd`;
chomp $dact;

# Subrutinas secundarias #
### Parsear
#  Modo de uso: &parsearimg("imgparseadasdd"); # Pero hay que ir al directorio donde estan las img a parsear
#		&parsearimg("imgparseadascarving"); # Idem arriba
#  Resultado:
#	- Una nueva carpeta con las fotografias en tamaño 500x375

sub parsearimg # El primer argumento es $_[0] que contendra la ruta a crear, que sera lanzado dos veces, una será imgparseadasdd y otra imgparseadascarving  
{
	### cambiar tamaño de acuerdo a preferencia  ###
	my $PictSize="500x375"; # recomendados: 500x375, 640x480, 640, 500	
	# nuevo directorio de imagenes
	my $imgdir = $_[0];
	my $PictType = "jpg|jpeg|png|gif|tiff|tif|art|bmp|JPG|JPEG|PNG|GIF|TIFF|TIF|ART|BMP";
	my @files =  < *>;

	$i = 0;
	foreach my $pict (@files) {
	   my $imgsdir = "$imgdir\/".$pict;
	   my $nameFile = (split /\./, $imgsdir)[0]; #sacamos la ruta y el nombre de archivo /blau/.jpg	
	   if ($nameFile =~ / /){ next; } # Si tiene espacios nos lo saltamos, porque sino se queda pillado
	   my $extFile = (split /\./, $pict)[-1]; #conseguimos la extensión del archivo
	   if ($extFile =~ /$PictType/ ) { #Es una imagen
		system("convert -resize $PictSize $pict $nameFile.\"jpg\" 2>/dev/null"); #convertimos a jpg
		$i=$i+1;
	   }
	}
        
	 print "Se han parseado $i imagenes en $imgdir.\n";
}


#Compara argumento 1 con argumento 2 y borra el argumento 1 si son iguales.
sub comparar{
	$fich1 = $_[0];
	$fich2 = $_[1];
	my $valor = `diff $fich1 $fich2 | wc -l`; # cuenta las lineas de fichero que salen al diferenciar ambos
	if ($valor==0){
		# Los ficheros 1 y 2 son iguales
		system("rm $fich1");
		# borrar si no funca
		return 1;
		# borrar si no funca
	} else {
		# Los ficheros 1 y 2 son distintos
		# borrar si no funca
		return 0;
		# borrar si no funca	
	} 
}

sub diffear # El primer argumento es $_[0] que contendra la ruta a del dd a comparar con los del argumento segundo $_[1] para borrar del primer argumento los que este en el segundo  
{
	chdir($_[0]);
	my @filescarving =  < *>; #Cogemos los del carving
	chdir($_[1]);
	my @filesdd = < *>; #Cogemos los del dd
	#$i = 0; #Ficheros que habian iguales y han sido borrados
	#$j = 0; #Ficheros distintos
	foreach my $filecarving (@filescarving) {
		#Por cada fichero de carving, comprobamos todos los del dd
		foreach my $filedd (@filesdd) {
			eval { $auxcarving = $_[0].$filecarving };
			#Asi conseguimos la ruta completa, el otro no es necesario por el chdir			
			$s = &comparar($auxcarving,$filedd);
			if ($s == 1) { $s = 0; goto SALTAFICHBORRADO; }
		}
		SALTAFICHBORRADO:
	}
        
	#print "Hay $i ficheros iguales que ahora han sido eliminados.\n";
	#print "Hay $j ficheros diferentes.\n";
}

##################
# Prog Principal #
##################

#Cogemos argumento
if ( $#ARGV == 1 ) { # El ultimo indice es 1, por lo tanto hay dos elementos
	# Solo necesitamos un argumento
	$direccionsalida = $ARGV[0];
	$firma = $ARGV[1];
} else {
	die "Error, se necesita un argumento con la direccion de salida y otro con el tipo de firma realizada\n";
}


# Comenzamos el carving
eval { $destinodd = $direccionsalida."/Imagen/"."imagen.dd" };
eval { $destinomd5 = $destinodd.".txt" };	
eval { $destinosha1 = $destinodd.".sig" };
eval { $dircarving = $direccionsalida."/Carving/" };
system("mkdir $dircarving"); # Creamos la carpeta Carving
		
# Realizamos el carving con foremost
#system("foremost -v -c /etc/foremost.conf -o $dircarving -i $destinodd");
system("foremost -vd -t ole,jpg,png,bmp -o $dircarving -i $destinodd");


# Montamos la imagen
system("sudo mkdir /mnt/imagen"); #Creamos la carpeta en la cual montaremos la imagen
system("sudo mount -t auto -o loop,ro $destinodd /mnt/imagen"); 
# Ahora esta montada la imagen en /mnt/imagen

## PASO 1.1: Sacar imagenes de la unidad /mnt/imagen y del carving
eval { $dirjpgdd = $direccionsalida."/jpgdd/" };
eval { $dirjpgcarving = $direccionsalida."/jpgcarving/" };
# No hace falta que se eliminen anteriores ya que después se borrarán
system("mkdir $dirjpgdd"); #creado dir jpgdd
system("mkdir $dirjpgcarving"); #creado dir jpgcarving

# Copiamos todas las imagenes del dd y la ponemos en $dirjpgdd			
system("sudo find /mnt/imagen -name \"*.png\" -o -name \"*.jpg\" -o -name \"*.jpeg\" -o -name \"*.bmp\" -o -name \"*.gif\" -o -name \"*.tiff\" -o -name \"*.tif\" -o -name \"*.art\" -o -name \"*.bmp\" -o -name \"*.PNG\" -o -name \"*.JPG\" -o -name \"*.JPEG\" -o -name \"*.BMP\" -o -name \"*.GIF\" -o -name \"*.TIFF\" -o -name \"*.TIF\" -o -name \"*.ART\" -o -name \"*.BMP\"| xargs -I {} cp {} $dirjpgdd");
#copiamos todas las imagenes del carving y la ponemos en $dirjpgcarving
system("sudo find $dircarving -name \"*.png\" -o -name \"*.jpg\" -o -name \"*.jpeg\" -o -name \"*.bmp\" -o -name \"*.gif\" -o -name \"*.tiff\" -o -name \"*.tif\" -o -name \"*.art\" -o -name \"*.bmp\"| xargs -I {} cp {} $dirjpgcarving");

## Una vez recolectados los documentos, comenzamos a parsearlos
print "Realizando la conversión de ficheros...\n";

## PASO 2.1: Parsear imagenes de las sacadas de la unidad /mnt/imagen y del carving
chdir($dirjpgdd) or die "No se puede cambiar al directorio $dirjpgdd.\n";
eval { $dirimgparseadascarving = $dirjpgcarving."imgparseadascarving/"};
eval { $dirimgparseadasdd = $dirjpgdd."imgparseadasdd/"};
system("mkdir $dirimgparseadasdd");
&parsearimg($dirimgparseadasdd);
chdir($dirjpgcarving) or die "No se puede cambiar al directorio $dirjpgcarving.\n";
system("mkdir $dirimgparseadascarving");
&parsearimg($dirimgparseadascarving);

print "Realizando la comparación de ficheros...\n";

# PASO 3.1 DIFF de *.jpg
&diffear($dirimgparseadascarving,$dirimgparseadasdd); #Nos deja en carving las imagenes que no existen en dd

print "Realizando el firmado de los ficheros...\n";

# PASO 4 Firmamos todos los ficheros finales
if ($firma == "md5") { 
	chdir($dirimgparseadascarving) or die "No se puede cambiar al directorio $dirimgparseadascarving\n";
	my @files =  < *>;
	foreach my $file (@files) {
		system("md5sum $file > $file.txt");
	}	
} elsif ($firma == "sha1") { 
	chdir($dirimgparseadascarving) or die "No se puede cambiar al directorio $dirimgparseadascarving\n";
	my @files =  < *>;
	foreach my $file (@files) {
		system("sha1sum $file > $file.txt");
	}	

} 


print "Eliminando ficheros...\n";

# PASO 5 Eliminar todas las cosas innecesarias y dejar las parseadas del dd unica y exclusivamente
#Cosas Importantes (para copiarlas en el directorio raiz $destino):
system("mv $dirimgparseadascarving $direccionsalida"); # movemos carpeta de $dirimgparseadascarving
#Cosas a eliminar (del directorio raiz $destino):
system("sudo rm -r $dircarving"); 	# borramos carpeta de carving
system("sudo rm -r $dirjpgdd");	  	# borramos carpeta de jpgdd
system("sudo rm -r $dirjpgcarving"); 	# borramos carpeta de jpgcarving

# Ahora desmontamos y eliminamos la unidad /mnt/imagen que usamos para montar el dd
system("sudo umount /mnt/imagen");
system("sudo rmdir /mnt/imagen"); 

