#!/bin/sh

# WARNING: Do not run this as root!
# If $SESSION_TOKEN_CACHE is a symlink, its target wil be overwritten.

DEVICE_NAME='tv'
DEVICE_HOST='192.168.1.3'
DEVICE_PORT='9922'
DEVICE_USERNAME='prisoner'
DEVICE_PASSPHRASE='DCD71D'

umask 077

if ! TEMP_KEY_DIR="$(mktemp -d)"; then
    echo "Failed to create random temporary directory for key; using fallback" >&2
    TEMP_KEY_DIR="/tmp/renew-script.$$"
    if ! mkdir "${TEMP_KEY_DIR}"; then
        echo "Fallback temporary directory ${TEMP_KEY_DIR} already exists" >&2
        exit 1
    fi
fi

PRIV_KEY_FILE="${TEMP_KEY_DIR}/webos_privkey_${DEVICE_NAME}"

cat >"${PRIV_KEY_FILE}" <<END_OF_PRIVKEY
-----BEGIN RSA PRIVATE KEY-----
Proc-Type: 4,ENCRYPTED
DEK-Info: AES-128-CBC,EAB27CDE9525AB72B9FB0A18D2A3A63F

Y7292dkyW6Tt+8yv9dBqorYQ4aQjHyW0EJ0ta+aiQix3TCK0Y7HYrNBbyyg2tMcs
NlES7PdrUBMnwhrNIzzGijRw8Em34Am86IKQLLgkMDC89qYfuy7MdCSpl0SBz5Zz
c5JZ40to/vCIxue8PoN8ydR32vePVbbbftbZD2i7cHYjLFgp2YpizbmqFvg6wTyw
0mocd1l1GNYY06T7/V2nymFdZmL3hob3ZdCb/mgYxuETcOWmnZTnec50LnxG2Zc/
gYgiSeo8xBL+5uBQ0bkclbsCKt4owNy28kkzGrG+ybXXmXjZMNUtP3BBd0lYVBqn
DInR42HG/JzHPlL/6d3kOyhUbsWZjSh2vLdQGraqRjkfGEl2FW6jXN5UGMhstBOL
XfzkpgjB/AIaL6UjnQH3tQkLLypZstFdqKfUN6UnXlQtYh0Z25N+q1gF5EtU32gq
ycnuD91gajPIUwjG87a3S8eFnXj/+jKjjKr8q6/6RBxotKUmEby+e57QjFWpy9HU
sMS1y9FzSaN6/CFhOShxlfw9bVjLD/dWEWszbJD++Nrm1dsHKYRGzsFgjAb0WTxU
lGG0hsvOLygddj9mkmGNkFY4wSkpeY35edT8j3UofT85NnGn9RVgWbFSMjfzlAIj
kb7x4AGXuN+LZJ0r11OLFXwUYTisdEtbaEXJLdvUFOg3MVP8K6wp+SkByUALQPYy
C+ze87enoK7UIiS7NNnakh4ZKmDeLp94jvcYLiUe1O3L4GTDT083KsENsYuACUJs
g/QPvTnmukOnRuhINxJ5rGu2y437bnMk0m/AU1KscfXQKoK0JhI0YyE+ws9dtTxL
4lDJ2d8vKqRg9he+Rg+khcF0yLSYxgGOCm2MFBmiAfss08mQLLc1i8eoChlzKD2j
JUClnASEH890uMP4OkRdcZbFm4cJpBuD+WzYtdb2PJg/Vx+4XHkPkxYyEDy6mdtJ
xbCRA137qTUrI5Vtmd30/vaTlqrveCECe05Znlcv0BIThJOo6GrAqZ8G2ZtGQxti
89qvkWbZzGgsRhXrnxbAX+2tcFMhmLslHpOir6gogM40i+aAnqA5GTPuBPkdICBE
cBarL24d+kw0blc/hs2S0+pMWmWOnwEIc6ObDF82+M/vSlMFrnaF2dNAXyO60/Ey
ybgoKASm/xzOQr1ZraqLHetT2dQQWQPASd/oAszKOO2+wW/6SlkJH4N8VQhjnmo2
GuhJ3uxdM867RZLeJxQ4Wx+cJY5WFKSHT8cE4s1unoElr3ZoI77gMHgriFQOu2uB
d7rXnP20r4nFnpKMXkTXMX5uXIZFO5YgO32j9x64BoQMhwX0YqwU6reGlJQs8xOc
ONHFMIEsiZ19qzH7p23NuPwc+rn2ZumGoOoAfnWpSi3FTivebGHQh8YU8QYhQqoK
jCHKlKxphwN6EjSf++BcItEgiHZh0CXh+FuOZEop40E5Uyd/uWDdFAp5fpaJs6pL
grqXRMIJZKDFS9ZSFeTHcI+QqWGofm8Oc2hDfeE32/prCr6kFzxqgIPN31RTX4ZB
GZYT5lRg6THR/H+IA6oqzYCNxJflpSNcCx4+YbDXNgbTV1M4+c1xlVMnUpKTmNe4
-----END RSA PRIVATE KEY-----
END_OF_PRIVKEY

if [ -n "${DEVICE_PASSPHRASE}" ]; then
  ssh-keygen -p -P "${DEVICE_PASSPHRASE}" -N '' -f "${PRIV_KEY_FILE}"
fi

SESSION_TOKEN=$(ssh -i "${PRIV_KEY_FILE}" \
  -o ConnectTimeout=3 -o StrictHostKeyChecking=no \
  -o HostKeyAlgorithms=+ssh-rsa \
  -o PubkeyAcceptedKeyTypes=+ssh-rsa \
  -p "${DEVICE_PORT}" "${DEVICE_USERNAME}@${DEVICE_HOST}" \
  cat /var/luna/preferences/devmode_enabled)

rm -rf "${TEMP_KEY_DIR}"

SESSION_TOKEN_CACHE="/tmp/webos_devmode_token_${DEVICE_NAME}.txt"

if [ -z "$SESSION_TOKEN" ]; then
  echo "ssh into TV failed, loading previous SESSION_TOKEN from ${SESSION_TOKEN_CACHE}" >&2
  SESSION_TOKEN=$(cat "${SESSION_TOKEN_CACHE}")
else
  echo "Got SESSION_TOKEN from TV - writing to ${SESSION_TOKEN_CACHE}" >&2
  echo "$SESSION_TOKEN" >"${SESSION_TOKEN_CACHE}"
fi

if [ -z "$SESSION_TOKEN" ]; then
  echo "Unable to get token" >&2
  exit 1
fi

CHECK_RESULT=$(curl --max-time 3 -s "https://developer.lge.com/secure/ResetDevModeSession.dev?sessionToken=$SESSION_TOKEN")

echo "${CHECK_RESULT}"
