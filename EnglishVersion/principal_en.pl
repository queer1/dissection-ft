#! /usr/bin/perl -w

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

use threads;
use strict;
use Gtk2 '-init';
use Glib qw/TRUE FALSE/; 

my $dactual=`pwd`;
chomp $dactual;

my ($unidadseleccionada, # Unidad de la cual se hara el ISO
	$direccionsalida,	 # Dirección de salida en la cual pondremos en una carpeta nueva el ISO y firma
	$radio,				 # Variable auxiliar para realizar la firma
	$firma,				 # Tipo de firma a realizar. Opciones = md5/sha1
	$destinodd,			 # Ruta del fichero dd
	$destinogz, 		 # Ruta del fichero gz
	$destinomd5,		 # Ruta del fichero md5	
	$destinosha1,		 # Ruta del fichero sha1
	$auxfich,
	$label01,$label02,$label03,
	$entry01,$entry02,$entry03
);

my @aux;

#standard window creation, placement, and signal connecting
my $window = Gtk2::Window->new('toplevel');
$window->signal_connect('destroy' => sub { Gtk2->main_quit; return FALSE;});
$window->signal_connect('delete_event' => sub { $_[0]->destroy; });
$window->set_border_width(10);
$window->set_position('center_always');
$window->set_title('Dissection :: Create Image');	# Nombre de ventana: Herramientas forenses
$window->set_default_size(400, 200);

#Preparación de widgets
my $vbox = Gtk2::VBox->new(FALSE,5);
$label01 = Gtk2::Label->new("Insert your name:");
$label01->set_alignment(0.0, 0.0);
$entry01 = Gtk2::Entry->new();
$label02 = Gtk2::Label->new("Insert your ID:");
$label02->set_alignment(0.0, 0.0);
$entry02 = Gtk2::Entry->new();
$label03 = Gtk2::Label->new("Insert comments:");
$label03->set_alignment(0.0, 0.0);
$entry03 = Gtk2::Entry->new();
my $label1 = Gtk2::Label->new("Choose the device to analyze:");
$label1->set_alignment(0.0, 0.0);
# Combo Box #
my $combo_box_entry = Gtk2::ComboBoxEntry->new_text;
my @unidades = `sudo blkid | cat`;
	
foreach my $unidad (@unidades){
	chop $unidad;
	$combo_box_entry->append_text("$unidad");
} 

#$combo_box_entry->set_active(0);
	

my $label2 = Gtk2::Label->new("Choose the output path:");
$label2->set_alignment(0.0, 0.0);
# Ahora lo de selección de carpeta de salida #
my $hbox_fl_chooser_dialog = Gtk2::HBox->new(FALSE,5);
#Select Folder---->
my $btn_select_folder   = Gtk2::Button->new('Output path');
$btn_select_folder->signal_connect('clicked' => 
	sub{ show_chooser('File Chooser type select-folder','select-folder') });
$hbox_fl_chooser_dialog->pack_start($btn_select_folder,TRUE,TRUE,0);

#Create Folder---->
my $op1 = 0;
my $check1 = Gtk2::CheckButton->new("Compress image");
$check1->set_active(FALSE);
$check1->signal_connect(toggled => sub { 
				if ($op1 == 1) { $op1 = 0; }
				else { $op1 = 1; }
});
$hbox_fl_chooser_dialog->pack_start($check1,TRUE,TRUE,0);

my $label3 = Gtk2::Label->new("Choose digital signature:");
$label3->set_alignment(0.0, 0.0);
# RadioButtons #
my $hbox1 = Gtk2::HBox->new(FALSE,5); # hbox para radiobuttons
my $radiobutton = Gtk2::RadioButton->new(undef,"MD5");
$radiobutton->set_active(TRUE);
my @group = $radiobutton->get_group;
$hbox1->pack_start($radiobutton,TRUE,TRUE,0);
$radiobutton = Gtk2::RadioButton->new(@group,"SHA1");
$hbox1->pack_start($radiobutton,TRUE,TRUE,0);
$firma="md5";

# Botones #
my $button1 = Gtk2::Button->new("_Next");
my $button2 = Gtk2::Button->new("_Exit");
$button1->signal_connect('clicked' => \&aceptar);
$button2->signal_connect('clicked' => sub { Gtk2->main_quit; });

# Barra de Estado #
my $statusbar = Gtk2::Statusbar->new;
    #El primer parametro de push() es el id de contexto de nuestra barra, el cual es un
    #identificador único que se obtiene llamando get_context_id del mismo objeto.
    $statusbar->push($statusbar->get_context_id('statusbar'),'Seleccione las opciones deseadas y pulse Aceptar');

####################### Manejadores de botones #####################
# Combo Box #
($combo_box_entry->child)->signal_connect('changed' => sub {
		my ($entry) = @_;
		@aux = split(/:/, $entry->get_text);
		$unidadseleccionada = $aux[0];
		#print "La unidad seleccionada es: $unidadseleccionada.\n";	
});

