##############################################
# $Id: myUtilsTemplate.pm 21509 2020-03-25 11:20:51Z rudolfkoenig $
#
# Save this file as 99_myUtils.pm, and create your own functions in the new
# file. They are then available in every Perl expression.

package main;

use strict;
use warnings;
use POSIX;



sub
myUtils_Initialize($$)
{
  my ($hash) = @_;
  return;
}


#Master-Function, ruft alle Funktionen auf, die initial beim Hinzufügen des Geräts aufgerufen werden sollen
sub addStock($){
	my ($deviceName) = @_;
	addDevice($deviceName);
	addAttributes($deviceName);
	create_Logfile("./log/$deviceName-%d-%m-%Y.log", 3, "Filelog für $deviceName created", "$deviceName");
	
	return "$deviceName wurde hinzugefügt";


}

#Fügt leeres Aktiengerät hinzu
sub addDevice($){
	my ($deviceName) = @_;
	
	fhem("define $deviceName HTTPMOD https://www.finanzen.net/suchergebnis.asp?_search=$deviceName 600");

	
	return undef;


}


#Fügt Attribute und Readings hinzu
sub addAttributes($){
	my ($deviceName) = @_;
	
	
	fhem("attr $deviceName room Aktien");
	
	#Regex für den Name der Aktie
	fhem("attr $deviceName reading01Name Name");
	fhem("attr $deviceName reading01Regex <h1 class=.font-resize.>([\\w\\W]{2,50}).Aktie");
	
	
	#Regex für den Kurs der Aktie
	fhem("attr $deviceName reading02Name Price");
	fhem("attr $deviceName reading02Regex class=.col-xs-5 col-sm-4 text-sm-right text-nowrap.>([\\d\\W].{1,15})<span>EUR");
	
	
	#Regex für die relative Veränderung
	fhem("attr $deviceName reading03Name RelativeChange");
	fhem("attr $deviceName reading03Regex EUR.{1,18}<div class=.col-xs-3.col-sm-3.text-right.text-nowrap[\\w\\W]{0,50}.>(.\\d*\\S\\d*)<span>%");
	
	
	fhem("attr $deviceName stateFormat Name: Price €");
	
	#Regex für die absolute Veränderung
	fhem("attr $deviceName reading04Name AbsolutChange");
	fhem("attr $deviceName reading04Regex class=.col-xs-4.col-sm-3.text-sm-right.text-nowrap.text-center[\\w\\W]{0,50}.>(.\\d*\\S\\d*).{1,20}EUR");
	
	
	#Funktionsaufruf für das Speichern des ersten Aktienkurses als Attribut
	getFirstPrice($deviceName);
	return undef;
	
	}

#Ermittelt den initialen Preis beim Hinzufügen der Aktie
sub getFirstPrice($){
	my ($deviceName) = @_;
	
	if (ReadingsVal($deviceName, "Price", "NotFound") eq "NotFound"){
	
	InternalTimer(gettimeofday()+10, "getFirstPrice", $deviceName);
	
	} else {
	
	my $first_price = ReadingsVal($deviceName, "Price", "NotFound");
	addToDevAttrList($deviceName, "FirstPrice");
	fhem("attr $deviceName FirstPrice $first_price");
	}


}

#Ermittelt die Kontakte, welche benachrichtigt werden
sub ExtractContacts($$){
	my ($deviceName, $message) = @_;

	my $contactsAttr = AttrVal($deviceName, "Contacts","NotFound");
	my @contacts = split(/,/, $contactsAttr);
	#my $string = fhem("set telebot msg \@\@"."@contacts[$i] $message");

	my @result;
	my $string;

	for (my $i=0; $i< @contacts; $i++) {
	push @result, fhem("set telebot msg \@@contacts[$i] $message\n");

}

return "@result";
}


#Ermittelt die Aktien, welche in FHEM angelegt sind
sub getStocks(){
	my (@stocks) = defInfo('TYPE=HTTPMOD:FILTER=room=Aktien', 'NAME'); 
	my $json_str = encode_json(\@stocks);
	return $json_str;
}

#Erstellt ein FileLog pro Aktiengerät und füllt es mit den jeweiligen Kursdaten
sub create_Logfile($$$$){
	 my ($filename, $loglevel, $text, $deviceName) = @_;
	 
	 
	#Werte in das FileLog schreiben
    return if ($loglevel > AttrVal('global', 'verbose', 3));

    my ($seconds, $microseconds) = gettimeofday();
    my @t = localtime($seconds);
    my $nfile = ResolveDateWildcards($filename, @t);

    my $tim = sprintf("%04d.%02d.%02d %02d:%02d:%02d", $t[5] + 1900, $t[4] + 1, $t[3], $t[2], $t[1], $t[0]);
    if (AttrVal('global', 'mseclog', 0)) {
        $tim .= sprintf(".%03d", $microseconds / 1000);
    }

    open(my $fh, '>>', $nfile);
    print $fh "$tim $loglevel: $text\n";
    close $fh;
	
	
	#Filelog Datei anlegen
	fhem("define FileLog_$deviceName FileLog ./log/$deviceName-%Y.log $deviceName:(Price).*");
	fhem("attr FileLog_$deviceName logtype text");
	fhem("attr FileLog_$deviceName room Aktien");
	
	
    return undef;

	
}

