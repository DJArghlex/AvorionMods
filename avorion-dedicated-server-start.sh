#!/bin/bash

# rglx's avorion server script

# configuration
service="avorion" # name of the service
restartDelay="15" # -1 = hold for console input, 0 = just exit, any positive number: wait that many seconds, then restart

# networking
# you will need the following ports opened:
# 27000: tcp & udp
# 27003, 27020, 27021: udp
# if your firewall is strict and doesn't do port handoffs, you'll want to enable UDP connections from 32768 upwards, or switch to a less strict firewall like ufw if you can.
# keep 27030 firewalled! this is your rcon port.

# updating settings
steamAppId="565060" # appid of server files
steamAppInstallLocation="/home/avorion/serverfiles/" # installation directory
steamCmdInstallLocation="/srv/software/steamcmd-console/" # steamcmd's bootstrapper location

# execution settings
# rcon settings
rconPassword="" # rcon password - set to "" to disable rcon.
# again, keep 27030 firewalled! this is your rcon port. it's locked to 127.0.0.1, but still.

# game settings
adminSteam64Id="76561198025206464" # your steam64 ID for administrator access
#whitelistGroupSteam64Id="103582791470931809" # steam64id of a group of your choosing that will have access to the server
whitelistGroupSteam64Id="" # steam64id of a group of your choosing that will have access to the server
steamOnly="true" # only allow connections via steam, or allow legacy direct connections?


# end configuration
# touching things below here is not recommended unless you understand it!

updateServerFiles() { # run an anonymous steam update
	echo "updateServerFiles: starting steamcmd update..."
	$steamCmdInstallLocation/steamcmd.sh +login anonymous +force_install_dir $steamAppInstallLocation +app_update $steamAppId +app_update $steamAppId validate +quit
	echo "updateServerFiles: steamcmd update completed!"
}

executeServer() { # run the server.
	pushd $steamAppInstallLocation
	LD_LIBRARY_PATH=$steamAppInstallLocation/linux64/ ./bin/AvorionServer \
--send-crash-reports false \
--galaxy-name avorion_galaxy \
--admin $adminSteam64Id \
--ip 0.0.0.0 \
--same-start-sector false \
--listed true \
--public true \
--multiplayer true \
--vac-secure true \
--use-steam-networking true \
--force-steam-networking $steamOnly \
--immediate-writeout true \
--max-logs 0 \
--port 27000 \
--query-port 27003 \
--steam-query-port 27020 \
--steam-master-port 27021 \
--rcon-ip 127.0.0.1 \
--rcon-port 27030 \
--rcon-password $rconPassword \
--pausable false
	popd
}

deepCleanServer() {
	echo "deepCleanServer: beginning deep clean!"

	echo "deepCleanServer: 	clearing whitelist and blacklists..."
	rm -f ~/.avorion/galaxies/avorion_galaxy/whitelist.txt
	rm -f ~/.avorion/galaxies/avorion_galaxy/blacklist.txt
	rm -f ~/.avorion/galaxies/avorion_galaxy/ipblacklist.txt

	echo "deepCleanServer: 	dissolving groups..."
	rm -f ~/.avorion/galaxies/avorion_galaxy/groups.dat

	echo "deepCleanServer: 	resetting steam group whitelist ID file..."
	echo $whitelistGroupSteam64Id > ~/.avorion/galaxies/avorion_galaxy/group-whitelist.txt

	echo "deepCleanServer: 	purging entire steam installation"
	rm -rf ~/Steam ~/.steam

	echo "deepCleanServer: 	purging existing game files"
	rm -rf $steamAppInstallLocation

	echo "deepCleanServer: deep clean complete!"
}

cleanServer() {
	echo "cleanServer: beginning file cleanup..."

	echo "cleanServer: 	stashing logs..."
	mkdir -p ~/.avorion/galaxies/avorion_galaxy/logs/
	xz -9 ~/.avorion/galaxies/avorion_galaxy/serverlog*.txt
	mv -n ~/.avorion/galaxies/avorion_galaxy/serverlog*.txt.xz ~/.avorion/galaxies/avorion_galaxy/logs/

	echo "cleanServer: 	stashing stats..."
	mkdir -p ~/.avorion/galaxies/avorion_galaxy/stats/
	xz -9 ~/.avorion/galaxies/avorion_galaxy/server-stats*.csv
	mv -n ~/.avorion/galaxies/avorion_galaxy/server-stats*.csv.xz ~/.avorion/galaxies/avorion_galaxy/stats/

	echo "cleanServer: 	cleaning workshop cached mods..."
	rm -rf ~/.avorion/galaxies/avorion_galaxy/workshop/

	echo "cleanServer: 	removing readmes"
	rm -f ~/.avorion/galaxies/avorion_galaxy/server.ini\ -\ readme.txt

	echo "cleanServer: file cleanup complete!"
}

