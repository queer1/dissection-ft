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

use Gtk2 '-init';
use Glib qw/TRUE FALSE/; 

my $dactual=`pwd`;
chomp $dactual;

my @aux;

my $window = Gtk2::Window->new('toplevel');
$window->signal_connect('destroy' => sub { Gtk2->main_quit; return FALSE;});
$window->signal_connect('delete_event' => sub { $_[0]->destroy; });
$window->set_border_width(10);
$window->set_position('center_always');
$window->set_title('Dissection');
$window->set_default_size(400, 200);


#Preparación de widgets
my $vbox = Gtk2::VBox->new(FALSE,5);
my $label1 = Gtk2::Label->new("Seleccione idioma / Choose the language:");
$label1->set_alignment(0.0, 0.0);
	
# Botones #
my $button1 = Gtk2::Button->new("_Castellano");
my $button2 = Gtk2::Button->new("_English");
my $button3 = Gtk2::Button->new("_Salir / Exit");

$button1->signal_connect('clicked' => \&spanish);
$button2->signal_connect('clicked' => \&english);
		
$button3->signal_connect('clicked' => sub { Gtk2->main_quit; });

#Empaquetado de widgets
$vbox->pack_start($label1,TRUE,TRUE,0);
$vbox->pack_start($button1,TRUE,TRUE,0);
$vbox->pack_start($button2,TRUE,TRUE,0);
$vbox->pack_start($button3,TRUE,TRUE,0);

$window->add($vbox);
$window->show_all();

Gtk2->main();


sub spanish{
	$window->hide();
	chdir("SpanishVersion");
	exec("perl menu.pl");
	
	exit 0;
}

sub english{
	$window->hide();
	chdir("EnglishVersion");
	exec("perl menu_en.pl");

	exit 0;
}


