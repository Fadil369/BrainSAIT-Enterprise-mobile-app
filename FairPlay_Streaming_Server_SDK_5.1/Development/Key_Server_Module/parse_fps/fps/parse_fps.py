#!/usr/bin/env python3
#
# Copyright © 2023-2024 Apple Inc. All rights reserved.
#

from fps.cfg.credentials_sdk import credentials as config
import fps.core.ckc
import fps.core.credentials
import fps.core.spc

import argparse
import logging


# Main

if __name__ == "__main__":

    parser = argparse.ArgumentParser(epilog=""" Display as much info as possible from the SPC and CKC.
    SPC header is always display.
    If a proper pkey/cert is given, use it to decrypt the SPC payload and display it.
    If a proper CKC is provided display its header.
    If a proper CKC is provided and matches the SPC, display its payload.
    """, formatter_class=argparse.RawTextHelpFormatter)

    parser.add_argument("--spc", type=str, metavar="SPC", help="binary or base64", required=True)
    parser.add_argument("--ckc", type=str, metavar="CKC", help="binary or base64", required=False)
    parser.add_argument("--log", default = "info", choices = [ "debug", "info", "warning", "error", "critical" ])
    args = parser.parse_args()

    # Logging
    logging.basicConfig(level=getattr(logging, args.log.upper()))

    # Load the credentials
    credentials = fps.core.credentials.load_config_into_credentials(config)

    # Create and parse the SPC element
    spc = fps.core.spc.SPC()
    spc.parse(args.spc, credentials)
    print(spc)

    if args.ckc:
        # Create and parse the CKC element
        ckc = fps.core.ckc.CKC()
        ckc.parse(args.ckc, spc)
        print(ckc)
