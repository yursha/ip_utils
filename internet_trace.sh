#!/usr/bin/env bash

# Instructions how to set up `geoiplookup` databases is described here:
#   http://xmodulo.com/geographic-location-ip-address-command-line.html

IP_LIST=$(
sudo traceroute -I 216.58.217.208 |  # use ICMP ECHO fro probes
												tail -n+3 |  # start with 3rd line:
											               #   1st line is header
																		 #   2nd line is 192.168.*.* network
				 sed 's/.*(\(.*\)).*/\1/g')  # extract router IP addresses

OUTPUT="IP^ORG^ASN^COUNTRY^STATE^CITY^ZIP\n" # output table header
for IP in ${IP_LIST}; do
	# We don't use `whoip` command because same info is available from `geoiplookup`
	#WHOIS_RESULT=$(whois $IP)
	#ORG=$(echo "${WHOIS_RESULT}" | grep Organization | sed 's/\w\+:\s\+\(.*\)/\1/g')
	#ASN=$(echo "${WHOIS_RESULT}" | grep OriginAS)

	ORG=$(geoiplookup $IP | tail -1 | sed 's/.*:\s\+\w\+\s\+\(.*\)/\1/g')
	ASN=$(geoiplookup $IP | tail -1 | sed 's/.*:\s\+\(\w\+\)\s\+.*/\1/g')
	COUNTRY=$(geoiplookup $IP | head -1 | sed 's/.*:\s\+\(.*\)/\1/g')
	ADDRESS=$(geoiplookup -f /usr/share/GeoIP/GeoLiteCity.dat $IP | sed 's/.*:\(.*\)/\1/g')
	IFS=',' read -a ADDRESS_PARTS <<< "$ADDRESS"

	for INDEX in "${!ADDRESS_PARTS[@]}"
	do
		ADDRESS_PARTS[INDEX]=$(echo ${ADDRESS_PARTS[INDEX]} | xargs)
	done

	STATE="${ADDRESS_PARTS[1]}, ${ADDRESS_PARTS[2]}"
	CITY="${ADDRESS_PARTS[3]}"
	ZIP="${ADDRESS_PARTS[4]}"
	
	OUTPUT="$OUTPUT$IP^$ORG^$ASN^$COUNTRY^$STATE^$CITY^$ZIP\n"
done

echo -e $OUTPUT | column -t -s^
