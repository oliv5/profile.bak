#!/bin/sh
DIR="${1:-$HOME/bin/cron}"
BACKUPDIR="${2:-/var/backups/$USER}"

# Ask for backup script binary directory
echo "Select scripts directory (default: '$DIR'): "
if ! { DIR=$(ask_file "" -n "$DIR"); }; then
	echo "Error: unknown directory '$DIR'..."
	return 1
fi
mkdir -p "$DIR"
echo

# Make backup directory
if ask_question "Create backup directory in '$BACKUPDIR'? (y/n) " y Y >/dev/null; then
	sudo mkdir -p "$BACKUPDIR"
	sudo chown $USER:$USER -R "$BACKUPDIR"
	sudo chmod 700 "$BACKUPDIR"
fi
echo

# Create crontabs
BACKUP="$DIR/backup"
if ask_question "Create crontabs? (y/n) " y Y >/dev/null; then
	# Write crontab rules
	echo > "$BACKUP.crontab" <<EOF
# Edit this file to introduce tasks to be run by cron.
# 
# Each task to run has to be defined through a single line
# indicating with different fields when the task will be run
# and what command to run for the task
# 

# m h  dom mon dow   command
## *  * * * * $USER sh -c "$BACKUP.minutly.sh"
0  * * * * $USER sh -c "$BACKUP.hourly.sh"
10 0 * * * $USER sh -c "$BACKUP.daily.sh"
20 0 * * 1 $USER sh -c "$BACKUP.weekly.sh"
30 0 1 * * $USER sh -c "$BACKUP.monthly.sh"
40 0 1 1 * $USER sh -c "$BACKUP.yearly.sh"

EOF

	# Write anacrontab rules
	echo > "$BACKUP.anacrontab" <<EOF
# /etc/anacrontab: configuration file for anacron
# See anacron(8) and anacrontab(5) for details.
#

SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# period  delay  job-identifier  command
1        10 backup.daily   "$BACKUP.daily.sh"
7        20 backup.weekly  "$BACKUP.weekly.sh"
@monthly 30 backup.monthly "$BACKUP.monthly.sh"
365      40 backup.yearly  "$BACKUP.yearly.sh"

EOF
fi
echo

# Create each backup script from the template
for SCRIPT in "$BACKUP.minutly.sh" "$BACKUP.hourly.sh" "$BACKUP.daily.sh" "$BACKUP.weekly.sh" "$BACKUP.monthly.sh" "$BACKUP.yearly.sh"; do
	if ask_question "Add a weekly home backup rule in '$SCRIPT'? (y/n) " y Y >/dev/null; then
		local TEMPLATE="$(dirname "$0")/resources/cron.backup.template.sh"
		if [ -f "$SCRIPT" ]; then
			if ask_question "Append to existing file? (y/n) " y Y >/dev/null; then
				echo >> "$SCRIPT"
				tail -n +2 "$TEMPLATE" >> "$SCRIPT"
				cat "$SCRIPT"
			else
				echo "Skip adding the backup rule..."
			fi
		else
			cp "$TEMPLATE" "$SCRIPT"
		fi
	fi
	if [ -f "$SCRIPT" ]; then
		chmod +x "$SCRIPT"
	fi
	echo
done

# Make system or local cron links
if ask_question "Create cron links in system /etc/cron* directory? (y/n) " y Y >/dev/null; then
	sudo ln -s "$BACKUP.crontab" "/etc/cron.d/backup.$USER"
elif { echo; ask_question "Add in user crontab instead? (y/n) " y Y >/dev/null; }; then
	CRONTAB="$(mktemp)"
	crontab -l > "$CRONTAB"
	grep "$BACKUP.crontab" "$CRONTAB" >/dev/null && echo "Rule already there, skip it." || {
		printf '\n%s\n' "## from $BACKUP.crontab (do not remove this line)" >> "$CRONTAB"
		cat "$BACKUP.crontab" | awk '!/^.*#/ && /'$USER'/ {$6="";print $0}' >> "$CRONTAB"
		printf '\n%s\n' "## from $BACKUP.crontab (do not remove this line)" >> "$CRONTAB"
		crontab "$CRONTAB"
	}
	crontab -l
	rm "$CRONTAB"
elif { echo; ask_question "Add in system anacrontab instead? (y/n) " y Y >/dev/null; }; then
	grep "$BACKUP.anacrontab" /etc/anacrontab >/dev/null && echo "Rule already there, skip it." || {
		sudo cat "$BACKUP.anacrontab" >> /etc/anacrontab
	}
elif { echo; ask_question "Create user anacrontab instead? (y/n) " y Y >/dev/null; }; then
	mkdir -p "${HOME}/.anacron"
	ln -s "$BACKUP.anacrontab" "${HOME}/.anacron/anacrontab"
fi
echo