countdown(){
	local OLD_IFS="${IFS}"
	IFS=":"
	local ARR=( $1 )
	local SECONDS=$((  (ARR[0] * 60 * 60) + (ARR[1] * 60) + ARR[2]  ))
	local START=$(date +%s)
	local END=$((START + SECONDS))
	local CUR=$START
	while [[ $CUR -lt $END ]]
	do
		CUR=$(date +%s)
		LEFT=$((END-CUR))
		printf "\r%02d:%02d:%02d" \
			$((LEFT/3600)) $(( (LEFT/60)%60)) $((LEFT%60))
		sleep 1
	done
	IFS="${OLD_IFS}"
	echo "        "
}

if [[ ! $(whoami) == 'avorion' ]]; then # prevent people from running stuff under the wrong users
	clear
	echo -e "`toilet "HEY!"`\nDon't run this script as the wrong user!"| lolcat
	exit 1
fi

case "$1" in
	start)
		while true; do
			echo "service: starting $service..."
			touch ~/.avorion/galaxies/avorion_galaxy/running.lck
			toilet -F crop -F border -w 99999 "$service" | lolcat
			broadcastmessage "ℹ️ $service started." &

			cleanServer # clean server files
			updateServerFiles # update via steamcmd

			executeServer # run the server itself

			# executed after server stop.

			cleanServer # clean server files
			rm -f ~/.avorion/galaxies/avorion_galaxy/running.lck # unlock server
			echo "service: $service stopped!"

			# now pick our restart warnings...
			if [[ $restartDelay == "0" ]]; then
				echo "service: not restarting! restart with $0"
				broadcastmessage "🛑 $service stopped! NOT RESTARTING!!" &
				exit 0
			#elif [[ $restartDelay == "-1" ]]; then
			#	echo "service: awaiting console input to restart service"
			#	broadcastmessage "⚠️ $service stopped! NOT RESTARTING!!" &
			#	sleep 5
			#	read -p "service: [ enter to continue or Ctrl-C to abort ]" unused
			else
				echo "service: waiting $restartDelay seconds, then restarting!"
				echo "service: [ Ctrl-C to abort ]"
				broadcastmessage "⚠️ $service stopped! Restarting!" &
				countdown "00:00:$restartDelay"
			fi
		done
	;;
	tmux)
		echo "session: creating tmux session for $service..."
		tmux new-session -d -n $service -s $service bash
		echo "session: session created! attach to it with 'tmux a -t $service'"
	;;
	tmux-direct)
		echo "session: creating tmux session for $service with server starting within..."
		tmux new-session -d -n $service -s $service bash $0
		echo "session: session created & server starting! attach to it with 'tmux a -t $service'"
	;;
	update)
		if [[ -f ~/.avorion/galaxies/avorion_galaxy/running.lck ]]; then
			echo "updateServerFiles: SERVER IS IN OPERATION! DO NOT DO THIS!"
			exit 1
		fi
		updateServerFiles
		cleanServer
	;;
	clean)
		if [[ -f ~/.avorion/galaxies/avorion_galaxy/running.lck ]]; then
			echo "cleanServer: SERVER IS IN OPERATION! DO NOT DO THIS!"
			exit 1
		fi
		cleanServer
	;;
	deepclean)
		if [[ -f ~/.avorion/galaxies/avorion_galaxy/running.lck ]]; then
			echo "deepCleanServer: SERVER IS IN OPERATION! DO NOT DO THIS!"
			exit 1
		fi
		echo "deepCleanServer: starting deep clean of server files!"
		echo "deepCleanServer: this is VERY destructive! (dissolves groups, white/blacklists)"
		read -p "deepCleanServer: [ enter to continue or Ctrl-C to abort ]" unused
		cleanServer
		deepCleanServer
		updateServerFiles
	;;
	restart)
		if [[ -f ~/.avorion/galaxies/avorion_galaxy/running.lck ]]; then
			echo "restarter: Attempting to restart the server via tmux-send"
			$0 send-tmux '/broadcastchatmessage "Server Restarter" 3 "Automatic server restart in fifteen minutes. - Expected downtime: 2 minutes."'
			countdown "00:05:00"
			$0 send-tmux '/broadcastchatmessage "Server Restarter" 3 "Automatic server restart in ten minutes. - Expected downtime: 2 minutes."'
			countdown "00:05:00"
			$0 send-tmux '/broadcastchatmessage "Server Restarter" 3 "Automatic server restart in five minutes. - Expected downtime: 2 minutes."'
			countdown "00:05:00"
			$0 send-tmux '/broadcastchatmessage "Server Restarter" 2 "Automatic server restart in one minute. - Expected downtime: 2 minutes."'
			countdown "00:00:30"
			$0 send-tmux '/broadcastchatmessage "Server Restarter" 1 "Server restart in thirty seconds! - Expected downtime: 2 minutes."'
			countdown "00:00:25"
			$0 send-tmux '/broadcastchatmessage "Server Restarter" 1 "Server restart in five seconds! - Expected downtime: 2 minutes."'
			sleep 1
			$0 send-tmux '/broadcastchatmessage "Server Restarter" 1 "Server restart in four seconds! - Expected downtime: 2 minutes."'
			sleep 1
			$0 send-tmux '/broadcastchatmessage "Server Restarter" 1 "Server restart in three seconds! - Expected downtime: 2 minutes."'
			sleep 1
			$0 send-tmux '/broadcastchatmessage "Server Restarter" 1 "Server restart in two seconds! - Expected downtime: 2 minutes."'
			sleep 1
			$0 send-tmux '/broadcastchatmessage "Server Restarter" 1 "Server restart in one second! - Expected downtime: 2 minutes."'
			sleep 1
			$0 send-tmux '/broadcastchatmessage "Server Restarter" 1 "Server restarting! - Expected downtime: 2 minutes."'
			broadcastmessage " service $service undergoing automated restart!"
			$0 send-tmux "/save"
			$0 send-tmux "/stop"
		else
			echo "restarter: server doesn't appear to be running?"
			echo "restarter: mission accomplished i guess"
			exit 1
		fi
	;;
	send-tmux)
		if [[ -f ~/.avorion/galaxies/avorion_galaxy/running.lck ]]; then
			echo "send-tmux: Attempting to send $2 to the server's console via tmux"
			tmux send-keys -t $service:$service Enter
			tmux send-keys -t $service:$service "${2}" Enter
		else
			echo "send-tmux: server doesn't appear to be running?"
			exit 1
		fi
	;;
	send-file)
		if [[ -f ~/.avorion/galaxies/avorion_galaxy/running.lck ]]; then
			echo "send-file: Attempting to send '$2' to the server's console via inbuilt command file"
			echo $2 > ~/.avorion/galaxies/avorion_galaxy/commands.txt
		else
			echo "send-file: server doesn't appear to be running?"
			exit 1
		fi
	;;
	send-rcon)
		if [[ -f ~/.avorion/galaxies/avorion_galaxy/running.lck ]]; then
			echo "unimplemented (at least, not yet :) )"
			#echo "send-rcon: Attempting to send '$2' to the server's console via rcon"
			#rcon  "$2"
		else
			echo "send-rcon: server doesn't appear to be running?"
			exit 1
		fi
	;;
	screen)
		echo "session: GNU screen is no longer supported. please install & configure tmux."
		exit 1
	;;
	unlock)
		echo "session: forcibly unlocking server! use with caution!"
		rm -f ~/.avorion/galaxies/avorion_galaxy/running.lck
	;;
	help)
		echo "Usage: $0 [optional function]"
		echo " - tmux: creates a properly-named tmux session for the server to reside in."
		echo " - tmux-direct: starts the server directly under a tmux session [recommended!]"
		echo " - update: updates the server's files from steamcmd"
		echo " - clean: cleans some base files if they weren't already when the server stopped."
		echo " - deepclean: completely uninstalls the server and steam, and removes numerous files from the universedata."
		echo " - send-tmux: sends a command to the server via tmux. wrap in quotes, and include leading /"
		echo " - send-file: sends a command to the server via commands.txt, if it's configured."
		echo " - send-rcon: sends a command to the server via rcon, if enabled."
		echo " - rcon: opens an rcon connection to the server, if a suitable rcon program is installed."
		echo " - restart: uses tmux-send to stop the server. crontab automatable!"
		echo " - unlock: removes stale running.lck file from the galaxy, allowing the server to start."
		echo " - <nothing>: starts the server in the current terminal."
		exit 0
	;;
	*)
		if [[ -f ~/.avorion/galaxies/avorion_galaxy/running.lck ]]; then
			echo "service: server already running! Attach to the session with 'tmux a -t $service'"
			exit 1
		else
			echo "service: restarting script..."
			bash $0 start
		fi
	;;
esac
