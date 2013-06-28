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

use strict; 
use Gtk2 -init;
use Gtk2::GladeXML;
		
my ($direccionsalida,$direccionimagenes,$diferencia,$auxfich,$text,$imagenactual,$auxpdf,$ev,$diferencia);

## Argumentos ##
if ( $#ARGV == 0 ) { # El ultimo indice es 0, por lo tanto hay un elemento
	# Solo necesitamos un argumento
	$direccionsalida = $ARGV[0];
} else {
	die "Error, an argument is needed\n";
}

my $dact = `pwd`;
chomp $dact;

my($programa,$ventana_principal,$boton_anterior,$boton_siguiente,$imagen1,$imagen2, $imagen3, $imagen4,$i,$j,$maxarray,$imagenvacia,$dir1,$dir2,$dir3,$dir4,@total,$img1vacia,$img2vacia,$img3vacia,$img4vacia,%hash,$imgact,$visto,$linea,$label1,$label2,$label3,$label4,$check1,$check2,$check3,$check4,$label,%evidencia,$fichevidencia,$fichvisto,$fichi,$clave,$valor,$status,$totalimagenes,$vistas,$evidencias,@aux,@tokenizer); ### Declaro las variables que usaré en el programa

$programa = Gtk2::GladeXML->new('visorimagenes_en.glade'); #Le estoy indicando la ruta (ubicación) donde se encuentra el XML generado por Glade, del cual Gtk2::GladeXML analizará y extraerá

$ventana_principal = $programa->get_widget('ventana_principal'); ### Ahora estoy cargando la ventana principal al hacer esto esto se crea un objeto "ventana_principal" el cual nos permite interactuar con la ventana mediante métodos ya predefinidos.

## Preparamos la ventana
$ventana_principal->set_border_width( 4 );
$ventana_principal->set_default_size( 800, 600 );
$ventana_principal->signal_connect( destroy => \&salir );
$ventana_principal->set_title('Dissection :: Image Viewer');
$ventana_principal->maximize;
##

$boton_siguiente = $programa->get_widget('button2'); ### Creo el objeto "$boton_cerrar" (haciendo referencia al 
$boton_anterior  = $programa->get_widget('button1'); #botón creado en glade) para así tener métodos predefinidos que me permitan trabajar he interactuar con el botón. 
$boton_siguiente->set_label("_Next");
$boton_anterior->set_label("_Previous");

#Referenciamos widget de imagenes
$imagen1 = $programa->get_widget('image1'); #Referenciamos a $imagen1 el widget image1
$imagen2 = $programa->get_widget('image2'); 
$imagen3 = $programa->get_widget('image3');
$imagen4 = $programa->get_widget('image4');

#Referenciamos widget de labels
$label1 = $programa->get_widget('label1');
$label2 = $programa->get_widget('label2');
$label3 = $programa->get_widget('label3');
$label4 = $programa->get_widget('label4');

#Referenciamos widget de checks
$check1 = $programa->get_widget('checkbutton1');
$check2 = $programa->get_widget('checkbutton2');
$check3 = $programa->get_widget('checkbutton3');
$check4 = $programa->get_widget('checkbutton4');

#Referenciamos status
$status = $programa->get_widget('statusbar1');

#########Preparamos para leer todos los datos de las imagenes que vamos a ver mostrar
eval { $imagenvacia= $dact."/empty.jpg" };
eval { $direccionimagenes = $direccionsalida."/imgparseadascarving/" };
eval { $ev = $direccionimagenes."evidencia.txt" };

my $generar;
if (-e $ev){
	$generar=1;
} else {
	$generar=0;
}

chdir($direccionimagenes);
my @total = `ls *.jpg`;
$maxarray=@total-1;
$totalimagenes=@total;
#####################################################

