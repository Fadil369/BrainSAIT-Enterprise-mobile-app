#!/usr/bin/env python3
#
# Copyright © 2023-2025 Apple Inc. All rights reserved.
#

from Crypto.Cipher import AES
from collections import defaultdict
from datetime import datetime, timedelta
from fps.core.utilities import format_hex
from fps.core.TLLV import TLLV, TLLV_MAP, Unknown
import logging

def decrypt_sk_r1(sk_r1, tllv_map, certificate_hash, credentials):
    import ctypes as ct

    class Key_Payload(ct.Structure):
        _fields_ = [("version", ct.c_uint8),
                    ("contentKey", ct.POINTER(ct.c_uint8)), ("contentKeyLength", ct.c_uint64),
                    ("contentIV", ct.POINTER(ct.c_uint8)), ("contentIVLength", ct.c_uint64),
                    ("contentType", ct.c_uint64),
                    ("SK_R1", ct.POINTER(ct.c_uint8)), ("SK_R1Length", ct.c_uint64),
                    ("R2", ct.POINTER(ct.c_uint8)), ("R2Length", ct.c_uint64),
                    ("R1Integrity", ct.POINTER(ct.c_uint8)), ("R1IntegrityLength", ct.c_uint64),
                    ("supportedKeyFormats", ct.POINTER(ct.c_uint64)), ("numberOfSupportedKeyFormats", ct.c_uint64),
                    ("cryptoVersionUsed", ct.c_uint64),
                    ("provisioningData", ct.POINTER(ct.c_uint8)), ("provisioningDataLength", ct.c_uint64),
                    ("certHash", ct.POINTER(ct.c_uint8)), ("certHashLength", ct.c_uint64),
                    ("clientHU", ct.POINTER(ct.c_uint64)), ("clientHULength", ct.c_uint64),
                    ("contentKeyTLLVTag", ct.c_uint64),
                    ("contentKeyTLLVPayload", ct.POINTER(ct.c_uint8)), ("contentKeyTLLVPayloadLength", ct.c_uint64),
                    ("R1", ct.POINTER(ct.c_uint8)), ("R1Length", ct.c_uint64)]

    content_key = bytes(16)
    content_iv = bytes(16)
    client_hu = bytes(20)
    content_key_payload = bytes(1024)
    r1 = bytes(44)

    if 'supported_key_formats' in tllv_map:
        supported_key_formats = (ct.c_uint64 * len(tllv_map['supported_key_formats'].supported_key_formats))(*tllv_map['supported_key_formats'].supported_key_formats)
        supported_key_formats_count = tllv_map['supported_key_formats'].number_of_keys
    else:
        # Use default value of FPSKeyFormatTag::buf16Byte if not present
        supported_key_formats = (ct.c_uint64 * 1) (0x58b38165af0e3d5a)
        supported_key_formats_count = 1

    payload = Key_Payload(1,
                            ct.cast(content_key, ct.POINTER(ct.c_uint8)), 16, # content key
                            ct.cast(content_iv, ct.POINTER(ct.c_uint8)), 16, # content IV
                            0, # content type
                            ct.cast(sk_r1, ct.POINTER(ct.c_uint8)), len(sk_r1), # SK R1
                            ct.cast(tllv_map['r2'].value, ct.POINTER(ct.c_uint8)), tllv_map['r2'].value_length, # R2
                            ct.cast(tllv_map['sk_r1_integrity'].value, ct.POINTER(ct.c_uint8)), tllv_map['sk_r1_integrity'].value_length, # R1 integrity
                            ct.cast(supported_key_formats, ct.POINTER(ct.c_uint64)), supported_key_formats_count, # supported key formats
                            tllv_map['protocol_versions_used'].protocol_versions_used, # crypto version used
                            ct.cast(credentials.provisioning_data, ct.POINTER(ct.c_uint8)), len(credentials.provisioning_data), # provisioning data
                            ct.cast(certificate_hash, ct.POINTER(ct.c_uint8)), len(certificate_hash), # cert hash
                            ct.cast(client_hu, ct.POINTER(ct.c_uint64)), len(client_hu), # client HU
                            0, # content key tllv tag
                            ct.cast(content_key_payload, ct.POINTER(ct.c_uint8)), len(content_key_payload), # content key payload
                            ct.cast(r1, ct.POINTER(ct.c_uint8)), 44)  # R1
    try:
        fplib = ct.CDLL("libfpscrypto.dylib")
    except OSError:
        fplib = ct.CDLL("libfpscrypto.so")

    # Call into library to get r1 and hu
    result = fplib.KSMCreateKeyPayload(ct.byref(payload))
    # Verify library call returned successfully
    if result != 0:
        logging.error(f"KSMCreateKeyPayload returned {result}. HU and R1 are unknown!")

    return (r1, client_hu)

