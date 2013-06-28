#!/usr/local/bin/perl

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

sub juntarFicheros
{
	my @files =  < *>;		#Recogemos todos los ficheros
	foreach my $log (@files) {	#Recorremos log a log
		my $ext1 = (split /\./, $log)[-1]; ## miramos si es uno de los que acaba en log, para seguir
		my $ext2 = (split /\./, $log)[-2];	
		my $nombrefich = (split /\./, $log)[0];	
	
		if ($nombrefich =~ /syslog/){
			#Nada, porque lo vamos a seguir luego, es para no descartarlo en los siguientes
		} elsif ($ext1 !~ /log/){
			#print "El log $log no lo tomaremos por correcto.\n";
			next; # No es el que necesitamos, ya que es uno de los que contiene numeros
	   	} else {
			if ($ext2 !~ /$nombrefich/){
				next; #tiene una estructura como el Xorg.numero.log		
			}		
			#else print "El log $log lo tomaremos por correcto.\n";		
		}
	
		eval { $nombrefich = $nombrefich."*" } ;
		$my_file=$log;
		open(FICH,">>$log") || die("El fichero $log no se ha podido abrir.");
	
		#	my $i = `find -name $nombrefich | wc -l`; # Contamos las lineas, que son los ficheros que hay iguales
		my @ficheros = `find $dirlogs -name "$nombrefich" -print | sort`;
	
		foreach my $fichero (@ficheros){
			chop $fichero;
			#print "log: $log.\n";			
			#print "fichero: $fichero.\n"; 		
			my $ext = (split /\./, $fichero)[-1]; # miramos si es uno de los que acaba en log, para no seguir
			if ($ext =~ /log/){
				next; # No es el que necesitamos, ya que es el primer log
		   	}	
		
			open(LEER, $fichero);     	        # Open the file
			@lines = <LEER>;          			# Read it into an array
			close(LEER);              	      	# Close the file
			print FICH @lines;                  # Print the array
			 
			system("sudo rm $fichero");
			#print "eliminado el fichero $fichero\n";
		}
		close(FICH);

	}

}

sub transformarFicheros
{
	my $i = 0;
	my @files =  < *>;		#Recogemos todos los ficheros
	foreach my $log (@files) {	#Recorremos log a log

		#Abrimos el primer log
		open(LEER, $log);     	        # Open the file
		@lines = <LEER>;          		# Read it into an array
		close(LEER);              	    # Close the file

		#print "log: $log.\n";
	
		$linea = $lines[0];
		($mes,$dia,@resto) = split(' ',$linea);
		if ($mes =~ /Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec/){
		
			#Creamos CON OTRO NOMBRE------------------------------------------------------------
			my $ext = (split /\./, $log)[-1];
			my $nombrefich = (split /\./, $log)[0];
			eval { $nuevofich = $nombrefich."new.".$ext};
			
			system("rm $nuevofich");	 #borramos 
			system("touch $nuevofich"); #y Creamos el fichero en blanco acceso.txt;
			#Creamos CON OTRO NOMBRE------------------------------------------------------------
			open(ESCRIBIR, ">$nuevofich");
		
			my $year = `date +%Y`; #2012 para tener el año actual
			chop $year;	

			#print "Transformamos el fichero: $log.\n"; #--------------------------------
			foreach my $linea (@lines){
				chop $linea;
				$ant = $mes; # para que se pueda cambiar de año
				($mes,$dia,@resto) = split(' ',$linea);
				if (($ant =~ /Jan/)and($mes =~ /Dec/)){ $year = $year-1; }
				$month = &cambioMes($mes,$dia,$year);
				print ESCRIBIR "$month @resto\n";
			}

			#print "Terminamos de transformar.\n"; #--------------------
			close(ESCRIBIR);
		
			if ($i > 0) { system("rm $borrar"); print "Borrado: $borrar\n";	}		
			eval { $borrar = $nombrefich.".".$ext };
			$i++;
		} 

		# Else = Está bien, no hay que modificar nada
	}

}

sub arrayBidimensional{

	my @files = < *>;		#Recogemos todos los ficheros y hacemos un array bidimensional de todos los logs
	$i = 0;
	foreach $file (@files){
		open(LEER, $file);     	        # Open the file
		@log = <LEER>;          	# Read it into an array
		close(LEER);              	    # Close the file
	
		push @{ $logs[$i] }, @log;
		$acabado[$i]=0; #Hay datos para leer
		$i++;
	}
}


