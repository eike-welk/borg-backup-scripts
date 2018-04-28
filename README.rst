
###############################################################################
                          Backups with **Borg**
###############################################################################

This directory contains a backup repository made with the program *Borg*.
This *Borg* repository is used with additional scripts which are described
below.

* Backups are made daily, old backups are deleted. The backups are encrypted.

* Only the directories ``/home`` and ``/usr/local`` are backed up, not the complete
  system.

* The script ``borg-backup-rsync.sh`` duplicates the backup repository on a
  removable hard disk.

The scripts' Github project:

    https://github.com/eike-welk/borg-backup-scripts

===============================================================================
Installing
===============================================================================

To install, run the script::

    install.sh

The necessary files will be copied to appropriate directories below
``/usr/local``.

===============================================================================
The Scripts
===============================================================================

borg-backup-init.sh
-------------------------------------------------------------------------------

``borg-backup-init.sh`` creates a new backup repository in the current directory,
and sets up the necessary configuration files. It asks the user for a
repository name, a password, and a path to duplicate the backup repository.


borg-backup-create.sh
-------------------------------------------------------------------------------

``borg-backup-create.sh`` creates a backup of ``/home`` and ``/usr/local``.  The
backups are stored in the backup repository, older backups are deleted, the
last yearly backup is kept indefinitely.

The script is run daily by *Systemd*. It can also be run manually, if it is 
necessary.


borg-backup-rsync.sh
-------------------------------------------------------------------------------

``borg-backup-rsync.sh`` duplicates the repository to other directories with
*rsync*. Intended for removable hard disks. 

Files that were deleted in the repository, are removed from the duplicates too.
This make the script quite dangerous: Syncing a damaged repository, will damage
the duplicates too.

