#!/usr/bin/perl

## Includes
use Getopt::Long;

## Constants
my $interval = 1;
my $wdev = "wlp3s0";
my @vpns = ( "openconnect", "vpnc" );

## Commands
my $awk = "/usr/bin/awk";
my $grep = "/bin/grep";
my $iw = "/usr/sbin/iw";
my $ps = "/bin/ps";
my $sed	= "/bin/sed";

## Flags
my $flag_test;

## Process Parameters
GetOptions( "test|t" => \$flag_test );

## Determine SSID 
my $ssid = `${iw} dev ${wdev} link | ${grep} SSID | ${sed} 's/\s*SSID: //'`;
$ssid =~ s/^\s+|\s+$//g;

## Infinite print loop
while(1){
	# Perform battery calculations
	my $sign = `cat /sys/class/power_supply/BAT0/status`;
	my $percentBattString;
	my $displayString;
	
	chomp($sign);
	# Apply a sign
	$sign =~ s/^Charging/+/g;
	$sign =~ s/^Discharging/-/g;
	
	# Retrieve date information and format it HH:MM
	my $dateString 	= `date +"%F %R"`;
	chomp($dateString);
	
	# Check for vpn
	my $vpnStat = "";
	if (&isVpn()){
		$vpnStat = "VPN ";
	}

	# Retrieve battery status
	unless ( $sign =~ m/Full/ ) {
		my $fullBatt 	= `cat /sys/class/power_supply/BAT0/charge_full`;
		my $curBatt 	= `cat /sys/class/power_supply/BAT0/charge_now`;
		my $percentBatt = $curBatt / $fullBatt * 100;
		$percentBattString = sprintf('%.2f', $percentBatt);

		$displayString = "${vpnStat}${ssid} ${sign}${percentBattString}\% ${dateString}";
	} else {
		$displayString = "${vpnStat}${ssid} ${sign} ${dateString}";
	}
	
	# Update dwm root or just print to STDOUT
	unless( $flag_test) {
		`xsetroot -name "${displayString}"`;
	} else {
		print "${displayString}", "\n";
	}

	# Wait our sleep interval
	sleep $interval;
}

sub isVpn {
	my $rc = 0;
	foreach( @vpns ) {
		my $command = "${ps} -e | ${awk} \'{print \$4;}\' | ${grep} $_";
		chomp(my $rc_ps = `$command`);
		if($rc_ps) {
			$rc = 1;
			last;
		}
	}
	return $rc;
}
