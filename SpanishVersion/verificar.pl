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
use Gtk2 '-init';
use Glib qw/TRUE FALSE/; 

my $dactual=`pwd`;
chomp $dactual;

# Definición de variables
my ($direccionsalida,	 # Dirección de salida en la cual pondremos en una carpeta nueva el ISO y firma
	$firma,				 # Tipo de firma a realizar. Opciones = md5/sha1
	$destinodd,			 # Ruta del fichero dd
	$destinogz,			 # Ruta del fichero dd en compresion gz
	$destinomd5,		 # Ruta del fichero md5	
	$destinosha1,		 # Ruta del fichero sha1
	$op1,			 	 # Si op1 = 1 => Carving + Visor de Imagenes
	$op2,			 	 # Si op2 = 1 => Logs + Visor de Eventos
						 # Si son 0, no hace nada, Si son 1, los dos se hacen los dos.
	$firma,				 # Nos dice si la firma de la imagen es md5 o sha1
	@aux,				 # Para tokenizers
	$dircarving,		 # Ruta de la carpeta Carving dentro de direccionsalida
	$dirjpgdd,			 # Ruta de la carpeta "jpgdd" dentro de direccionsalida
	$dirjpgcarving,	     # Ruta de la carpeta "jpgcarving" dentro de direccionsalida
	$dirrtfdd,			 # Ruta de la carpeta "rtfdd" dentro de direccionsalida
	$dirrtfcarving,		 # Ruta de la carpeta "rtfcarving" dentro de direccionsalida
	$dirhtmldd,			 # Ruta de la carpeta "htmldd" dentro de direccionsalida
	$dirhtmlcarving,	 # Ruta de la carpeta "htmlcarving" dentro de direccionsalida
	$dirimgparseadascarving,		# Ruta de la carpeta "imgparseadascarving" 
	$dirimgparseadasdd,				# Ruta de la carpeta "imgparseadasdd"
	$dirrtfparseadasdd,
	$dirrtfparseadascarving,
	$dirhtmlparseadosdd,
	$dirhtmlparseadoscarving,
	$auxpdf,$text,$i,$fich1,$fich2,$auxcarving,$txtsalida,
	$completosalida,$txtsalida,$rtfsalida,$antiword,$dmove,$aux
);
my $fin=0;

if ( $#ARGV == 1 ) { # El ultimo indice es 1, por lo tanto hay dos elementos
	# Solo necesitamos un argumento
	$direccionsalida = $ARGV[0];
	$firma = $ARGV[1];
} else {
	die "Error, se necesita un argumento con la direccion de salida y otro con el tipo de firma realizada\n";
}



#Suponemos que está correcto, ya que se llama desde el otro programa 
eval { $destinodd = $direccionsalida."/Imagen/"."imagen.dd" };
eval { $destinomd5 = $destinodd.".txt" };	
eval { $destinosha1 = $destinodd.".txt" };

#standard window creation, placement, and signal connecting
my $window = Gtk2::Window->new('toplevel');
$window->signal_connect('destroy' => sub { Gtk2->main_quit; return FALSE;});
$window->signal_connect('delete_event' => sub { $_[0]->destroy; });
$window->set_border_width(10);
$window->set_position('center_always');
$window->set_title('Dissection :: Verificar imagen');
$window->set_default_size(400, 200);

#Preparación de widgets
my $vbox = Gtk2::VBox->new(FALSE,5);
my $label1 = Gtk2::Label->new("Seleccione que tipo de analisis realizar:");
$label1->set_alignment(0.0, 0.0);

# Combo Box #
my $combo_box_entry = Gtk2::ComboBoxEntry->new_text;
$combo_box_entry->append_text("2x2"); 
$combo_box_entry->append_text("3x3");
$combo_box_entry->append_text("4x4");
$combo_box_entry->set_active(0);

# Manejador Combo Box #
($combo_box_entry->child)->signal_connect('changed' => sub {
		my ($entry) = @_;
		$aux = $entry->get_text;
		#print "El visor seleccionado es: $aux.\n";	
});


# Botones #
my $hbox = Gtk2::HBox->new(FALSE,5);
my $button1 = Gtk2::Button->new("_Aceptar");
my $button2 = Gtk2::Button->new("_Salir");
$button1->signal_connect('clicked' => \&aceptar);
$button2->signal_connect('clicked' => sub { Gtk2->main_quit; });
$hbox->pack_start($button1,TRUE,TRUE,0);
$hbox->pack_start($button2,TRUE,TRUE,0);

# Barra de Estado #
my $statusbar = Gtk2::Statusbar->new;
#El primer parametro de push() es el id de contexto de nuestra barra, el cual es un
#identificador único que se obtiene llamando get_context_id del mismo objeto.
$statusbar->push($statusbar->get_context_id('statusbar'),'Comprobando si es valida la imagen DD...');

