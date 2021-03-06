#!/bin/bash

# Show debugging output
#set -x

# ----------------------------------------------------------------------------
# Duplicate Backup Directories with **Rsync**
# ----------------------------------------------------------------------------
#
# Intended to copy the backup repository to an other (removable) disk.
#
# If an argument is given, this is the target path.
# Otherwise possible target paths are taken from the configuration file
# `/etc/borg-backup/repo-secrets.sh`
#
# TODO: option --help
#
# ----------------------------------------------------------------------------
# The rsync configuration file:
#
#     /etc/borg-backup/rsync-config.sh
#
# `rsync-config.sh` must contain the following lines:
#
#     # Directories where the original Borg repository should be copied to.
#     BORG_RSYNC_TARGET_DIR_1='/run/media/root/back-ext-4/borg-backup/'
#     BORG_RSYNC_TARGET_DIR_2=''
#     BORG_RSYNC_TARGET_DIR_3=''
#     BORG_RSYNC_TARGET_DIR_4=''
#
# ----------------------------------------------------------------------------
# The backup configuration file:
#
#     /etc/borg-backup/repo-secrets.sh
#
# `repo-secrets.sh` must contain the following lines:
#
#     # The location of the backup repository.
#     BORG_REPO='/backup/borg-backup/lixie-backup-1.borg'
#     # The repository's passphrase:
#     BORG_PASSPHRASE='xxxxxxxxxxx'
#
# ----------------------------------------------------------------------------

# Print messages to standard output with date and time.
info() { printf "\n%s %s\n\n" "$( date --rfc-3339=seconds )" "$*" >&2; }

# Exit the whole script when Ctrl-C is pressed.
trap 'info "Copying the repositories interrupted."; exit 2' INT TERM

# Set configuration values. ---------------------------------------------------
# Set paths of the duplicate Borg repositories
config_file='/etc/borg-backup/rsync-config.sh'
if [ ! -f "$config_file" ]; then
    info "Error: Rsync configuration does not exist: \"${config_file}\""
    exit 2
fi
# Set repository location and passphrase.
borg_secrets_file='/etc/borg-backup/repo-secrets.sh'
if [ ! -f "$borg_secrets_file" ]; then
    info "Error: Borg configuration does not exist: \"${borg_secrets_file}\""
    exit 2
fi
source "$config_file"
source "$borg_secrets_file"
export BORG_REPO
export BORG_PASSPHRASE

# Test if $BORG_REPO is really a Borg repository. ----------------------------
if [ -z "$BORG_REPO" ]; then
    info "Error: Variable \"BORG_REPO\" is empty.
                          Configuration: $config_file"
    exit 1
fi

# Test repository only with `borg list` because `borg check` takes too long.
borg list > /dev/null
if (( $? != 0 )); then
    info "Error: \"$BORG_REPO\" is not a functioning Borg repository.
                          Configuration: $config_file"
    exit 1
fi

# Test minimum repo size.
# TODO: Maybe store size, and make sure it does not decrease dramatically.
# Result format: 125 /backup/foo/bar
du_answer=(`du --summarize --block-size=1G $BORG_REPO`)
min_size=100 #100 GB
if [ ${du_answer[0]} -lt $min_size ]; then
    info "Error: Backup repository is very small. Has it been damaged?
                          Size:          ${du_answer[0]} GiB
                          Repository:    $BORG_REPO
                          Configuration: $config_file"
    exit 1
fi

# Set up the target directories. ---------------------------------------------
if [ -z "$1" ]; then
    # No argument given. Taking target directories from configuration file.
    target_dirs="$BORG_RSYNC_TARGET_DIR_1 $BORG_RSYNC_TARGET_DIR_2
                 $BORG_RSYNC_TARGET_DIR_3 $BORG_RSYNC_TARGET_DIR_4"
else
    # The supplied argument is the target directory.
    target_dirs="$1"
fi

# A function that gets a repository's fingerprint.
# The parameter is the repository's path.
function get_repository_id {
    local repo_path="$1"
    local config_path="$repo_path/config"
    if [ -f "$config_path" ]; then
        # Parse ini file with awk. Get the value of "id".
        # See: https://stackoverflow.com/q/6318809
        local repo_id=$(awk -F "=" '/id/ {print $2}' "$config_path" \
                       | tr -d ' ')
        echo "$repo_id"
        return 0
    else
        echo ''
        return 1
    fi
}

# Loop over the target directories --------------------------------------------
repo_path="$BORG_REPO"
repo_base_name=$(basename $repo_path)
repo_id=$(get_repository_id "$repo_path")

for target_1dir in $target_dirs; do
    target_path="$target_1dir/$repo_base_name"
    # Skip external disks that are currently not connected.
    if [ ! -d "$target_1dir" ]; then
        info "Target directory not found. Skipping: \"$target_1dir\""
    # The target repository exists, but it has a different ID.
    elif [ -e "$target_path" ] \
      && [ "$repo_id" != $(get_repository_id "$target_path") ]; then
        info "Error: Repository ID of source and target don't match.
                          Config: \"$borg_secrets_file\"
                          Config: \"$config_file\"
                          Source: \"$repo_path\"
                          Target: \"$target_path\""
        info "Stopping."
        exit 1
    # The target repository doesn't exist, or source and target have the same ID
    else
        info "Copying the Borg repository with 'rsync'.
                          Source: \"$repo_path\"
                          Target: \"$target_path\""
        # Copy the backup repository with rsync.

        # Option `--delete` deletes file which are no longer in the source directory.

        # Trailing "/" in source path: Copy contents, not directory itself.
        # Rationale: Always add "/" to get the same behavior, whether 
        # $BORG_REPO contains a trailing "/" or not.

        rsync --verbose --archive --delete "$repo_path/" "$target_path"
    fi
done