class SK_R1(TLLV):
    NAME = "[SK..R1]"
    FIELD = "sk_r1"
    TAG = 0x3d1a10b8bffac2ec

    def parse(self):
        assert self.value_length == 0x70
        self.iv = self.value[0:16]
        self.encrypted_payload = self.value[16:16 + 96]

    def decrypt(self, tllv_map, certificate_hash, credentials):
        (self.r1, self.hu) = decrypt_sk_r1(self.value, tllv_map, certificate_hash, credentials)

    def __str__(self):
        s = ""
        s += super().__str__()
        try:
            s += "\tHU:\n" + format_hex(self.hu, "\t\t")
            s += "\tR1:\n" + format_hex(self.r1, "\t\t")
        except AttributeError as e:
            print(e)

        return s


class SK_R1_Integrity(TLLV):
    NAME = "[SK..R1] integrity"
    FIELD = "sk_r1_integrity"
    TAG = 0xb349d4809e910687

    def parse(self):
        assert self.value_length == 16, "[SK..R1] Integrity is a 16-byte value."


class AR_seed(TLLV):
    NAME = "Anti-replay seed"
    FIELD = "ar_seed"
    TAG = 0x89c90f12204106b2

    def parse(self):
        assert self.value_length == 16


class R2(TLLV):
    NAME = "R2"
    FIELD = "r2"
    TAG = 0x71b5595ac1521133

    def parse(self, *args):
        assert self.value_length == 21


class Return_Request(TLLV):
    NAME = "Return Request"
    FIELD = "return_request"
    TAG = 0x19f9d4e5ab7609cb

    def parse(self):
        assert self.value_length % 8 == 0

        self.tags = []
        data = self.value
        while data:
            self.tags.append(int.from_bytes(data[0:8], byteorder="big"))
            data = data[8:]

    def __str__(self):
        s = super().__str__()
        s += "\t\tRequested tags:\n"
        for tag in self.tags:
            s += f"\t\t\t{tag:#018x} -- {TLLV_MAP[tag].NAME}\n"
        return s


class Asset_ID(TLLV):
    NAME = "Asset ID"
    FIELD = "asset_id"
    TAG = 0x1bf7f53f5d5d5a1f

    def parse(self):
        assert 2 <= self.value_length <= 200

    def __str__(self):
        s = super().__str__()
        try:
            s += f"\tasset: {self.value.decode()}\n"
        except UnicodeError:
            pass
        return s


class Transaction_ID(TLLV):
    NAME = "Transaction ID"
    FIELD = "transaction_id"
    TAG = 0x47aa7ad3440577de

    def parse(self):
        assert self.value_length == 8


class Protocol_Versions_Supported(TLLV):
    NAME = "Protocol Versions Supported"
    FIELD = "protocol_versions_supported"
    TAG = 0x67b8fb79ecce1a13

    def parse(self):
        assert self.value_length % 4 == 0, "{self.NAME} is a concatenation of 4 byte-values"

        self.protocol_versions_supported = []
        data = self.value
        while data:
            self.protocol_versions_supported.append(int.from_bytes(data[0:4], byteorder="big"))
            data = data[4:]

    def __str__(self):
        s = ""
        s += super().__str__()
        s += f"\tversions supported: {self.protocol_versions_supported}\n"
        return s


class Protocol_Versions_Used(TLLV):
    NAME = "Protocol Versions Used"
    FIELD = "protocol_versions_used"
    TAG = 0x5d81bcbcc7f61703

    def parse(self):
        assert self.value_length == 4
        self.protocol_versions_used = int.from_bytes(self.value, byteorder="big")

    def __str__(self):
        s = ""
        s += super().__str__()
        s += f"\tversion used: {self.protocol_versions_used}\n"
        return s


