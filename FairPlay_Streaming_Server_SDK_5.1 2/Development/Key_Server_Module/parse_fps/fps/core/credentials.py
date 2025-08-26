#!/usr/bin/env python3
#
# Copyright © 2023-2024 Apple Inc. All rights reserved.
#

from Crypto.Hash import SHA
from Crypto.PublicKey import RSA
from fps.core.utilities import format_hex
import logging


def load_config_into_credentials(config):
    credentials = []
    for elem in config:
        try:
            credentials.append(Credentials(**elem))
        except:
            logging.warning(f"Failed to load credentials:{elem}")
            pass
    return credentials

class Credentials:
    """Identify a digital authority"""

    def __init__(self, provisioning_data, cert, pkey_1024 = None, pkey_2048 = None):

        self.pkey_1024_str = pkey_1024
        self.pkey_2048_str = pkey_2048
        self.cert_str = cert
        self.cert_hash_1024 = bytes()
        self.cert_hash_2048 = bytes()
        self.cert_hash_full = bytes()
        self.provisioning_data_str = provisioning_data

        logging.debug(f"trying to load:{self}")

        # Import 1024-bit private key (optional)
        if pkey_1024 != None:
            try:
                with open(pkey_1024, "r") as f:
                    self.pkey_1024 = RSA.importKey(f.read())
                assert self.pkey_1024.size_in_bits() == 1024, f"{pkey_1024} is not a 1024-bit key"
            except Exception as e:
                logging.warning(f"Unable to import key from credentials file {self.pkey_1024_str}: {e}")
                raise e

        # Import 2048-bit private key (optional)
        if pkey_2048 != None:
            try:
                with open(pkey_2048, "r") as f:
                    self.pkey_2048 = RSA.importKey(f.read())
                assert self.pkey_2048.size_in_bits() == 2048, f"{pkey_2048} is not a 2048-bit key"
            except Exception as e:
                logging.warning(f"Unable to import key from credentials file {self.pkey_2048_str}: {e}")
                raise e

        # Import cert
        try:
            with open(cert, "rb") as f:
                cert_data = f.read()

                sequence_bytes = int.from_bytes(cert_data[0:2], byteorder="big")
                length1 = 4 + int.from_bytes(cert_data[2:4], byteorder="big")
                if sequence_bytes == 0x3082 and length1 < len(cert_data):
                    # Assume the certificate is a concatenation of the 1024 and 2048 bit certs.
                    # Save the hash of each one separately.
                    self.cert_hash_1024 = SHA.new(cert_data[:length1]).digest()
                    self.cert_hash_2048 = SHA.new(cert_data[length1:]).digest()
                    # Also save the full hash to be compatible with some older v1 devices.
                    self.cert_hash_full = SHA.new(cert_data).digest()
                elif pkey_2048 == None:
                    # For testing purposes, allow only the 1024-bit cert to be provided.
                    self.cert_hash_1024 = SHA.new(cert_data).digest()
                elif pkey_1024 == None:
                    # For testing purposes, allow only the 2048-bit cert to be provided.
                    self.cert_hash_2048 = SHA.new(cert_data).digest()
                else:
                    raise Exception("Two private keys provided, but certificate bundle only has one certificate.")

        except Exception as e:
            logging.warning(f"Unable to read certificate file {self.cert_str}: {e}")
            raise e

        # Import provisioning data
        try:
            with open(provisioning_data, 'rb') as f:
                self.provisioning_data = f.read()
        except Exception as e:
            logging.warning(f"Unable to import provisioning data from file {self.provisioning_data_str}: {e}")
            raise e

        logging.debug(f"loaded:{self}")

    def __str__(self):
        s = "\n"
        s += f"\tprivate key (1024-bit): {self.pkey_1024_str}\n"
        s += f"\tprivate key (2048-bit): {self.pkey_2048_str}\n"
        s += f"\tcertificate:            {self.cert_str}\n"
        s += f"\tcert hash (1024-bit):   {format_hex(self.cert_hash_1024, cols=20)}"
        s += f"\tcert hash (2048-bit):   {format_hex(self.cert_hash_2048, cols=20)}"
        s += f"\tcert hash (full):       {format_hex(self.cert_hash_full, cols=20)}"
        s += f"\tprovisioning data:      {self.provisioning_data_str}\n"
        return s