######################
# Programa principal #
######################

my $auxpdf;
# La idea es generar un log que contenga a todos , historicofinal.log
my $dact = `pwd`;
chomp $dact;

#Cogemos argumento
if ( $#ARGV == 1 ) { # El ultimo indice es 1, por lo tanto hay 2 elementos
	$direccionsalida = $ARGV[0];
	$firma = $ARGV[1];
} else {
	die "Error, se necesita dos argumento con la direccion de salida y firma\n";
}

## Poner esto al final de imagen.pl, pero antes probarlo aqui

eval { $destinodd = $direccionsalida."/Imagen/"."imagen.dd" };
eval { $destinomd5 = $destinodd.".txt" };	
eval { $destinosha1 = $destinodd.".txt" };
eval { $dircarving = $direccionsalida."/Carving/" };
eval { $dirlogs = $direccionsalida."/logs/" };
system("mkdir $dirlogs");


# Montamos la imagen, ya que la habiamos desmontado antes
system("sudo mkdir /mnt/imagen"); #Creamos la carpeta en la cual montaremos la imagen
system("sudo mount -t auto -o loop,ro $destinodd /mnt/imagen"); 
# Ahora esta montada la imagen en /mnt/imagen

# Y recogemos todos los logs y los depositamos en $dirlogs, que es en la carpeta de salida.
system("sudo find /mnt/imagen/var/log/ -name *.log -o -name *.gz -o -name \"wtmp*\" -o -name \"syslog*\" 2>/dev/null | xargs -I {} cp {} $dirlogs");

## Ahora hacer un fichero juntando todos los logs por orden, por si está compuesto de logs rotatorios
system("sudo find $dirlogs -name *.gz | xargs -I {} gunzip -df {}"); 

#ahora mismo solo existen los .log y .x.log
#recoger los que son iguales, hacer un foreach con cada fichero que hay y hacer lo siguiente con cada uno:

chdir($dirlogs); 		#Nos vamos a la carpeta de logs
eval { $dirwtmp = $dirlogs."wtmp" };
if (-e $dirwtmp){
	system("sudo last -f wtmp > wtmp.txt");
	system("sudo rm wtmp");
}	
#print "Eliminado el fichero $dirlog.\"wtmp\"\n";
	
&juntarFicheros(); ## usa esta funcion principal

## Ahora hacemos el lo de los ultimos accesos de los ficheros
eval { $todosfichs = $dirlogs."todosfichs.txt"} ;
eval { $accesos = $dirlogs."accesos.log" } ;

chdir($dirlogs); # Nos ponemos donde los logs
#system("rm nacceso.txt"); ?
#system("rm facceso.txt"); ?

system("find /mnt/imagen/ -print > nacceso.txt");
system("find /mnt/imagen/ -print0 | xargs -0 stat -c %y > facceso.txt"); # cambiar a direccion

#system("rm accesos.txt");	 #? no deberia de existir
system("touch accesos.txt"); #y Creamos el fichero en blanco acceso.txt

$longacceso = @facceso; # 10302 lineas, asi que en el for < $longacceso	

open(LEERN, "nacceso.txt");
open(LEERF, "facceso.txt");
@nacceso=<LEERN>;
@facceso=<LEERF>;
close(LEERN);
close(LEERF);

$file = "acceso.txt";	
open(ESCRIBIR, ">$file");
$i=0;
# 1970-01-01 01:00:00.000000000 +0100;/mnt/imagen/ <- antes
# 1970-01-01 01:00:00.000000000 Creacion/Modificacion de /mnt/imagen/ <- despues
foreach $na (@nacceso){
	chop $facceso[$i];
	($fecha, $hora, $nada) = split(" ", $facceso[$i]);
	@horaguay = split(/\./, $hora);
	print ESCRIBIR "$fecha $horaguay[0] Creacion/Modificacion de $na";
	$i++;
}

close(ESCRIBIR);

system("cat acceso.txt | sort > accesos.log"); # este esta ordenado y es el que usaremos
system("rm acceso.txt");
system("rm nacceso.txt");
system("rm facceso.txt");

# Ahora desmontamos y eliminamos la unidad /mnt/imagen que usamos para montar el dd
system("sudo umount /mnt/imagen"); 
system("sudo rmdir /mnt/imagen"); 

