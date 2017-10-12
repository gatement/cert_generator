#!/bin/sh

## input CERT_NAME
read -p 'What is the certificate common name? [debug.example.com]: ' CERT_NAME
if [ "x" == "x${CERT_NAME}" ] ; then
    CERT_NAME=debug.example.com
fi

## input CA_NAME
read -p 'Which CA will sign the certificate? [RootCA]: ' CA_NAME
if [ "x" == "x${CA_NAME}" ] ; then
    CA_NAME=RootCA
fi

## input EXTENSIONS
read -p 'What is the certificate type? 1(server) or 2(client)? [1]: ' CERT_TYPE
if [ "x" == "x${CERT_TYPE}" ] ; then
    EXTENSIONS=server_extensions
elif [ "1" == "${CERT_TYPE}" ] ; then
    EXTENSIONS=server_extensions
elif [ "2" == "${CERT_TYPE}" ] ; then
    EXTENSIONS=client_extensions
fi

## input PKCS12_PWD
read -p 'Please input pkcs12 file password [123456]: ' PKCS12_PWD
if [ "x" == "x${PKCS12_PWD}" ] ; then
    PKCS12_PWD=123456
fi

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
openssl req -new -key key.pem -out req.pem -outform PEM -subj /CN="${CERT_NAME}"/ -nodes

## 2. sign by CA
cd "../${CA_NAME}"
openssl ca -config openssl.cnf -in "../${CERT_NAME}/req.pem" -out "../${CERT_NAME}/cert.pem" -notext -batch -extensions ${EXTENSIONS} 

## 3. export and convert format
cd "../${CERT_NAME}"
openssl pkcs12 -export -out keycert.p12 -in cert.pem -inkey key.pem -passout pass:${PKCS12_PWD}
openssl x509 -in cert.pem -out cert.cer -outform DER

cd ../..