#Retomamos valores iniciales
chdir($direccionimagenes);
$fichvisto=">visto.txt"; #Lo dejamos como overwrite, leeremos con cat
$fichevidencia=">evidencia.txt"; #Lo dejamos como overwrite
$fichi="i.txt";
if (-e $fichi) {
   #Existe, asi que cogemos el valor que tenia
   $i = `cat i.txt`; #cuando hacemos el carving hay que guardar este fichero con un 0
   if ($i>=$maxarray){
	#Ya hemos visto todos
	#&anterior;
   }
   
}  else {
   #Como no existe, le ponemos un 0
   #creamos el fchero i.txt con un valor aleatorio, ya que luego se sobreescribira
   system("ls > i.txt");
   $i=0;
}

#Inicializamos barra de estado
$status->push( $status->get_context_id( 'statusbar1' ), "Pictures seen: $i / $totalimagenes." );

if ($i==0){ 
	# Es la primera vez que abrimos el visor
	
	#Inicializamos a todas las imagenes como no vistas
	foreach $linea (@total) {
		$imgact = $linea;
		chop $imgact;
		$hash{$imgact}="No visto";
	}

	#Inicializamos todas las imagenes como que no son evidencias, utilizamos hash para poder acceder a activar y desactivar evidencias fácilmente
	foreach $linea (@total) {
		$imgact = $linea;
		chop $imgact;
		$evidencia{$imgact}=0; #1 = evidencia, podremos comprobarlo con if ($evidencia{img})
	}

	
} else {
	#No es la primera vez, recuperamos datos
	#Recuperamos los datos de evidencia
	open FICHEVIDENCIA, "evidencia.txt" or die "Can't access to evidencia.txt";
	@aux = <FICHEVIDENCIA>;
	foreach $linea (@aux){
		@tokenizer = split(",",$linea); #$tokenizer[0] = clave, #tokenizer[1]=valor\n
		chop $tokenizer[1];
		if (($tokenizer[0] ne "")&&($tokenizer[0] ne $imagenvacia)) { 
			$evidencia{$tokenizer[0]}=$tokenizer[1];
		}
	}
	close(FICHEVIDENCIA);
	
	#Recuperamos los datos de vistos
	open FICHEVISTO, "visto.txt" or die "Can't acces to visto.txt";
	@aux = <FICHEVISTO>;
	foreach $linea (@aux){
		@tokenizer = split(",",$linea); #$tokenizer[0] = clave, #tokenizer[1]=valor\n
		chop $tokenizer[1];
		$hash{$tokenizer[0]}=$tokenizer[1];
	}
	close(FICHVISTO);
	
	$i=$i-4;
	#leer imgvacias :)
}


$boton_siguiente->signal_connect(clicked => \&siguiente); ### Estoy asignándole al objeto "$boton_siguiente" (al botón) la señal "clicked" que a su vez hace referencia a una subrutina. Así, una vez presionado el botón se ejecutará la subrutina "&siguiente"

$boton_anterior->signal_connect(clicked => \&anterior); ##Asignamos $

$programa->signal_autoconnect_from_package('main'); # Esta subrutina llamada salir sólo se va a ejecutar si sucede el evento que le asignamos al botón

  
$ventana_principal->show_all(); #por defecto (depende de la versión del módulo Gtk2::GladeXML tengas) no se muestra la ventana, se carga más mas no se muestra Con el método show_all() hacemos que sea visible para el usuario
if ($i==0){
 &siguiente; # hacemos la primera iteración
} else {
 &anterior;
}

Gtk2->main;

