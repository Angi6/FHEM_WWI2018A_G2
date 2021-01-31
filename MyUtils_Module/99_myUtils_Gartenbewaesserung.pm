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
 sub
 getAverageTemperature($$$)
 {
  my ($offset,$logfile,$cspec) = @_;
  my $period_s = strftime "%Y-%m-%d\x5f%H:%M:%S", localtime(time-$offset);
  my $period_e = strftime "%Y-%m-%d\x5f%H:%M:%S", localtime;
  my $oll = $attr{global}{verbose};
  $attr{global}{verbose} = 0; 
  my @logdata = split("\n", fhem("get $logfile - - $period_s $period_e $cspec"));
  $attr{global}{verbose} = $oll; 
  my ($cnt, $cum, $avg) = (0)x3;
  foreach (@logdata){
   my @line = split(" ", $_);
   if(defined $line[1] && "$line[1]" ne ""){
    $cnt += 1;
    $cum += $line[1];
   }
  }
  if("$cnt" > 0){$avg = sprintf("%0.1f", $cum/$cnt)};
  Log 4, ("myAverage: File: $logfile, Field: $cspec, Period: $period_s bis $period_e, Count: $cnt, Cum: $cum, Average: $avg");
  return $avg;
 }
 
 
 sub
 replaceComma($) {
 	my($inputString) = @_;
	$inputString =~ tr/,/./; 
	#fhem("set telebot msg \@\@smart_lightning $inputString");
	return $inputString;
 }
 sub
 postToLogTemperature($) {
 	my $input = @_;
	fhem("deleteattr regensensor_aussen userReadings");
	$input = fhem("attr rs_sensorHTTP userReadings reading01User {replaceComma(ReadingsVal('rs_sensorHTTP','temperature','');;)}");
	fhem("set telebot msg \@\@smart_lightning $input");
	return undef;
	
 }
  
 sub 
 getCurrentTemperature() {
 	my $tempReadings = ReadingsVal("rs_sensorHTTP","temperature","no temp value found");
	$tempReadings= replaceComma($tempReadings);
	return $tempReadings;
 }
 
 sub
 getWindSpeed() {
	return replaceComma(ReadingsVal("windsensor_aussen","windspeed","no wind speed value found")) / 3.6;
 }
 
  sub
 getWindgustSpeed() {
	return replaceComma(ReadingsVal("windsensor_aussen","gust","no windgust speed value found")) / 3.6;
 }
 
sub
getRainAmount($$$){
my ($offset,$logfile,$cspec) = @_;
  my $period_s = strftime "%Y-%m-%d\x5f%H:%M:%S", localtime(time-$offset);
  my $period_e = strftime "%Y-%m-%d\x5f%H:%M:%S", localtime;
  my $oll = $attr{global}{verbose};
  $attr{global}{verbose} = 0; 
  my @logdata = split("\n", fhem("get $logfile - - $period_s $period_e $cspec"));
  $attr{global}{verbose} = $oll; 
  my @first_value= split(" ",$logdata[0]);
  my $index= @logdata - 2;
  my @last_value= split(" ",$logdata[$index]);
  if(defined $first_value[1] && "$first_value[1]" ne "" && defined $last_value[1] && "$last_value[1]" ne "") {
  	return $last_value[1]-$first_value[1];
  }
  return 0;
 #Log 4, ("myAverage: File: $logfile, Field: $cspec, Period: $period_s bis $period_e, Count: $cnt, Cum: $cum, Sum: $sum");
  return undef;
}

sub
calculateWaterlvl($){
	my ($distance) = @_;
	my ($waterlvl) = (171 - $distance);
	return sprintf("%.2f", $waterlvl);
}

sub
calculateVolume($){
	my ($distance) = @_;
	my ($waterlvl) = ::calculateWaterlvl($distance) / 10;
	my ($volume) = 24.58 * (8.55**2 * acos(1-$waterlvl/8.55) - (8.55-$waterlvl) * sqrt(17.1*$waterlvl-$waterlvl**2));
	return sprintf("%.2f", $volume);
}

1;