$op1 = 0;
$op2 = 0;
my $check1 = Gtk2::CheckButton->new("Realizar data carving");
my $check2 = Gtk2::CheckButton->new("Realizar solapamiento de historicos");
$check1->set_active(FALSE);
$check1->signal_connect(toggled => sub { 
				if ($op1 == 1) { $op1 = 0; }
				else { $op1 = 1; }
});
$check2->set_active(FALSE);
$check2->signal_connect(toggled => sub {
				if ($op2 == 1) { $op2 = 0; }
				else { $op2 = 1; }
});

#Empaquetado de widgets
my $hbox2 = Gtk2::VBox->new(FALSE,5);
$hbox2->pack_start($check1,TRUE,TRUE,0); # checkbutton1
$hbox2->pack_start($combo_box_entry,TRUE,TRUE,0);# 

$vbox->pack_start($label1,TRUE,TRUE,0); # Label
$vbox->pack_start($hbox2,TRUE,TRUE,0); # Check button 1
$vbox->pack_start($check2,TRUE,TRUE,0); # Check button 2
$vbox->pack_start($hbox,TRUE,TRUE,0); # HBox que contiene a los botones {Aceptar,Salir}
$vbox->pack_start($statusbar,TRUE,TRUE,0); # Status Bar

$window->add($vbox);
$window->show_all();

# Comenzamos con la tarea ajena a Gtk
eval { $dmove = $direccionsalida."/Imagen/" };
eval { $destinogz = $destinodd.".gz" };
chdir($dmove);

# Comprobamos si existe la imagen descomprimida:
if (-e $destinodd){
	print "Procedemos a verificar la firma $firma\n";
 
} else {
	# No existe la imagen descomprimida:
	print "No existe la imagen descomprimida, la descomprimimos antes de verificar la firma $firma: \n";
	#system("gzip -d $destinogz"); # Vamos a cambiarlo por el de pv
	system("pv $destinogz | gzip -d > $destinodd"); 

} 

my $firmacorrecta = 0;
my $salidafirma;
if ($firma eq "md5"){
	$salidafirma = `md5sum -c $destinomd5`; 
	
	my @tokenizer = split (":", $salidafirma);
	chomp $tokenizer[-1]; 
	if ($tokenizer[-1] =~ /La suma coincide/) { # Correcto
		$firmacorrecta = 1;
	} else {
		$firmacorrecta = 0;
	}

} elsif  ($firma eq "sha1"){
	$salidafirma = `sha1sum -c $destinosha1`; 
	
	my @tokenizer = split (":", $salidafirma);
	chomp $tokenizer[-1]; 
	if ($tokenizer[-1] =~ /La suma coincide/) { # Correcto
		$firmacorrecta = 1;
	} else {
		$firmacorrecta = 0;
	}
} else {
	die "Tipo de firmado incorrecto: $firma\n";
}

if ($firmacorrecta == 1){
	$statusbar->push($statusbar->get_context_id('statusbar'),'Correcto, es valida la imagen DD');
} else {
	$statusbar->push($statusbar->get_context_id('statusbar'),'Error, no es valida la imagen DD');
}


Gtk2->main();

