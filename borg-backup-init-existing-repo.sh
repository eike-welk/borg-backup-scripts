#!/bin/bash

# Show debugging output
#set -x

# ----------------------------------------------------------------------------
#           Initialize Borg Backup Repository and Daily Backups
# ----------------------------------------------------------------------------
#
# The Github project of this script:
#   https://github.com/eike-welk/borg-backup-scripts

# Configure error handler.
trap 'printf "\n\"borg-backup-init-existing-repo.sh\" was interrupted.\n"; exit 2' INT TERM

# Test: We need root permissions for nearly everything in this script.
if (( $(id -u) != 0 )); then
   echo "Error: This script needs to be run as root."
   exit 1
fi

config_dir='/etc/borg-backup'
bin_dir='/usr/local/bin'

# create the configuration directory, if it does not exist.
mkdir -p "$config_dir"

# Create secrets file if no configuration exists. -----------------------------
# The secrets file contains the repository name and password.
borg_repo_path='xxxxxxxx'
repo_passphrase='xxxxxxxx'

secrets_path="${config_dir}/repo-secrets.sh"

if [ ! -f "$secrets_path" ]; then
    echo 'No repository configuration found.'
    echo 'This script will create a configuration file for a backup into a Borg'
    echo 'repository. You will be asked for the path and password of the repository.'
    echo
    echo 'The repository can be located on a separate file server. The repository path'
    echo 'must then start with a username and a domain name (or IP); like so:'
    echo
    echo '   "borg-backup@file-box:/srv/disk-backup/borg-repos/bookxie-backup"'
    echo

    while true; do
        # Ask repository name
        read -e -p "Repository path: " borg_repo_path
        # Ask repository password
        read -e -p "Repository password: " repo_passphrase

        # Create secrets file
        echo "Creating repository configuration file:"
        echo "    $secrets_path"
        cat > "$secrets_path" << EOF
# The location of the backup repository.
BORG_REPO="$borg_repo_path"
# The repository's passphrase:
BORG_PASSPHRASE="$repo_passphrase"
EOF
        chmod go-rwx "$secrets_path"

        # Test if the repository is accessible.
        source /etc/borg-backup/repo-secrets.sh
        export BORG_REPO
        export BORG_PASSPHRASE

        echo 'borg list'
        borg list
        if [ $? -ne 0 ]; then
            echo "Error: The repository is not accessible."
        else
            echo "The repository is accessible."
            break
        fi
    done

else
    echo "A Repository configuration already exists:"
    echo "    $secrets_path"
    echo "Edit / rename / delete this file if you want to use a different"
    echo "repository name or password."

    # TODO: Test if the repository is accessible.
fi
echo
