#!/bin/sh

## input CA_NAME
read -p 'What is the CA certificate common name? [RootCA]: ' CA_NAME
if [ "x" == "x${CA_NAME}" ] ; then
    CA_NAME=RootCA
fi

## input VALIDATE_YEARS
read -p 'How many years this and issued certificates will expire? [20]: ' VALIDATE_YEARS
if [ "x" == "x${VALIDATE_YEARS}" ] ; then
    VALIDATE_YEARS=20
fi
VALIDATE_DAYS=$((VALIDATE_YEARS * 365))

## input PKCS12_PWD
read -p 'Please input pkcs12 file password [123456]: ' PKCS12_PWD
if [ "x" == "x${PKCS12_PWD}" ] ; then
    PKCS12_PWD=123456
fi

CERT_DIR=certs/${CA_NAME}

if [ -d "${CERT_DIR}" ]; then
    echo "Error, target certificate exists."
    exit 1
fi

rm -rf "${CERT_DIR}"
mkdir -p "${CERT_DIR}"
cd "${CERT_DIR}"

mkdir certs private
chmod 700 private
echo 01 > serial
touch index.txt
cp ../../openssl.cnf .

## 1. create self-sign CA
openssl req -x509 -config openssl.cnf -newkey rsa:2048 -days ${VALIDATE_DAYS} -out cacert.pem -outform PEM -subj /CN="${CA_NAME}"/ -nodes

## 2. export and convert format
openssl pkcs12 -export -out cakeycert.p12 -in cacert.pem -inkey private/cakey.pem -passout pass:${PKCS12_PWD}
openssl x509 -in cacert.pem -out cacert.cer -outform DER

cd ../..