sub aceptar{
	# print "Op1: $op1, Op2: $op2\n"; Funciona bien
	if ($firmacorrecta == 0){
		print "No es correcta la firma. Debe comenzar el analisis de nuevo .\n";
		# Fail, no es correcta

	} else {
		my $auxfich;
		eval { $auxfich = $direccionsalida."/informe.tex" };		
		eval { $auxpdf = $direccionsalida."/informe.pdf" };
	
		open(FICH,">>$auxfich") || die("El fichero $auxfich no se ha podido abrir.");	
	
		# Correcto, continuar :)
		if (($op1 == 1)and($op2 == 1)){
			# Realizar Carving + Visor de Imagenes
			## 1.1- Carving
			chdir($dactual) or die "No se puede abrir $dactual\n"; #donde estan los .pl
			system("perl carving.pl $direccionsalida $firma");

			# 1.2.- Llamar al Visor de Imagenes
			chdir($dactual) or die "No se puede abrir $dactual\n"; #donde estan los .pl
			
			if ($aux =~ "3x3"){
				system("perl visorimagenes3x3.pl $direccionsalida");
			} elsif ($aux =~ "4x4") {
				system("perl visorimagenes4x4.pl $direccionsalida");
			} else {
				system("perl visorimagenes2x2.pl $direccionsalida");
			}

			# Realizar Logs + Visor de Eventos
			# 2.1- Recolectar logs
			chdir($dactual) or die "No se puede abrir $dactual\n"; #donde estan los .pl
			system("perl logs.pl $direccionsalida $firma");
			
			if (-e $auxpdf) { 
				print "Análisis realizado anteriormente.\n"; 
				goto noEscribe1; 
			
			} else {
				if (-e $auxfich) { #existe el tex
					my $val = `cat $auxfich | tail -n 1`; # pillariamos el \end{document} si hemos acabado de escribir
					if ($val =~ /end{document}/) { 
						print "Análisis realizado anteriormente.\n"; 
						goto noEscribe1; 
					}
				}
			}
		
			# Para acabar el informe final: 
			my $text = '
\end{document}
';
			print FICH "$text"; # Comentar
			close(FICH);

			# Ejecutar
			chdir($direccionsalida);
			system("pdflatex informe.tex >> /dev/null");
						
			noEscribe1: 
			# 2.2- Llamar al Visor de Eventos
			chdir($dactual) or die "No se puede abrir $dactual\n"; #donde estan los .pl
			system("perl visoreventos.pl $direccionsalida");
			
			$fin = 1;

		} elsif (($op1 == 1)and($op2 == 0)){ 
			# Realizar Carving + Visor de Imagenes
			
			## 1.- Carving
			chdir($dactual) or die "No se puede abrir $dactual\n"; #donde estan los .pl
			system("perl carving.pl $direccionsalida $firma");

			# 2.- Llamar al Visor de Imagenes
			chdir($dactual) or die "No se puede abrir $dactual\n"; #donde estan los .pl
			
			if ($aux =~ "3x3"){
				system("perl visorimagenes3x3.pl $direccionsalida");
			} elsif ($aux =~ "4x4") {
				system("perl visorimagenes4x4.pl $direccionsalida");
			} else {
				system("perl visorimagenes2x2.pl $direccionsalida");
			}


			if (-e $auxpdf){ 
				print "Análisis realizado anteriormente.\n"; 
				goto noEscribe2; 
			
			} else {
				if (-e $auxfich){
					my $val = `cat $auxfich | tail -n 1`; # pillariamos el \end{document} si hemos acabado de escribir					
					if ($val =~ /end{document}/){ 
						print "Análisis realizado anteriormente.\n"; 
						goto noEscribe2; 
					}
				}
			}
		
			if (-e $auxfich) {
				my $val = `cat $auxfich | tail -n 1`; # pillariamos la etiqueta %FinImagenes para poner el end
				if ($val =~ /\%FinImagenes/){					 	 
					$text = '
\end{document}
';				
			
					print FICH "$text"; # Comentar
					close(FICH);
		
					# Ejecutar
					chdir($direccionsalida);
					system("pdflatex informe.tex >> /dev/null");
					$fin = 1;
				} else {
					$fin = 0;
				}

			}

			noEscribe2:

		} elsif (($op1 == 0)and($op2 == 1)){
			# Realizar Logs + Visor de Eventos
			
			# 1.- Recolectar logs
			chdir($dactual) or die "No se puede abrir $dactual\n"; #donde estan los .pl
			system("perl logs.pl $direccionsalida $firma");
	
			if (-e $auxpdf){ 
				print "Análisis realizado anteriormente.\n"; 
				goto noEscribe3; 
			} else {
				if (-e $auxfich){
					my $val = `cat $auxfich | tail -n 1`; # pillariamos el \end{document} si hemos acabado de escribir					
					if ($val =~ /end{document}/){ 
						print "Análisis realizado anteriormente.\n"; 
						goto noEscribe3; 
					}
				
				}
			}

			# Para acabar el informe final:
			$text = '
\end{document}
';
			print FICH "$text"; # Comentar
			close(FICH);
		
			# Ejecutar
			chdir($direccionsalida);
			system("pdflatex informe.tex >> /dev/null");
			
		
			noEscribe3:
			# 2.- Llamar al Visor de Eventos
			chdir($dactual) or die "No se puede abrir $dactual\n"; #donde estan los .pl
			system("perl visoreventos.pl $direccionsalida");

			$fin = 1;
	
		} else { # Ambos 0
			# No realizar nada
			$statusbar->push($statusbar->get_context_id('statusbar'),'Seleccione la opcion deseada');
			$fin = 0;
		}
		
		if ($fin == 1) {
			# Borrar .tex, aux, ...
			#my $auxdelete;		
			chdir($direccionsalida);			
			#eval { $auxdelete = $direccionsalida."/informe.aux" };	
			system("rm informe.aux");
			#eval { $auxdelete = $direccionsalida."/informe.log" };
			system("rm informe.log");
			#eval { $auxdelete = $direccionsalida."/informe.out" };
			system("rm informe.out");
			#eval { $auxdelete = $direccionsalida."/informe.tex" };
			#system("rm informe.tex");

			#firmamos el pdf de Latex
			my $pdf;
			eval { $pdf = $direccionsalida."/informe.pdf" };
			if ($firma eq "md5") {	
				system("md5sum $pdf > $pdf.txt"); # Hacemos el md5
			} elsif ($firma eq "sha1") {
				system("sha1sum $pdf > $pdf.txt"); # Hacemos el firmado sha1
			}		
		}
			
		#Gtk2->main_quit;
		exit;
	}

	sig: # No hacemos nada, solo mostrar el mensaje en el status bar

}
