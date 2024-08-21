#!/bin/bash

echo "###########################"
echo "Start building the packages"
echo "###########################"
echo "Current directory: "$(pwd)

current_directory=$(pwd)

MAJORVERSION=`php -r 'const _JEXEC=true; const JPATH_PLATFORM=true; require("libraries/src/Version.php"); echo \Joomla\CMS\Version::MAJOR_VERSION;'`
EXTRAVERSION=`php -r 'const _JEXEC=true; const JPATH_PLATFORM=true; require("libraries/src/Version.php"); echo \Joomla\CMS\Version::EXTRA_VERSION;'`
EXTRAVERSION="${EXTRAVERSION}+pr.${DRONE_PULL_REQUEST}"

(
cat <<JOOMLA
<?php
\$content = file_get_contents("libraries/src/Version.php");
\$content = preg_replace("/EXTRA_VERSION\s*=\s*\'[^\']*\'/", "EXTRA_VERSION = '$EXTRAVERSION'", \$content);
file_put_contents("libraries/src/Version.php", \$content);
JOOMLA
) | php

PRVERSIONSTRING=`php -r 'const _JEXEC=true; const JPATH_PLATFORM=true; require("libraries/src/Version.php"); echo (new \Joomla\CMS\Version)->getShortVersion();'`
JOOMLAVERSION=$PRVERSIONSTRING

git config --global user.email "drone@ci.joomla.org"
git config --global user.name "Drone"

git add libraries/src/Version.php
git commit -m "${PRVERSIONSTRING}"
git tag -m "${PRVERSIONSTRING}" "${PRVERSIONSTRING}"

php build/build.php --remote="${PRVERSIONSTRING}" --exclude-gzip --exclude-bzip2 --include-zstd --disable-patch-packages

# Move files to upload directory
mkdir upload
mv build/tmp/packages/* ./upload
echo "Finished build."

echo "Building html page"

DOWNLOADURL="${HTTP_ROOT}/${DRONE_REPO}/${DRONE_BRANCH}/${DRONE_PULL_REQUEST}/downloads/${DRONE_BUILD_NUMBER}"
DRONE_BUILD_LINK="https://${DRONE_SYSTEM_HOSTNAME}/${DRONE_REPO}/${DRONE_BUILD_NUMBER}"
PRGITHUBURL="https://github.com/${DRONE_REPO}/pull/${DRONE_PULL_REQUEST}"
PRUPDATELISTURL="${DOWNLOADURL}/pr_list.xml"
PRUPDATEEXTENSIONURL="${DOWNLOADURL}/pr_extension.xml"

PACKAGEFILES=""
for packagefile in ./upload/*
do
  file=$(basename $packagefile)
  PACKAGEFILES="${PACKAGEFILES}<li><a href="${DOWNLOADURL}/${file}">${file}</a></li>"

  if [[ "$file" == *"Update_Package.zip"* ]]; then
    PRUPDATEPACKAGEURL="${DOWNLOADURL}/${file}"
  fi
done

MENU=`curl https://cdn.joomla.org/template/renderer.php?section=menu&language=en-GB`
FOOTER=`curl https://cdn.joomla.org/template/renderer.php?section=footer&language=en-GB`

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
template=${template//%MENU%/"${MENU}"}
template=${template//%FOOTER%/"${FOOTER}"}
template=${template//%reportroute%/"https://github.com/joomla-projects/docker-images/issues"}
template=${template//%loginroute%/"https://ci.joomla.org/login"}
template=${template//%logintext%/"Drone Login"}
template=${template//%currentyear%/"`date +%Y`"}

echo $template > ./upload/index.html

template=$(</build_templates/j${MAJORVERSION}/pr_list.xml)

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

template=$(</build_templates/j${MAJORVERSION}/pr_extension.xml)

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
