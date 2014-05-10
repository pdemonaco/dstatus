#!/usr/bin/perl
## Includes
use feature "switch";

## Constants
my $interval = 1;
my $wdev = "wlp3s0";

## Commands
my $awk = "/usr/bin/awk";
my $grep = "/bin/grep";
my $iw = "/usr/sbin/iw";
my $sed	= "/bin/sed";

## Determine SSID 
my $ssid = `${iw} dev ${wdev} link | ${grep} SSID | ${sed} 's/\s*SSID: //'`;
$ssid =~ s/^\s+|\s+$//g;

## Infinite print loop
while(1){
	# Perform battery calculations
	my $sign	= `cat /sys/class/power_supply/BAT0/status`;
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
	
	# Test line for output 
	#print "${displayString}\n\n";
	
	# Call to xsetroot which actually enables the display
	`xsetroot -name "${displayString}"`;

	# Wait our sleep interval
	sleep ${interval};
}

sub isVpn {
	my $command = 'ps -e | awk \'{print $4;}\' | grep vpnc';
	chomp(my $ps = `$command`);
	if($ps){
		return 1;
	}
	return 0;
}
