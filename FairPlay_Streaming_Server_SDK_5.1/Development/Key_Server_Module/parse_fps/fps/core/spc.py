#!/usr/bin/env python3
#
# Copyright © 2023-2024 Apple Inc. All rights reserved.
#
from Crypto.Cipher import AES
from Crypto.Cipher import PKCS1_OAEP
from Crypto.Hash import SHA256
from fps.core.TLLVContainer import TLLVContainer
from fps.core.utilities import format_hex
import binascii
import base64
import logging


class SPC(TLLVContainer):

    def __init__(self):
        self.version = int()
        self.reserved = bytes()
        self.data_iv = bytes()  # Terminology: SPC data = SPC encrypted payload
        self.encrypted_AES128_key = bytes()
        self.certificate_hash = bytes()
        self.payload_length = int()
        self.data = bytes()
        self.spck = bytes()
        self.dask = bytes()
        # Init self.payload, self.tllvs and self.tag_TLLVs
        super().__init__()

    def select_credential(self, credentials):
        logging.debug(f'select credential matching: {format_hex(self.certificate_hash, cols=20)}')
        for c in credentials:
            logging.debug(f'trying: {c}')
            # Older devices may use the full certificate bundle hash instead of just the 1024 portion
            if self.version == 1 and (c.cert_hash_1024 == self.certificate_hash or c.cert_hash_full == self.certificate_hash):
                logging.debug(f'cert hash match using v1!')
                return c
            elif self.version == 2 and c.cert_hash_2048 == self.certificate_hash:
                logging.debug(f'cert hash match using v2!')
                return c

    def parse(self, spc, credentials=[]):
        """ Parse the incoming SPC message

        credentials is the list of credentials supported by the server
        """

        # Open the spc
        with open(spc, "rb") as f:
            raw_spc = f.read()
            try:
                raw_spc = base64.b64decode(raw_spc)
            except binascii.Error:
                pass

        # Parse the container
        self.parse_container(raw_spc)

        # Select the proper credential
        #
        # A server can be identified with several certificates.
        # The SPC needs to select the proper certificate babsed on the certificate_hash field.
        credential = self.select_credential(credentials)
        if not credential:
            logging.error("No credential found, cannot uncipher SPCK to parse further")
            return

        try:
            # Decrypt encrypted_AES128_key to obtain spck
            self.decrypt_encrypted_AES128_key(credential)
        except:
            logging.error("Private key is incorrect")
            return

        # Decrypt the SPC payload
        self.decrypt_payload()

        # Parse the SPC payload
        self.parse_TLLVs()

        # decrypt sk_r1
        self.tllvs['sk_r1'].decrypt(self.tllvs, self.certificate_hash, credential)

    def parse_container(self, raw_spc):
        # Parse the SPC container
        assert len(raw_spc) >= 24
        self.version = int.from_bytes(raw_spc[0:4], byteorder="big")
        assert self.version in (1, 2)
        self.reserved = raw_spc[4:8]
        self.data_iv = raw_spc[8:24]
        if self.version == 1:
            self.encrypted_AES128_key = raw_spc[24:152]
            self.certificate_hash = raw_spc[152:172]
            self.payload_length = int.from_bytes(raw_spc[172:176], byteorder="big")
            self.data = raw_spc[176:]
        else:
            assert len(raw_spc) >= 304
            self.encrypted_AES128_key = raw_spc[24:280]
            self.certificate_hash = raw_spc[280:300]
            self.payload_length = int.from_bytes(raw_spc[300:304], byteorder="big")
            self.data = raw_spc[304:]

        # Assert SPC container
        assert self.reserved == bytes([0, 0, 0, 0])
        assert self.payload_length == len(self.data)

    def decrypt_encrypted_AES128_key(self, credential):
        if self.version == 1:
            self.spck = PKCS1_OAEP.new(credential.pkey_1024).decrypt(self.encrypted_AES128_key)
        else:
            self.spck = PKCS1_OAEP.new(credential.pkey_2048, hashAlgo=SHA256).decrypt(self.encrypted_AES128_key)

    def decrypt_payload(self):
        self.payload = AES.new(self.spck, AES.MODE_CBC, self.data_iv).decrypt(self.data)

    def check_integrity(self):
        assert self.tllvs["sk_r1"].integrity == self.tllvs[
            "sk_r1_integrity"].value, "[SK..R1] integrity bytes do not match the value in SKR1 Integrity tag"

    def __str__(self):
        s = ""
        s += "=" * 80 + "\n"
        s += "SPC container\n\n"
        try:
            s += f"version:    {self.version}" + "\n"
            s += "reserved:   " + format_hex(self.reserved, "")
            s += "data iv:    " + format_hex(self.data_iv, "")
            s += "encrypted AES128 key:\n" + format_hex(self.encrypted_AES128_key, " "*12)
            s += "certificate hash:\n" + format_hex(self.certificate_hash, indent=" "*12)
            s += f"payload length: {self.payload_length:#x}\n"
            s += "SPCK:       " + format_hex(self.spck)
            s += "DASk:       " + format_hex(self.dask)
            s += f"\n"
            if self.tllvs:
                s += "*" * 80 + "\n"
                s += "SPC payload\n\n"
                s += super().__str_tllvs__()
        except AttributeError as e:
            raise e
        return s
