#!/bin/bash

# Show debugging output
#set -x

# Change to the directory where this script is located
cd "$( dirname "${BASH_SOURCE[0]}" )"

install borg-backup-create.sh /usr/local/bin

# TODO: Maybe install into `/usr/local/lib/systemd/system`?
cp borg-backup-daily.service  /etc/systemd/system/
cp borg-backup-daily.timer    /etc/systemd/system/