sub siguiente {
	#print "Traza: Al entrar en siguiente, i=$i\n";

	#Ponemos a los anteriores como visto:
	if ($img1vacia==0) {	$hash{$dir1} = "Visto"; }
	if ($img2vacia==0) {	$hash{$dir2} = "Visto"; }
	if ($img3vacia==0) {	$hash{$dir3} = "Visto"; }
	if ($img4vacia==0) {	$hash{$dir4} = "Visto";	}
	
	#Ponemos como evidencias los que hayan sido marcado como tales:
	if ($check1->get_active) { #Esta pulsado
		#Es una evidencia
		if ($img1vacia==0) { $evidencia{$dir1}=1; }
	} else { 
		#No es una evidencia
		if ($img1vacia==0) { $evidencia{$dir1}=0; }
	}
	if ($check2->get_active) { 
		if ($img2vacia==0) { $evidencia{$dir2}=1; }
	} else {
		if ($img2vacia==0) { $evidencia{$dir2}=0; }
	}
	if ($check3->get_active) {
		if ($img3vacia==0) { $evidencia{$dir3}=1; }
	} else {
		if ($img3vacia==0) { $evidencia{$dir3}=0; }
	}
	if ($check4->get_active) {
		if ($img4vacia==0) { $evidencia{$dir4}=1; }
	} else {
		if ($img4vacia==0) { $evidencia{$dir4}=0; }
	}
	
	#Modificamos la barra de estado
	$vistas=0;
	while (($clave,$valor) = each(%hash)) { 
		if ($valor =~ /Visto/){
			if (($clave ne "")&&($clave ne $imagenvacia)) { 
				$vistas=$vistas+1; 
			} #calculamos las imagenes vistas que hay que no sean vacias
		}
	}
	$evidencias=0;
	while (($clave,$valor) = each(%evidencia)) {
		if ($valor==1){
			$evidencias=$evidencias+1;
		}
	}
	$status->push( $status->get_context_id( 'statusbar1' ), "Seen: $vistas / $totalimagenes \t Checked as evidences: $evidencias." );	

	if ($i<=$maxarray){
		if ($i<=$maxarray) {
			#Nueva foto
			$dir1=$total[$i];
			chop $dir1;
			$img1vacia=0;
			#Comprobamos si ha sido vista o no la nueva foto
			$visto = $hash{$dir1};
			eval { $label = $dir1." - ".$visto};
			$label1->set_text($label); #Mostramos nombre fichero y si ha sido o no vista
			#Ponemos activa si ha sido evidencia anteriormente (porque ya haya sido vista)
			if ($evidencia{$dir1}) { 
				#Ha sido marcada como evidencia, asi que dejamos activo
				$check1->set_active(1);
			} else {
				$check1->set_active(0);			
			}
			$i=$i+1;
		} else {
			$dir1=$imagenvacia; #sacamos una pantallita, diciendo de que no hay más :P
			$img1vacia=1;
			$check1->set_active(0);
			$label1->set_text("Imagen vacia");
		}
		# modificamos  la imagen con la dir1
		$imagen1->set_from_pixbuf(Gtk2::Gdk::Pixbuf->new_from_file($dir1));

		if ($i<=$maxarray) {
			$dir2=$total[$i];
			chop $dir2;
			$img2vacia=0;
			#Modificamos como vista
			$visto = $hash{$dir2};
			eval { $label = $dir2." - ".$visto};
			$label2->set_text($label);
			if ($evidencia{$dir2}) { 
				#Ha sido marcada como evidencia, asi que dejamos activo
				$check2->set_active(1);
			} else {
				$check2->set_active(0);			
			}
			$i=$i+1;
		} else {
			$dir2=$imagenvacia;
			$img2vacia=1;
			$check2->set_active(0);
			$label2->set_text("Imagen vacia");
		}
		# modificamos  la imagen con la dir2
		$imagen2->set_from_pixbuf(Gtk2::Gdk::Pixbuf->new_from_file($dir2));
	
		if ($i<=$maxarray) {
			$dir3=$total[$i];
			chop $dir3;
			$img3vacia=0;
			#Modificamos como vista
			$visto = $hash{$dir3};
			eval { $label = $dir3." - ".$visto};
			$label3->set_text($label);
			if ($evidencia{$dir3}) { 
				#Ha sido marcada como evidencia, asi que dejamos activo
				$check3->set_active(1);
			} else {
				$check3->set_active(0);
			}			
			$i=$i+1;
		} else {
			$dir3=$imagenvacia;
			$img3vacia=1;
			$check3->set_active(0);
			$label3->set_text("Imagen vacia");
		}
		# modificamos  la imagen con la dir3
		$imagen3->set_from_pixbuf(Gtk2::Gdk::Pixbuf->new_from_file($dir3));

		if ($i<=$maxarray) {
			$dir4=$total[$i];
			chop $dir4;
			$img4vacia=0;
			#Modificamos como vista
			$visto = $hash{$dir4};
			eval { $label = $dir4." - ".$visto};
			$label4->set_text($label);
			if ($evidencia{$dir4}) { 
				#Ha sido marcada como evidencia, asi que dejamos activo
				$check4->set_active(1);
			} else {
				$check4->set_active(0);
			}
			$i=$i+1; #Lo dejamos para la siguiente
		} else {
			$dir4=$imagenvacia;
			$img4vacia=1;
			$check4->set_active(0);
			$label4->set_text("Imagen vacia");
		}
		# modificamos  la imagen con la dir4
		$imagen4->set_from_pixbuf(Gtk2::Gdk::Pixbuf->new_from_file($dir4));
	} else { # Estamos al final dlfichero¿?
				#Modificamos el label1
		$visto = $hash{$dir1};
		eval { $label = $dir1." - ".$visto};
		$label1->set_text($label);
		#Modificamos el label2
		$visto = $hash{$dir2};
		eval { $label = $dir2." - ".$visto};
		$label2->set_text($label);
		#Modificamos el label3
		$visto = $hash{$dir3};
		eval { $label = $dir3." - ".$visto};
		$label3->set_text($label);
		#Modificamos el label4
		$visto = $hash{$dir4};
		eval { $label = $dir4." - ".$visto};
		$label4->set_text($label);
		#No hacemos nada o mostramos ventana de: No hay más imagenes detrás

	}
	#Guardamos ficheros ahora por si no se vuelve a pulsar los botones	
	#Salvaguardamos el hash de evidencia
	open(FICHEVIDENCIA, $fichevidencia) or die "Can't access to $fichevidencia.\n";
	while (($clave, $valor) = each(%evidencia))
	{
		if (($clave ne "")&&($clave ne $imagenvacia)) {
        		print FICHEVIDENCIA "$clave,$valor\n"; #Los guardamos como imagen,1 o imagen,0
		}					#Luego tokenizaremos con el caracter ','
	}
	close(FICHEVIDENCIA);

	#Salvaguardamos el hash de visto
	open(FICHVISTO, $fichvisto) or die "Can't access to $fichvisto.\n";
	while (($clave, $valor) = each(%hash))
	{
		if (($clave ne "")&&($clave ne $imagenvacia)) {
        		print FICHVISTO "$clave,$valor\n"; #Los guardamos como imagen,visto o imagen,no visto
		}					#Luego tokenizaremos con el caracter ','
	}
	close(FICHVISTO);

	#Salvaguardamos el valor de i
	open(FICHI, ">i.txt") or die "Can't access to $fichi.\n";
	print FICHI "$i"; #Solo guardamos la i
	close(FICHI);
	
	# print "Traza: Al salir de siguiente, i=$i\n";
	
} # Esta subrutina llamada salir sólo se va a ejecutar si sucede el evento que le asignamos al botón