class Streaming_Indicator(TLLV):
    NAME = "Streaming Indicator"
    FIELD = "streaming_indicator"
    TAG = 0xabb0256a31843974

    STREAMING_INDICATOR = defaultdict(lambda: "Content playback will occur on the requesting device")
    STREAMING_INDICATOR.update({
        0xabb0256a31843974: "Content will be sent by AirPlay to an Apple TV box or FPS-enabled TV or STB",
        0x5f9c8132b59f2fde: "Content will be sent to an Apple digital AV adapter",
        })

    def parse(self):
        assert self.value_length == 8
        self.indicator = int.from_bytes(self.value, byteorder="big")

    def __str__(self):
        s = ""
        s += super().__str__()
        s += f"\t{self.indicator:#x}: {self.STREAMING_INDICATOR[self.indicator]}\n"
        return s


class Media_Playback_State(TLLV):
    """ Also called Client Reference Time """

    NAME = "Media Playback State"
    FIELD = "media_playback_state"
    TAG = 0xeb8efdf2b25ab3a0

    PLAYBACK_STATE = {
        0xf4dee5a2: ("State 1: The Apple device is ready to start playing. "
            "The response CKC must contain a valid content key."),
        0xa5d6739e: ("State 2: The playback stream is playing or paused. "
            "The KSM must reply with a CKC containing a rent/lease response TLLV, "
            "but it does not need to contain a valid content key."),
        0x4f834330: ("State 3: The playback stream is playing, but the lease is about to expire."
            "The response CKC must contain a valid content key."),
        }

    def parse(self):
        assert self.value_length == 16
        self.creation_date = int.from_bytes(self.value[0:4], byteorder="big")
        self.playback_state = int.from_bytes(self.value[4:8], byteorder="big")
        self.session_id = int.from_bytes(self.value[8:16], byteorder="big")
        assert self.playback_state in self.PLAYBACK_STATE

    def __str__(self):
        s = ""
        s += super().__str__()
        s += f'\tcreation date: {datetime.fromtimestamp(self.creation_date).strftime("%c")}\n'
        s += f"\tplayback:      {self.PLAYBACK_STATE[self.playback_state]}\n"
        s += f"\tsession id:    {self.session_id:#x}\n"
        return s


class Capabilities(TLLV):
    NAME = "Capabilities"
    FIELD = "capabilities"
    TAG = 0x9c02af3253c07fb2

    LV_BITFIELD = {
            0: "HDCP type 1 enforcement",
            1: "offline key",
            2: "check-in (secure delete)",
            3: "offline key TLLV v2",
            4: "enforcement of security level Baseline",
            5: "enforcement of security level Main",
            }

    def parse(self):
        assert self.value_length == 16
        self.HV = bin(int.from_bytes(self.value[0:8], byteorder="big"))[:1:-1]
        self.LV = bin(int.from_bytes(self.value[8:16], byteorder="big"))[:1:-1]

    def __str__(self):
        s = ""
        s += super().__str__()
        for i, bit in enumerate(self.LV):
            if i in self.LV_BITFIELD:
                s += f"\t\tLV bit {i:>2d}: {self.LV_BITFIELD[i]}" + (" not", "")[int(bit)] + " supported\n"
        return s


class Offline_Sync(TLLV):
    NAME = "Offline Sync"
    FIELD = "offline_sync"
    TAG = 0x77966de1dc1083ad

    FLAGS = {
            0: "The client requested a sync.",
            1: "The client requested a secure invalidation.",
            2: "The client requested a `Delete all` operation.",
            16: "The requested operation was successful.",
            17: "The provided persistent key was not found or is invalid.",
            18: "The provided persistent key is valid, but expired by the time of the request.",
            }

    def parse(self):
        assert self.value_length >= 4
        self.version = int.from_bytes(self.value[0:4], byteorder="big")
        self.reserved = self.value[4:8]
        assert self.version in (0, 1, 2)
        # Parse v1 and v2, could be split into separate functions
        if self.version == 1:
            assert self.value_length == 28
            assert self.reserved == bytes(4)
            self.content_id = self.value[8:24]
            self.duration_to_expiry = int.from_bytes(self.value[24:28], byteorder="big")
        elif self.version == 2:
            assert self.value_length >= 48
            assert self.reserved == bytes(4)
            self.server_challenge = self.value[8:16]
            self.flags = bin(int.from_bytes(self.value[16:24], byteorder="big"))[:1:-1]
            self.title_id = self.value[24:40]
            self.duration_to_expiry = int.from_bytes(self.value[40:44], byteorder="big")
            self.invalidated_record = int.from_bytes(self.value[44:48], byteorder="big")
            assert self.value_length == (48 + 16 * self.invalidated_record)
            self.records = []
            data = self.value[48:]
            while data:
                self.record.append(int.from_bytes(data[0:16], byteorder="big"))
                data = data[8:]

    def __str__(self):
        s = ""
        s += super().__str__()
        if self.version == 0:
            s += f"\tNo offline requested\n"
        else:
            s += f"\tversion: {self.version}\n"
            if self.version == 1:
                s += f"\tcontent id:" + format_hex(self.content_id)
                s += f"\tduration to expiry: {timedelta(seconds=self.duration_to_expiry)}\n"
            if self.version == 2:
                for i, bit in enumerate(self.flags):
                    if i in self.FLAGS:
                        s += f"\t\tflags bit {i:>2d}: {self.FLAGS[i]}\n"
                s += f"\ttitle id:" + format_hex(self.title_id)
                s += f"\tduration to expiry: {timedelta(seconds=self.duration_to_expiry)}\n"
                s += f"\tInvalid records: {self.invalidated_record:#x}\n"
                for rec in self.records:
                    s += f"\t\t{rec:#x}\n"
        return s


