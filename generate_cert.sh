#!/bin/sh

## input CERT_NAME
read -p 'What is the certificate common name? [example.com]: ' CERT_NAME
CERT_NAME=${CERT_NAME:-test.example.com}

## input subject alternative name(SAN)
read -p 'any subject alternative names? e.g. "DNS:example.com, DNS:*.example.com, IP:8.135.19.237" [no need]: ' SAN

## input CA_NAME
read -p 'Which CA will sign the certificate? [RootCA]: ' CA_NAME
CA_NAME=${CA_NAME:-RootCA}

## input EXTENSIONS
read -p 'What is the certificate type? 1(server) or 2(client)? [1]: ' CERT_TYPE
if [ "${CERT_TYPE}" = "1" ] ; then
    EXTENSIONS=server_extensions
elif [ "${CERT_TYPE}" = "2" ] ; then
    EXTENSIONS=client_extensions
else
    EXTENSIONS=server_extensions
fi

## input PKCS12_PWD
read -p 'Please input pkcs12 file password [123456]: ' PKCS12_PWD
PKCS12_PWD=${PKCS12_PWD:-123456}

CERT_DIR=certs/${CERT_NAME}

if [ -d "${CERT_DIR}" ]; then
    echo "Error, target certificate exists."
    exit 1
fi

rm -rf "${CERT_DIR}"
mkdir -p "${CERT_DIR}"
cd "${CERT_DIR}"

## 1. generate key and csr
openssl genrsa -out key.pem 2048
echo "--- key generated."
openssl req -new -sha512 -key key.pem -out req.pem -outform PEM -subj /CN="${CERT_NAME}"/ -nodes
echo "--- csr generated."

## 2. sign by CA
cd "../${CA_NAME}"
# add subjectAltName for server certifiate
cp openssl.cnf openssl_tmp.cnf
echo -n "subjectAltName = DNS:${CERT_NAME}" >> openssl_tmp.cnf
if [ "${SAN}" ] ; then
    echo ", ${SAN}" >> openssl_tmp.cnf
fi
openssl ca -md sha512 -config openssl_tmp.cnf -in "../${CERT_NAME}/req.pem" -out "../${CERT_NAME}/cert.pem" -notext -batch -extensions ${EXTENSIONS} 
rm -rf openssl_tmp.cnf
echo "--- signed by CA"

## 3. export and convert format
cd "../${CERT_NAME}"

cp cert.pem certs.pem
cat ../${CA_NAME}/cacerts.pem >> certs.pem
echo "--- certs.pem generated."

openssl pkcs12 -export -out keycert.p12 -in cert.pem -inkey key.pem -passout pass:${PKCS12_PWD}
echo "--- keycert.p12 generated."

openssl pkcs12 -export -out keycerts.p12 -in certs.pem -inkey key.pem -passout pass:${PKCS12_PWD}
echo "--- keycerts.p12 generated."

openssl x509 -in cert.pem -out cert.cer -outform DER
echo "--- cert.cer generated."

cd ../..
