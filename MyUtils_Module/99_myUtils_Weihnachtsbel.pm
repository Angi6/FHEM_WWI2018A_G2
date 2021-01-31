##############################################
# $Id: myUtilsTemplate.pm 21509 2020-03-25 11:20:51Z rudolfkoenig $
#
# Save this file as 99_myUtils.pm, and create your own functions in the new
# file. They are then available in every Perl expression.

package main;

use strict;
use warnings;
use POSIX 'strftime';

sub
myUtils_Initialize($$)
{
  my ($hash) = @_;
}

# Enter you functions below _this_ line.
# Betriebsmodus für spätere Ausführung setzen
sub
betriebsmodus_setzen{

	my ($betriebsmodus) = @_;
# Großbuchstaben um Eingabe zu vereinheitlichen	
	$betriebsmodus = uc($betriebsmodus);

# Je nach angegebenem Betriebsmodus den status des passenden dummy devices setzen
	if ($betriebsmodus eq "DAEMMERUNG_FUNK"){
		fhem("set d_betriebsmodus_funk DAEMMERUNG;");
	}
	elsif ($betriebsmodus eq "AUTOMATIK_FUNK"){
		fhem("set d_betriebsmodus_funk AUTOMATIK;");
	}
	elsif ($betriebsmodus eq "ANWESENHEIT_FUNK"){
		fhem("set d_betriebsmodus_funk ANWESENHEIT;");
	}
	elsif ($betriebsmodus eq "MIX_FUNK"){
		fhem("set d_betriebsmodus_funk MIX;");
	}
	elsif ($betriebsmodus eq "MANUELL_FUNK"){
		fhem("set d_betriebsmodus_funk MANUELL;");
	}
	
	if ($betriebsmodus eq "DAEMMERUNG_WLAN"){
		fhem("set d_betriebsmodus_wlan DAEMMERUNG;");
	}
	elsif ($betriebsmodus eq "AUTOMATIK_WLAN"){
		fhem("set d_betriebsmodus_wlan AUTOMATIK;");
	}
	elsif ($betriebsmodus eq "ANWESENHEIT_WLAN"){
		fhem("set d_betriebsmodus_wlan ANWESENHEIT;");
	}
	elsif ($betriebsmodus eq "MIX_WLAN"){
		fhem("set d_betriebsmodus_wlan MIX;");
	}
	elsif ($betriebsmodus eq "MANUELL_WLAN"){
		fhem("set d_betriebsmodus_wlan MANUELL;");
	}
# Ausgewählten Betriebsmodus ausführen	
	betriebsmodus_ausfuehren($betriebsmodus);
}

