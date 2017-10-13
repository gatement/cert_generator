#!/bin/sh

## input INTERMEDIATE_CA_NAME
read -p 'What is the intermediate CA certificate common name? [IntermediateCA]: ' INTERMEDIATE_CA_NAME
if [ "x" == "x${INTERMEDIATE_CA_NAME}" ] ; then
    INTERMEDIATE_CA_NAME=IntermediateCA
fi

## input CA_NAME
read -p 'Which CA will sign the certificate? [RootCA]: ' CA_NAME
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

CERT_DIR=certs/${INTERMEDIATE_CA_NAME}

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

## 1. generate key and csr
openssl genrsa -out private/cakey.pem 2048
openssl req -new -sha512 -key private/cakey.pem -out req.pem -outform PEM -subj /CN="${INTERMEDIATE_CA_NAME}"/ -nodes

## 2. sign by CA
cd "../${CA_NAME}"
openssl ca -md sha512 -config openssl.cnf -in "../${INTERMEDIATE_CA_NAME}/req.pem" -out "../${INTERMEDIATE_CA_NAME}/cacert.pem" -notext -batch -extensions ca_extensions 

## 3. export and convert format
cd "../${INTERMEDIATE_CA_NAME}"
openssl pkcs12 -export -out cakeycert.p12 -in cacert.pem -inkey private/cakey.pem -passout pass:${PKCS12_PWD}
openssl x509 -in cacert.pem -out cacert.cer -outform DER

cd ../..

