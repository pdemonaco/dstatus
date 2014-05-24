#!/usr/bin/perl

## Includes
use Getopt::Long;

## Paths
my $battpath = "/sys/class/power_supply/BAT0/";

## Constants
my $interval = 1;
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
while( 1 ){
	my $displayString;
	
	# Retrieve date information and format it HH:MM
	my $dateString 	= `date +"%F %R"`;
	chomp( $dateString );
	
	# Check the wireless status
	if ( defined $wdev ) {
		my $wstat = checkWireless( $wdev );
		$displayString = "${displayString} ${wstat}"
	}
	
	# Check for vpn
	if( &isVPN() ) {
		$displayString = "VPN ${displayString}";
	}

	# Retrieve battery status
	if( -e $battpath ) {
		my $battStat = checkBattery();
		$displayString = "${displayString} ${battStat} ${dateString}";
	} else { 
		$displayString = "${displayString} ${dateString}";
	}
	
	# Update dwm root or just print to STDOUT
	unless( $flag_test ) {
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

## checkBattery ===============================================
# Calculate current battery statuses
## ============================================================
sub checkBattery {
	my $batteryStatus;
	
	# Charge statistics
	my $charge_design = `cat /sys/class/power_supply/BAT0/charge_full_design`;
	my $charge_full   = `cat /sys/class/power_supply/BAT0/charge_full`;
	my $charge        = `cat /sys/class/power_supply/BAT0/charge_now`;
	my $ac_offline    = `cat /sys/class/power_supply/AC/online`;

	# Perform battery calculations
	my $charge_percent;

	# Determine whether we're charging or not 
	my $sign;
	unless( $ac_offline ) {
		$sign = "+";
	} else {
		$sign = "-";
	}

	# Calculate battery status if we're not full
	unless( $charge == $charge_design ) {
		$charge_percent = $charge / $charge_full * 100;
		$charge_percent = sprintf( '%.2f', $charge_percent );
		$batteryStatus = "${sign}${charge_percent}\%";
	} else {
		$batteryStatus = "Full";
	}
	
	return $batteryStatus;
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
