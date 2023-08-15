#!/usr/bin/env python3

import argparse
import re

version_re = re.compile(r"[a-zA-Z-_+]*(\d+)(.0)?.?(\d+)?.?(\d+)?.*")

parser = argparse.ArgumentParser(description='''
    "This program takes a semver-like version (jdk-18.0.2.1-ga), where the last three numbers are optional, and transforms it to an integer.
    The integer will be bigger for a higher version number''')
parser.add_argument("version")
args = parser.parse_args()

m = version_re.search(args.version)

result_version = m.group(1).rjust(2, "0")
result_version += "0"
result_version += (m.group(3) or "0").rjust(3, "0")
result_version += (m.group(4) or "0")

print(result_version)
