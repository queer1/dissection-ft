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

use strict;
use Gtk2 '-init';
use Glib qw/TRUE FALSE/; 

my $dactual=`pwd`;
chomp $dactual;

my @aux;
my $numimgs;
my ($radio, $direccionsalida, $accion, $firma);
my ($radiobutton01, $radiobutton02, $radiobutton1, $radiobutton2, $radiobutton3, $radiobutton4);

my $window = Gtk2::Window->new('toplevel');
$window->signal_connect('destroy' => sub { Gtk2->main_quit; return FALSE; });
$window->signal_connect('delete_event' => sub { $_[0]->destroy; });
$window->set_border_width(10);
$window->set_position('center_always');
$window->set_title('Dissection :: Menu');
$window->set_default_size(400, 200);

$firma="md5";
$accion="1";

#Preparación de widgets
my $vbox = Gtk2::VBox->new(FALSE,5);
my $hbox1 = Gtk2::HBox->new(FALSE,5);
my $hbox2 = Gtk2::HBox->new(FALSE,5);
my $label1 = Gtk2::Label->new("Seleccione que desea realizar:");
$label1->set_alignment(0.0, 0.0);
	
# Separador #
my $separador1 = Gtk2::HSeparator->new;

# Etapa 1 #
my $label2 = Gtk2::Label->new("Etapa 1:"); 
$label2->set_alignment(0.0, 0.0);
my $separador2 = Gtk2::HSeparator->new;

# Etapa 2 # 
my $label3 = Gtk2::Label->new("Etapa 2:");
$label3->set_alignment(0.0, 0.0);
my $separador3 = Gtk2::HSeparator->new;

# Etapa 3 #
my $label4 = Gtk2::Label->new("Etapa 3:");
$label4->set_alignment(0.0, 0.0);
my $separador4 = Gtk2::HSeparator->new;

# Etapa 4 #
my $label5 = Gtk2::Label->new("Etapa 4:");
$label5->set_alignment(0.0, 0.0);
my $separador5 = Gtk2::HSeparator->new;

# Opciones #
my $label6 = Gtk2::Label->new("Directorio de salida y firma");
$label6->set_alignment(0.0, 0.0); 
my $separador6 = Gtk2::HSeparator->new;

# Botones #
my $button0 = Gtk2::Button->new('Directorio de salida');
my $button1 = Gtk2::Button->new("_Aceptar");
my $button2 = Gtk2::Button->new("_Salir");
my $hbox_fl_chooser_dialog = Gtk2::HBox->new(FALSE,5);
$hbox_fl_chooser_dialog->pack_start($button0,TRUE,TRUE,0);

$button0->signal_connect('clicked' => sub { show_chooser('File Chooser type select-folder','select-folder') });
$button1->signal_connect('clicked' => \&aceptar);
$button2->signal_connect('clicked' => sub { Gtk2->main_quit; });

# Radio Buttons -> de Firmado #
$hbox1->pack_start($hbox_fl_chooser_dialog,TRUE,TRUE,0); 
$radiobutton01 = Gtk2::RadioButton->new(undef,"MD5");
#$radiobutton1->set_active(TRUE);
my @group1 = $radiobutton01->get_group;
$hbox1->pack_start($radiobutton01,TRUE,TRUE,0);
$radiobutton02 = Gtk2::RadioButton->new(@group1,"SHA1");
$hbox1->pack_start($radiobutton02,TRUE,TRUE,0);

# Combo Box #
my $combo_box_entry = Gtk2::ComboBoxEntry->new_text;
$combo_box_entry->append_text("2x2"); 
$combo_box_entry->append_text("3x3");
$combo_box_entry->append_text("4x4");

# Manejador Combo Box #
($combo_box_entry->child)->signal_connect('changed' => sub {
		my ($entry) = @_;
		$numimgs = $entry->get_text;
		#print "El visor seleccionado es: $numimgs.\n";	
});

# Radio Button 1 #
#Empaquetado de widgets + radio buttons de seleccion
$vbox->pack_start($label1,TRUE,TRUE,0);
$vbox->pack_start($separador1,TRUE,TRUE,0);
$vbox->pack_start($label2,TRUE,TRUE,0);
$radiobutton1 = Gtk2::RadioButton->new(undef,"Realizar imagen");
#$radiobutton1->set_active(TRUE);
$vbox->pack_start($radiobutton1,TRUE,TRUE,0);
my @group = $radiobutton1->get_group;
$vbox->pack_start($separador2,TRUE,TRUE,0);
$vbox->pack_start($label3,TRUE,TRUE,0);
$radiobutton2 = Gtk2::RadioButton->new(@group,"Verificar imagen");
$vbox->pack_start($radiobutton2,TRUE,TRUE,0);
$vbox->pack_start($separador3,TRUE,TRUE,0);
$vbox->pack_start($label4,TRUE,TRUE,0);
$radiobutton3 = Gtk2::RadioButton->new(@group,"Visor de Imagenes");

my $hbox3 = Gtk2::HBox->new;
$hbox3->pack_start($radiobutton3,TRUE,TRUE,0);
$hbox3->pack_start($combo_box_entry,TRUE,TRUE,0);
$vbox->pack_start($hbox3,TRUE,TRUE,0);

$vbox->pack_start($separador4,TRUE,TRUE,0);
$vbox->pack_start($label5,TRUE,TRUE,0);
$radiobutton4 = Gtk2::RadioButton->new(@group,"Visor de Sucesos");
$vbox->pack_start($radiobutton4,TRUE,TRUE,0);
$vbox->pack_start($separador5,TRUE,TRUE,0);
$vbox->pack_start($label6,TRUE,TRUE,0);
$vbox->pack_start($hbox1,TRUE,TRUE,0);
$hbox2->pack_start($button1,TRUE,TRUE,0);
$hbox2->pack_start($button2,TRUE,TRUE,0);
$vbox->pack_start($hbox2,TRUE,TRUE,0);

$window->add($vbox);
$window->show_all();


Gtk2->main();

sub show_chooser {
    my($heading,$type,$filter) =@_; 
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
	# Leer radio button
	if($radiobutton1 -> get_active()){
 		#print "Se ha elegido accion 1.\n";
		exec("perl principal.pl");

 	} elsif ($radiobutton2 -> get_active()){
		#print "Se ha elegido accion 2.\n";
		if ($radiobutton01 -> get_active()){
			#print "Se ha elegido firma md5.\n";
			exec("perl verificar.pl $direccionsalida md5");
		} elsif ($radiobutton02 -> get_active()) {
			#print "Se ha elegido firma sha1.\n";
			exec("perl verificar.pl $direccionsalida sha1");
		}

	} elsif ($radiobutton3 -> get_active()){
		#print "Se ha elegido accion 3.\n";	
		if ($numimgs =~ "2x2"){
			exec("perl visorimagenes2x2.pl $direccionsalida");
		} elsif ($numimgs =~ "3x3"){
			exec("perl visorimagenes3x3.pl $direccionsalida");
		} elsif ($numimgs =~ "4x4") {
			exec("perl visorimagenes4x4.pl $direccionsalida");
		}
	} elsif ($radiobutton4 -> get_active()){
		#print "Se ha elegido accion 4.\n";
		exec("perl visoreventos.pl $direccionsalida");
	}
	
	exit 0;
	
}


