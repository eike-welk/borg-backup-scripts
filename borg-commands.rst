#####################################################################
Useful Commands for the Backup Program Borg 
#####################################################################

Configure the archive
=====================================================================

Add enoough free space to the Reository, so that Borg does not run out of disk
space, and can fail gracefully. ::

    borg config /path/to/repo additional_free_space 2G

Create an archive (a backup)
=====================================================================

Create a reasonable compressed archive. Doing the initial backup takes 4 hours.
Subsequent backups take only 5 minutes. The name consists of nicely formatted
date-and-time. ::

    borg create --progress --compression zlib lixie-backup-test-3::{hostname}-{utcnow:%Y-%m-%dT%H:%M:%S} /home /usr/local

Exclude from Backup
=====================================================================

A big part of daily backups is this `.cache` directory. The changes are from Firefox. ::

    .cache/*