#Löscht das Aktiengrät
sub deleteStock($){
	my ($deviceName) = @_;
	fhem("delete $deviceName");
	fhem("set FileLog_$deviceName clear");
	fhem("delete FileLog_$deviceName");
	
	return undef;
}

 
#legt die Attribute für die Werteveränderung, das Zeitintervall und die jeweiligen Kontakte an
sub sendNotificationDefine($$$$){
	my ($deviceName, $changeTime, $changePercent, $contacts) = @_;
	
	addToDevAttrList($deviceName, "ChangeTime");
	addToDevAttrList($deviceName, "ChangePercent");
	addToDevAttrList($deviceName, "Contacts");
	
	fhem("attr $deviceName ChangeTime $changeTime");
	fhem("attr $deviceName ChangePercent $changePercent");
	fhem("attr $deviceName Contacts $contacts");
	
	return sendNotification($deviceName);

}	

# Enthält die Logik für das Versenden einer Nachricht
sub sendNotification($){

	my ($deviceName) = @_;
	
	#Werte auslesen
	my $input = AttrVal($deviceName, "ChangeTime","NotFound");
	my $change_relative = AttrVal($deviceName, "ChangePercent","NotFound");
	my $first_price = AttrVal($deviceName, "FirstPrice","NotFound");
	my $stock_name = ReadingsVal($deviceName, "Name", "NotFound");
	
	
	#Zeiten in Sekunden umrechnen
	my $time_input = ($input * 60 * 60) - (10*60);
	my $time_input_2 = $time_input - 600;
	my $timestamp = OldTimestamp("$deviceName");
	my $ts_seconds = time_str2num($timestamp);
	my $last_price=0;
	
	#Hilfsvariable
	my $search_last_price = 1;
	
	#Daten aus dem FileLog anfordern
	my $time1 = POSIX::strftime("%Y-%m-%d_%H:%M:%S",localtime($ts_seconds-($input*60*60)));
	my $time2 = POSIX::strftime("%Y-%m-%d_%H:%M:%S",localtime($ts_seconds-$time_input));
	
	 
	 my $result = fhem("get FileLog_$deviceName - - $time1 $time2");
	 
	 #Aktienkurs durch ein Regex extrahieren
     my $regex = qr/20.{0,50}.[PriceKurs].([\d\W].{1,15})/mp;
	 
	 

		if ( $result =~ /$regex/ ) {
		
		$last_price = $1;
		}
		
		
	#Fall behandeln, falls noch keine Logeinträge vorhanden sind
	 
	 if ("$last_price" eq "0") {
	 
		$search_last_price = 0;
		$last_price = $first_price;
		}
	
	# Ermittlung des aktuellen Kurses und Umrechnung
	my $current_price = ReadingsVal("$deviceName", "Price", "NotFound");
	
	
	# Punkte bei 4Stelligen Akteinkursen entfernen
	my $replacement = qr/\./p;
    my $subst = ''; 
	$current_price = $current_price =~ s/$replacement/$subst/r;
	
	$replacement = qr/\./p;
    $subst = ''; 
	$last_price = $last_price =~ s/$replacement/$subst/r;
	
	#Komma in Punkte umwandeln, damit die Rechnung programmseitig durchgeführt werden kann
	$current_price =~ tr/,/./;
	$last_price =~ tr/,/./;
	my $rounded;
	my $print;
	
	
	#Logik für Push-Notification
	if ($last_price != $current_price) {
		
		my $difference_relative = (($last_price/$current_price)-1) * (-100);
		$rounded = int(100 * $difference_relative + 0.5) / 100;
		$print = $rounded . '%';
		#Log3 $deviceName, 3, "$print";
		
		}
		
		
		if ($rounded >= $change_relative) {
			
			if ($search_last_price == 0) {
			
			ExtractContacts($deviceName, "Es fehlen Referenzdaten zum angegebenen Zeitintervall. 
										  Daher dient der Startpreis der $stock_name in Höhe von $first_price€ als Vergleichswert\n 
										  Der Kurs für $stock_name ist zum Startpreis um $print gestiegen");
			}
			
			else {
			
			ExtractContacts($deviceName, "Der Kurs für $stock_name ist in den letzten $input h um $print auf $current_price€ gestiegen");
	
			}
		}
		
		elsif ($rounded < 0 and $rounded <= ($change_relative)*(-1)){
		
			if ($search_last_price == 0) {
			
			ExtractContacts($deviceName, "Es fehlen Referenzdaten zum angegebenen Zeitintervall. 
										  Daher dient der Startpreis der $stock_name in Höhe von $first_price€ als Vergleichswert\n 
										  Der Kurs für $stock_name ist zum Startpreis um $print gefallen");
											
					}
			
			else {
			
			ExtractContacts($deviceName, "Der Kurs für $stock_name ist in den letzten $input h um $print auf $current_price€ gefallen");
	
			}
		}
	
	#Timer für Wiederaufruf der Funktion
	InternalTimer(gettimeofday()+7200, "sendNotification", $deviceName);
	
	if ($search_last_price == 0) {
	
	return "Wertevedänderung seit Hinzufügen der Aktie: $print";
	
	} else {
	
	return "Wertevedänderung im angegebenen Zeitintervall: $print";
	}
	
	
	
}

#löscht die Attribute
sub deleteNotify($){
	my ($deviceName) = @_;
	
	fhem("deleteattr $deviceName ChangePercent");
	fhem("deleteattr $deviceName ChangeTime");
	fhem("deleteattr $deviceName Contacts");
	
	return undef;
}

#Ermittelt alle Logeinträge der jeweiligen Aktie
sub getLogs($$){
	my ($deviceName, $datetime) = @_;
	my $logs = fhem("get FileLog_$deviceName - - $datetime 2030-10-01_16:00:00");
	return $logs;
}
1;