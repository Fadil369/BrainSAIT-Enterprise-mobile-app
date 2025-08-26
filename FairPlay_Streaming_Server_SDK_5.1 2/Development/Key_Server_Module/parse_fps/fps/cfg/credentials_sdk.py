#!/usr/bin/env python3
#
# Copyright © 2023-2024 Apple Inc. All rights reserved.
#
''' Server credential configuration '''


# credentials is meant to be included by ../parse_fps.py
credentials = [
    {
        'pkey_1024': 'credentials/test_priv_key_1024.pem',
        'pkey_2048': 'credentials/test_priv_key_2048.pem',
        'cert': 'credentials/test_fps_certificate.bin',
        'provisioning_data': 'credentials/test_provisioning_data.bin',
    }
    # Here you may add your own production credentials if so desired
    # Follow the pattern laid out by the previous examples
]
