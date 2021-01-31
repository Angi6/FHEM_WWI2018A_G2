##############################################
# $Id: myUtilsTemplate.pm 21509 2020-03-25 11:20:51Z rudolfkoenig $
#
# Save this file as 99_myUtils.pm, and create your own functions in the new
# file. They are then available in every Perl expression.

package main;

use strict;
use warnings;

sub
myUtils_Initialize($$)
{
  my ($hash) = @_;
}

# Enter you functions below _this_ line.
sub getContactsTele(){

	my $contactsReading = ReadingsVal("telebot", "Contacts", "No Contact Found");
	
	my @contactsArray = split(/ /,$contactsReading);

	my %contacts = ();

	foreach(@contactsArray){
		my $contactNotAnalyzed = $_;

		my @contactInfo = split(/:/, $contactNotAnalyzed);

		my $contactName = $contactInfo[1];	
		my $contactID = $contactInfo[2];

		if($contactName ne "" && $contactID ne ""){
			$contacts{$contactID} = $contactName; 
		}

	}
	
	my $json_str = encode_json(\%contacts);
	return $json_str;
	#return %contacts;
}




1;