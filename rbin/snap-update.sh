#!/bin/sh
set -x
systemctl unmask snapd.service
systemctl start snapd.service
systemctl status --no-pager snapd.service
snap refresh
systemctl mask snapd.service
systemctl stop snapd.service