my ($lastfecha, $lasthora);
my $mayormayor=0;
my $salto=0;
$k=0;


#Borramos por si existe de un análisis anterior
system("touch historicofinal.log"); 
system("rm historicofinal.log 2>/dev/null");
my $year = `date +%Y`; #2012 para tener el año actual
chop $year;

# AQUI INSERTAMOS EL CAMBIO DE WTMP A FICHERO NORMAL # FECHA-HORA
eval { $wtmptxt = $dirlogs."wtmp.txt" };

if (-e $wtmptxt){
	@wtmp = `tac wtmp.txt`; # es la salida del cat pero revertida
	open(ESCRIBIR, ">wtmp.log");
	$i = 0;

	foreach my $linea (@wtmp){
		if ($i<=1) { $i++; next; } # Para quitar las dos primeras lineas que no valen para nada
		@tokenizer = split(' ',$linea);
		$user = $tokenizer[0];
		$mes = $tokenizer[-6];
		$dia = $tokenizer[-5];
		$hora1 = $tokenizer[-4];
		$logged = $tokenizer[-1];	
		eval { $hora2 = $hora1.":00" };	
		#print "[$i] user: $user, mes=$mes, dia=$dia, hora1=$hora1, logged=$logged\n";
		#sleep(1);	
		print ESCRIBIR "$mes $dia $hora2 $logged $user\n";	
		$i++;
	}
	close(ESCRIBIR);
}

# Ahora hay que transformar los ficheros que aparecen con el mes en nombre

&transformarFicheros();

system("rm $borrar 2>/dev/null"); # Eliminamos el último

#Ahora hay que coger todos los ficheros, y crear uno, poniendo la fecha más reciente
#Como seguimos en $dirlogs..
$eliminar = 0;
$aux = "";

my @files = < *>;		#Recogemos todos los ficheros y borramos los que no empiecen por la fecha
foreach my $log (@files){
	#print "A procesar: $log\n";
	if ($eliminar==1){
		#print "Eliminamos el aux = $aux.\n"; es el log anterior, en el caso de que haya que borrarlo
		system("rm $aux 2>/dev/null"); 
	}

	#Abrimos el primer log
	open(LEER, $log);     	        # Open the file
	@lines = <LEER>;          		# Read it into an array
	close(LEER);              	    # Close the fileg

	$linea = $lines[0];
	($fecha,@resto) = split(' ',$linea);

	if ($fecha =~ /((\d{4})-(\d{1,2})-(\d{1,2}))/ ){
		#print "El fichero $log tiene la estructura YYYY/MM/DD.\n"; # ó con M o D en vez de MM/DD
		$eliminar=0;
	} else {
		#print "El fichero $log no tiene la estructura YYYY/MM/DD.\n";
		$eliminar=1; # Lo preparamos para borrar en la proxima iteracion
	}
	$aux = $log;

}

#Eliminamos el último
if ($eliminar==1){
	#print "Eliminamos el aux = $aux.\n";
	system("rm $aux 2>/dev/null"); 
}

&arrayBidimensional();

#Recogida inicial de recientes
for $i ( 0 .. $#logs ) {
	$reciente[$i] = pop(@{$logs[$i]});
	#print "Reciente [inic] $i : $reciente[$i]"; #-- Mostrar en caso de duda, pero funciona
}

#Creamos el fichero historico final
system("touch historicofinal.log");
#BucleFinal --- No parara mientras hayan más lineas que poner
open(ESCRIBIR, ">historicofinal.log"); 
my $cuenta = &masLogs();
$ant = 0;
$antant =0;
print "El fichero final tendra: $cuenta líneas.\n";
while ($cuenta > 0) { # Implementar masLogs # Hace la suma de líneas por cada una.
	
	&actualizarRecientes(); #Hacemos de las líneas de reciente, el array fecha y horario	
	my $indice = &buscarMayorIndice; # Devuelve el índice del más reciente, hay que hacer split y tal.. ----- hacer
	#print "Indice mayor: $indice\n";
	#Escribimos en nuevo fichero el valor más reciente
	if ($salto==1){
		$salto=0;
		print ESCRIBIR "SALTO $files[$indice]\n";
	}
	if ($files[$indice] ne "")	{
		print ESCRIBIR "$files[$indice] ~> $reciente[$indice]"; #hacer uno del resto[$indice]
	}	
	#quitar el $files[$indice]:-> 
	################ antes: 	print ESCRIBIR "$files[$indice]: ~> $fecha[$indice] $horario[$indice]\n"; 
	
	$tamanio = @{$logs[$indice]};
	if ($tamanio == 0){
		$acabado[$indice]=1;
	} else {
		$reciente[$indice]= pop(@{$logs[$indice]});
	}
	
	#Recoger el nuevo valor en el indice indicado
	$antant = $ant;	
	$ant = $cuenta;			
	#$cuenta = &masLogs();
	$cuenta--;	
	#print "$cuenta\n";
	if ($antant == $cuenta) { goto END; }	
	if ($cuenta % 1000 == 0) { print "Cuenta = $cuenta\n"; }
}