# Radio Button #
$radiobutton->signal_connect('toggled'=> sub {
                                $radio = $radiobutton->get_active;
								if ( $radio == 1 ){
									$firma = "sha1";  
								} else {
									$firma = "md5";
								}
							});


#Empaquetado de widgets
$label01 = Gtk2::Label->new("Insert your name:");
$label01->set_alignment(0.0, 0.0);
$entry01 = Gtk2::Entry->new();
$label02 = Gtk2::Label->new("Insert your ID:");
$label02->set_alignment(0.0, 0.0);
$entry02 = Gtk2::Entry->new();
$label03 = Gtk2::Label->new("Insert comments:");
$label03->set_alignment(0.0, 0.0);
$entry03 = Gtk2::Entry->new();
$vbox->pack_start($label01,TRUE,TRUE,0);
$vbox->pack_start($entry01,TRUE,TRUE,0);
$vbox->pack_start($label02,TRUE,TRUE,0);
$vbox->pack_start($entry02,TRUE,TRUE,0);
$vbox->pack_start($label03,TRUE,TRUE,0);
$vbox->pack_start($entry03,TRUE,TRUE,0);
$vbox->pack_start($label1,TRUE,TRUE,0);
$vbox->pack_start($combo_box_entry,TRUE,TRUE,0);
$vbox->pack_start($label2,TRUE,TRUE,0);
$vbox->pack_start($hbox_fl_chooser_dialog,TRUE,TRUE,0); # Seleccion
$vbox->pack_start($label3,TRUE,TRUE,0);
$vbox->pack_start($hbox1,TRUE,TRUE,0); # insertamos hbox1
my $hbox2 = Gtk2::HBox->new(FALSE,5); # hbox para botones
$hbox2->pack_start($button1,TRUE,TRUE,0);
$hbox2->pack_start($button2,TRUE,TRUE,0);
$vbox->pack_start($hbox2,TRUE,TRUE,0); #insertamos hbox2
$vbox->pack_start($statusbar,TRUE,TRUE,0); #insertamos la barra de estados

#add and show the vbox
$window->add($vbox);
$window->show_all();

#our main event-loop
Gtk2->main();

sub show_chooser {

    my($heading,$type,$filter) =@_;
#$type can be:
#* 'select-folder'
#* 'create-folder' 
    my $file_chooser =  Gtk2::FileChooserDialog->new ( 
                            $heading,
                            undef,
                            $type,
                            'gtk-cancel' => 'cancel',
                            'gtk-ok' => 'ok'
                        );
    (defined $filter)&&($file_chooser->add_filter($filter));
    
    if ('ok' eq $file_chooser->run){    
       $direccionsalida = $file_chooser->get_filename;
       #print "filename $filename\n"; # Poner aquí que hacer con el fichero
    }

    $file_chooser->destroy;

    return $direccionsalida;
}

