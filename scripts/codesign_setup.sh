#!/bin/bash
set -e

CMD_NAME=$1
if ! [[ -n $CMD_NAME ]]; then
  echo "Usage: $0 [cli tool name]"
  exit 1
fi

CODESIGN_NAME="$CMD_NAME"

# check exist
if security find-identity -v | grep $CODESIGN_NAME > /dev/null 2>&1; then
  echo "already exist $CODESIGN_NAME"
  exit 1
fi

cat <<EOF > $CODESIGN_NAME.cfg
[ req ]
default_bits            = 2048                  # RSA key size
encrypt_key             = no                    # Protect private key
default_md              = sha512                # MD to use
prompt                  = no                    # Prompt for DN
distinguished_name      = codesign_dn           # DN template
[ codesign_dn ]
commonName              = "$CODESIGN_NAME"
[ codesign_reqext ]
keyUsage                = critical,digitalSignature
extendedKeyUsage        = critical,codeSigning
EOF

openssl req -new -newkey rsa:2048 -x509 -days 3650 -nodes -config $CODESIGN_NAME.cfg -extensions codesign_reqext -batch -out $CODESIGN_NAME.cer -keyout $CODESIGN_NAME.key
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain $CODESIGN_NAME.cer
sudo security import $CODESIGN_NAME.key -A -k /Library/Keychains/System.keychain

# restart(reload) taskgated daemon
sudo pkill -f /usr/libexec/taskgated

# need once
sudo security authorizationdb write system.privilege.taskport allow
# need once
DevToolsSecurity -enable
