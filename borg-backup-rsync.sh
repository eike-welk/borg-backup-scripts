#!/bin/bash

# Show debugging output
#set -x

# ----------------------------------------------------------------------------
# Duplicate Backup Directories with **Rsync**
# ----------------------------------------------------------------------------
# Copy the backup repository to an other (removable) disk with *Rsync*.
#
# TODO: Test for an argument. If an argument is given, this is the target path.

# Some helpers and error handling: -------------------------------------------
info() { printf "\n%s %s\n\n" "$( date --rfc-3339=seconds )" "$*" >&2; }

trap 'info "Copying the repositories interrupted."; exit 2' INT TERM

# Take various paths from `/etc/borg-backup/repo-secrets.sh`
#     BORG_REPO='...'               # Path of the original Borg repository.
#     BORG_RSYNC_TARGET_DIR_1='...' # Directories where the original
#     BORG_RSYNC_TARGET_DIR_2='...' # Borg repository should be copied to.
#     BORG_RSYNC_TARGET_DIR_3='...'
#     BORG_RSYNC_TARGET_DIR_4='...'
source /etc/borg-backup/repo-secrets.sh

# Test if $BORG_REPO is really a Borg repository. ----------------------------
if [ -z "$BORG_REPO" ]; then
    info 'Variable "BORG_REPO" is empty.'
    exit -1
fi

if [ ! -d "$BORG_REPO" ]; then
    info "\"$BORG_REPO\" must be a directory."
    exit -1
fi

if [ ! -f "$BORG_REPO/config" ] && [ ! -f "$BORG_REPO/README" ] && \
   [ ! -f "$BORG_REPO/hints.*" ] && [ ! -f "$BORG_REPO/index.*" ] && \
   [ ! -d "$BORG_REPO/data" ]; then
    info "\"$BORG_REPO\" is not a Borg repository."
    exit -1
fi
# TODO: test minimum size

# Loop over the target directories
target_dirs="$BORG_RSYNC_TARGET_DIR_1 $BORG_RSYNC_TARGET_DIR_2
             $BORG_RSYNC_TARGET_DIR_3 $BORG_RSYNC_TARGET_DIR_4"

for target in $target_dirs; do
    if [ ! -d "$target" ]; then
        info "The target directory must be a directory, but it is not.
                          Target: \"$target\""
    else
        info "Copying the Borg repository with 'rsync'.
                          Source: \"$BORG_REPO\"
                          Target: \"$target\""
        # Copy the backup repository with *Rsync*.
        # Option `--delete` deletes file which are no longer in the source directory.
        rsync --verbose --archive --delete "$BORG_REPO" "$target"
    fi
done