class Device_Info(TLLV):
    NAME = "Client Device Info"
    FIELD = "device_info"
    TAG = 0xd43fc6abc596aae7

    DEVICE_TYPE = {
            0x358c41b1ec78f599: "Mac",
            0xc1500767c86c1fae: "Apple TV, TV, STB",
            0x8551fd5e31f479b3: "iPhone, iPad, iPod",
            0x5da86ac0c57155dc: "Apple Watch",
            }

    def parse(self):
        assert self.value_length == 16
        self.device_type = int.from_bytes(self.value[0:8], byteorder="big")
        self.os_version = self.value[8:12]

    def __str__(self):
        s = ""
        s += super().__str__()
        if self.device_type in self.DEVICE_TYPE:
            s += f"\tdevice: {self.DEVICE_TYPE[self.device_type]}\n"
        else:
            s += f"\tdevice: {self.device_type:#018x}\n"
        s += f"\tOS version: {self.os_version[1]}.{self.os_version[2]}.{self.os_version[3]}\n"
        return s


class Security_Level_Report(TLLV):
    NAME = "Security Level Report"
    FIELD = "security_level_report"
    TAG = 0xb18ee16ea50f6c02
    SECURITY_LEVEL = {
            0x32f0004966a5c4f8: "Baseline",
            0x4e7fd92421d588b4: "Main"
    }

    def parse(self):
        assert self.value_length == 20

        self.version = int.from_bytes(self.value[0:4], byteorder="big")
        self.reserved = self.value[4:8]
        self.security_level = int.from_bytes(self.value[8:16], byteorder="big")
        self.reserved = self.value[16:20]

    def __str__(self):
        s = ""
        s += super().__str__()
        s += f"\tsecurity level: {self.security_level:#x} -- {self.SECURITY_LEVEL.get(self.security_level)}\n"
        return s


class Kext_Deny_List(TLLV):
    NAME = "Kext Deny List"
    FIELD = "kext_deny_list"
    TAG = 0x70eca6573388e329

    def parse(self):
        assert self.value_length == 4

        self.kdl_version = int.from_bytes(self.value[0:4], byteorder="big")

    def __str__(self):
        s = ""
        s += super().__str__()
        s += f"\tkext deny list version:{self.kdl_version:#x}\n"
        return s


class Encrypted_CK(TLLV):
    NAME = "Encrypted CK"
    FIELD = "encrypted_ck"
    TAG = 0x58b38165af0e3d5a
    pass


class R1(TLLV):
    NAME = "R1"
    FIELD = "r1"
    TAG = 0xea74c4645d5efee9

    def parse(self):
        assert self.value_length == 44


