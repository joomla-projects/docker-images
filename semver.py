#!/usr/bin/python
import sys
import re
import json

# Joomla_5.0.0-alpha2-Alpha-Update_Package.zip

# 5.0.0-alpha2 - shall be the Version semver

# Alpha shall be the stability in the template file

total = len(sys.argv)
# cmdargs = str(sys.argv)

SEMVER_REGEX="^(?P<major>0|[1-9]\d*)\.(?P<minor>0|[1-9]\d*)\.(?P<patch>0|[1-9]\d*)(?:-(?P<prerelease>(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+(?P<buildmetadata>[0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$"
SEMVER_FULLNAME_REGEX="^.*(?P<version>((?P<major>0|[1-9]\d*)\.(?P<minor>0|[1-9]\d*)\.(?P<patch>0|[1-9]\d*)(?:-(?P<prerelease>(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+(?P<buildmetadata>[0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?)).*$"

p = re.compile(SEMVER_FULLNAME_REGEX)
m = p.match(sys.argv[1])
print(json.dumps(m.groupdict()))