sub aceptar{
	# Recogemos los datos del perito
	my $fecha = `date`;
	eval { $auxfich = $direccionsalida."/informe.tex" };	
	system("touch $auxfich");
	system("rm $auxfich");
	system("touch $auxfich");	
	open(FICH,">>$auxfich") || die("Can't access to $auxfich.");	
	
	#Comenzamos a realizar el documento LaTeX
my $text = '\documentclass[12pt,letterpaper]{article}
\usepackage[T1]{fontenc} 
\usepackage{palatino} 
\usepackage{eurosym}

\usepackage{longtable} 
\usepackage{fullpage} 
\usepackage{multirow} 
\usepackage{setspace} 
%\usepackage{tocbibind}

\onehalfspacing
\usepackage{float}
\usepackage[pdftex]{thumbpdf} 
\usepackage{url} 
  \usepackage[pdftitle={Final Report}, 
             pdfauthor={Dissection Forensic Toolkit}, 
             pdfsubject={Final Report}, 
             pdfproducer={pdfLaTeX} 
            pdftex, 
             colorlinks=false, 
             linkcolor=black, 
             pdfstartview=FitH]{hyperref}

\usepackage{color} 
\definecolor{gray97}{gray}{.97} 
\definecolor{rltred}{rgb}{0.75,0,0} 
\definecolor{rltgreen}{rgb}{0,0.5,0} 
\definecolor{rltblue}{rgb}{0,0,0.75} 
\usepackage[pdftex]{graphicx} 
\usepackage{graphicx} %%%%%%%%%%
\usepackage{pdfpages} 
\usepackage{t1enc}

\DeclareGraphicsExtensions{.pdf,.png,.jpg}

\usepackage[utf8]{inputenc}
\usepackage[spanish]{babel} 
\usepackage{csquotes} 
\usepackage{verbatim} 
\usepackage{calc}  
\usepackage{shadow} 
\usepackage{xspace}

\usepackage{listings} 
\lstset{ 
%	frame=Ltb,
	framerule=1pt,
  	aboveskip=0.5cm,      
	framextopmargin=3pt,      
	framexbottommargin=3pt,      
	framexleftmargin=0.4cm,      
	framesep=0pt,      
	rulesep=.4pt,      
	backgroundcolor=\color{gray97},      
	rulesepcolor=\color{black},      
	stringstyle=\color{blue}\ttfamily,      
	showstringspaces = false,      
	basicstyle=\color{red}\ttfamily,      	
	commentstyle=\color{green}\ttfamily,      	
	keywordstyle=\color{black}\bfseries,      
	breaklines=true,    
} 

\begin{document}

\section{Final Report}
';
	print FICH "$text";
# Para acabar: \end{document}
	$text='\begin{description}
';	
	print FICH "$text";
	$text = '\item [Name]: ';
	print FICH "$text";
	$text = $entry01->get_text; # Nombre
	print FICH "$text\n";
	
	$text = '\item [ID]: ';
	print FICH "$text";
	$text = $entry02->get_text; # DNI
	print FICH "$text\n";
	
	$text = '\item [Comments]: ';
	print FICH "$text";
	$text = $entry03->get_text; # Comentario
	print FICH "$text\n";

	$text = '\item [Output path]: ';
	print FICH "$text $direccionsalida\n";

	$text = '\item [Start date analysis]: ';
	print FICH "$text $fecha\n";

	# Aquí comenzamos a hacer el DD de la unidad, firma y comprimir ambos.
	#$statusbar->push($statusbar->get_context_id('statusbar'),'Realizando la imagen DD de la unidad seleccionada...');	

	chdir($direccionsalida);
	system("mkdir Imagen");
	eval { $destinodd = $direccionsalida."/Imagen/"."imagen.dd" };
	eval { $destinomd5 = $destinodd.".txt" };	
	eval { $destinosha1 = $destinodd.".txt" };
	
	# Modificamos el destinodd por si tiene carpetas con espacios entre ella
	@aux = split(' ',$destinodd);

	#print "destino dd: $destinodd.\n";

	if ($#aux > 0){
		eval { $destinodd = $aux[0] };
		for my $i (1 .. $#aux-1) {
			if  ($i < $#aux-1){
				eval { $destinodd = $destinodd."\\ ".$aux[$i] };
			}
		}
		eval { $destinodd = $destinodd."\\ ".$aux[-1] };
	}

	#print "nuevo destinodd: $destinodd\n";

	# Creamos la imagen
	print "Creating dd image, please wait...\n";
	# system("sudo dd if=$unidadseleccionada | pv | dd of=$destinodd");	#sin threads
 

### Método con threads usando USR1
	my $thread1 = threads->create(\&dd);
	sleep 3;
	while ($thread1->is_running()){
			sleep 1;
			system("clear all");		
			system("sudo pkill -USR1 -x dd");
	}
	$thread1->join(); # Recuperamos el thread

	#$statusbar->push($statusbar->get_context_id('statusbar'),'Realizando el firmado de la imagen...');
	$fecha = `date`;
	$text = '\item [Date creation image]: ';
	print FICH "$text $fecha\n";
	$text = '
';
	print FICH "$text";

	# Ahora firmamos la imagen
	if ($firma eq "md5") {	
		system("md5sum $destinodd > $destinodd.txt"); # Hacemos el md5
		$text = '\item [MD5 signature]: ';
		print FICH "$text $destinodd.txt \n";
	} elsif ($firma eq "sha1") {
		system("sha1sum $destinodd > $destinodd.txt"); # Hacemos el firmado sha1
		$text = '\item [SHA1 signature]: ';
		print FICH "$text $destinodd.txt \n";
	} #sha1sum gnupg-1.4.12.tar.bz2
	
	print "$firma digital signature has been done.\n";

	#$statusbar->push($statusbar->get_context_id('statusbar'),'Comprimiendo la imagen DD...');

	$text = '\end{description}';
	print FICH "$text\n\n";
	
	eval { $destinogz = $destinodd.".gz" };

	# Realizar la compresión
	if ($op1 == 1){	
		print "Compressing the imagen, please wait...\n";
		#system("gzip $destinodd"); vamos a mostrar lo que saca
		system("pv $destinodd | gzip > $destinogz"); # NO ELIMINA el dd
		#El DD se elimina solo, dejando únicamente la imágen comprimida y su firma
		print "Compression done.\n";
                print "Process completed.\n";
		exec("sleep 1");
	

	} else {	
		chdir($dactual);
		exec("perl verificar_en.pl $direccionsalida $firma");

	}

	exit 0;
}

sub dd{
	system("sudo dd if=$unidadseleccionada of=$destinodd");
}