class Content_Key_Duration(TLLV):
    NAME = "Content Key Duration"
    FIELD = "content_key_duration"
    TAG = 0x47acf6a418cd091a

    RESERVED = 0x86d34a3a
    KEY_TYPE = {
            0x1a4bde7e: "Content key valid for lease only.",
            0x3dfe45a0: "Content key valid for rental only.",
            0x27b59bde: "Content key valid for both lease and rental.",
            0x3df2d9fb: "Content key can be persisted with unlimited validity duration.",
            0x18f06048: "Content key can be persisted, and its validity duration is limited to the Rental Duration value.",
            }

    def parse(self):
        assert self.value_length == 16
        self.lease_duration = int.from_bytes(self.value[0:4], byteorder="big")
        self.rental_duration = int.from_bytes(self.value[4:8], byteorder="big")
        self.key_type = int.from_bytes(self.value[8:12], byteorder="big")
        self.reserved = int.from_bytes(self.value[12:16], byteorder="big")
        assert self.key_type in self.KEY_TYPE
        #assert self.reserved == self.RESERVED

    def __str__(self):
        s = ""
        s += super().__str__()
        s += f"\tlease_duration: {timedelta(seconds=self.lease_duration)}\n"
        s += f"\trental_duration: {timedelta(seconds=self.rental_duration)}s\n"
        s += f"\tkey type: {self.KEY_TYPE[self.key_type]}\n"
        return s


class HDCP_Enforcement(TLLV):
    NAME = "HDCP_Enforcement"
    FIELD = "hdcp_enforcement"
    TAG = 0x2e52f1530d8ddb4a

    HDCP = {
            0xef72894ca7895b78: "HDCP not required.",
            0x40791ac78bd5c571: "HDCP Type 0 is required.",
            0x285a0863bba8e1d3: "HDCP Type 1 is required.",
            }

    def parse(self):
        assert self.value_length == 16
        self.required_hdcp_level = int.from_bytes(self.value[0:8], byteorder="big")
        self.reserved = self.value[8:16]
        assert self.required_hdcp_level in self.HDCP

    def __str__(self):
        s = ""
        s += super().__str__()
        s += f"\t{self.required_hdcp_level:#x}: {self.HDCP[self.required_hdcp_level]}\n"
        return s


class Security_Level_Required(TLLV):
    NAME = "Security Level Required"
    FIELD = "security_level_required"
    TAG = 0x644cb1dac0313250

    SECURITY_LEVEL = {
            0x17d99d574eed567d: "Audio",
            0x32f0004966a5c4f8: "Baseline",
            0x4e7fd92421d588b4: "Main"
    }

    def parse(self):
        assert self.value_length == 16

        self.version = int.from_bytes(self.value[0:4], byteorder="big")
        self.reserved = self.value[4:8]
        self.security_level = int.from_bytes(self.value[8:16], byteorder="big")

    def __str__(self):
        s = ""
        s += super().__str__()
        if self.security_level in self.SECURITY_LEVEL:
            s += f"\tsecurity level: {self.security_level:#x} -- {self.SECURITY_LEVEL[self.security_level]}\n"
        else:
            s += f"\tsecurity level: {self.security_level:#x}\n"
        return s


class Offline_Key(TLLV):
    NAME = "Offline Key"
    FIELD = "offline_key"
    TAG = 0x6375d9727060218c

    def parse(self):
        assert self.value_length >= 4
        self.version = int.from_bytes(self.value[0:4], byteorder="big")
        assert self.version in (1, 2)
        if self.version == 1:
            assert self.value_length == 32
        elif self.version == 2:
            assert self.value_length == 48
        self.reserved = self.value[4:8]
        self.streamid = self.value[8:24]
        self.storage_duration = int.from_bytes(self.value[24:28], byteorder="big")
        self.playback_duration = int.from_bytes(self.value[28:32], byteorder="big")
        assert self.reserved == bytes(4)
        if self.version == 2:
            self.title_id = int.from_bytes(self.value[32:48], byteorder="big")

    def __str__(self):
        s = ""
        s += super().__str__()
        s += f"\tversion: {self.version}\n"
        s += f"\tstream id:\n" + format_hex(self.streamid, indent="\t\t")
        s += f"\tstorage duration: {timedelta(seconds=self.storage_duration)}\n"
        s += f"\tplayback duration: {timedelta(seconds=self.playback_duration)}\n"
        return s


