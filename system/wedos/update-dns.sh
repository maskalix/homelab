#!/bin/bash

# Default values for the parameters
DOMAIN=""
SUBDOMAIN=""
LOGIN=""
PASSWORD=""

# Parse command line arguments
while getopts d:s:l:p: flag
do
    case "${flag}" in
        d) DOMAIN=${OPTARG};;
        s) SUBDOMAIN=${OPTARG};;
        l) LOGIN=${OPTARG};;
        p) PASSWORD=${OPTARG};;
        *) echo "Usage: $0 -d DOMAIN -s SUBDOMAIN -l LOGIN -p PASSWORD"
           exit 1 ;;
    esac
done

# Ensure required parameters are set
if [ -z "$DOMAIN" ] || [ -z "$LOGIN" ] || [ -z "$PASSWORD" ]; then
    echo "Missing required parameters. Usage: $0 -d DOMAIN -s SUBDOMAIN -l LOGIN -p PASSWORD"
    exit 1
fi

# Constants
API='https://api.wedos.com/wapi/json'

# Function to get authentication hash
get_auth() {
    local password_hash
    password_hash=$(echo -n "$PASSWORD" | sha1sum | awk '{print $1}')
    local phrase
    phrase="${LOGIN}${password_hash}$(date +%H)"
    echo -n "$phrase" | sha1sum | awk '{print $1}'
}

# Function to make a request to the WEDOS API
request() {
    local command="$1"
    local data="$2"
    local auth
    auth=$(get_auth)
    local request_json
    request_json=$(jq -n --arg user "$LOGIN" --arg auth "$auth" --arg command "$command" --argjson data "$data" '{
        request: {
            user: $user,
            auth: $auth,
            command: $command,
            data: $data
        }
    }')
    response=$(curl -s -X POST "$API" -d "request=$request_json")
    echo "$response" | jq '.response'
}

# Function to get DNS rows list
dns_rows_list() {
    request "dns-rows-list" "$(jq -n --arg domain "$DOMAIN" '{domain: $domain}')"
}

# Function to update DNS row
dns_row_update() {
    local row_id="$1"
    local ttl="$2"
    local rdata="$3"
    request "dns-row-update" "$(jq -n --arg domain "$DOMAIN" --arg row_id "$row_id" --arg ttl "$ttl" --arg rdata "$rdata" '{
        domain: $domain,
        row_id: $row_id,
        ttl: $ttl,
        rdata: $rdata
    }')"
}

# Function to commit DNS domain changes
dns_domain_commit() {
    request "dns-domain-commit" "$(jq -n --arg name "$DOMAIN" '{name: $name}')"
}

# Function to find the A record
find_A_record() {
    local rows
    rows=$(dns_rows_list)
    local row_id=""
    local ttl=""

    row_id=$(echo "$rows" | jq -r --arg sub "$SUBDOMAIN" '.data.row[] | select(.rdtype == "A" and .name == $sub) | .ID')
    ttl=$(echo "$rows" | jq -r --arg sub "$SUBDOMAIN" '.data.row[] | select(.rdtype == "A" and .name == $sub) | .ttl')

    if [ -z "$row_id" ]; then
        echo "Cannot find A record for the domain"
        exit 1
    fi

    echo "$row_id" "$ttl"
}

# Function to get the fully qualified domain name
fqdn() {
    if [ -z "$SUBDOMAIN" ]; then
        echo "$DOMAIN"
    else
        echo "$SUBDOMAIN.$DOMAIN"
    fi
}

# Function to update the A record
update_A_record() {
    local ip="$1"
    local row_id
    local ttl

    read -r row_id ttl <<< "$(find_A_record)"
    dns_row_update "$row_id" "$ttl" "$ip"
    dns_domain_commit
    echo "Updated $(fqdn) to $ip"
}

# Function to get the current device's public IP
get_current_device_public_ip() {
    curl -s https://ident.me
}

# Function to compare the IP of the DNS record and the local device, and make changes if necessary
compare_ip_of_dns_record_and_local_device_and_make_changes() {
    local testadr
    testadr=$(fqdn)
    local dns_ip
    dns_ip=$(dig +short "$testadr")
    local local_device_ip
    local_device_ip=$(get_current_device_public_ip)

    if [ "$dns_ip" != "$local_device_ip" ]; then
        update_A_record "$local_device_ip"
    else
        echo "IP addresses match"
    fi
}

# Main script execution
compare_ip_of_dns_record_and_local_device_and_make_changes