END:

close(ESCRIBIR);

#Firmamos todos los ficheros finales
if ($firma == "md5") { 
	my @files =  < *>;
	foreach my $file (@files) {
		system("md5sum $file > $file.txt");
	}	
} elsif ($firma == "sha1") { 
	my @files =  < *>;
	foreach my $file (@files) {
		system("sha1sum $file > $file.txt");
	}
}

eval { $auxfich = $direccionsalida."/informe.tex" };	
eval { $auxpdf = $direccionsalida."/informe.pdf" };

#Miramos si ha sido creado antes el .tex
if (-e $auxpdf) { 
	print "Analisis realizado anteriormente.\n.\n"; 
	goto noEscribe; 

} else {
	if (-e $auxfich) { #existe el tex
		my $val = `cat $auxfich | tail -n 1`; # pillariamos el \end{document} si hemos acabado de escribir
		if ($val =~ /end{document}/) { 
			print "Analisis realizado anteriormente.\n.\n"; 
			goto noEscribe; 
		}
	}
}

open(FICH,">>$auxfich") || die("El fichero $auxfich no se ha podido abrir.");	
	
my $text = '
\section{Históricos}
Los históricos, con sus respectivas firmas, son los siguientes:
\begin{itemize}
';

print FICH "$text";

my @files = < *>;
foreach my $file (@files) {
	if ($file =~ /.txt/ ) { #Es una firma
		$actual = `cat $file`;
		$text = '\item';
		print FICH "$text $actual";
	}
}

$text = '\end{itemize}
';
print FICH "$text";

close(FICH);

noEscribe:


exit 0;

# Subrutinas # 
# ------------------------------------------------------------------------------------------------------------#
## Manejo fechas
sub mayorActual() {
	($lastyear,$lastmonth,$lastday) = split('-',$lastfecha); 
	($lasthora,$lastminuto,$lastsegundo) = split(':',$lasthora); 

	if ($year[$_[0]] > $lastyear) {
		return $_[0];
	} elsif ($year[$_[0]] < $lastyear) {
		return -1;
	} else {
		if ($month[$_[0]] > $lastmonth) {
			return $_[0];
		} elsif ($month[$_[0]] < $lastmonth) {
			return -1;
		} else {
		
			if ($day[$_[0]] > $lastday) {
				return $_[0];
			} elsif ($day[$_[0]] < $lastday) {
				return -1;
			} else {
				
				if ($hora[$_[0]] > $lasthora) {
					return $_[0];
				} elsif ($hora[$_[0]] < $lasthora) {
					return -1;
				} else {
					if ($minuto[$_[0]] > $lastminuto) {
						return $_[0];
					} elsif ($minuto[$_[0]] < $lastminuto) {
						return -1;
					} else {
						if ($segundo[$_[0]] > $lastsegundo) {
							return $_[0];
						} elsif ($segundo[$_[0]] < $lastsegundo) {
							return -1;
						} else {
							return -1; # por ejemplo
						}
					}
				}
			}
		}
	}
}