class Device_Identity(TLLV):
    NAME = "Client Device Identity"
    FIELD = "device_identity"
    TAG = 0x94c17cd676c69b59

    DEVICE_CLASS = {
        0: "Unknown",
        1: "Apple Living",
        2: "Apple Mobile",
        3: "Apple Desktop",
        4: "Apple Spacial",
        127: "Apple Unknown",
        128: "Partner Living",
        255: "Partner Unknown",
    }

    def parse(self):
        #assert self.value_length == 16
        self.device_version = int.from_bytes(self.value[0:4], byteorder="big")
        self.device_class = int.from_bytes(self.value[4:8], byteorder="big")
        self.vendorhash = int.from_bytes(self.value[8:16], byteorder="big")
        self.producthash = int.from_bytes(self.value[16:24], byteorder="big")
        self.fp_ree = int.from_bytes(self.value[24:28], byteorder="big")
        self.fp_tee = int.from_bytes(self.value[28:32], byteorder="big")
        self.os_version = int.from_bytes(self.value[32:36], byteorder="big")

    def __str__(self):
        s = ""
        s += super().__str__()
        s += f"\tDevice Version: {self.device_version}\n"
        if self.device_class in self.DEVICE_CLASS:
            s += f"\tDevice Class: {self.device_class} -- {self.DEVICE_CLASS[self.device_class]}\n"
        else:
            s += f"\tDevice Class: {self.device_class} -- UNKNOWN\n"
        s += f"\tVendor Hash:    {self.vendorhash:#x}\n"
        s += f"\tProduct Hash:    {self.producthash:#x}\n"
        s += f"\tFairPlay version REE:    {self.fp_ree:#010x}\n"
        s += f"\tFairPlay version TEE:    {self.fp_tee:#010x}\n"

        if self.device_version <= 127:
            s += f"\tOS Version:    {self.os_version:#010x}\n"

        return s

class Supported_Key_Formats(TLLV):
    NAME = "Supported Key Formats"
    FIELD = "supported_key_formats"
    TAG = 0x8d8e84fa6cc35eb7

    def parse(self):
        self.version = int.from_bytes(self.value[0:4], byteorder='big')

        if self.version == 1:
            int.from_bytes(self.value[4:8], byteorder='big')

            self.number_of_keys = int.from_bytes(self.value[8:12], byteorder='big')

            assert self.number_of_keys < 64

            offset = 12
            self.supported_key_formats = []
            for i in range(0, self.number_of_keys):
                self.supported_key_formats.append(int.from_bytes(self.value[offset:offset + 8], byteorder='big'))
                offset += 8

    def __str__(self):
        s = ''
        s += super().__str__()
        s += f'\tNumber of supported key formats: {self.number_of_keys}\n'
        s += '\tKey formats supported:\n'
        for key in self.supported_key_formats:
            s += f'\t\t{key:#x}\n'

        return s

class VM_Device_Information(TLLV):
    NAME = "VM Device Information"
    FIELD = "vm_device_information"
    TAG = 0x756440e240499f70

    DEVICE_CLASS = {
        0: "Unknown",
        1: "Apple Living",
        2: "Apple Mobile",
        3: "Apple Desktop",
        4: "Apple Spacial",
        127: "Apple Unknown",
        128: "Partner Living",
        255: "Partner Unknown",
    }

    def parse(self):
        self.version = int.from_bytes(self.value[0:4], byteorder='big')
        if self.version == 1:
            self.host_device_class = int.from_bytes(self.value[4:8], byteorder='big')
            self.host_os_version = int.from_bytes(self.value[8:12], byteorder='big')
            self.host_vm_protocol_version = int.from_bytes(self.value[12:16], byteorder='big')
            self.guest_device_class = int.from_bytes(self.value[16:20], byteorder='big')
            self.guest_os_version = int.from_bytes(self.value[20:24], byteorder='big')
            self.guest_vm_protocol_version = int.from_bytes(self.value[24:28], byteorder='big')

    def __str__(self):
        s = ''
        s += super().__str__()
        s += f"\tVersion: {self.version}\n"
        if self.version == 1:
            if self.host_device_class in self.DEVICE_CLASS:
                s += f"\tHost Device Class: {self.host_device_class} -- {self.DEVICE_CLASS[self.host_device_class]}\n"
            else:
                s += f"\tHost Device Class: {self.host_device_class} -- UNKNOWN\n"
            s += f"\tHost OS Version: {self.host_os_version:#010x}\n"
            s += f"\tHost VM Protocol Version: {self.host_vm_protocol_version}\n"
            if self.guest_device_class in self.DEVICE_CLASS:
                s += f"\tGuest Device Class: {self.guest_device_class} -- {self.DEVICE_CLASS[self.guest_device_class]}\n"
            else:
                s += f"\tGuest Device Class: {self.guest_device_class} -- UNKNOWN\n"
            s += f"\tGuest OS Version: {self.guest_os_version:#010x}\n"
            s += f"\tGuest VM Protocol Version: {self.guest_vm_protocol_version}\n"
        else:
            s += "\tNo VM Device Information\n"
        return s
