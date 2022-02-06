#!/bin/bash
#
#
# Script to install macOS updates
#
#################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# VARIABLES
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

notifier=/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper

batteryLevel=$(pmset -g batt | grep 'InternalBattery' | awk '{print $3}' | tr -d '%'';')

freeSpace=$(df -h -m | grep 'disk1s1' | awk '{print $4}')

updateLog=/Library/updateLogs/macOSPatchingscript.log

firstCheck=$(cat $updateLog | awk '{print $8}')

lastDay=$(date -j -f %y%m%d -v+4d $FirstCheck +%y%m%d)

today=$(date +%y%m%d)

processor=$(uname -m)

updateIcon="$updateIcon"

m1softwareupdate(){
	user=APIUSER
	passwd=APIPASSWORD
	serial=$(system_profiler SPHardwareDataType | awk '/Serial Number/{print $4}')
	ID=$(curl -u $user:$passwd -X GET "https://YOUR.JAMFSERVER.COM/JSSResource/computers/serialnumber/$serial" | tr '<' '\n' | grep -m 1 id | tr -d 'id>')
	curl -u $user:$passwd -X POST "https://YOUR.JAMFSERVER.COM/JSSResource/computercommands/command/ScheduleOSUpdate/action/InstallForceRestart/id/$ID"
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# FUNCTIONS
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# Check Battery level
battery_level_check(){
  if (( $batteryLevel > 60 )); then
	  echo "Battery Level OK, Continuing Update..."
	else
	  "$notifier" \
	  -windowType hud \
	  -lockHUD \
	  -title "MacOS Updates" \
	  -heading "Plug in Power" \
	  -description "Battery level is too low.

Please connect to a power supply before continuing." \
	  -icon /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertStopIcon.icns \
	  -button1 "Continue"
  fi
}

storage_capacity_check(){
	until (( $freeSpace >= 15000 )); do
		"$notifier" \
		-windowType hud \
		-lockHUD \
		-title "MacOS Updates" \
		-heading "Free up Disk space" \
		-description "Free disk space is critically low.

Please free up at least 15gb of disk space before continuing." \
		-icon /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertStopIcon.icns \
		-button1 "Continue"
	done
	
	echo "Enough free space, Continuing Update..."
}


runUpdate(){
"$notifier" \
-windowType hud \
-lockHUD \
-title "MacOS Updates" \
-heading "MacOS Update installing" \
-description "MacOS updates are now being installed.

This process can take 20-40min so please do not turn off your device during this time.

Your device will reboot by itself once completed." \
-icon $updateIcon &

if [[ $processor == arm64 ]]; then
	echo "Mac is M1"
	M1softwareupdate
else
	echo "Mac is Intel"
	sudo softwareupdate -i -r --restart --agree-to-licence
fi
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# RUN
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# Check for previous postponed updates

if [[ -f $updateLog ]]; then
	echo "Previous updates postponed. Checking if 4 days have passed...."
if [[ $today > $lastDay ]]; then
	echo "4 Days have passed. OS updates will now be installed"
	
# Check Battery level
battery_level_check
	
# Check Free Disk space
storage_capacity_check
	
	"$notifier" \
	-windowType hud \
	-lockHUD \
	-title "MacOS Updates" \
	-heading "MacOS Updates available." \
	-description "There are MacOS updates waiting to be installed.
	
	4 Days have passed since you first postponed the OS updates and they will now be installed after 4 hours.
	
	If you require any assistance - please don’t hesitate to raise an IT support ticket.
	
	Thank you, IT Support" \
	-icon $updateIcon \
	-iconSize 150 \
	-button1 "Install Now" \
	-defaultButton 1 \
	-countdown \
	-timeout 14400 \
	
	rm -f $updateLog

	"$notifier" \
	-windowType hud \
	-lockHUD \
	-title "MacOS Updates" \
	-heading "MacOS Update installing" \
	-description "MacOS updates are now being installed.

This process can take 20-40min so please do not turn off your device during this time.

Your device will reboot by itself once completed." \
	-icon $updateIcon &

	if [[ $processor == arm64 ]]; then
		echo "Mac is M1"
		M1softwareupdate
	else
		echo "Mac is Intel"
		sudo softwareupdate -i -r --restart --agree-to-licence
	fi
	
	exit 0

else
	echo "User still has time."
fi
else
	echo "No previous postponed updates. Continuing...."
fi

# Message to notif the user 

message=$("$notifier" \
-windowType hud \
-lockHUD \
-title "MacOS Updates" \
-heading "MacOS Updates available." \
-description "There are MacOS updates waiting to be installed.

This update will require a reboot so please save any work you have open to prevent any loss of data.

Please click 'Install now' to run the updates. If you click 'Postpone' the update will be scheduled to try again later.

If you require any assistance - please don’t hesitate to raise an IT support ticket.

Thank you, IT Support" \
-icon $updateIcon \
-iconSize 150 \
-button1 "Install now" \
-button2 "Postpone" \
-defaultButton 1 \
)

if [[ $message == 0 ]]; then
	echo "User agreed to install the MacOS update"
	rm -f $updateLog
else
	echo "User postponed the MacOS update: Date YYMMDD $today" >> $updateLog
	echo "User postponed the MacOS update: Date YYMMDD $today"
	exit 0
fi
	
# Check Free Disk space
storage_capacity_check

# Run software update
runUpdate

exit
