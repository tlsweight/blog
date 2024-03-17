---
layout: post
title: "Integrating OpenSSL with OQS Providers for Enhanced Quantum-Safe Security"
image: assets/images/crypto/openssl_oqs.png
date: 2023-12-06
categories: [security, OpenSSL, OQS, Quantum-Safe]
author: vkosuri
tags: [featured]
---

In the rapidly evolving landscape of quantum computing, ensuring quantum-safe security protocols is more critical than ever. OpenSSL, a widely used toolkit for SSL and TLS protocols, has extended its capabilities to include support for quantum-safe algorithms through [Open Quantum Safe (OQS) providers](https://github.com/open-quantum-safe/oqs-provider). This integration heralds a new era in cybersecurity, preparing systems for the quantum future.

## What are OpenSSL OQS Providers?
OpenSSL OQS providers are modules that enable OpenSSL to utilize quantum-resistant algorithms. These providers are crucial for maintaining secure communication in the post-quantum era. They integrate seamlessly with OpenSSL, ensuring compatibility with existing systems while offering advanced protection against quantum threats.
Installing and Activating an OQS Provider

## Setting the Stage for OpenSSL and OQS Integration

1. **Environment Preparation:**
   We begin by setting up our environment, designating directories for OpenSSL (`/opt/openssl`), liboqs (`/opt/liboqs`), and the OQS provider (`/opt/oqs-provider`). These paths are crucial for organized installation and management.

2. **Script Mechanics:**
   Our script employs error handling (`set -e`) to ensure any issues are caught promptly. It's all about precision and efficiency, utilizing available CPU cores (`$(nproc)`) to expedite the build process.

3. **Clean Slate:**
   We clear out any existing directories (`/optbuild/liboqs`, `/optbuild/openssl`, `/optbuild/oqs-provider`) to avoid conflicts and ensure a fresh start.

```sh
#!/bin/bash

# Enable error handling
set -e

# Set up environment and variables
INSTALLDIR_OPENSSL="/opt/openssl"
INSTALLDIR_LIBOQS="/opt/liboqs"
INSTALLDIR_PROVIDER="/opt/oqs-provider"
LIBOQS_BUILD_DEFINES="ON"
OQS_ALGS_ENABLED="STD"
OQS_MINIMAL_BUILD="KEM_kyber_768"
MAKE_DEFINES="-j $(nproc)"  # Use all available cores
SIG_ALG="dilithium3"

# clenup dirs if exists
echo "clenup dirs if exists"
rm -rf /optbuild/liboqs /optbuild/openssl /optbuild/oqs-provider
```

## The Integration Odyssey

1. **Cloning Repositories:**
   The journey involves cloning the latest versions of OpenSSL, liboqs, and the OQS provider from their respective GitHub repositories. This step is crucial to obtain the most up-to-date and secure versions.

   ```sh
    # List of repositories and branches to clone
    repos=(
        "https://github.com/openssl/openssl.git openssl-3.2"
        "https://github.com/open-quantum-safe/liboqs main"
        "https://github.com/open-quantum-safe/oqs-provider.git main"
    )

    # Function to clone a repository
    clone_repo() {
        repo_url=$(echo "$1" | awk '{print $1}')
        branch=$(echo "$1" | awk '{print $2}')
        if git clone --depth 1 --branch "$branch" "$repo_url"; then
            echo "Successfully cloned $repo_url"
        else
            echo "Error cloning $repo_url" >&2
            exit 1
        fi
    }

    # Export it so it's available to parallel
    export -f clone_repo

    mkdir -p /optbuild && cd /optbuild || exit

    # Call the function with xargs
    printf '%s\n' "${repos[@]}" | xargs -I {} -P 4 bash -c 'clone_repo "$@"' _ {}
   ```

2. **Building OpenSSL:**
   Next, we compile and install OpenSSL, tweaking library paths to ensure smooth operation. This step lays the groundwork for integrating the OQS provider.
   ```sh
    # Build OpenSSL
    cd openssl || exit
    LDFLAGS="-Wl,-rpath -Wl,${INSTALLDIR_OPENSSL}/lib64" ./config shared --prefix="${INSTALLDIR_OPENSSL}"
    make ${MAKE_DEFINES} 2>&1 >/dev/null
    make install 2>&1 >/dev/null
    if [ -d "${INSTALLDIR_OPENSSL}/lib64" ]; then
        ln -s "${INSTALLDIR_OPENSSL}/lib64" "${INSTALLDIR_OPENSSL}/lib"
    fi
    if [ -d "${INSTALLDIR_OPENSSL}/lib" ]; then
        ln -s "${INSTALLDIR_OPENSSL}/lib" "${INSTALLDIR_OPENSSL}/lib64"
    fi

   ```

3. **Assembling liboqs:**
   We then build liboqs with custom settings to enable specific quantum-safe algorithms, adjusting for performance and compatibility.
   ```sh
    # Build liboqs
    cd /optbuild/liboqs || exit
    mkdir -p build
    cmake -S . -B build \
        -DCMAKE_ASM_FLAGS='-Wa,--noexecstack' \
        -DOPENSSL_ROOT_DIR="${INSTALLDIR_OPENSSL}" \
        -DCMAKE_BUILD_TYPE=Debug \
        -DOQS_ALGS_ENABLED="${OQS_ALGS_ENABLED}" \
        -DOQS_DIST_BUILD="${LIBOQS_BUILD_DEFINES}" \
        -DOQS_OPT_TARGET=generic \
        -DOQS_MINIMAL_BUILD="${OQS_MINIMAL_BUILD}"

    cmake --build build --parallel $(nproc)
    cmake --build build --target install
   ```

4. **OQS Provider Installation:**
   Finally, the OQS provider is compiled and installed. We tweak the OpenSSL configuration to recognize and activate the new provider, marking the culmination of our integration process.
   ```sh
    # Build oqs-provider
    cd /optbuild/oqs-provider || exit
    liboqs_DIR="${INSTALLDIR_LIBOQS}" cmake -DOPENSSL_ROOT_DIR="${INSTALLDIR_OPENSSL}" -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH="${INSTALLDIR_OPENSSL}" -S . -B _build
    cmake --build _build
    cmake --install _build
    cp _build/lib/oqsprovider.so "${INSTALLDIR_OPENSSL}/lib64/ossl-modules"
    sed -i "s/default = default_sect/default = default_sect\noqsprovider = oqsprovider_sect/g" "${INSTALLDIR_OPENSSL}/ssl/openssl.cnf"
    sed -i "s/\[default_sect\]/\[default_sect\]\nactivate = 1\n\[oqsprovider_sect\]\nactivate = 1\n/g" "${INSTALLDIR_OPENSSL}/ssl/openssl.cnf"
    sed -i "s/providers = provider_sect/providers = provider_sect\nssl_conf = ssl_sect\n\n\[ssl_sect\]\nsystem_default = system_default_sect\n\n\[system_default_sect\]\nGroups = \$ENV\:\:DEFAULT_GROUPS\n/g" "${INSTALLDIR_OPENSSL}/ssl/openssl.cnf"
    sed -i "s/HOME\t\t\t= ./HOME           = .\nDEFAULT_GROUPS = kyber768/g" "${INSTALLDIR_OPENSSL}/ssl/openssl.cnf"
    ```

5. **Verification:**
   A key step is to verify our setup. We check the OpenSSL version and list the available providers to confirm that our OQS provider is successfully integrated.
   ```sh
    # Verify openssl version and providers
    /opt/openssl/bin/openssl version -a
    /opt/openssl/bin/openssl list -providers
    ```

The script found github gist as well https://gist.github.com/vkosuri/09a7e66a745d6cf3933e76100e5e729e

## Embracing a Quantum-Safe Future

This script doesn't just represent a set of commands; it's a gateway to a new era of quantum-safe encryption. By integrating OQS providers with OpenSSL, we're taking a proactive stance against the looming quantum threat, ensuring our digital communications remain secure and confidential.

In conclusion, the integration of OpenSSL with OQS providers is more than a technical task; it's a necessary step in our ongoing journey towards a secure digital future. This guide, inspired by a shell script, is a testament to the power of open-source collaboration and innovation in the face of emerging cybersecurity challenges.