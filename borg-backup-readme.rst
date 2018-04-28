###############################################################################
                          Backups with **Borg**
###############################################################################

This directory contains a backup repository made with the program *Borg*.
This *Borg* repository is used with additional scripts which are described
below.

* Backups are made daily, old backups are deleted. The backups are encrypted.

* Only the directories `/home` and `/usr/local` are backed up, not the complete
  system.

* The script `borg-backup-rsync.sh` duplicates the backup repository on a
  removable hard disk.

The scripts' Github project:

    https://github.com/eike-welk/borg-backup-scripts

===============================================================================
Daily Usage
===============================================================================

A backup is created daily at night with the script `borg-backup-create.sh`. It
is controlled by a *Systemd* timer.

Restore a Lost File
-------------------------------------------------------------------------------

To restore a small amount of lost data:

1. Mount the backup repository with:
   `borg mount name-of-the-repository mnt/`. You are asked for the repository's
   password.

2. Browse the repository at the directory where it is mounted. Copy the lost
   files. (There is a directory `mnt/` here for this purpose.)
   
   Accessing the backup this way is relatively slow, and graphical file
   managers can appear to hang from time to time.

3. Detach (unmount) the backup repository from the file system with:
   `borg umount directory-for-mount`.

Duplicate the Repository
-------------------------------------------------------------------------------

To duplicate the repository on an external hard disk:

1. Mount the external hard disk to the configured directory.
2. Run `borg-backup-rsync.sh`.

The external hard disk(s) must be configured in
`/etc/borg-backup/rsync-config.sh`.


===============================================================================
The Scripts
===============================================================================

The scripts are installed in `/usr/local/bin`. They must be run as *root*.


borg-backup-init.sh
-------------------------------------------------------------------------------

`borg-backup-init.sh` creates a new backup repository in the current directory,
and sets up the necessary configuration files. It asks the user for a
repository name, a password, and a path to duplicate the backup repository.


borg-backup-create.sh
-------------------------------------------------------------------------------

`borg-backup-create.sh` creates a backup of `/home` and `/usr/local`.  The
backups are stored in the backup repository, older backups are deleted, the
last yearly backup is kept indefinitely.

The script is run daily by *Systemd*. It can also be run manually, if it is 
necessary.


borg-backup-rsync.sh
-------------------------------------------------------------------------------

`borg-backup-rsync.sh` duplicates the repository to other directories with
*rsync*. Intended for removable hard disks. 

Files that were deleted in the repository, are removed from the duplicates too.
This make the script quite dangerous: Syncing a damaged repository, will damage
the duplicates too.


===============================================================================
Borg
===============================================================================

This script creates backups on a local had disk. It keeps a number of past
backups, and deletes backups that are too old. It uses the backup program
*Borg*.

Documentation and source code for the *Borg* program itself:
    https://borgbackup.readthedocs.io/en/stable/index.html
    https://github.com/borgbackup/borg/

-------------------------------------------------------------------------------
Create new backup repositories with the following command:

    borg init --encryption=repokey /backup/borg-backup/lixie-backup-1.borg

-------------------------------------------------------------------------------
List the repository's contents:

    borg list /backup/borg-backup/lixie-backup-1.borg

Restore an archive: The restored files are created in the current working
directory.

    borg extract /backup/borg-backup/lixie-backup-1.borg/::lixie-2018-04-13T17:11:46


===============================================================================
Rsync
===============================================================================
Copy the backup repository to an other (removable) disk with *Rsync*. Option
`--delete` deletes file which are no longer in the source directory.

    rsync --verbose --archive --delete            \
         /backup/borg-backup/lixie-backup-1.borg  \
         /path/to/other/disk                      \


===============================================================================
Systemd
===============================================================================
systemctl daemon-reload

systemctl enable
systemctl start

systemctl stop
systemctl disable

Systemd Unit Files
-------------------------------------------------------------------------------

Backups are run daily by *Systemd* instead of *Cron*. Two unit files are
necessary for it: A service and a timer. Both files are in
`/usr/local/lib/systemd/system`.

`borg-backup-daily.service`
    This unit file runs the script `borg-backup-create.sh`.

`borg-backup-daily.timer`
    The timer that is activated daily. Each timer corresponds to a `service`
    file of her same name.


