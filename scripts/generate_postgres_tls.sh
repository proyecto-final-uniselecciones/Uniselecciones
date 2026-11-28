
#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TLS_DIR="$ROOT_DIR/certs/postgres/ags"
SERVER_DIR="$TLS_DIR/server"

if ! command -v openssl >/dev/null 2>&1; then
    echo "Error: OpenSSL no está instalado."
    exit 1
fi

if [[ -e "$TLS_DIR/ca.key" || -e "$SERVER_DIR/server.key" ]]; then
    echo "Ya existen llaves TLS. No se sobrescribirán."
    exit 1
fi

umask 077
mkdir -p "$SERVER_DIR"
chmod 755 "$ROOT_DIR/certs" "$ROOT_DIR/certs/postgres" "$TLS_DIR" "$SERVER_DIR"

echo "1. Generando la llave privada de la CA..."
openssl genrsa -aes256 -out "$TLS_DIR/ca.key" 4096

echo "2. Generando el certificado de la CA..."
openssl req -x509 -new -sha256 -days 3650 \
    -key "$TLS_DIR/ca.key" \
    -out "$TLS_DIR/ca.crt" \
    -subj "/CN=UniSelecciones Local PostgreSQL CA"

echo "3. Generando la llave privada del servidor..."
openssl genpkey -algorithm RSA \
    -pkeyopt rsa_keygen_bits:3072 \
    -out "$SERVER_DIR/server.key"

echo "4. Generando la solicitud del certificado..."
openssl req -new \
    -key "$SERVER_DIR/server.key" \
    -out "$TLS_DIR/server.csr" \
    -subj "/CN=localhost"

cat > "$TLS_DIR/server.ext" <<'EOF'
basicConstraints=critical,CA:FALSE
keyUsage=critical,digitalSignature,keyEncipherment
extendedKeyUsage=serverAuth
subjectAltName=@alt_names

[alt_names]
DNS.1=localhost
IP.1=127.0.0.1
EOF

echo "5. Firmando el certificado del servidor..."
openssl x509 -req \
    -in "$TLS_DIR/server.csr" \
    -CA "$TLS_DIR/ca.crt" \
    -CAkey "$TLS_DIR/ca.key" \
    -CAcreateserial \
    -out "$SERVER_DIR/server.crt" \
    -days 825 \
    -sha256 \
    -extfile "$TLS_DIR/server.ext"

rm -f "$TLS_DIR/server.csr"

echo "6. Configurando permisos..."
chmod 600 "$TLS_DIR/ca.key"
chmod 644 "$TLS_DIR/ca.crt" "$SERVER_DIR/server.crt"
sudo chown root:999 "$SERVER_DIR/server.key"
sudo chmod 640 "$SERVER_DIR/server.key"

echo "7. Verificando el certificado..."
openssl verify -CAfile "$TLS_DIR/ca.crt" "$SERVER_DIR/server.crt"

echo "Certificados TLS generados correctamente."
echo "CA pública: $TLS_DIR/ca.crt"
echo "Certificado del servidor: $SERVER_DIR/server.crt"