sub
betriebsmodus_ausfuehren{

	my ($betriebsmodus) = @_;
	
	$betriebsmodus = uc($betriebsmodus);
	
	my $time_current;
	
# Aktuellen Zeitstempel festhalten	
	$time_current = POSIX::strftime('%X', localtime);
	
	my $time_device_on;
	my $time_device_off;

# Je nachdem, welcher Betriebsmodus für die Funksteckdose ausgeführt werden soll, 
# müssen die passenden ats bzw. DOIFs aktiviert/deaktiviert werden
	if (index ($betriebsmodus,'FUNK') != -1){
	
		if (ReadingsVal("d_betriebsmodus_funk", "state","") eq "DAEMMERUNG"){
			#sonne_enable
			fhem("attr Funksteckdose_SUNR_OFF disable 0; attr Funksteckdose_SUNS_ON disable 0;");
			#automatik_disable
			fhem("attr Funksteckdose_AUTO_OFF disable 1; attr Funksteckdose_AUTO_ON disable 1;");
			#anwesenheit_disable
			fhem("attr Funksteckdose_ANWS disable 1;");
			#mix_disable
			fhem("attr Funksteckdose_MIX_OFF disable 1;");
			
			# Zeitstempel der nächsten AN und AUS Schaltvorgänge festhalten
			$time_device_on = substr(ReadingsVal("Funksteckdose_SUNS_ON", "state",""),6,8);
			$time_device_off = substr(ReadingsVal("Funksteckdose_SUNR_OFF", "state",""),6,8);
			
			# Muss die Steckdose bei Aktivierung des Betriebsmodus an bzw. ausgeschalten werden?
			if($time_current gt $time_device_on || $time_current lt $time_device_off){
				fhem("set Funksteckdose on");
			}
			elsif($time_current gt $time_device_off && $time_current lt $time_device_on){
				fhem("set Funksteckdose off");
			}
			elsif($time_current eq $time_device_on){
				fhem("set Funksteckdose on");
			}
			elsif($time_current eq $time_device_off){
				fhem("set Funksteckdose off");
			}
			
			# Festgehaltene Zeitstempel in passendes Dummy device zur Anzeige im Frontend schreiben
			fhem("set d_zeit_funk_on AN: $time_device_on;");
			fhem("set d_zeit_funk_off AUS: $time_device_off;");
		}
		elsif (ReadingsVal("d_betriebsmodus_funk", "state","") eq "AUTOMATIK"){
			#sonne_disable
			fhem("attr Funksteckdose_SUNR_OFF disable 1; attr Funksteckdose_SUNS_ON disable 1;");
			#automatik_enable
			fhem("attr Funksteckdose_AUTO_OFF disable 0; attr Funksteckdose_AUTO_ON disable 0;");
			#anwesenheit_disable
			fhem("attr Funksteckdose_ANWS disable 1;");
			#mix_disable
			fhem("attr Funksteckdose_MIX_OFF disable 1;");
			
			$time_device_on = substr(ReadingsVal("Funksteckdose_AUTO_ON", "state",""),6,8);
			$time_device_off = substr(ReadingsVal("Funksteckdose_AUTO_OFF", "state",""),6,8);
			
			if($time_current gt $time_device_on || $time_current lt $time_device_off){
				fhem("set Funksteckdose on");
			}
			elsif($time_current gt $time_device_off && $time_current lt $time_device_on){
				fhem("set Funksteckdose off");
			}
			elsif($time_current eq $time_device_on){
				fhem("set Funksteckdose on");
			}
			elsif($time_current eq $time_device_off){
				fhem("set Funksteckdose off");
			}
			
			fhem("set d_zeit_funk_on AN: $time_device_on;");
			fhem("set d_zeit_funk_off AUS: $time_device_off;");
		}
		
		# Funktion wie bei Betriebsmodi vorher, hier wird jedoch mit der Funltion IsWe
		# Zwischen Wochenende und Werktagen unterschieden um jeweils die passenden
		# ats oder DOIFS zu aktivieren
		elsif (ReadingsVal("d_betriebsmodus_funk", "state","") eq "ANWESENHEIT"){
			#Wochenende?
			if (!(IsWe())){
				#sonne_disable
				fhem("attr Funksteckdose_SUNR_OFF disable 1; attr Funksteckdose_SUNS_ON disable 1;");
				#anwesenheit_enable
				fhem("attr Funksteckdose_ANWS disable 0;");
			}
			elsif (IsWe()){
				#sonne_enable
				fhem("attr Funksteckdose_SUNR_OFF disable 0; attr Funksteckdose_SUNS_ON disable 0;");
				#anwesenheit_disable
				fhem("attr Funksteckdose_ANWS disable 1;");
			}
			#automatik_disable
			fhem("attr Funksteckdose_AUTO_OFF disable 1; attr Funksteckdose_AUTO_ON disable 1;");
			#mix_disable
			fhem("attr Funksteckdose_MIX_OFF disable 1;");
			
			if (IsWe()){
				$time_device_on = substr(ReadingsVal("Funksteckdose_SUNS_ON", "state",""),6,8);
				$time_device_off = substr(ReadingsVal("Funksteckdose_SUNR_OFF", "state",""),6,8);

				if($time_current gt $time_device_on || $time_current lt $time_device_off){
					fhem("set Funksteckdose on");
				}
				elsif($time_current gt $time_device_off && $time_current lt $time_device_on){
					fhem("set Funksteckdose off");
				}
				elsif($time_current eq $time_device_on){
					fhem("set Funksteckdose on");
				}
				elsif($time_current eq $time_device_off){
					fhem("set Funksteckdose off");
				}
				fhem("set d_zeit_funk_on AN: $time_device_on;");
				fhem("set d_zeit_funk_off AUS: $time_device_off;");
			}
			elsif(!(IsWe())){
				fhem("set d_zeit_funk_on AN: 17:00:00;");
				fhem("set d_zeit_funk_off AUS: 07:00:00;");
			}
		}
		# Funktion wie bei Betriebsmodi vorher, hier wird jedoch mit der Funltion IsWe
		# Zwischen Wochenende und Werktagen unterschieden um jeweils die passenden
		# ats oder DOIFS zu aktivieren
		elsif (ReadingsVal("d_betriebsmodus_funk", "state","") eq "MIX"){
			#Wochenende?
			if (!(IsWe())){
				#sunr_disable
				fhem("attr Funksteckdose_SUNR_OFF disable 1;");
				#sunset_enable
				fhem("attr Funksteckdose_SUNS_ON disable 0;");
				#mix_enable
				fhem("attr Funksteckdose_MIX_OFF disable 0;");
			}
			elsif (IsWe()){
				#sonne_enable
				fhem("attr Funksteckdose_SUNR_OFF disable 0; attr Funksteckdose_SUNS_ON disable 0;");
				#mix_disable
				fhem("attr Funksteckdose_MIX_OFF disable 1;");
			}
			#automatik_disable
			fhem("attr Funksteckdose_AUTO_OFF disable 1; attr Funksteckdose_AUTO_ON disable 1;");
			#anwesenheit_disable
			fhem("attr Funksteckdose_ANWS disable 1;");
			#mix_enable
			fhem("attr Funksteckdose_MIX_OFF disable 0;");
			
			if (IsWe()){
				$time_device_on = substr(ReadingsVal("Funksteckdose_SUNS_ON", "state",""),6,8);
				$time_device_off = substr(ReadingsVal("Funksteckdose_SUNS_OFF", "state",""),6,8);
			
				if($time_current gt $time_device_on || $time_current lt $time_device_off){
				fhem("set WLANSteckdose on");
				}
				elsif($time_current gt $time_device_off && $time_current lt $time_device_on){
				fhem("set WLANSteckdose off");
				}
				elsif($time_current eq $time_device_on){
				fhem("set WLANSteckdose on");
				}
				elsif($time_current eq $time_device_off){
				fhem("set WLANSteckdose off");
				}

				fhem("set d_zeit_wlan_on AN: $time_device_on;");
				fhem("set d_zeit_wlan_off AUS: $time_device_off;");
			}
			elsif (!(IsWe())){
				$time_device_on = substr(ReadingsVal("Funksteckdose_SUNS_ON", "state",""),6,8);
				$time_device_off = substr(ReadingsVal("Funksteckdose_MIX_OFF", "state",""),6,8);
			
				if($time_current gt $time_device_on || $time_current lt $time_device_off){
				fhem("set WLANSteckdose on");
				}
				elsif($time_current gt $time_device_off && $time_current lt $time_device_on){
				fhem("set WLANSteckdose off");
				}
				elsif($time_current eq $time_device_on){
				fhem("set WLANSteckdose on");
				}
				elsif($time_current eq $time_device_off){
				fhem("set WLANSteckdose off");
				}

				fhem("set d_zeit_wlan_on AN: $time_device_on;");
				fhem("set d_zeit_wlan_off AUS: $time_device_off;");
			}
		}
		# Für Manuellen Betriebsmodus werden alle anderne Modi deaktiviert
		elsif (ReadingsVal("d_betriebsmodus_funk", "state","") eq "MANUELL"){
			#sonne_disable
			fhem("attr Funksteckdose_SUNR_OFF disable 1; attr Funksteckdose_SUNS_ON disable 1;");
			#automatik_disable
			fhem("attr Funksteckdose_AUTO_OFF disable 1; attr Funksteckdose_AUTO_ON disable 1;");
			#anwesenheit_disable
			fhem("attr Funksteckdose_ANWS disable 1;");
			#mix_disable
			fhem("attr Funksteckdose_MIX_OFF disable 1;");

			fhem("set d_zeit_funk_on AN: Manueller Betrieb;");
			fhem("set d_zeit_funk_off AUS: Manueller Betrieb;");
		}
	}
	# Funktion für WLANSteckdose genau wie bei Funksteckdose
	elsif (index ($betriebsmodus,'WLAN') != -1){
	
		if (ReadingsVal("d_betriebsmodus_wlan", "state","") eq "DAEMMERUNG"){
			#sonne_enable
			fhem("attr WLANSteckdose_SUNR_OFF disable 0; attr WLANSteckdose_SUNS_ON disable 0;");
			#automatik_disable
			fhem("attr WLANSteckdose_AUTO_OFF disable 1; attr WLANSteckdose_AUTO_ON disable 1;");
			#anwesenheit_disable
			fhem("attr WLANSteckdose_ANWS disable 1;");
			#mix_disable
			fhem("attr WLANSteckdose_MIX_OFF disable 1;");
			
			$time_device_on = substr(ReadingsVal("WLANSteckdose_SUNS_ON", "state",""),6,8);
			$time_device_off = substr(ReadingsVal("WLANSteckdose_SUNR_OFF", "state",""),6,8);
			
			if($time_current gt $time_device_on || $time_current lt $time_device_off){
			fhem("set WLANSteckdose on");
			}
			elsif($time_current gt $time_device_off && $time_current lt $time_device_on){
			fhem("set WLANSteckdose off");
			}
			elsif($time_current eq $time_device_on){
			fhem("set WLANSteckdose on");
			}
			elsif($time_current eq $time_device_off){
			fhem("set WLANSteckdose off");
			}
			
			fhem("set d_zeit_wlan_on AN: $time_device_on;");
			fhem("set d_zeit_wlan_off AUS: $time_device_off;");
		}
		elsif (ReadingsVal("d_betriebsmodus_wlan", "state","") eq "AUTOMATIK"){
			#sonne_disable
			fhem("attr WLANSteckdose_SUNR_OFF disable 1; attr WLANSteckdose_SUNS_ON disable 1;");
			#automatik_enable
			fhem("attr WLANSteckdose_AUTO_OFF disable 0; attr WLANSteckdose_AUTO_ON disable 0;");
			#anwesenheit_disable
			fhem("attr WLANSteckdose_ANWS disable 1;");
			#mix_disable
			fhem("attr WLANSteckdose_MIX_OFF disable 1;");
				
			$time_device_on = substr(ReadingsVal("WLANSteckdose_AUTO_ON", "state",""),6,8);
			$time_device_off = substr(ReadingsVal("WLANSteckdose_AUTO_OFF", "state",""),6,8);
			
			if($time_current gt $time_device_on || $time_current lt $time_device_off){
			fhem("set WLANSteckdose on");
			}
			elsif($time_current gt $time_device_off && $time_current lt $time_device_on){
			fhem("set WLANSteckdose off");
			}
			elsif($time_current eq $time_device_on){
			fhem("set WLANSteckdose on");
			}
			elsif($time_current eq $time_device_off){
			fhem("set WLANSteckdose off");
			}
			
			fhem("set d_zeit_wlan_on AN: $time_device_on;");
			fhem("set d_zeit_wlan_off AUS: $time_device_off;");
		}
		elsif (ReadingsVal("d_betriebsmodus_wlan", "state","") eq "ANWESENHEIT"){
			#Wochenende?
			if (!(IsWe())){
				#sonne_disable
				fhem("attr WLANSteckdose_SUNR_OFF disable 1; attr WLANSteckdose_SUNS_ON disable 1;");
				#anwesenheit_enable
				fhem("attr WLANSteckdose_ANWS disable 0;");
			}
			elsif (IsWe()){
				#sonne_enable
				fhem("attr WLANSteckdose_SUNR_OFF disable 0; attr WLANSteckdose_SUNS_ON disable 0;");
				#anwesenheit_disable
				fhem("attr WLANSteckdose_ANWS disable 1;");
			}
			#automatik_disable#
			fhem("attr WLANSteckdose_AUTO_OFF disable 1; attr WLANSteckdose_AUTO_ON disable 1;");
			#mix_disable
			fhem("attr WLANSteckdose_MIX_OFF disable 1;");
			
			if (IsWe()){
				$time_device_on = substr(ReadingsVal("WLANSteckdose_SUNS_ON", "state",""),6,8);
				$time_device_off = substr(ReadingsVal("WLANSteckdose_SUNR_OFF", "state",""),6,8);

				if($time_current gt $time_device_on || $time_current lt $time_device_off){
				fhem("set WLANSteckdose on");
				}
				elsif($time_current gt $time_device_off && $time_current lt $time_device_on){
				fhem("set WLANSteckdose off");
				}
				elsif($time_current eq $time_device_on){
				fhem("set WLANSteckdose on");
				}
				elsif($time_current eq $time_device_off){
				fhem("set WLANSteckdose off");
				}
				fhem("set d_zeit_funk_on AN: $time_device_on;");
				fhem("set d_zeit_funk_off AUS: $time_device_off;");
			}
			elsif(!(IsWe())){
				fhem("set d_zeit_wlan_on AN: 17:00:00;");
				fhem("set d_zeit_wlan_off AUS: 07:00:00;");
			}
		}
		elsif (ReadingsVal("d_betriebsmodus_wlan", "state","") eq "MIX"){
			#Wochenende?
			if (!(IsWe())){
				#sunr_disable
				fhem("attr WLANSteckdose_SUNR_OFF disable 1;");
				#sunset_enable
				fhem("attr WLANSteckdose_SUNS_ON disable 0;");
				#mix_enable
				fhem("attr WLANSteckdose_MIX_OFF disable 0;");
			}
			elsif (IsWe()){
				#sonne_enable
				fhem("attr WLANSteckdose_SUNR_OFF disable 0; attr WLANSteckdose_SUNS_ON disable 0;");
				#mix_disable
				fhem("attr WLANSteckdose_MIX_OFF disable 1;");
			}
			#automatik_disable
			fhem("attr WLANSteckdose_AUTO_OFF disable 1; attr WLANSteckdose_AUTO_ON disable 1;");
			#anwesenheit_disable
			fhem("attr WLANSteckdose_ANWS disable 1;");
			
			if (IsWe()){
				$time_device_on = substr(ReadingsVal("WLANSteckdose_SUNS_ON", "state",""),6,8);
				$time_device_off = substr(ReadingsVal("WLANSteckdose_SUNS_OFF", "state",""),6,8);
			
				if($time_current gt $time_device_on || $time_current lt $time_device_off){
				fhem("set WLANSteckdose on");
				}
				elsif($time_current gt $time_device_off && $time_current lt $time_device_on){
				fhem("set WLANSteckdose off");
				}
				elsif($time_current eq $time_device_on){
				fhem("set WLANSteckdose on");
				}
				elsif($time_current eq $time_device_off){
				fhem("set WLANSteckdose off");
				}

				fhem("set d_zeit_wlan_on AN: $time_device_on;");
				fhem("set d_zeit_wlan_off AUS: $time_device_off;");
			}
			elsif (!(IsWe())){
				$time_device_on = substr(ReadingsVal("WLANSteckdose_SUNS_ON", "state",""),6,8);
				$time_device_off = substr(ReadingsVal("WLANSteckdose_MIX_OFF", "state",""),6,8);
			
				if($time_current gt $time_device_on || $time_current lt $time_device_off){
				fhem("set WLANSteckdose on");
				}
				elsif($time_current gt $time_device_off && $time_current lt $time_device_on){
				fhem("set WLANSteckdose off");
				}
				elsif($time_current eq $time_device_on){
				fhem("set WLANSteckdose on");
				}
				elsif($time_current eq $time_device_off){
				fhem("set WLANSteckdose off");
				}

				fhem("set d_zeit_wlan_on AN: $time_device_on;");
				fhem("set d_zeit_wlan_off AUS: $time_device_off;");
			}
		}
		elsif (ReadingsVal("d_betriebsmodus_wlan", "state","") eq "MANUELL"){
			#sonne_disable
			fhem("attr WLANSteckdose_SUNR_OFF disable 1; attr WLANSteckdose_SUNS_ON disable 1;");
			#automatik_disable
			fhem("attr WLANSteckdose_AUTO_OFF disable 1; attr WLANSteckdose_AUTO_ON disable 1;");
			#anwesenheit_disable
			fhem("attr WLANSteckdose_ANWS disable 1;");
			#mix_disable
			fhem("attr WLANSteckdose_MIX_OFF disable 1;");

			fhem("set d_zeit_wlan_on AN: Manueller Betrieb;");
			fhem("set d_zeit_wlan_off AUS: Manueller Betrieb;");
		}
	}
}
# Damit AN und AUS Zeiten im Frontend aktuell sind, muss die folgende Funktion
# Jeden Tag zu einem festgelegten Zeitpunkt automatisch ausgeführt werden.
sub
betriebszeit_aktualisieren{
	if (ReadingsVal("d_betriebsmodus_funk", "state","") eq "DAEMMERUNG"){
		betriebsmodus_ausfuehren("DAEMMERUNG_FUNK");
	}
	elsif (ReadingsVal("d_betriebsmodus_funk", "state","") eq "AUTOMATIK"){
		betriebsmodus_ausfuehren("AUTOMATIK_FUNK");
	}
	elsif (ReadingsVal("d_betriebsmodus_funk", "state","") eq "ANWESENHEIT"){
		betriebsmodus_ausfuehren("ANWESENHEIT_FUNK");
	}
	elsif (ReadingsVal("d_betriebsmodus_funk", "state","") eq "MIX"){
		betriebsmodus_ausfuehren("MIX_FUNK");
	}
	elsif (ReadingsVal("d_betriebsmodus_funk", "state","") eq "MANUELL"){
		betriebsmodus_ausfuehren("MANUELL_FUNK");
	}
	
	if (ReadingsVal("d_betriebsmodus_wlan", "state","") eq "DAEMMERUNG"){
		betriebsmodus_ausfuehren("DAEMMERUNG_WLAN");
	}
	elsif (ReadingsVal("d_betriebsmodus_wlan", "state","") eq "AUTOMATIK"){
		betriebsmodus_ausfuehren("AUTOMATIK_WLAN");
	}
	elsif (ReadingsVal("d_betriebsmodus_wlan", "state","") eq "ANWESENHEIT"){
		betriebsmodus_ausfuehren("ANWESENHEIT_WLAN");
	}
	elsif (ReadingsVal("d_betriebsmodus_wlan", "state","") eq "MIX"){
		betriebsmodus_ausfuehren("MIX_WLAN");
	}
	elsif (ReadingsVal("d_betriebsmodus_wlan", "state","") eq "MANUELL"){
		betriebsmodus_ausfuehren("MANUELL_WLAN");
	}
}

1;