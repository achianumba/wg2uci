#!/bin/sh

INI_FILEPATH=$1
INI_FILENAME="$(basename $INI_FILEPATH)"
# INTERFACE_NAME="$(grep -E "^#(\s)?InterfaceName" $INI_FILEPATH | tr -d '[:space:]' | cut -d '=' -f 2)"



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

\n\n# Configure Wireguard Interface
SCRIPT
)

declare CURRENT_SECTION
declare DESCRIPTION
declare INTERFACE_NAME
declare INTERFACE_KEY
declare INTERFACE_ADDRESSES
declare INTERFACE_PORT
declare INTERFACE_DNS

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
      ;;
    
    \[Peer\] | \#Description)
      CURRENT_SECTION='Peer'
      ;;
  esac

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
done < "$INI_FILEPATH"

# Write script to file
echo -e $SCRIPT | tee "configure-$INTERFACE_NAME.sh"