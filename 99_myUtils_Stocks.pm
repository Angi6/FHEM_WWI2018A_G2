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

# Enter you functions below _this_ line.
sub addDevice($){
	my ($deviceName) = @_;
	
	if (!(IsWe())) {
	
	fhem("define $deviceName HTTPMOD https://www.finanzen.net/suchergebnis.asp?_search=$deviceName 600");
	
	} 
	else {
	 fhem("define $deviceName HTTPMOD https://www.finanzen.net/suchergebnis.asp?_search=$deviceName 43200");
	
	}

	
	
	return undef;


}
# returns pointer to device

#sub updateDevice($);
# returns pointer to updated device, or log message

sub addAttributes($){
	my ($deviceName) = @_;
	
	#fhem("attr $deviceName event-on-change-reading state);
	
	
	fhem("attr $deviceName room Aktien");
	
	#Regex für Name
	fhem("attr $deviceName reading01Name Name");
	fhem("attr $deviceName reading01Regex <h1 class=.font-resize.>([\\w\\W]{2,50}).Aktie");
	
	
	#Regex für den Kurs
	fhem("attr $deviceName reading02Name Price");
	fhem("attr $deviceName reading02Regex class=.col-xs-5 col-sm-4 text-sm-right text-nowrap.>([\\d\\W].{1,15})<span>EUR");
	
	
	#Regex für die Veränderung
	fhem("attr $deviceName reading03Name RelativeChange");
	fhem("attr $deviceName reading03Regex EUR.{1,18}<div class=.col-xs-3.col-sm-3.text-right.text-nowrap[\\w\\W]{0,50}.>(.\\d*\\S\\d*)<span>%");
	
	
	fhem("attr $deviceName stateFormat Name: Price €");
	
	
	#Log3 $deviceName, 3, "$change_rel";
	
	#Veränderung absolut
	fhem("attr $deviceName reading04Name AbsolutChange");
	fhem("attr $deviceName reading04Regex class=.col-xs-4.col-sm-3.text-sm-right.text-nowrap.text-center[\\w\\W]{0,50}.>(.\\d*\\S\\d*).{1,20}EUR");
	
	getFirstPrice($deviceName);
	return undef;
	
	}

# returns value array from given wkn

sub addStock($){
	my ($deviceName) = @_;
	addDevice($deviceName);
	addAttributes($deviceName);
	create_Logfile("./log/$deviceName-%d-%m-%Y.log", 3, "Filelog für $deviceName created", "$deviceName");
	
	
	
	
	
	return "$deviceName wurde hinzugefügt";


}

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

sub TestContacts(){


my @contactarray = contacts();
my $length = @contactarray;
my @result;

for(my $i = 0;$i < $length;$i ++) {
push @result, "\@\@"."@contactarray[$i]";

fhem ("set telebot msg Test");

}

return "@result";

#foreach (@contactarray){

#return "@contactarray\n";
}



sub getStocks(){
	my (@stocks) = defInfo('TYPE=HTTPMOD:FILTER=room=Aktien', 'NAME'); 
	my $json_str = encode_json(\@stocks);
	return $json_str;
}

