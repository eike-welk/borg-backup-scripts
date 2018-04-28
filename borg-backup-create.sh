#!/bin/bash

# Show debugging output
#set -x

# ----------------------------------------------------------------------------
#                     Create Backups with **Borg**
# ----------------------------------------------------------------------------
# This script creates backups on a local had disk. It keeps a number of past
# backups, and deletes backups that are too old. It uses the backup program
# *Borg*.
#
# The Github project of this script:
#   https://github.com/eike-welk/borg-backup-scripts
#
# Documentation and source code for the *Borg* program itself:
#     https://borgbackup.readthedocs.io/en/stable/index.html
#     https://github.com/borgbackup/borg/
#
# ----------------------------------------------------------------------------
# Create new backup repositories with the following command:
#
#     borg init --encryption=repokey /backup/borg-backup/lixie-backup-1.borg
#
# ----------------------------------------------------------------------------
# List the repository's contents:
#
#     borg list /backup/borg-backup/lixie-backup-1.borg
#
# Restore an archive: The restored files are created in the current working
# directory.
#
#     borg extract /backup/borg-backup/lixie-backup-1.borg/::lixie-2018-04-13T17:11:46
#
# ----------------------------------------------------------------------------
# Copy the backup repository to an other (removable) disk with *Rsync*. Option
# `--delete` deletes file which are no longer in the source directory.
#
#     rsync --verbose --archive --delete            \
#          /backup/borg-backup/lixie-backup-1.borg  \
#          /run/media/root/back-ext-4/borg-backup
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
# Set the repository location and passphrase. --------------------------------
source /etc/borg-backup/repo-secrets.sh
export BORG_REPO
export BORG_PASSPHRASE

# some helpers and error handling: -------------------------------------------
info() { printf "\n%s %s\n\n" "$( date --rfc-3339=seconds )" "$*" >&2; }

trap 'info "Backup interrupted."; exit 2' INT TERM

info "Starting backup - $BORG_REPO"

# Create the backup ----------------------------------------------------------
# The command line is for the older *Borg* version 1.0.10
# The archive name consists of the hostname, the current date and time.

# Further cache directories that may be excluded from the archive:
#    --exclude '/var/cache/*'                  \
#    --exclude '/var/tmp/*'                    \

borg create                                   \
    --verbose                                 \
    --filter AME                              \
    --list                                    \
    --stats                                   \
    --show-rc                                 \
    --compression lz4                         \
    --exclude-caches                          \
    --exclude '/home/*/.cache/*'              \
                                              \
    ::'{hostname}-{utcnow:%Y-%m-%dT%H:%M:%S}' \
                                              \
    '/home'                                   \
    '/usr/local'                              \

backup_exit=$?

info "Pruning repository"

# Delete old archives --------------------------------------------------------
# Use the `prune` subcommand to maintain 10 daily, 10 weekly, 10 monthly and
# unlimited yearly archives of THIS machine. The '{hostname}-' prefix is very
# important to limit prune's operation to this machine's archives and not apply
# to other machines' archives also:

borg prune                          \
    --list                          \
    --prefix '{hostname}-'          \
    --show-rc                       \
    --keep-daily   10               \
    --keep-weekly  10               \
    --keep-monthly 10               \
    --keep-yearly  -1               \

prune_exit=$?

# Error handling -------------------------------------------------------------
# use highest exit code as global exit code
global_exit=$(( backup_exit > prune_exit ? backup_exit : prune_exit ))

if [ ${global_exit} -eq 1 ];
then
    info "Backup and/or Prune finished with a warning"
fi

if [ ${global_exit} -gt 1 ];
then
    info "Backup and/or Prune finished with an error"
fi

exit ${global_exit}