sub mayorFecha() {
	if ($_[0] == $_[1]) { return $_[0]; }	
	if ($year[$_[0]] > $year[$_[1]]) {
		return $_[0];
	} elsif ($year[$_[0]] < $year[$_[1]]) {
		return $_[1];
	} else {
		if ($month[$_[0]] > $month[$_[1]]) {
			return $_[0];
		} elsif ($month[$_[0]] < $month[$_[1]]) {
			return $_[1];
		} else {
		
			if ($day[$_[0]] > $day[$_[1]]) {
				return $_[0];
			} elsif ($day[$_[0]] < $day[$_[1]]) {
				return $_[1];
			} else {
				
				if ($hora[$_[0]] > $hora[$_[1]]) {
					return $_[0];
				} elsif ($hora[$_[0]] < $hora[$_[1]]) {
					return $_[1];
				} else {
					if ($minuto[$_[0]] > $minuto[$_[1]]) {
						return $_[0];
					} elsif ($minuto[$_[0]] < $minuto[$_[1]]) {
						return $_[1];
					} else {
						if ($segundo[$_[0]] > $segundo[$_[1]]) {
							return $_[0];
						} elsif ($segundo[$_[0]] < $segundo[$_[1]]) {
							return $_[1];
						} else {
							return $_[0]; # por ejemplo
						}
					}
				}
			}
		}
	}
}

#Pasa una línea básica: 2013/20/17 14:28 Wankestrah CRON[87] ... a separados por fecha/hora
sub actualizarRecientes{
	for $i ( 0 .. $#logs){ #i = linea última de los ficheros recientes
		($fecha[$i],$horario[$i],@resto) = split(' ',$reciente[$i]);
		#Prueba 1 print "[Actualizar recientes]: fecha i = $fecha[$i]\n"; 
		###print "Reciente [sub] $i : $reciente[$i]"; #-- Mostrar en caso de duda, pero funciona
		#Prueba 3 print "fecha $i : $fecha[$i].\n";
		while ($fecha[$i] !~ /((\d{4})-(\d{1,2})-(\d{1,2}))/ ){ #Por si hay alguna línea jodida
			print "fecha = $fecha[$i], no es correcta, cogemos otra (fichero $i).\n";
			$reciente[$i] = pop(@{$logs[$i]}); 
			($fecha[$i],$horario[$i],@resto) = split(' ',$reciente[$i]);	
		}
	
	}
	#Ahora tenemos la hora y fecha en array en la misma posición de índice
}

#Inicializamos las fechas para todos los más recientes
sub inicializaFechas(){ 
	for $i ( 0 .. $#fecha ){
		($year[$i],$month[$i],$day[$i]) = split('-',$fecha[$i]); 
		#print "[inicializaFechas]: year i = $year[$i]\n";
		($hora[$i],$minuto[$i],$segundo[$i]) = split(':',$horario[$i]); 
	}
}

#Comparamos dos a dos para ver cual es el mayor (Incluye a inicializaFechas())
sub buscarMayorIndice(){

	&inicializaFechas();
	$mayor = 0; #contendrá el índice del número más reciente, 0 para empezar
	while ($acabado[$mayor]==1){ $mayor++; }
	for $i ( 1 .. $#fecha ){
			if ($acabado[$i]==1){ next; }
			$mayor = &mayorFecha($mayor,$i);
	}

	if ($k > 0){ #Ya no es el primer valor
		$mayormayor=&mayorActual($mayor);
		#print "mayor mayor: $mayormayor\n";
		#print "mayor: $mayor\n";
		if ($mayormayor!=-1){ #$salto=1; 
			$salto=1;		
		}
	}
	$k++;
	$lasthora=$horario[$mayor];
	$lastfecha=$fecha[$mayor];
	return $mayor; #Esta es la mayor fecha
}

