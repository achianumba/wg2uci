#!/bin/sh

INI_FILEPATH=$1
INI_FILENAME=$(basename "$INI_FILEPATH")

SCRIPT=$(cat << SCRIPT
#!/bin/sh

\n\n# Copyright 2024 Arinze Chianumba
\n#
\n# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
\n#
\n# -
\n# 
\n# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
\n#
\n# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

\n\n# Configure the WireGuard interface
SCRIPT
)

declare CURRENT_SECTION
declare PEER_DESCRIPTION
declare INTERFACE_NAME
declare PEER_NAME
declare PEER_NETWORK

while IFS='=' read -r key value || [ -n "$key" ]; do
  # Strip whitespace
  key=$(echo "$key" | tr -d '[:space:]')
  value=$(echo "$value" | tr -d '[:space:]')
  
  # Skip empty lines
  [ -z "$key" ] && continue

  # Set interface name & update section headers
  case $key in
    \#InterfaceName)
      INTERFACE_NAME="$value"
      continue
      ;;

    \[Interface\])
      CURRENT_SECTION='Interface'

      if [ -n "$INTERFACE_NAME" ]; then
        SCRIPT+="\nuci set network.$INTERFACE_NAME=interface"
      else
        INTERFACE_NAME="${INI_FILENAME%.conf}"
        SCRIPT+="\nuci set network.$INTERFACE_NAME=interface"
      fi

      SCRIPT+="\nuci set network.$INTERFACE_NAME.proto='wireguard'"
      
      continue
      ;;
    
    \#Description)
      PEER_DESCRIPTION="$value"
      ;;

    \[Peer\])
      CURRENT_SECTION='Peer'
      PEER_NAME="wirguard_$INTERFACE_NAME"
      PEER_NETWORK="set network.@$PEER_NAME[-1]"
      SCRIPT+="\n\n# Configure a WireGuard peer\nuci add network $PEER_NAME\nuci $PEER_NETWORK.description='$PEER_DESCRIPTION'"
      continue
      ;;
  esac

  # Parse Interface fields
  if [ "$CURRENT_SECTION" == "Interface" ]; then
    case "$key" in
      PrivateKey)
        SCRIPT+="\nuci set network.$INTERFACE_NAME.private_key='$value'"
        ;;

      Address)
        SCRIPT+="\nuci set network.$INTERFACE_NAME.addresses='$value'"
        ;;

      DNS)
        SCRIPT+="\nuci set network.$INTERFACE_NAME.dns='$(echo $value | tr ',' ' ')'"
        ;;

      ListenPort)
        SCRIPT+="\nuci set network.$INTERFACE_NAME.listen_port='$value'"
        ;;
    esac
  fi

  # Parse peer sections
  if [ "$CURRENT_SECTION" == "Peer" ]; then
    case "$key" in
      PublicKey)
        SCRIPT+="\nuci $PEER_NETWORK.public_key='$value'"
        ;;

      Endpoint)
        SCRIPT+="\nuci $PEER_NETWORK.endpoint_host='${value%:*}'"
        SCRIPT+="\nuci $PEER_NETWORK.endpoint_port='${value#*:}'"
        ;;

      PersistentKeepalive)
        SCRIPT+="\nuci $PEER_NETWORK.persistent_keepalive='$value'"
        ;;
      
      AllowedIPs)
        SCRIPT+="\nuci $PEER_NETWORK.allowed_ips='$(echo $value | tr ',' ' ')'"
        ;;

      PresharedKey)
        SCRIPT+="\nuci $PEER_NETWORK.preshared_key='$value'"
        ;;
    esac
  fi
done < "$INI_FILEPATH"

SCRIPT+=$(cat << SCRIPT
\n\n# Commit network changes
\nuci commit network

\n\n# Restart the network and firewall
\n/etc/init.d/network restart
\n/etc/init.d/firewall restart
SCRIPT
)

SCRIPT_NAME="config-$INTERFACE_NAME.sh"
# Write script to file
echo -e $SCRIPT | tee "$SCRIPT_NAME"
chmod +x "$SCRIPT_NAME"