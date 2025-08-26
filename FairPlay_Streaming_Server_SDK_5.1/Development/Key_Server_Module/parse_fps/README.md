<!--
Copyright © 2023-2024 Apple Inc. All rights reserved.
-->
# Usage

```
% python3 -m fps.parse_fps --help
usage: parse_fps.py [-h] --spc SPC [--ckc CKC] [--log {debug,info,warning,error,critical}]

optional arguments:
  -h, --help            show this help message and exit
  --spc SPC             binary or base64
  --ckc CKC             binary or base64
  --log {debug,info,warning,error,critical}

 Display as much info as possible from the SPC and CKC.
    SPC header is always display.
    If a proper pkey/cert is given, use it to decrypt the SPC payload and display it.
    If a proper CKC is provided display its header.
    If a proper CKC is provided and matches the SPC, display its payload.
```

# Requirements

packages:

$pip3 install -U PyCryptodome
