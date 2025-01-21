#!/bin/bash

# Show debugging output
# set +x

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

# Some important paths.
bin_dir='/usr/local/bin'
config_dir='/etc/borg-backup'
secrets_path="${config_dir}/repo-secrets.sh"
rsync_config_path="${config_dir}/rsync-config.sh"

# create the configuration directory, if it does not exist.
mkdir -p "$config_dir"

# Create secrets file if no configuration exists. -----------------------------
# The secrets file contains the repository name and password.
borg_repo_path='xxxxxxxx'
repo_passphrase='xxxxxxxx'

if [ ! -f "$secrets_path" ]; then
    echo 'No repository configuration found.'
    echo 'This script will create a configuration file for a backup into a Borg'
    echo 'repository. You will be asked for the path and password of the repository.'
    echo
    echo 'The repository can be located on a separate file server. The repository path'
    echo 'must then start with a username and a domain name (or IP); like so:'
    echo
    echo '   "borg-backup@file-box.fritz.box:/srv/disk-backup/borg-repos/bookxie-backup"'
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

        # Source the secrets file to make the variables available.
        source /etc/borg-backup/repo-secrets.sh
        export BORG_REPO
        export BORG_PASSPHRASE

        # Test if the repository is accessible.
        echo '> borg list'
        borg list
        if [ $? -ne 0 ]; then
            echo "Error: The repository is not accessible."

            read -e -p "Continue anyway? [y/n] (n): " ans_yn
            if [[ "$ans_yn" == "y" ]]; then
                break
            fi
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

# Create Rsync configuration file, if none exists. ---------------------------
if [ ! -f "$rsync_config_path" ]; then
    echo "No rsync configuration found."
    echo "Enter the path of the cloned repository. (Can be left empty.)"

    # Ask for rsync locations
    read -e -p "Cloned repository: " rsync_target_dir_1

    # Create rsync configuration file
    echo "Creating \"rsync\" configuration file:"
    echo "    $rsync_config_path"
    cat > "$rsync_config_path" << EOF
# Directories where the original Borg repository should be copied to.
BORG_RSYNC_TARGET_DIR_1='${rsync_target_dir_1}'
BORG_RSYNC_TARGET_DIR_2=''
BORG_RSYNC_TARGET_DIR_3=''
BORG_RSYNC_TARGET_DIR_4=''
EOF

else
    echo "\"rsync\" configuration already exists:"
    echo "    $rsync_config_path"
    echo "Edit / rename / delete this file if you want to use a different"
    echo "\"rsync\" configuration."
fi
echo

# TODO: Install the unit files if necessary.
# Start Systemd timer ---------------------------------------------------------
# Reload all Systemd unit files.
systemctl daemon-reload

# Enable daily backups and also start them.
systemctl enable borg-backup-daily.timer
systemctl start borg-backup-daily.timer
