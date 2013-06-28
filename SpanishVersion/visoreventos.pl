#! /usr/bin/perl

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
use Glib qw/TRUE FALSE/; 

my ($fichero,$flecha,@resto,@lab,$saltotomado);
my ($importante1,$importante2,@item1,@item2,@item3);
my (@eventbox,$menuitem1,$menuitem2,$menuitem3,$menuitem4,$menuitem5,@menu,@eventboxf,@menuf,$h);
my (@lname,@files,@l,@label);
my ($h1,$h2,$act,$x,$y,$z,$zp,$fecha,@lines,$hora,$f,$log,@bla,$lab,$importante,$j,$i,$destino,$dirlogs,
	$scrolled_window1,$scrolled_window2,$p,%op,$nombre1,$nombre2,$j);
my $quit = sub { exit };

my $dact = `pwd`;
chomp $dact;

my ($direccionsalida,$dirlogs);

#Cogemos argumento
if ( $#ARGV == 0 ) { # El ultimo indice es 0, por lo tanto hay 1 elemento
	# Solo necesitamos un argumento
	$direccionsalida = $ARGV[0];
} else {
	die "Error, es necesario un argumento.\n";
}

## Poner esto al final de imagen.pl, pero antes probarlo aqui

eval { $dirlogs = $direccionsalida."/logs/" };

#Configuración básica de la ventana principal
my $window = Gtk2::Window->new;								
$window->signal_connect('delete_event', $quit); 		
$window->set_position('center');							
$window->set_border_width(10);								
$window->set_title('Dissection :: Visor de Sucesos');		
$window->set_default_size(800,600);						
$window->maximize;

$scrolled_window1 = Gtk2::ScrolledWindow->new;
$scrolled_window1->set_policy('automatic', 'automatic');

#Preparación ficheros
chdir($dirlogs); 		#Nos vamos a la carpeta de logs
my @files =  < *>;		#Recogemos todos los ficheros
my $vbox = Gtk2::VBox->new(FALSE,0);
my $hbox = Gtk2::HBox->new(FALSE,0);
my $vbox1 = Gtk2::VBox->new(FALSE,0);

# Boton de actualizar
my $labelficheros = Gtk2::Label->new("Seleccione ficheros:");
$vbox1->pack_start($labelficheros,FALSE,FALSE,0);
my $button = Gtk2::Button->new("Actualizar");
$button->signal_connect('clicked' => \&cambio);

#Poner todos los logs que existan
my @files = < *>;
my %checklogs;
my $checkint;

foreach my $file (@files){
	my $ext = (split /\./, $file)[-1];
	if ($ext =~ /log/){	
		if ($file =~ /historicofinal.log/) { next; }
		$checklogs{$file} = Gtk2::CheckButton->new("$file");
		$checklogs{$file}->set_active(TRUE);
		$op{$file} = 1;
		$checklogs{$file}->signal_connect(toggled => sub { 
				if ($op{$file} eq 1) { 
					# print "Traza antes: op{$file} = $op{$file} deberia ser 1\n";					
					$op{$file} = 0; 
					# print "Traza despues: op{$file} = $op{$file} deberia ser 0\n"; 
				} else {
					# print "Traza antes: op{$file} = $op{$file} deberia ser 0\n"; 
					$op{$file} = 1; 
					# print "Traza despues: op{$file} = $op{$file} deberia ser 1\n";
				}
		});
		$vbox1->pack_start($checklogs{$file},FALSE,FALSE,0);
	}
}


my $labelexpreg = Gtk2::Label->new("Expresion regular:");
my $entryexpreg = Gtk2::Entry->new_with_max_length(20); ## cambiar
$vbox1->pack_start($labelexpreg,FALSE,FALSE,0);
$vbox1->pack_start($entryexpreg,FALSE,FALSE,0);

# Añadimos la opción de intercalar sucesos
my $opint = 0; # Equivale a que muestra la opción del intercalador
$checkint = Gtk2::CheckButton->new("Intercalar");
$checkint->set_active(FALSE);
$checkint->signal_connect(toggled => sub {
		if ($opint eq 1) {
			$opint=0;
		} else {
			$opint=1;
		}
	}
);

$vbox1->pack_start($checkint,FALSE,FALSE,0);

$vbox1->pack_start($button,FALSE,FALSE,0);

$i=0;


open(LEER, "historicofinal.log");
@lines = <LEER>;
close(LEER);

