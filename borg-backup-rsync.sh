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

# Some helpers and error handling: -------------------------------------------
info() { printf "\n%s %s\n\n" "$( date --rfc-3339=seconds )" "$*" >&2; }

trap 'info "Copying the repositories interrupted."; exit 2' INT TERM

# Take various paths from `/etc/borg-backup/repo-secrets.sh`
#     BORG_REPO='...'               # Path of the original Borg repository.
#     BORG_RSYNC_TARGET_DIR_1='...' # Directories where the original
#     BORG_RSYNC_TARGET_DIR_2='...' # Borg repository should be copied to.
#     BORG_RSYNC_TARGET_DIR_3='...'
#     BORG_RSYNC_TARGET_DIR_4='...'
config_file='/etc/borg-backup/repo-secrets.sh'
source "$config_file"

# Test if $BORG_REPO is really a Borg repository. ----------------------------
if [ -z "$BORG_REPO" ]; then
    info "Variable \"BORG_REPO\" is empty. Configuration: $config_file"
    exit -1
fi

if [ ! -d "$BORG_REPO" ]; then
    info "\"$BORG_REPO\" must be a directory. Configuration: $config_file"
    exit -1
fi

if [ ! -f "$BORG_REPO/config" ] && [ ! -f "$BORG_REPO/README" ] && \
   [ ! -f "$BORG_REPO/hints.*" ] && [ ! -f "$BORG_REPO/index.*" ] && \
   [ ! -d "$BORG_REPO/data" ]; then
    info "\"$BORG_REPO\" is not a Borg repository. Configuration: $config_file"
    exit -1
fi
# Test minimum repo size.
# Format: 125 /backup/foo/bar
du_answer=(`du --summarize --block-size=1G $BORG_REPO`)
min_size=100 #100 GB
if [ ${du_answer[0]} -lt $min_size ]; then
    info "Backup repository is very small. Has it been damaged?
                          Size:          ${du_answer[0]} GiB
                          Repository:    $BORG_REPO
                          Configuration: $config_file"
    exit -1
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

# Loop over the target directories -------------------------------------------
for target in $target_dirs; do
    if [ ! -d "$target" ]; then
        info "Target directory not found: \"$target\""
    else
        info "Copying the Borg repository with 'rsync'.
                          Config: \"$config_file\"
                          Source: \"$BORG_REPO\"
                          Target: \"$target\""
        # Copy the backup repository with rsync.
        # Option `--delete` deletes file which are no longer in the source directory.
        rsync --verbose --archive --delete "$BORG_REPO" "$target"
    fi
done

