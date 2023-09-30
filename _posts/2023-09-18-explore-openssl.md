---
layout: post
title: "Automating OpenSSL with a Bash Script: Certificate Management Made Easy"
image: assets/images/openssl_gen.jpg
tags: [scripts]
date: 2023-09-18
categories: [security, openssl]
author: vkosuri
tags: [featured]
---

OpenSSL is a Swiss Army knife for managing digital certificates and performing cryptographic tasks. In this post, we'll embark on a journey to discover a powerful OpenSSL bash script that can help us secure our systems and data. Not only will we provide the script, but we'll also walk you through its functionality.

## The OpenSSL Bash Script

Below is the bash script that leverages OpenSSL for a variety of security-related tasks. This script covers everything from certificate generation to encryption and hashing:

<script src="https://gist.github.com/vkosuri/dbc5f375c6a461b49d0cc3022b045d0d.js"></script>

## Configuration File for CA Certificate (ca-config.cnf):

In the OpenSSL bash script, we create a temporary configuration file called ca-config.cnf to specify the parameters for generating the CA certificate. This configuration file is used as input when generating the certificate to define the Subject and extensions.

```bash
cat > ca-config.cnf << EOF
[req]
default_bits = 2048
prompt = no
distinguished_name = dn

[dn]
C = ${country_code}
CN = ${common_name}
EOF
```
- [req]: This section defines the settings for certificate request generation. default_bits specifies the key size (2048 bits in this example), prompt is set to no to avoid prompting for certificate details interactively, and distinguished_name points to the dn section for Subject details.
- [dn]: This section defines the Subject field of the certificate, which includes the Country (C) and Common Name (CN). ${country_code} and ${common_name} are variables passed as command line arguments.

### Generating the CA Certificate:

The script generates the CA certificate with the specified Subject and extensions using the openssl req command:
```bash
openssl req -new -x509 -key "${output_prefix}_private.pem" -out "${output_prefix}_public.pem" -config ca-config.cnf -extensions v3_ca -subj "/C=${country_code}/CN=${common_name}/SAN=${san}"
```
- -new: This option specifies that a new certificate request should be created.
- -x509: This option indicates that a self-signed certificate should be generated.
- -key "${output_prefix}_private.pem": This specifies the private key file to use.
- -out "${output_prefix}_public.pem": This specifies the output file for the generated CA certificate.
- -config ca-config.cnf: This specifies the configuration file with the certificate details.
- -extensions v3_ca: This includes the v3_ca extension in the certificate, which is typically used for CA certificates.
- -subj "/C=${country_code}/CN=${common_name}/SAN=${san}": This sets the Subject of the certificate, including the country code (C), Common Name (CN), and Subject Alternative Name (SAN) based on the provided arguments.

### Cleaning Up:

After generating the CA certificate, the script removes the temporary configuration file (ca-config.cnf) to clean up the workspace:
```bash
rm -f ca-config.cnf
```
This step ensures that the temporary configuration file is not left behind after the certificate generation is complete.

Overall, these added sections allow the script to create a CA certificate with specific Subject details (Common Name, Country) and extensions (v3_ca and SAN) using OpenSSL.

## Generating Self-Signed Certificates
One of the essential tasks in securing a web server is generating a self-signed certificate. This script simplifies the process:
```bash
# To generate a self-signed certificate, run:
# ./openssl_script.sh gen-self-signed-cert mycert
```

## Encrypting Files with Ease
Data encryption is crucial for protecting sensitive information. Our script makes it a breeze:
```bash
# To encrypt a file using AES-256-CBC encryption, use:
# ./openssl_script.sh encrypt-file input.txt encrypted.enc
```
This command will encrypt "input.txt" and save it as "encrypted.enc."

## Calculating Secure Hashes
Hashing is fundamental for data integrity and password storage. Our script supports SHA-256 hashing:
```bash
# To create a SHA-256 hash of a file, run:
# ./openssl_script.sh hash-file data.txt file.sha256
```

## Enhancing Your Security Toolbox

By now, you should have a firm grasp of the script's capabilities. Whether you need to secure communication, protect sensitive files, or verify data integrity, OpenSSL, combined with this script, can be your trusted companion.

Remember that security is an ever-evolving field, and staying informed and up-to-date is key. Explore the OpenSSL documentation to dive deeper into its capabilities.

As you continue to refine your security practices, may this script serve as a valuable asset in your quest for a safer digital world.

Happy scripting, and stay secure!