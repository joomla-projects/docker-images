# Docker Container for Patch Tester (Joomla! 4)

Docker Container for zip'ing the diff between the Pull Request's branch and the reference branch (e.g. `4.0-dev`). 

### Script steps

1. Update the reference repo. You can set the branch of the repo with `BRANCH_NAME` environmental variable. In this step, the reference repo will be cloned (if it not exists) and update itself to the latest commit. This repo is in a mounted directory so it will stay for the next build aswell. The reference repo's folder should be mounted in `CMP_MASTER_FOLDER` environmental variable.

1. Create the diff between the local repo and the reference repo. A list of all created, changed/differing and deleted files gets created. All the files that were created or modified get packet into a zip file with the name `build` environmental variable. The deleted files are noted in `deleted-files.log`.

1. Last but not least, the zip file and deleted file list is uploaded to the CI server.

### List of environmental variables

| Variable           | Mandatory | Description                                                                         |
|--------------------|-----------|-------------------------------------------------------------------------------------|
| CMP_ARCHIVE_NAME   | No        | The name of the zip file                                                            |
| CMP_MASTER_FOLDER  | Yes       | The directory path of the reference repository                                      |
| CMP_SLAVE_FOLDER   | Yes       | The directory path of the current repository                                        |
| BRANCH_NAME        | Yes       | The branch name of the reference repository                                         |
| DRONE_PULL_REQUEST | Yes       | The Pull Request ID                                                                 |
| FTP_HOSTNAME       | Yes       | The host name (including port) where the files get uploaded (e.g. ci.joomla.org:21) |
| FTP_USERNAME       | Yes       | The username to connect to the CI server                                            |
| FTP_PASSWORD       | Yes       | The password to connect to the CI server                                            |
| FTP_SECURE         | No        | Allow and enforce SSL decryption (SFTP)                                             |
| FTP_VERIFY         | No        | Verify certificate and check hostname                                               |
| FTP_DEST_DIR       | No        | Destination directory on CI server (where files get uploaded)                       |
| FTP_SRC_DIR        | No        | The source directory where files are uploaded from                                  |
| FTP_CHMOD          | No        | Disallow file permissions on remote server                                          |
| FTP_CLEAN_DIR      | No        | Clean remote directory before deploying new files                                   |
