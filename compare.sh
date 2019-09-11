#!/bin/bash

##########
# UPDATE #
##########

echo "#################################################"
echo "Updating Joomla! 4.0-dev reference (if necassary)"
echo "#################################################"

echo "Current directory: "$(pwd)

current_directory=$(pwd)

if ! [ -d $CMP_MASTER_FOLDER ]; then
    # Reference cache not mounted
    echo "Reference cache not mounted"
    # exit 1
    mkdir $CMP_MASTER_FOLDER # DEBUG ONLY
fi

cd $CMP_MASTER_FOLDER
echo "Current directory: "$(pwd)

if ! [ -d .git ]; then
    # Directory is not a git repository
    echo "Git repository not cloned"
    git clone https://github.com/joomla/joomla-cms.git .
fi

git checkout $BRANCH_NAME
git pull

cd $current_directory
echo "Current directory: "$(pwd)

########
# DIFF #
########

echo "##################################"
echo "Creating diff between repositories"
echo "##################################"
echo "Current directory: "$(pwd)

# Check if archive name is set
if [ -z "$CMP_ARCHIVE" ]; then
    echo "Build Archive name hasn't been set"
    CMP_ARCHIVE="build"
fi

# Check if master repository folder is set
if [ -z "$CMP_MASTER_FOLDER" ]; then
    echo "Master folder hasn't been set"
    CMP_MASTER_FOLDER="../joomla-cms"
fi

# Check if master repository folder is set
if [ -z "$CMP_SLAVE_FOLDER" ]; then
    echo "Slave folder hasn't been set"
    $CMP_SLAVE_FOLDER="$(pwd)/../joomla4"
fi

# Declare variables (can be set from outside)
CMP_TMP="tmp"
CMP_BUILD_DIR="$CMP_TMP/build"
CMP_DIFF_LOG="$CMP_TMP/diff.log"
CMP_ONLY_IN_MASTER_LOG="$CMP_TMP/only_in_master.log"
CMP_ONLY_IN_SLAVE_LOG="$CMP_TMP/only_in_slave.log"
CMP_DIFFERS_FROM_LOG="$CMP_TMP/differs_from.log"
CMP_DELETED_FILES_LOG="deleted_files.log"

# Remove existent temp directory
rm -rf $CMP_TMP

# Create temp directories
mkdir $CMP_TMP
mkdir $CMP_BUILD_DIR

# Compare files/directories
echo "Finding differences between builds..."
	diff -qr --exclude=node_modules \
             --exclude=build \
             --exclude=administrator/components/com_media/node_modules \
             --exclude=.* \
             --exclude=configuration.php \
             --exclude=tmp \
        $CMP_MASTER_FOLDER $CMP_SLAVE_FOLDER >> $CMP_DIFF_LOG

# Create list of files that only exist in master directory
cat $CMP_DIFF_LOG | grep -E "^Only in $CMP_MASTER_FOLDER+" | sed -n 's/://p' | sed 's|'$CMP_MASTER_FOLDER'/|./|' | awk '{print $3"/"$4}' >> $CMP_ONLY_IN_MASTER_LOG

# Create list of files that only exist in slave directory
cat $CMP_DIFF_LOG | grep -E "^Only in $CMP_SLAVE_FOLDER+" | sed -n 's/://p' | sed 's|'$CMP_SLAVE_FOLDER'/|./|' | awk '{print $3"/"$4}' >> $CMP_ONLY_IN_SLAVE_LOG

# Create list of files that differ from master
cat $CMP_DIFF_LOG | grep -Eo " and $CMP_SLAVE_FOLDER/[^[:space:]]+" | grep -Eo "$CMP_SLAVE_FOLDER/[^[:space:]]+" | sed 's|'$CMP_SLAVE_FOLDER'/|./|' >> $CMP_DIFFERS_FROM_LOG

echo "Finished finding differences between builds."

# Copy all files that only occur in slave into build folder
echo "COPYING NEW FILES"
cd $CMP_SLAVE_FOLDER
echo "Current directory: "$(pwd)

while IFS="" read -r file || [ -n "$file" ]
do
    echo "Copying file " $file "..."
    cp --parents -r $file $current_directory"/"$CMP_BUILD_DIR
done < $current_directory"/"$CMP_ONLY_IN_SLAVE_LOG

cd $current_directory
echo "Current directory: "$(pwd)

# Copy all files that differ into build folder
echo "COPY DIFFERING FILES"
cd $CMP_SLAVE_FOLDER
echo "Current directory: "$(pwd)

while IFS="" read -r file || [ -n "$file" ]
do
    echo "Copying file " $file "..."
    cp --parents -r $file $current_directory"/"$CMP_BUILD_DIR
done < $current_directory"/"$CMP_DIFFERS_FROM_LOG

cd $current_directory
echo "Current directory: "$(pwd)