sub create_Logfile($$$$){
	 my ($filename, $loglevel, $text, $deviceName) = @_;

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

sub deleteStock($){
	my ($deviceName) = @_;
	fhem("delete $deviceName");
	fhem("set FileLog_$deviceName clear");
	fhem("delete FileLog_$deviceName");
	
	return undef;
}

sub sendNotificationDefine($$$){
	my ($deviceName, $changeTime, $changePercent) = @_;
	
	addToDevAttrList($deviceName, "ChangeTime");
	addToDevAttrList($deviceName, "ChangePercent");
	
	fhem("attr $deviceName ChangeTime $changeTime");
	fhem("attr $deviceName ChangePercent $changePercent");
	
	return sendNotification($deviceName);

}

sub GetFirstLog($) {
 	my ($deviceName) = @_;
 
	
	my $timestamp = OldTimestamp("$deviceName");
	my $ts_seconds = time_str2num($timestamp);
	my $last_price;
	
	#hier oldtimestamp Funktion verwenden anstelle von localtime
	my $input = 24;
	my $time_input = ($input * 60 * 60) - (10*60);
	my $time1 = POSIX::strftime("%Y-%m-%d_%H:%M:%S",localtime($ts_seconds-($input*60*60)));
	my $time2 = POSIX::strftime("%Y-%m-%d_%H:%M:%S",localtime($ts_seconds-$time_input));
	 
	 my $result = fhem("get FileLog_$deviceName - - $time1 $time2");
	 
     my $regex = qr/20.{0,50}.[PriceKurs].([\d\W].{1,15})/mp;
	 
	 my $first_price = AttrVal($deviceName, "FirstPrice","NotFound");
	 
	 

		if ( $result =~ /$regex/ ) {
		
		$last_price = $1;
		}
		
		if ("$last_price" eq "") {
		
		return $last_price=$first_price;
		}
		
	
		else {	
		return $last_price;
		}
		}
		
		
	 
	# my @resultarray = $first_price;
	 
	 #if ("@resultarray" eq ""){
	 ##
	 #return "IsEmpty";
	 #}
	 #else {
	 
	 
	# }
	 
	# return @resultarray;
	
 

sub TestPrice($){

	my ($deviceName) = @_;
	my $current_price = ReadingsVal("$deviceName", "Price", "NotFound");
	my $last_price ="2.699,00";
	
	my $replacement = qr/\./p;
    my $subst = ''; 
	$current_price = $current_price =~ s/$replacement/$subst/r;
	
	$replacement = qr/\./p;
    $subst = ''; 
	$last_price = $last_price =~ s/$replacement/$subst/r;
	#$current_price =~ tr/.//;
	
	
	
	
	$last_price =~ tr/,/./;
	
	return $current_price;

}



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
	 
     my $regex = qr/20.{0,50}.[PriceKurs].([\d\W].{1,15})/mp;
	 
	 

		if ( $result =~ /$regex/ ) {
		
		$last_price = $1;
		}
		
	#Fall behandeln, falls noch keine Logeinträge vorhanden sind
	
	print "Das ist $last_price";
	
	 
	 if ("$last_price" eq "0") {
	 
		#print"Ich bin in das if gegangen";
		#$first_price = "90,66";
		$search_last_price = 0;
		$last_price = $first_price;
		}
	
	# Ermittlung des aktuellen Kurses und Umrechnung
	my $current_price = ReadingsVal("$deviceName", "Price", "NotFound");
	
	
	#Fall bei 4Stelligen Akteinkursen
	my $replacement = qr/\./p;
    my $subst = ''; 
	$current_price = $current_price =~ s/$replacement/$subst/r;
	
	$replacement = qr/\./p;
    $subst = ''; 
	$last_price = $last_price =~ s/$replacement/$subst/r;
	
	#Default Fall
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
			
			#$message = "Angela";
			fhem("set telebot msg \@Angela Kurs für $stock_name ist in den letzten $input h um $print gestiegen");
			#fhem("set telebot msg \@#SmartWifi_FHEM Kurs für $stock_name ist in den letzten $input h um $print gestiegen");
			print "Nachricht für Kurs gestiegen";
		}
		
		elsif ($rounded < 0 and $rounded <= ($change_relative)*(-1)){
			
			#$message = "@@Angela";
			fhem("set telebot msg \@Angela Kurs für $stock_name ist in den letzten $input h um $print gefallen");
			#fhem("set telebot msg \@#SmartWifi_FHEM Kurs für $stock_name ist in den letzten $input h um $print gefallen");
			print "Nachricht für: Kurs gefallen";
		}
		
		
	else {
			
	 print "Du solltest keine Nachricht bekommen";
	 fhem("set telebot msg \@Angela Keine Nachricht bekommen");
	 
		}
	
	#Timer für Wiederaufruf der Funktion
	InternalTimer(gettimeofday()+7200, "sendNotification", $deviceName);
	
	if ($search_last_price == 0) {
	
	return "Wertevedänderung seit Hinzufügen der Aktie: $print";
	
	} else {
	
	return "Wertevedänderung im angegebenen Zeitintervall: $print";
	}
	
	
	
}


sub contacts(){

	my $contacts = ReadingsVal("telebot", "Contacts", "No Contact Found");


	my $regex = qr/@(\w*)/mp;
	my @matches = ($contacts =~ /$regex/g);

		
	return @matches;


}

sub addAtDevice($$$){
	my($deviceName, $hours, $percentage) = @_;
	my $borderTime = time();
	my $name = "at_" . "$deviceName" . "_" . "$hours" . "_" . "$percentage";
	
	fhem("define $name at +*02:00:00 {sendNotificationFunction(\"$deviceName\", \"$hours\", \"$percentage\", \"$borderTime\")}");
	fhem("attr $name room Aktien");
	
	return undef;
}

sub sendNotificationFunction($$$$){
	my ($deviceName, $hours, $percentage, $borderTime) = @_;
	my ($currentTime);
	my ($targetTime);
	my ($before);
	my (@valString);
	my ($val);
	my ($minChange);
	my ($maxChange);
	
	$before = time() - ($hours*60*60);
	$currentTime = strftime( '%Y-%m-%d_%H:%M:%S', localtime);
	
	if($before > $borderTime){
		$targetTime = strftime( '%Y-%m-%d_%H:%M:%S', localtime($before));
	} else {
		$targetTime = strftime( '%Y-%m-%d_%H:%M:%S', localtime($borderTime));
	}
	
	
	my $logs = fhem("get FileLog_$deviceName - - $targetTime $currentTime");
	my @logsString = split "\n", $logs;
	my $length = @logsString;
	
	my @lastValString = split(/ /,@logsString[$length - 1]);
	my $lastVal = @lastValString[3];
	$lastVal =~ tr/,/./;
	
	
	
	for(my $i = 0; $i < $length - 1; $i++){
		@valString = split(/ /,@logsString[$i]);
		$val = @valString[3];
		$val =~ tr/,/./;
		
		$minChange = $val * (1 - $percentage / 100);
		$maxChange = $val * (1 + $percentage / 100);
		
		if($lastVal <= $minChange || $lastVal >= $maxChange ){
			return "Klappt";
		}
	}
	
	return "Klappt auch";
}

sub getLogs($$){
	my ($deviceName, $datetime) = @_;
	my $logs = fhem("get FileLog_$deviceName - - $datetime 2030-10-01_16:00:00");
	return $logs;
}
#Fn-call addDevice(WKN)
#Fn-call FinanzenNetHttpMod(WKN)
#FN-call updateDevidce();
1;