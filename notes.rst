#####################################################################
Notes for the Backup Program Borg
#####################################################################

Configure the archive
=====================================================================

Add enough free space to the repository, so that Borg does not run out of disk
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

Systemd Unit Files
=====================================================================

Unit files are in various directories. The command to show these directories
is: `systemctl show --property=UnitPath` On *openSuse* these directories are::

        /etc/systemd/system 
        /run/systemd/system 
        /run/systemd/generator 
        /usr/local/lib/systemd/system 
        /usr/lib/systemd/system 
        /lib/systemd/system 
        /run/systemd/generator.late

Units installed by the system administrator::

        /etc/systemd/system/

When a unit file is changed, all unit files must be reloaded with::

        systemctl daemon-reload

