# Docker Container for packaging Joomla (4)

This Docker Container build packages for download. 

### Script steps

1. Build the packages for the current pr

1. Upload the zip file to the CI server and notify github. 

### List of environmental variables

| Variable           | Mandatory | Description                                                                         |
|--------------------|-----------|-------------------------------------------------------------------------------------|
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
