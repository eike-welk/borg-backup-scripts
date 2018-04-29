
###############################################################################
                          Backups with **Borg**
###############################################################################

This is a collection of scripts and documentation, to create daily backups of a
personal computer with the program *Borg*. The scripts work only on Linux.

* Backups are made daily, old backups are deleted. The backups are encrypted.

* Only the directories ``/home`` and ``/usr/local`` are backed up, not the
  complete system.

* The backup repository can be duplicated on a removable or external hard disk.

Documentation for the *Borg* program:

    https://borgbackup.readthedocs.io/en/stable/index.html

This collection of scripts is developed on Github:

    https://github.com/eike-welk/borg-backup-scripts


===============================================================================
Installation
===============================================================================

To install, become *root*, and run the script::

    install.sh


===============================================================================
Usage
===============================================================================

Obviously you must be *root* for everything described here.


Create a new repository
-------------------------------------------------------------------------------

Create the directory, where you want to keep your backup repository. For
example: ``/backups/borg-backup``, ``/srv/borg-backup`` or
``/var/lib/borg-backup``.

Change into this directory, and run ``borg-backup-init.sh``. The script asks
you for a repository name, a password, and a path to duplicate the backup
repository.

The script creates a new backup repository (in the current directory), creates
the configuration files, beautifies the backup directory with a README and a
restoration mount point, and starts the timer for the daily backups.

A backup is created every night with the script ``borg-backup-create.sh``. It
is controlled by a *Systemd* timer.


Restore a Lost File
-------------------------------------------------------------------------------

To restore a small amount of lost data:

1. Mount the backup repository with:
   ``borg mount name-of-the-repository mnt/``. You are asked for the repository's
   password. (There is a directory ``mnt/`` in the backup directory for this
   purpose.)

2. Browse the repository at the directory where it is mounted. Copy the lost
   files.
   
   Accessing the backup this way is relatively slow, graphical file managers
   can appear to hang from time to time.

3. Detach (unmount) the backup repository from the file system with:
   ``borg umount directory-for-mount``.


Duplicate the Repository
-------------------------------------------------------------------------------

To duplicate the repository on an external hard disk:

1. Mount the external hard disk to the configured directory.
2. Run ``borg-backup-rsync.sh``.

The external hard disk(s) must be configured in
``/etc/borg-backup/rsync-config.sh``.


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

