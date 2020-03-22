#!/bin/bash

echo "###########################"
echo "Start building the packages"
echo "###########################"
echo "Current directory: "$(pwd)

current_directory=$(pwd)

EXTRAVERSION=`php -r 'const JPATH_PLATFORM=true; require("libraries/src/Version.php"); echo \Joomla\CMS\Version::EXTRA_VERSION;'`
EXTRAVERSION="${EXTRAVERSION}+pr.${DRONE_PULL_REQUEST}"

(
cat <<JOOMLA
<?php
\$content = file_get_contents("libraries/src/Version.php");
\$content = preg_replace("/EXTRA_VERSION\s*=\s*\'[^\']*\'/", "EXTRA_VERSION = '$EXTRAVERSION'", \$content);
file_put_contents("libraries/src/Version.php", \$content);
JOOMLA
) | php

PRVERSIONSTRING=`php -r 'const JPATH_PLATFORM=true; require("libraries/src/Version.php"); echo \Joomla\CMS\Version::getShortVersion();'`
JOOMLAVERSION=$PRVERSIONSTRING

php build/build.php --remote=$DRONE_COMMIT --exclude-gzip --exclude-bzip2 --include-zstd

# Move files to upload directory
mkdir upload
mv build/tmp/packages/* ./upload
echo "Finished build."

echo "Building html page"

DOWNLOADURL="${HTTP_ROOT}/${DRONE_REPO}/${DRONE_BRANCH}/${DRONE_PULL_REQUEST}/downloads/${DRONE_BUILD_NUMBER}"
DRONE_BUILD_LINK="https://${DRONE_SYSTEM_HOSTNAME}/${DRONE_REPO}/${DRONE_BUILD_NUMBER}"
PRGITHUBURL="https://github.com/${DRONE_REPO}/${DRONE_BRANCH}/pull/${DRONE_PULL_REQUEST}"
PRUPDATELISTURL="${DOWNLOADURL}/pr_list.xml"
PRUPDATEEXTENSIONURL="${DOWNLOADURL}/pr_extension.xml"

PACKAGEFILES=""
for packagefile in ./upload/*
do
  file=$(basename $packagefile)
  PACKAGEFILES="${PACKAGEFILES}<li><a href="${DOWNLOADURL}/${file}">${file}</a></li>"

  if [[ $string == *"Update_Package.zip"* ]]; then
    PRUPDATEPACKAGEURL="${DOWNLOADURL}/${file}" !
  fi
done

template=$(</build_templates/index.html)

template=${template//%PRGITHUBURL%/"${PRGITHUBURL}"}
template=${template//%PRISSUESURL%/"https://issues.joomla.org/tracker/joomla-cms/%PRID%"}
template=${template//%PRID%/"${DRONE_PULL_REQUEST}"}
template=${template//%PRVERSIONSTRING%/"${PRVERSIONSTRING}"}
template=${template//%PRUPDATEPACKAGEURL%/"${PRUPDATEPACKAGEURL}"}
template=${template//%BUILDDRONEURL%/"${DRONE_BUILD_LINK}"}
template=${template//%PRUPDATELISTURL%/"${PRUPDATELISTURL}"}
template=${template//%PACKAGEFILES%/"${PACKAGEFILES}"}
template=${template//%DATE%/"`date`"}
template=${template//%PRCOMMITURL%/"https://github.com/joomla/joomla-cms/tree/%PRCOMMIT%"}
template=${template//%PRCOMMIT%/"${DRONE_COMMIT}"}
template=${template//%JOOMLAVERSION%/"${JOOMLAVERSION}"}
template=${template//%MENU%/"`curl http://cdn.joomla.org/template/renderer.php?section=menu&language=en-GB`"}
template=${template//%FOOTER%/"`curl http://cdn.joomla.org/template/renderer.php?section=footer&language=en-GB`"}
template=${template//%reportroute%/"https://github.com/joomla-projects/docker-images/issues"}
template=${template//%loginroute%/"https://ci.joomla.org/login"}
template=${template//%logintext%/"Drone Login"}
template=${template//%currentyear%/"`date +%Y`"}

echo $template > ./upload/index.html

template=$(</build_templates/pr_list.xml)

template=${template//%PRGITHUBURL%/"${PRGITHUBURL}"}
template=${template//%PRISSUESURL%/"https://issues.joomla.org/tracker/joomla-cms/%PRID%"}
template=${template//%PRID%/"${DRONE_PULL_REQUEST}"}
template=${template//%PRVERSIONSTRING%/"${PRVERSIONSTRING}"}
template=${template//%PRUPDATEPACKAGEURL%/"${PRUPDATEPACKAGEURL}"}
template=${template//%BUILDDRONEURL%/"${DRONE_BUILD_LINK}"}
template=${template//%PRUPDATELISTURL%/"${PRUPDATELISTURL}"}
template=${template//%PACKAGEFILES%/"${PACKAGEFILES}"}
template=${template//%DATE%/"`date`"}
template=${template//%PRCOMMITURL%/"https://github.com/joomla/joomla-cms/tree/%PRCOMMIT%"}
template=${template//%PRCOMMIT%/"${DRONE_COMMIT}"}
template=${template//%JOOMLAVERSION%/"${JOOMLAVERSION}"}

template=${template//%PRUPDATEEXTENSIONURL%/"${PRUPDATEEXTENSIONURL}"}


echo $template > ./upload/pr_list.xml

template=$(</build_templates/pr_extension.xml)

template=${template//%PRGITHUBURL%/"${PRGITHUBURL}"}
template=${template//%PRISSUESURL%/"https://issues.joomla.org/tracker/joomla-cms/%PRID%"}
template=${template//%PRID%/"${DRONE_PULL_REQUEST}"}
template=${template//%PRVERSIONSTRING%/"${PRVERSIONSTRING}"}
template=${template//%PRUPDATEPACKAGEURL%/"${PRUPDATEPACKAGEURL}"}
template=${template//%BUILDDRONEURL%/"${DRONE_BUILD_LINK}"}
template=${template//%PRUPDATELISTURL%/"${PRUPDATELISTURL}"}
template=${template//%PACKAGEFILES%/"${PACKAGEFILES}"}
template=${template//%DATE%/"`date`"}
template=${template//%PRCOMMITURL%/"https://github.com/joomla/joomla-cms/tree/%PRCOMMIT%"}
template=${template//%PRCOMMIT%/"${DRONE_COMMIT}"}
template=${template//%JOOMLAVERSION%/"${JOOMLAVERSION}"}

echo $template > ./upload/pr_extension.xml

# Clean up temporary files
rm -rf build/tmp

##########
# UPLOAD #
##########

echo "################################"
echo "Uploading Packages to the server"
echo "################################"
echo "Current directory: "$(pwd)

# Check if FTP username is set
if [ -z "$FTP_USERNAME" ]; then
    echo "FTP-username not set"
    exit 1
fi

# Check if FTP hostname is set
if [ -z "$FTP_HOSTNAME" ]; then
    echo "FTP-hostname not set"
    exit 1
fi

# Check if FTP port is set
if [ -z "$FTP_PORT" ]; then
    FTP_PORT="21"
fi

# Check if FTP password is set
if [ -z "$FTP_PASSWORD" ]; then
    echo "FTP-password not set"
    exit 1
fi

# Allow and enforce SSL decryption
if [ -z "$FTP_SECURE" ]; then
    FTP_SECURE="true"
else
    FTP_SECURE="false"
fi

# Verify certificate and check hostname
if [ -z "$FTP_VERIFY" ]; then
    FTP_VERIFY="true"
fi

# Destination directory on remote server
export FTP_DEST_DIR=$FTP_DEST_DIR/$DRONE_REPO/$DRONE_BRANCH/$DRONE_PULL_REQUEST/downloads/$DRONE_BUILD_NUMBER

# Source directory on local machine
if [ -z "$FTP_SRC_DIR" ]; then
    FTP_SRC_DIR="/"
fi

# Disallow file permissions
if [ "$FTP_CHMOD" = false ]; then
    FTP_CHMOD="-p"
else
    FTP_CHMOD=""
fi

FTP_EXCLUDE_STRING=""
FTP_INCLUDE_STRING="./upload"

IFS=',' read -ra in_arr <<< "$FTP_EXCLUDE"
for i in "${in_arr[@]}"; do
    FTP_EXCLUDE_STRING="$FTP_EXCLUDE_STRING -x $i"
done
IFS=',' read -ra in_arr <<< "$FTP_INCLUDE"
for i in "${in_arr[@]}"; do
    FTP_INCLUDE_STRING="$FTP_INCLUDE_STRING -x $i"
done

lftp -u $FTP_USERNAME,$FTP_PASSWORD $FTP_HOSTNAME:$FTP_PORT << EOF
set ftp:ssl-allow $FTP_SECURE
set ftp:ssl-force $FTP_SECURE
set ftp:ssl-protect-data $FTP_SECURE
set ssl:verify-certificate $FTP_VERIFY
set ssl:check-hostname $FTP_VERIFY
mirror --verbose $FTP_CHMOD -R $FTP_INCLUDE_STRING $FTP_EXCLUDE_STRING -R $FTP_DEST_DIR
wait all
exit
EOF

# Clean up
rm -rf ./upload

curl -X POST "https://api.github.com/repos/$DRONE_REPO/statuses/$DRONE_COMMIT" \
  -H "Content-Type: application/json" \
  -H "Authorization: token $GITHUB_TOKEN" \
  -d "{\"state\": \"success\", \"context\": \"Download\", \"description\": \"Prebuild packages are available for download.\", \"target_url\": \"$DOWNLOADURL\"}" > /dev/null

# Finish

echo ""
echo ""
echo ""
echo "Find the packages online: $DOWNLOADURL"
echo ""
echo ""
echo ""
