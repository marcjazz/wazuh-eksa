#!/usr/bin/env bash
set -euo pipefail

OUTPUT="instances.csv"

# Ensure jq is installed
if ! command -v jq &>/dev/null; then
  echo "jq not found, installing..."
  if command -v apt-get &>/dev/null; then
    sudo apt-get update -y && sudo apt-get install -y jq
  elif command -v yum &>/dev/null; then
    sudo yum install -y jq
  else
    echo "Package manager not supported. Please install jq manually."
    exit 1
  fi
fi

# Write CSV header
echo "hostname,bmc_ip,bmc_username,bmc_password,mac,ip_address,netmask,gateway,nameservers,labels,disk" > "$OUTPUT"

# Get only instances starting with "eksa"
gcloud compute instances list --filter="name~^eksa" --format="value(name,zone,status)" | while read -r NAME ZONE STATUS; do
  # Skip terminated instances
  if [[ "$STATUS" == "TERMINATED" ]]; then
    echo "Skipping $NAME (terminated)"
    continue
  fi

  echo "Processing $NAME in $ZONE..."

  # Describe instance
  INFO=$(gcloud compute instances describe "$NAME" --zone "$ZONE" --format=json)

  # Extract fields safely
  IP_ADDRESS=$(echo "$INFO" | jq -r '.networkInterfaces[0].networkIP // ""')
  MAC=$(echo "$INFO" | jq -r '.networkInterfaces[0].macAddress // ""')
  LABELS=$(echo "$INFO" | jq -r '.labels // {} | to_entries | map("\(.key)=\(.value)") | join(";")')
  DISK=$(echo "$INFO" | jq -r '.disks[0].source // ""' | awk -F/ '{print $NF}')
  DISK_SIZE=""
  if [[ -n "$DISK" ]]; then
    DISK_SIZE=$(gcloud compute disks describe "$DISK" --zone "$ZONE" --format="value(sizeGb)" 2>/dev/null || echo "")
  fi

  # Network/subnet info
  SUBNET_URL=$(echo "$INFO" | jq -r '.networkInterfaces[0].subnetwork // ""')
  REGION=$(echo "$ZONE" | sed 's/-[a-z]$//') # extract region from zone
  SUBNET_NAME=$(basename "$SUBNET_URL")

  NETMASK=""
  GATEWAY=""
  NAMESERVERS=""
  if [[ -n "$SUBNET_NAME" ]]; then
    SUBNET_INFO=$(gcloud compute networks subnets describe "$SUBNET_NAME" --region "$REGION" --format=json)
    NETMASK=$(echo "$SUBNET_INFO" | jq -r '.ipCidrRange // ""')
    GATEWAY=$(echo "$SUBNET_INFO" | jq -r '.gatewayAddress // ""')
    NAMESERVERS=$(echo "$SUBNET_INFO" | jq -r '.dnsServers // [] | join(";")')
  fi

  # Write line to CSV
  echo "$NAME,,,,$MAC,$IP_ADDRESS,$NETMASK,$GATEWAY,$NAMESERVERS,$LABELS,${DISK}(${DISK_SIZE}GB)" >> "$OUTPUT"
done

echo "CSV written to $OUTPUT"

