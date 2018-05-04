###############################################################################
                          Backups with **Borg**
###############################################################################

This directory contains a backup repository made with the program *Borg*.
This *Borg* repository is used with additional scripts which are described
below.

* Backups are made daily, old backups are deleted. The backups are encrypted.

* Only the directories ``/home`` and ``/usr/local`` are backed up, not the complete
  system.

* The backup repository can be duplicated on a removable or external hard disk.

The scripts' Github project:

    https://github.com/eike-welk/borg-backup-scripts


===============================================================================
Usage
===============================================================================

A backup is created daily at night with the script ``borg-backup-create.sh``. It
is controlled by a *Systemd* timer.

Obviously you must be *root* for everything described here.


Restore a Lost File
-------------------------------------------------------------------------------

To restore a small amount of lost data:

1. Mount the backup repository with:
   ``borg mount name-of-the-repository mnt/``. You are asked for the repository's
   password. (There is a directory ``mnt/`` in the backup directory for this
   purpose.)

2. Browse the repository at the directory where it is mounted. Copy the lost
   files.

   Accessing a backup this way is relatively slow, graphical file managers
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


Create a new repository
-------------------------------------------------------------------------------

Create the directory, where you want to keep your backup repository. For
example: ``/backups/borg-backup``, ``/srv/borg-backup`` or
``/var/lib/borg-backup``.

Change into this directory, and run ``borg-backup-init.sh``. The script asks
you for a repository name, a password, and a path to duplicate the backup
repository.

The script creates a new backup repository (in the current directory). It also
creates configuration files, beautifies the current directory, and starts the
timer.

From then on, a backup is created every night with the script
``borg-backup-create.sh``.


===============================================================================
The Scripts
===============================================================================

The scripts are installed in ``/usr/local/bin``. They must be run as *root*.


borg-backup-init.sh
-------------------------------------------------------------------------------

``borg-backup-init.sh`` creates a new backup repository in the current directory,
and sets up the necessary configuration files. It asks the user for a
repository name, a password, and a path to duplicate the backup repository.

The script also creates this README and a mount point (`mnt/`) to browse the
repository.


borg-backup-create.sh
-------------------------------------------------------------------------------

``borg-backup-create.sh`` creates a backup of ``/home`` and ``/usr/local``. The
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


===============================================================================
Borg
===============================================================================

*Borg* is a fully featured backup program: Backups can be created, restored,
and mounted as directories. Furthermore backups can be deleted from the
repository and checked for errors.

Documentation and source code for the *Borg* program itself:

    https://borgbackup.readthedocs.io/en/stable/index.html
    https://github.com/borgbackup/borg/

A few useful subcommands of *Borg* are listed below.


List the Repository's Contents:
-------------------------------------------------------------------------------

To list the repository's contents run::

    borg list /backup/borg-backup/lixie-backup-1.borg


Restore an Archive
-------------------------------------------------------------------------------

To restore an entire archive run the following command::

    borg extract /backup/borg-backup/lixie-backup-1.borg/::lixie-2018-04-13T17:11:46

The restored files are created in the current working directory.


Mount a Backup Repository
-------------------------------------------------------------------------------

Mount the backup repository with::

    borg mount name-of-the-repository name-of-empty-directory
  
There is a directory ``mnt/`` in the backup directory for this purpose.

Accessing a backup this way is relatively slow, graphical file managers can
appear to hang from time to time.


Unmount a Backup Repository
-------------------------------------------------------------------------------

Detach (unmount) the backup repository from the file system with::

    borg umount directory-for-mount


Create a New Repository
-------------------------------------------------------------------------------

Create new backup repositories with the following command::

    borg init --encryption=repokey name-of-the-repository


===============================================================================
Systemd
===============================================================================

This project uses *Systemd* to create daily backups, instead of *Cron*.
It uses a feature of *Systemd* called *timer*.

The documentation for *Systemd* is quite extensive, but it is very hard to get
started.

    https://www.freedesktop.org/wiki/Software/systemd/

The documentation for *units* links to pages for *services* and *timers*. 
These are quite helpful, if you want to write your own unit files.

    https://www.freedesktop.org/software/systemd/man/systemd.unit.html


Commands
-------------------------------------------------------------------------------

*Systemd* is controlled with the program ``systemctl``. It has a good tab
completion (at least on openSuse and Debian), so that it can be explored fairly
well.

When unit files have been edited, they need to be reloaded with::

    systemctl daemon-reload

To see the current timers, and their state, use::

    systemctl list-timers

More detailed information is shown by the ``status`` subcommand. It is
especially useful for a *service* because it shows the last few log entries. ::

    systemctl status borg-backup-daily.service

Units need to be enabled and started, to be loaded at boot time and to run. 
However only ``borg-backup-daily.timer`` needs to be enabled and started. 
The *service* depends on the *timer* and is processed automatically. ::

    systemctl enable borg-backup-daily.timer
    systemctl start borg-backup-daily.timer

To stop the *timer* and disable it from being loaded at boot time run::

    systemctl stop borg-backup-daily.timer
    systemctl disable borg-backup-daily.timer

To access *Systemd's* log use ``journalctl``. Option ``-u`` filter for *units*.
To see the (large amount of) log messages from the backup script use::

    journalctl -u borg-backup-daily.service


Systemd Unit Files
-------------------------------------------------------------------------------

Backups are run daily by *Systemd* instead of *Cron*. Two unit files are
necessary for it: A *service* and a *timer*. Both files are installed into
``/etc/systemd/system/``.

``borg-backup-daily.service``
    This unit file runs the script ``borg-backup-create.sh``.

``borg-backup-daily.timer``
    The timer that is activated daily. Each timer corresponds to a ``service``
    file of her same name.


===============================================================================
Rsync
===============================================================================

*Rsync* is used to duplicate the backup repository to an external/removable
hard disk. In principle *Rsync* can also duplicate a hard disk over the
network, but this is unsupported by the scripts. The documentation is here:

    https://rsync.samba.org/documentation.html

Copy the backup repository to an other (removable) disk with *Rsync*. Option
``--delete`` deletes file which are no longer in the source directory. ::

    rsync --verbose --archive --delete            \
         /backup/borg-backup/lixie-backup-1       \
         /path/to/other/disk                      \