sub anterior {

	# print "Traza: Al entrar en anterior, i=$i\n";
	#Ponemos a los anteriores como visto:
	if ($img1vacia==0) {	$hash{$dir1} = "Visto"; }
	if ($img2vacia==0) {	$hash{$dir2} = "Visto"; }
	if ($img3vacia==0) {	$hash{$dir3} = "Visto"; }
	if ($img4vacia==0) {	$hash{$dir4} = "Visto";	}
	
	#Ponemos como evidencias los que hayan sido marcado como tales:
	if ($check1->get_active) { #Esta pulsado
		#Es una evidencia
		if ($img1vacia==0) { $evidencia{$dir1}=1; }
	} else { 
		#No es una evidencia
		if ($img1vacia==0) { $evidencia{$dir1}=0; }
	}
	if ($check2->get_active) { 
		if ($img2vacia==0) { $evidencia{$dir2}=1; }
	} else {
		if ($img2vacia==0) { $evidencia{$dir2}=0; }
	}
	if ($check3->get_active) {
		if ($img3vacia==0) { $evidencia{$dir3}=1; }
	} else {
		if ($img3vacia==0) { $evidencia{$dir3}=0; }
	}
	if ($check4->get_active) {
		if ($img4vacia==0) { $evidencia{$dir4}=1; }
	} else {
		if ($img4vacia==0) { $evidencia{$dir4}=0; }
	}

	
	#Modificamos la barra de estado
	$vistas=0;
	while (($clave,$valor) = each(%hash)) { 
		if ($valor =~ /Visto/){
			if (($clave ne "")&&($clave ne $imagenvacia)) { 
				$vistas=$vistas+1; 
			} #calculamos las imagenes vistas que hay que no sean vacias
		}
	}
	$evidencias=0;
	while (($clave,$valor) = each(%evidencia)) {
		if ($valor==1){
			$evidencias=$evidencias+1;
		}
	}
	$status->push( $status->get_context_id( 'statusbar1' ), "Seen: $vistas / $totalimagenes \t Checked as evidences: $evidencias." );


	if ($i>4) { #No estamos en la posicion inicial y damos por hecho que se puede ir hacia atrás
		#Salvaguardar los img1vacia,img2vacia,img3vacia e img4vacia		
		$valor = $i%4; #Con las 4 imagenes, vamos a ponerlas 
		if ($valor==0) { # Todas las imagenes caben --------------> Funciona bien
			$img1vacia=0;
			$img2vacia=0;
			$img3vacia=0;
			$img4vacia=0;
		} elsif ($valor==1) { # Hay una imagen visible
			$img1vacia=0;
			$img2vacia=1;
			$img3vacia=1;
			$img4vacia=1;
		} elsif ($valor==2) { # Hay dos imagenes visibles
			$img1vacia=0;
			$img2vacia=0;
			$img3vacia=1;
			$img4vacia=1;
		} elsif ($valor==3) { # Hay tres imagenes visibles y 1 vacia#
			$img1vacia=0;
			$img2vacia=0;
			$img3vacia=0;
			$img4vacia=1;
		}
		if ($img2vacia==1){ #solo esta la primera mostrada
			$i=$i-1;
		} elsif ($img3vacia==1){ #solo estan la primera y segunda mostrada
			$i=$i-2;
		} elsif ($img4vacia==1){ #estan la primera,segunda y tercera mostrada
			$i=$i-3;
		} else { #Estaban todas mostradas
			$i=$i-4;
			#Ahora $i apunta a donde $dir1 actual, que es donde habrá que dejar el índice
		}
		$j=$i;   #Para la siguiente iteración esté correcta, tanto para sig como ant
		
		#Empezamos por la cuarta imagen
		#Si damos hacia atrás siempre cabrán las imagenes
		$i=$i-1; #Lugar donde va dir4
		$dir4=$total[$i];
		chop $dir4;
		$visto = $hash{$dir4};
		eval { $label = $dir4." - ".$visto};
		$label4->set_text($label);
		if ($evidencia{$dir4}) { 
			#Ha sido marcada como evidencia, asi que dejamos activo
			$check4->set_active(1);
		} else {
			$check4->set_active(0);
		}
		$imagen4->set_from_pixbuf(Gtk2::Gdk::Pixbuf->new_from_file($dir4));

		#Ahora imagen 3	
		$i=$i-1; #Lugar donde va dir3
		$dir3=$total[$i];
		chop $dir3;
		$visto = $hash{$dir3};
		eval { $label = $dir3." - ".$visto};
		$label3->set_text($label);
		if ($evidencia{$dir3}) { 
			#Ha sido marcada como evidencia, asi que dejamos activo
			$check3->set_active(1);
		} else {
			$check3->set_active(0);
		}
		$imagen3->set_from_pixbuf(Gtk2::Gdk::Pixbuf->new_from_file($dir3));
		
		#Ahora imagen 2
		$i=$i-1; #Lugar donde va dir2
		$dir2=$total[$i];
		chop $dir2;
		$visto = $hash{$dir2};
		eval { $label = $dir2." - ".$visto};
		$label2->set_text($label);
		if ($evidencia{$dir2}) { 
			#Ha sido marcada como evidencia, asi que dejamos activo
			$check2->set_active(1);
		} else {
			$check2->set_active(0);
		}
		$imagen2->set_from_pixbuf(Gtk2::Gdk::Pixbuf->new_from_file($dir2));

		#Ahora imagen 1
		$i=$i-1; #Lugar donde va dir1
		$dir1=$total[$i];
		chop $dir1;
		$visto = $hash{$dir1};
		eval { $label = $dir1." - ".$visto};
		$label1->set_text($label);
		if ($evidencia{$dir1}) { 
			#Ha sido marcada como evidencia, asi que dejamos activo
			$check1->set_active(1);
		} else {
			$check1->set_active(0);
		}
		$imagen1->set_from_pixbuf(Gtk2::Gdk::Pixbuf->new_from_file($dir1));
		
		#Recogemos el valor de $i para la siguiente iteración
		$img1vacia=0; #Ahora decimos que estan todas mostradas
		$img2vacia=0;
		$img3vacia=0;
		$img4vacia=0;

		#Recuperamos el valor de $j
		$i=$j;

	} else { #Estamos en la posicion inicial
		$img1vacia=0;
		$img2vacia=0;
		$img3vacia=0;
		$img4vacia=0;
		
		#Recogemos imagen1
		$dir1 = $total[0];
		chop $dir1;	 
		$imagen1->set_from_pixbuf(Gtk2::Gdk::Pixbuf->new_from_file($dir1));
		#Recogemos imagen2
		$dir2 = $total[1];
		chop $dir2;	 
		$imagen2->set_from_pixbuf(Gtk2::Gdk::Pixbuf->new_from_file($dir2));
		#Recogemos imagen3
		$dir3 = $total[2];
		chop $dir3;	 
		$imagen3->set_from_pixbuf(Gtk2::Gdk::Pixbuf->new_from_file($dir3));
		#Recogemos imagen4
		$dir4 = $total[3];
		chop $dir4;	 
		$imagen4->set_from_pixbuf(Gtk2::Gdk::Pixbuf->new_from_file($dir4));
		
		#Modificamos el label1
		$visto = $hash{$dir1};
		eval { $label = $dir1." - ".$visto};
		$label1->set_text($label);
		#Modificamos el label2
		$visto = $hash{$dir2};
		eval { $label = $dir2." - ".$visto};
		$label2->set_text($label);
		#Modificamos el label3
		$visto = $hash{$dir3};
		eval { $label = $dir3." - ".$visto};
		$label3->set_text($label);
		#Modificamos el label4
		$visto = $hash{$dir4};
		eval { $label = $dir4." - ".$visto};
		$label4->set_text($label);
		#No hacemos nada o mostramos ventana de: No hay más imagenes detrás
		$i=4; #Dejamos la siguiente iteración listo para funcionar
	}

	#Guardamos ficheros ahora por si no se vuelve a pulsar los botones	
	#Salvaguardamos el hash de evidencia
	open(FICHEVIDENCIA, $fichevidencia) or die "Can't access to $fichevidencia.\n";
	while (($clave, $valor) = each(%evidencia))
	{
		if (($clave ne "")&&($clave ne $imagenvacia)) {
        		print FICHEVIDENCIA "$clave,$valor\n"; #Los guardamos como imagen,1 o imagen,0
		}					#Luego tokenizaremos con el caracter ','
	}
	close(FICHEVIDENCIA);

	#Salvaguardamos el hash de visto
	open(FICHVISTO, $fichvisto) or die "Can't access to $fichvisto.\n";
	while (($clave, $valor) = each(%hash))
	{
		if (($clave ne "")&&($clave ne $imagenvacia)) {
        		print FICHVISTO "$clave,$valor\n"; #Los guardamos como imagen,visto o imagen,no visto
		}					#Luego tokenizaremos con el caracter ','
	}
	close(FICHVISTO);

	#Salvaguardamos el valor de i
	open(FICHI, $fichi) or die "Can't access to $fichi.\n";
	print FICHI "$i"; #Solo guardamos la i
	close(FICHI);
		
	# print "Traza: Al salir de anterior, i=$i\n";
}

