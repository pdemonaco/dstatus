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
my ${ifconfig} = "/bin/ifconfig";
my $iw = "/usr/sbin/iw";
my $ps = "/bin/ps";
my $sed	= "/bin/sed";

## Flags
my $flag_test;

## Global Variables
my $wdev;

## Enable bundling of single character options... risky business
Getopt::Long::Configure( "bundling" );

## Process Parameters
GetOptions( "test|t"            => \$flag_test,
            "wireless|wdev|w=s" => \$wdev);

# Sanitize wireless device if it's provided
if( defined $wdev ) {
	$wdev = untaintValue($wdev);
} else {
	$wdev = getWireless();
}

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
	if (&isVPN()){
		$displayString = "VPN ";
	}
	
	# Check the wireless status
	if ( defined $wdev ) {
		my $wstat = checkWireless( $wdev );
		$displayString = "${displayString}${wstat}"
	}

	# Retrieve battery status
	unless ( $sign =~ m/Full/ ) {
		my $fullBatt 	= `cat /sys/class/power_supply/BAT0/charge_full`;
		my $curBatt 	= `cat /sys/class/power_supply/BAT0/charge_now`;
		my $percentBatt = $curBatt / $fullBatt * 100;
		$percentBattString = sprintf('%.2f', $percentBatt);

		$displayString = "${displayString} ${sign}${percentBattString}\% ${dateString}";
	} else {
		$displayString = "${displayString} ${sign} ${dateString}";
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

## isVPN ======================================================
# Determines the active SSID for the provided wireless device
## ============================================================
sub isVPN {
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

## checkWireless ==============================================
# Determines the active SSID for the provided wireless device
## ============================================================
sub checkWireless {
	my $wdev = @_[0];
	my $status;
	my $ifCheck = "${ifconfig} | ${grep} ${wdev} | ${awk} \'BEGIN { FS=\":\" } { print \$1 }\'";
	my $ssidCheck = "${iw} dev ${wdev} link | ${grep} SSID | ${sed} \'s/\s*SSID: //\'";

	chomp( my $rc_if = `$ifCheck` );
	unless( $rc_if ) {
		$status = "${wdev} Down";
	} else {
		my $ssid = `$ssidCheck`;
		$status = cleanValue( $ssid );
	}

	return $status;
}

## getWireless ================================================
# Attempts to determine the wireless device
## ============================================================
sub getWireless() {
	my $wCheck = "${iw} dev | ${grep} Interface | ${awk} \'{print \$2}\'";
	my $dev = `$wCheck`;
	
	unless( $dev ) {
		undef $dev;
	} else {
		$dev = cleanValue( $dev );
	}

	return $dev;
}

## untaintValue ===============================================
# Checks the provided string for unsafe characters
## ============================================================
sub untaintValue() {
	my $value = @_[0];
	unless( $value =~ m/^([a-zA-Z0-9_.\/]+)$/ ) {
		die "Value ${value} is tainted!";
	} else {
		$value = $1;
	}

	return $value;
}

## cleanValue =================================================
# Removes undesirable characters from the provided value
## ============================================================
sub cleanValue() {
	my $value = @_[0];
	if( $value =~ m/[^a-zA-Z0-9_.\-]*([a-zA-Z0-9_.\-]+)[^a-zA-Z0-9_.\-]*/ ) {
		$value = $1
	} else {
		$value = "!";
	}

	return $value;
}