#Cambiar de Jan - a 01
sub cambioMes ## $_[0]=mes, $_[1]=dia, $_[2]=year
{
	if ($_[0] =~ /Jan/){
		$fecha[0] = "$_[2]-01-$_[1]";
		$fecha[1] = `date --rfc-3339=date`;

		$may=&mayorFecha(0,1);
		
		if ($may==1){ #El año es correcto
			return "$_[2]-01-$_[1]";
		} else {
			$nyear= $_[2]-1;
			return "$nyear-01-$_[1]";
		}

	} elsif ($_[0] =~ /Feb/){
		$fecha[0] = "$_[2]-02-$_[1]";
		$fecha[1] = `date --rfc-3339=date`;

		$may=&mayorFecha(0,1);
		
		if ($may==1){ #El año es correcto
			return "$_[2]-02-$_[1]";
		} else {
			$nyear=$_[2]-1;
			return "$nyear-02-$_[1]";
		}

	} elsif ($_[0] =~ /Mar/){
		$fecha[0] = "$_[2]-03-$_[1]";
		$fecha[1] = `date --rfc-3339=date`;

		$may=&mayorFecha(0,1);
		
		if ($may==1){ #El año es correcto
			return "$_[2]-03-$_[1]";
		} else {
			$nyear=$_[2]-1;
			return "$nyear-03-$_[1]";
		}

	} elsif ($_[0] =~ /Apr/){
		$fecha[0] = "$_[2]-04-$_[1]";
		$fecha[1] = `date --rfc-3339=date`;

		$may=&mayorFecha(0,1);
		
		if ($may==1){ #El año es correcto
			return "$_[2]-04-$_[1]";
		} else {
			$nyear=$_[2]-1;
			return "$nyear-04-$_[1]";
		}

	} elsif ($_[0] =~ /May/){
		$fecha[0] = "$_[2]-05-$_[1]";
		$fecha[1] = `date --rfc-3339=date`;

		$may=&mayorFecha(0,1);
		
		if ($may==1){ #El año es correcto
			return "$_[2]-05-$_[1]";
		} else {
			$nyear=$_[2]-1;
			return "$nyear-05-$_[1]";
		}
	
	} elsif ($_[0] =~ /Jun/){        
		$fecha[0] = "$_[2]-06-$_[1]";
		$fecha[1] = `date --rfc-3339=date`;

		$may=&mayorFecha(0,1);
		
		if ($may==1){ #El año es correcto
			return "$_[2]-06-$_[1]";
		} else {
			$nyear=$_[2]-1;
			return "$nyear-06-$_[1]";
		}
	
	} elsif ($_[0] =~ /Jul/){
		$fecha[0] = "$_[2]-07-$_[1]";
		$fecha[1] = `date --rfc-3339=date`;

		$may=&mayorFecha(0,1);
		
		if ($may==1){ #El año es correcto
			return "$_[2]-07-$_[1]";
		} else {
			$nyear=$_[2]-1;
			return "$nyear-07-$_[1]";
		}

	} elsif ($_[0] =~ /Aug/){
		$fecha[0] = "$_[2]-08-$_[1]";
		$fecha[1] = `date --rfc-3339=date`;

		$may=&mayorFecha(0,1);
		
		if ($may==1){ #El año es correcto
			return "$_[2]-08-$_[1]";
		} else {
			$nyear=$_[2]-1;
			return "$nyear-08-$_[1]";
		}

	} elsif ($_[0] =~ /Sep/){
		$fecha[0] = "$_[2]-09-$_[1]";
		$fecha[1] = `date --rfc-3339=date`;

		$may=&mayorFecha(0,1);
		
		if ($may==1){ #El año es correcto
			return "$_[2]-09-$_[1]";
		} else {
			$nyear=$_[2]-1;
			return "$nyear-09-$_[1]";
		}

	} elsif ($_[0] =~ /Oct/){
		$fecha[0] = "$_[2]-10-$_[1]";
		$fecha[1] = `date --rfc-3339=date`;

		$may=&mayorFecha(0,1);
		
		if ($may==1){ #El año es correcto
			return "$_[2]-10-$_[1]";
		} else {
			$nyear=$_[2]-1;
			return "$nyear-10-$_[1]";
		}

	} elsif ($_[0] =~ /Nov/){
		$fecha[0] = "$_[2]-11-$_[1]";
		$fecha[1] = `date --rfc-3339=date`;

		$may=&mayorFecha(0,1);
		
		if ($may==1){ #El año es correcto
			return "$_[2]-11-$_[1]";
		} else {
			$nyear=$_[2]-1;
			return "$nyear-11-$_[1]";
		}

	} elsif ($_[0] =~ /Dec/){
		$fecha[0] = "$_[2]-12-$_[1]";
		$fecha[1] = `date --rfc-3339=date`;

		$may=&mayorFecha(0,1);
		
		if ($may==1){ #El año es correcto
			return "$_[2]-12-$_[1]";
		} else {
			$nyear=$_[2]-1;
			return "$nyear-12-$_[1]";
		}	
	}
     
}

#Nos devuelve las líneas que quedan por ordenar
sub masLogs {
	$cuenta = 0;
	for $x (0 .. $#logs)
	{
	  #foreach $y (@{$logs[$x]})
	  $tam = @{$logs[$x]};
	  for $y (0 .. $tam)
	  {
		$cuenta++;
	  }
	} 	

	return $cuenta;
}