sub salir{ 
	if ($vistas == $totalimagenes){
		my $auxfich;
		eval { $auxfich = $direccionsalida."/informe.tex" };	
		eval { $auxpdf = $direccionsalida."/informe.pdf" };

		#Miramos si ha sido creado antes el .tex
		if (-e $auxpdf){ #existe el pdf
			#print "No escribimos en el .tex\n"; 
			goto noEscribe; 
		} else { 
			if (-e $auxfich) { #existe el tex
				my $val = `cat $auxfich | tail -n 1`; # pillariamos el \end{document} si hemos acabado de escribir
				if ($val =~ /end{document}/) { 
					#print "No escribimos en el .tex\n"; 
					goto noEscribe; 
				}

			}
		}

		open(FICH,">>$auxfich") || die("Can't access to $auxfich.\n");	
		print FICH '
\section{Pictures}

';
		$text = "Have been found $totalimagenes pictures and $evidencias are evidences. \n\n The evidences are: \n\n";
		print FICH "$text";

		#Mostrar imagenes pertinentes
	
		my @files = `cat evidencia.txt`;
		foreach my $linea (@files) {
		   my ($pict,$prueba) = (split /,/, $linea);
           my $extFile = (split /\./, $pict)[-1]; #conseguimos la extensión del archivo
		   if (($extFile =~ /jpg|jpeg/ ) and ($prueba==1)) { #Es una imagen
			
				# Inicio inserción de imagen en LaTeX
				$text = '\begin{figure}[H]
\centering
	\includegraphics{';
				print FICH "$text";
				eval { $imagenactual= "./imgparseadascarving/".$pict };
				print FICH "$imagenactual";
				$text= '}
\caption{';
				print FICH "$text";
				print FICH "$imagenactual";
				$text= '}
\label{fig:';
				print FICH "$text";
				print FICH "$imagenactual";
				$text= '}
\end{figure}

';
				print FICH "$text \n\n";
				#Fin inserción de imagen en LaTeX
		   }
		}


		$diferencia = $totalimagenes-$evidencias;
		$text = "$diferencia normal pictures have been found.\n\n";
		print FICH "$text";
		$text = '
%FinImagenes';
		print FICH "$text";
		
		if ($generar == 1){
			#Generamos el PDF porque ha sido restaurada la sesion
			# Para acabar el informe final:
			$text = '
\end{document}
';
			print FICH "$text"; # Comentar
			close(FICH);
			chdir($direccionsalida);
			system("pdflatex informe.tex >> /dev/null"); #funciona
		
			# Borrar .tex, aux, ...
			my $auxdelete;		
			eval { $auxdelete = $direccionsalida."/informe.aux" };	
			system("rm $auxdelete");
			eval { $auxdelete = $direccionsalida."/informe.log" };
			system("rm $auxdelete");
			eval { $auxdelete = $direccionsalida."/informe.out" };
			system("rm $auxdelete");
			eval { $auxdelete = $direccionsalida."/informe.tex" };
			system("rm $auxdelete");

			#firmamos el pdf de Latex
			my $pdf;
			eval { $pdf = $direccionsalida."/informe.pdf" };
			system("md5sum $pdf > $pdf.txtmd5"); # Hacemos el md5
			system("sha1sum $pdf > $pdf.txtsha1"); # Hacemos el firmado sha1
					
		} else {
			
			close(FICH);

		}

		noEscribe:
		
	}
	
	Gtk2->main_quit; 

}
	
