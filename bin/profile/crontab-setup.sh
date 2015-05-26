#!/bin/sh
DIR="${1:-$HOME/bin/cron}"
BACKUPDIR="${2:-/var/backups/$USER}"

# Ask for backup script binary directory
echo "Select backup scripts directory (default: '$DIR'): "
if ! { DIR=$(ask_file "" -n "$DIR"); }; then
	echo "Error: unknown directory '$DIR'..."
	return 1
fi
mkdir -p "$DIR"
echo

# Create scripts
BACKUP="$DIR/backup"
if ask_question "Create backup scripts? (y/n) " y Y >/dev/null; then
	touch "$BACKUP.cron"; 						chmod +x "$BACKUP.cron"
	echo "#!/bin/sh" > "$BACKUP.minutly.sh";	chmod +x "$BACKUP.minutly.sh"
	echo "#!/bin/sh" > "$BACKUP.hourly.sh";		chmod +x "$BACKUP.hourly.sh"
	echo "#!/bin/sh" > "$BACKUP.daily.sh";		chmod +x "$BACKUP.daily.sh"
	echo "#!/bin/sh" > "$BACKUP.weekly.sh";		chmod +x "$BACKUP.weekly.sh"
	echo "#!/bin/sh" > "$BACKUP.monthly.sh";	chmod +x "$BACKUP.monthly.sh"
	echo "#!/bin/sh" > "$BACKUP.yearly.sh";		chmod +x "$BACKUP.yearly.sh"
	# Create rules
	grep "$BACKUP.minutly.sh" "$BACKUP.cron" 	>/dev/null || echo "## *  * * * * $USER sh -c \"$BACKUP.minutly.sh\""	>> "$BACKUP.cron"
	grep "$BACKUP.hourly.sh" "$BACKUP.cron" 	>/dev/null || echo "0  * * * * $USER sh -c \"$BACKUP.hourly.sh\""	>> "$BACKUP.cron"
	grep "$BACKUP.daily.sh" "$BACKUP.cron" 		>/dev/null || echo "10 0 * * * $USER sh -c \"$BACKUP.daily.sh\""	>> "$BACKUP.cron"
	grep "$BACKUP.weekly.sh" "$BACKUP.cron" 	>/dev/null || echo "20 0 * * 1 $USER sh -c \"$BACKUP.weekly.sh\""	>> "$BACKUP.cron"
	grep "$BACKUP.monthly.sh" "$BACKUP.cron" 	>/dev/null || echo "30 0 1 * * $USER sh -c \"$BACKUP.monthly.sh\""	>> "$BACKUP.cron"
	grep "$BACKUP.yearly.sh" "$BACKUP.cron" 	>/dev/null || echo "40 0 1 1 * $USER sh -c \"$BACKUP.yearly.sh\""	>> "$BACKUP.cron"
fi
echo

# Make system or local cron links
if ask_question "Create cron links in system /etc/cron* directory? (y/n) " y Y >/dev/null; then
	sudo sudo ln -s "$BACKUP.cron" "/etc/cron.d/backup.$USER"
elif { echo; ask_question "Add in user crontab instead? (y/n) " y Y >/dev/null; }; then
	CRONTAB="$(mktemp)"
	crontab -l > "$CRONTAB"
	grep "$BACKUP.cron" "$CRONTAB" >/dev/null && echo "Rule already there, skip it." || {
		printf '\n%s\n' "## from $BACKUP.cron (do not remove this line)" >> "$CRONTAB"
		cat "$BACKUP.cron" | awk '!/^.*#/ && /'$USER'/ {$6="";print $0}' >> "$CRONTAB"
		printf '\n%s\n' "## from $BACKUP.cron (do not remove this line)" >> "$CRONTAB"
		crontab "$CRONTAB"
	}
	crontab -l
	rm "$CRONTAB"
fi
echo

# Make backup directory
if ask_question "Create backup directory in '$BACKUPDIR'? (y/n) " y Y >/dev/null; then
	sudo mkdir -p "$BACKUPDIR"
	sudo chown $USER:$USER -R "$BACKUPDIR"
	sudo chmod 700 "$BACKUPDIR"
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
	echo
done
