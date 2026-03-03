#!/bin/sh

. /lib/functions.sh

OPENSSL_BIN="/usr/bin/openssl"
CERT_DIR="/etc/siteman/certs"
CLIENT_CERT_DIR="$CERT_DIR/client"
CRL_FILE="$CERT_DIR/crl.pem"
SERIAL_FILE="$CERT_DIR/ca.srl"

CA_NAME="ca"

dm_create_ca() {
    if [ -f "$CERT_DIR/$CA_NAME".crt ]; then
        echo "CA key already exists"
        return 1
    fi

    $OPENSSL_BIN req -new -x509 -nodes -days "${DAYS:-5475}" -extensions v3_ca \
            -keyout "$CERT_DIR/$CA_NAME".key -out "$CERT_DIR/$CA_NAME".crt \
            -subj /C="${COUNTRY:-ZZ}"/ST="${STATE:-Somewhere}"/L="${LOCATION:-Unknown}"/O="${ORG:-Teltonika}"/CN="CA" &>/dev/null || {
        echo "Failed to create CA key"
        return 1
    }

    return 0
}

dm_sign_cert() {
    local csr="$1"
    local crt="$2"
    local days

    [ -z "$csr" ] || [ -z "$crt" ] && {
        echo "CSR or certificate file not specified"

        return 1
    }

    [ ! -f "$csr" ] && {
        echo "CSR file does not exist"

        return 1
    }

    [ -f "$crt" ] && {
        echo "Certificate file already exists"

        return 1
    }

    [ ! -f "$CERT_DIR/$CA_NAME".crt ] || [ ! -f "$CERT_DIR/$CA_NAME".key ] && {
        echo "CA key does not exist"

        return 1
    }

    $OPENSSL_BIN req -text -noout -verify -in "$csr" &>/dev/null || {
        echo "CSR file is not a valid certificate request"

        return 1
    }

    $OPENSSL_BIN x509 -req -in "$csr" -CA "$CERT_DIR/$CA_NAME".crt -CAkey "$CERT_DIR/$CA_NAME".key \
            -CAserial "$SERIAL_FILE" -CAcreateserial -out "$crt" -days "${DAYS:-5475}" &>/dev/null || {
        echo "Failed to create server certificate"
        return 1
    }

    return 0
}

dm_create_cert() {
    local name="$1"
    local cn="$2"
    local days bits country state location org

    [ -z "$cn" ] && {
        config_get cn defaults commonname "Siteman"
    }

    if [ ! -f "$CERT_DIR/$CA_NAME".crt ] || [ ! -f "$CERT_DIR/$CA_NAME".key ]; then
        echo "CA key does not exist. Generating..."
        dm_create_ca || {
            echo "Failed to create CA key"
            return 1
        }
    fi

    $OPENSSL_BIN genrsa -out "$name".key "${BITS:-2048}" &>/dev/null || {
        echo "Failed to create server key"
        return 1
    }

    $OPENSSL_BIN req -new -key "$name".key \
            -out "$name".csr -subj /C="${COUNTRY:-ZZ}"/ST="${STATE:-Somewhere}"/L="${LOCATION:-Unknown}"/O="${ORG:-Teltonika}"/CN="$cn" &>/dev/null || {
        echo "Failed to create server CSR"
        return 1
    }

    return 0
}

dm_create_signed_cert() {
    local name="$1"
    local dir="$2"
    local tmp_name="$(mktemp -u 2>/dev/null)"

    [ -z "$tmp_name" ] && {
        echo "Failed to create temporary file"

        exit 1
    }

    dm_create_cert "$tmp_name" || {
        echo "Failed to create server certificate"
        exit 1
    }
    
    dm_sign_cert "$tmp_name".csr "$tmp_name".crt || {
        echo "Failed to sign server certificate"
        exit 1
    }

    sync
    rm -f "$tmp_name".csr
    mv "$tmp_name".key "$dir/$name".key
    mv "$tmp_name".crt "$dir/$name".crt
}

dm_revoke_cert() {
    local mac="$1"
    local path

    [ ! -f "$CERT_DIR/$CA_NAME".crt ] || [ ! -f "$CERT_DIR/$CA_NAME".key ] && {
        echo "CA key does not exist"

        return 1
    }

    [ -e "$CRL_FILE" ] || {
        $OPENSSL_BIN ca -gencrl -keyfile "$CERT_DIR/$CA_NAME".key -cert \
                "$CERT_DIR/$CA_NAME".crt -out "$CRL_FILE" &>/dev/null || {
            echo "Failed to generate CRL"

            return 1
        }
    }

    [ -z "$mac" ] && return 0

    path="$CLIENT_CERT_DIR/$mac.crt"
    [ ! -f "$path" ] && {
        echo "Certificate file does not exist"

        return 1
    }

    $OPENSSL_BIN ca -revoke "$path" -keyfile "$CERT_DIR/$CA_NAME".key \
            -cert "$CERT_DIR/$CA_NAME".crt -crl_reason KeyCompromise &>/dev/null || {
        echo "Failed to revoke certificate"
        return 1
    }

    $OPENSSL_BIN ca -gencrl -keyfile "$CERT_DIR/$CA_NAME".key \
            -cert "$CERT_DIR/$CA_NAME".crt -out "$CRL_FILE" &>/dev/null || {
        echo "Failed to generate CRL"

        return 1
    }

    rm -f "$cert"

    return 0
}

which openssl &>/dev/null || {
    echo "openssl not found"
    exit 1
}

[ -d "$CERT_DIR" ] || mkdir -p "$CERT_DIR"

config_load siteman
config_get DAYS     defaults days 5475
config_get BITS     defaults bits 2048
config_get COUNTRY  defaults country "ZZ"
config_get STATE    defaults state "Somewhere"
config_get LOCATION defaults location "Unknown"
config_get ORG      defaults org "Teltonika"

case "$1" in
    ca)
        dm_create_ca
        ;;
    crt)
        [ -z "$2" ] && {
            echo "Usage: $0 crt <name> [save_dir] [common_name]"
            exit 1
        }

        dm_create_signed_cert "$2" "${3:-$CERT_DIR}"
        ;;
    sign)
        [ -z "$2" ] || [ -z "$3" ] && {
            echo "Usage: $0 sign <csr_file> <out_file>"
            exit 1
        }

        dm_sign_cert "$2" "$3"
        ;;
    revoke)
        dm_revoke_cert "$2"
        ;;
    *)
        echo "Usage: $0 {ca|crt|sign}"
        exit 1
esac