$saltotomado=" ";
for $x (0 .. $#lines){
		($fichero,$fecha,@resto) = split(' ',$lines[$x]);
		chomp $lines[$x];			
		# Este si se puede pulsar botón derecho, entonces
		$lab[$x] = Gtk2::Label->new("$lines[$x]"); 
		$lab[$x]->set_alignment(0.0, 0.0);		
		$h = $lab[$x]->get_text();
		# Si ha habido un salto, lo ponemos en magenta #
		#$ficherosalto = $si fichero = salto, o $flecha = salto, nose como quedara asi :S examinar pero ese fich
		# todos los demas tienen q ir de magenta
		if ($fichero =~ /SALTO|JUMP/){
			if ($fecha !~ $saltotomado){ 
				eval { $saltotomado = $saltotomado.$fecha." " }; # Segun se lee es: "SALTO fichero"
			}
		} elsif ($saltotomado =~ $fichero) {

			$lab[$x]->modify_fg('normal',Gtk2::Gdk::Color->parse("magenta"));		
		}
		$eventboxf[$x] = Gtk2::EventBox->new;
		$eventboxf[$x]->add($lab[$x]);
		

		$vbox->pack_start($eventboxf[$x],FALSE,FALSE,0); # fila 3ª
		# Seguir con las propiedades del botón derecho
		$menuf[$x] = Gtk2::Menu->new();
		$menuitem1 = Gtk2::MenuItem->new("Seguro cierto");				# Verde
		$menuitem2 = Gtk2::MenuItem->new("Seguro falso");				# Rojo	
		$menuitem3 = Gtk2::MenuItem->new("Hipoteticamente cierto");		# Azul
		$menuitem4 = Gtk2::MenuItem->new("Hipoteticamente falso");		# Magenta '#FF00FF'
		$menuitem5 = Gtk2::MenuItem->new("Desconocido"); 				# Negro
		#
		#$lbl_show->set_markup("<span foreground=\"$fg\" background=\"$bg\" size=\"30000\"><b>Test Text</b></span>");
		#-----------------------------hacer del sub el \&1,2,3 para forestgreen,red,black.
		$menuitem1->signal_connect(activate => sub {
								$lab[$x]->modify_fg('normal',Gtk2::Gdk::Color->parse("forestgreen"));
					});
		$menuitem2->signal_connect(activate => sub { 
								$lab[$x]->modify_fg('normal',Gtk2::Gdk::Color->parse("red"));
					});
		$menuitem3->signal_connect(activate => sub { 
								$lab[$x]->modify_fg('normal',Gtk2::Gdk::Color->parse("blue"));
					});
		$menuitem4->signal_connect(activate => sub { 
								$lab[$x]->modify_fg('normal',Gtk2::Gdk::Color->parse("magenta"));
					});
		$menuitem5->signal_connect(activate => sub { 
								$lab[$x]->modify_fg('normal',Gtk2::Gdk::Color->parse("black"));
					});

		$menuitem1->show();
		$menuitem2->show();
		$menuitem3->show();
		$menuitem4->show();
		$menuitem5->show();

		$menuf[$x]->append($menuitem1);
		$menuf[$x]->append($menuitem2);
		$menuf[$x]->append($menuitem3);
		$menuf[$x]->append($menuitem4);
		$menuf[$x]->append($menuitem5);
		
		
		$eventboxf[$x]->signal_connect ('button-press-event' => 
				sub {   my ($widget, $event) = @_;
				        return 0 unless $event->button == 3;
				        $menuf[$x]->popup(
				                undef,
				                undef,
				                undef,
				                undef,
				                $event->button,
				                $event->time
				        );
				}
		);
}
	

$scrolled_window1->add_with_viewport($vbox);


$hbox->pack_start($vbox1,FALSE,FALSE,0);
my $separador = Gtk2::HSeparator->new;
$hbox->pack_start($separador,FALSE,FALSE,0);
$hbox->pack_start($scrolled_window1,TRUE,TRUE,0); #vbox


$window->add($hbox); #vbox1
$window->show_all;
		

Gtk2->main;

sub cambio{
	my $expregbuscar = $entryexpreg->get_text();
	
	for (keys %checklogs){
		$nombre1 = $checklogs{$_}->get_label;
		#eval { $nombre1 = $nombre1." " };

		if ($op{$_} eq 1) { # Activar
		
			for $j (0 .. $#lab){
				$nombre2 = $lab[$j]->get_text;

				#print "Traza (opcion marcada> nombre 1: \"$nombre1\", nombre 2: \"$nombre2\"\n";
				my $problem = (split / ~/, $nombre2)[0];
				if ($nombre1 eq $problem){
					#print "Traza: nombre1=$nombre1, problem=$problem\n";
					#print "Encaja marcado: mostramos los de fich $nombre1\n";
					#$lab[$j]->show;
					if (($expregbuscar eq "") or ($nombre2 =~ /$expregbuscar/)){
						if ($opint eq 0) { # desactivada la opción de intercalar sucesos
							$lab[$j]->visible(1);
						} else {		   # activada la opción de intercalar sucesos
							$lab[$j]->show;
						}
					} else { 	
						if ($opint eq 0) { # desactivado
							$lab[$j]->visible(0);
						} else {
							$lab[$j]->hide;
						} 
					}	 		
				}
			}

		} else { # Desactivar

			for $j (0 .. $#lab){
				$nombre2 = $lab[$j]->get_text;
				#print "Traza (opcion desmarcada nombre1: $nombre1, nombre 2: $nombre2\n";
				my $problem = (split / ~/, $nombre2)[0];
				if (($nombre1 eq $problem) or (($expregbuscar ne "") and ($nombre2 !~ /$expregbuscar/))){
					#print "Traza: nombre1=$nombre1, problem=$problem\n";					
					#print "Encaja desmarcado: ocultamos los de fich $nombre1\n";
					if ($opint eq 0) { # desactivado
						$lab[$j]->visible(0); # Con huecos pero RAPIDO
					} else {
						$lab[$j]->hide; # Sin huecos pero LENTO
					}
				}
			}
		}		

	}

	$scrolled_window1->hide;	
	$scrolled_window1->show;

}

