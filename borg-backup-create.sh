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
# The original version of this script was taken from the documentation of Borg.
#
# The Github project of this script:
#   https://github.com/eike-welk/borg-backup-scripts
#
# Documentation and source code for the *Borg* program itself:
#     https://borgbackup.readthedocs.io/en/stable/index.html
#     https://github.com/borgbackup/borg/
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
# spellchecker: ignore lixie utcnow

# Set the repository location and passphrase. --------------------------------
source /etc/borg-backup/repo-secrets.sh
export BORG_REPO
export BORG_PASSPHRASE

# Print messages to standard output with date and time.
info() { printf "\n%s %s\n\n" "$( date --rfc-3339=seconds )" "$*" >&2; }

# Exit the whole script when Ctrl-C is pressed.
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
                                              \
    ::'{hostname}-{utcnow:%Y-%m-%dT%H:%M:%S}' \
                                              \
    '/home'                                   \
    '/usr/local'                              \

backup_exit=$?

info "Pruning repository"

# Delete old archives --------------------------------------------------------
# Use the `prune` subcommand to delete old backups, but keep a number of mostly
# recent backups. The retention rules are: Keep all backups for 2 days. Keep 10
# daily, 10 weekly, 10 monthly and unlimited yearly backups.
# Only backups of THIS machine are affected. The '{hostname}-' prefix limits
# the prune command to backups of the current machine. Therefore the archive
# could hold backups of multiple computers.

borg prune                          \
    --list                          \
    --glob-archives '{hostname}-*'  \
    --show-rc                       \
    --keep-within  10d              \
    --keep-daily   30               \
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