# Move deleted files list to build folder
while IFS="" read -r file || [ -n "$file" ]
do
    deleted_file_no_root=$(echo $file | cut -d'/' -f3-)
    echo $deleted_file_no_root >> $CMP_DELETED_FILES_LOG
done < $CMP_ONLY_IN_MASTER_LOG

echo "Moving file " $CMP_DELETED_FILES_LOG "..."
mv $CMP_DELETED_FILES_LOG $CMP_BUILD_DIR

# Zip build folder
echo "Zipping build folder..."
pushd $CMP_BUILD_DIR
zip -qr $CMP_ARCHIVE *
popd
# Move files to upload directory
mkdir upload
mv "$CMP_BUILD_DIR/$CMP_ARCHIVE.zip" ./upload
echo "Finished zipping build."

# Clean up temporary files
rm -rf $CMP_TMP

##########
# UPLOAD #
##########

echo "###########################"
echo "Uploading diff to CI server"
echo "###########################"
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
if [ -z "$FTP_DEST_DIR" ]; then
    FTP_DEST_DIR="/"
fi

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

# Clean remote directory before deploy
if [ "$FTP_CLEAN_DIR" = true ]; then
    FTP_CLEAN_DIR="rm -r $FTP_DEST_DIR"/"$DRONE_PULL_REQUEST"
else
    FTP_CLEAN_DIR=""
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

lftp -u $FTP_USERNAME,$FTP_PASSWORD $FTP_HOSTNAME << EOF
set ftp:ssl-allow $FTP_SECURE
set ftp:ssl-force $FTP_SECURE
set ftp:ssl-protect-data $FTP_SECURE
set ssl:verify-certificate $FTP_VERIFY
set ssl:check-hostname $FTP_VERIFY
$FTP_CLEAN_DIR
mirror --verbose $FTP_CHMOD -R $FTP_INCLUDE_STRING $FTP_EXCLUDE_STRING -R $FTP_DEST_DIR"/"$DRONE_PULL_REQUEST
wait all
exit
EOF

rm -rf ./upload

echo ""
echo ""
echo ""

echo "                             Bye, have a great time!                            "

echo ""
echo ""
echo ""
echo "...................................................................       ..'',,"
echo ".........................................'''...............'.........       ..''"
echo "........................................'',;,''''....''',,;:::;;,.....       ';,"
echo "........................................';oxddodlccclllclloooollc;'....      .',"
echo ".... .. ...............................,:lxkkkkkkkkOOOOkxxxdddool:,'...       .'"
echo "..  ..  ........,cl:,....''............:odxxkkkkkxkkOOOkkxxddoollc;,...        ."
echo ".   ............,oxdo:'...............;oddxxxxxxxxkkkkkxxdddooollc:,'..        ."
echo "    .............lxddl,..............':ccclodxxkkxxkkkkxxxxddoollc:;'..        ."
echo "     ....  .....;oddo:..............,:c::;;;:codxxddlc:::clloolllcc;'..       .."
echo "      ... ....'cxxddo:'............:ool:;;::;:coxdolc:::;;::ccllllc:,...   . ..."
echo ".     .......;oxxxxxddooolc;.......cxddoooolllodxdollc:::;;;:lllllcc;,...';;,..."
echo "...........'cddddxxddooodddol:'....:xxkkkkxxdddddooooododddoooooolcc:,,',cccc;.."
echo "..........,ldddddddooooooooool;.  .:dxxxxxdodxdoloooddxxxxkxddoolcc:;:c:coool;.."
echo ".........:odddddddollloooolllc'....;odooooolccc::cccloodxxxddoolcc:::clodddo:'.."
echo ".......;ldddddddddddooooooolll;.. .:oollooooolcccllllllloooollllcc:::cldddo:'..."
echo ".....;lddddddddddddoollolllcc:'....:odolcc:looooollcccccllllllllc::::cool;'....."
echo "...,lddddddddddddddoolllllc:;'.....,oddooolloddddolc::::cllllllc::;;,....  .    "
echo "..;loddddddddddddddolllllcc:;'......;ldddoolclooolcccllolllcccc:;,''..     .    "
echo ".,cooddddddoooooolllllllcc:'..... ...'coooollllllollllooolc::;,''....           "
echo ".,coddddoooollllcllllcc:;,.. ..       .;clollllllllllllcc::;,'...''..'.     .   "
echo " .coooollcc::::;;;;,'..... ......      ..':llooooollc::;,,'''''',,,,;c'      .. "
echo " ..';ccc:;'......  ...   ........         ..',,,,,,,'''''.'',,;;;;,:l;.       .."
echo "     ......        .............               ........'',,;;::::lod:.         ."
echo "....            . ..........   .                ..''',,;;:::ccclxOkc.           "

echo ""
echo ""
echo ""
