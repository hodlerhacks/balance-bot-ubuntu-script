##################################################################################
#!/bin/bash
# to install : wget -P /tmp -L https://raw.githubusercontent.com/hodlerhacks/balance-bot-ubuntu-script/master/bb_install.sh bb_install.sh;bash /tmp/bb_install.sh
# Balance Bot UBUNTU/DEBIAN Installer
##################################################################################
SCRIPTVERSION="2.2.0"
BBPATH=/var/opt
BBFOLDER=balance-botv2
BBSCRIPTFOLDER=balance-bot-ubuntu-script
BBREPOSITORY=https://github.com/hodlerhacks/balance-bot-v2.git
BBREPOSITORYSTAGING=https://github.com/hodlerhacks/balance-bot-v2-staging.git
BBSCRIPTREPOSITORY=https://github.com/hodlerhacks/balance-bot-ubuntu-script.git
PM2FILE=bb.js

##################################################################################
bashrc_shortcuts=( bbupdate scriptupdate bbmenu bbstart bbrestart bbstop)
bbupdate="'cd "$BBPATH"/"$BBFOLDER";git pull --ff-only origin master;cd '"
scriptupdate="'cd "$BBPATH"/"$BBSCRIPTFOLDER";git pull --ff-only origin master;cd '"
bbmenu="'bash "$BBPATH"/"$BBSCRIPTFOLDER"/bb_install.sh'"
bbstart="'pm2 start all'"
bbrestart="'pm2 restart all'"
bbstop="'pm2 stop all'"
##################################################################################

############################## Functions #########################################

write_bashrc_shortcut() {
	all_args=("$@")
	rest_args=("${all_args[@]:1}")
	shortcut_cmd="${rest_args[@]}"

 	sed -i "s|^alias $1.*|alias $1=$shortcut_cmd|gI" ~/.bashrc
}


update_bashrc_shortcuts() {
	for i in "${bashrc_shortcuts[@]}"
		do
			eval shortcut_string=\$$i
			write_bashrc_shortcut $i $shortcut_string
	done
}

check_bashrc_shortcuts() {
	for i in "${bashrc_shortcuts[@]}"
		do	
			if grep -q $i ~/.bashrc; then
				echo "Alias "$i" exist"
				update_bashrc_shortcuts
			else	
				eval shortcut_string=\$$i
				echo "Alias does not exist!!"
				echo "alias "$i"="$shortcut_string >> ~/.bashrc
			fi
	done
}

pm2_install () { 
	cd "$BBPATH"/"$BBFOLDER";pm2 start "$PM2FILE" --name=BalanceBot
	pm2 save
}

restart_bot () { 
	pm2 restart BalanceBot
}

stop_bot () { 
	pm2 stop BalanceBot
}

list_bots () {
	pm2 list
}

bb_update() {
	cd "$BBPATH"/"$BBFOLDER"
	git pull --ff-only origin master
}

bbscript_update() {
	if [ -d "$BBPATH"/"$BBSCRIPTFOLDER" ]; then
	# If local repository exists check for updates		
		cd "$BBPATH"/"$BBSCRIPTFOLDER"
			git pull --ff-only origin master
	else
		git clone "$BBSCRIPTREPOSITORY" "$BBPATH"/"$BBSCRIPTFOLDER"
	fi
}

bbscript_install() {
	cd
	rm -r "$BBPATH"/"$BBSCRIPTFOLDER"
	git clone "$BBSCRIPTREPOSITORY" "$BBPATH"/"$BBSCRIPTFOLDER"
}

bbscript_refresh() {
	/bin/bash "$BBPATH"/"$BBSCRIPTFOLDER"/bb_install.sh
}

reload_shell() {
	cd
	exec bash
}

install_packages() {
	echo "### Installing packages ###"
	apt -y update
	apt -y install git
	apt -y install -y nodejs
	apt -y install npm
	npm install pm2@latest -g
	apt -y update

	## Set maximum pm2 log file size and number of rotate files
	pm2 install pm2-logrotate
	pm2 set pm2-logrotate:max_size 10M
	pm2 set pm2-logrotate:retain 2
}

new_install() { 
	## Install packages ##
	install_packages
	
	## Creating local repository ##
	echo "### Downloading Balance Bot ###"
	
	if [ -d "$BBPATH"/"$BBFOLDER" ]; then
	# If local repository exists check for updates		
		CWD="$PWD"
		cd "$BBPATH"/"$BBFOLDER"
		git pull --ff-only origin master
		restart_bot
	else
		git clone "$INSTALLREPOSITORY" "$BBPATH"/"$BBFOLDER"
	fi

	## Open port 3000
	sudo ufw allow 3000

	## Start bot ##
	echo "### Starting Balance Bot ###"
	pm2_install

	## Create PM2 startup ##
	pm2 startup

	## Add or update shortcuts
	check_bashrc_shortcuts
	rm -r /tmp/bb_install.sh
	bbscript_refresh
}

reinstall_bot() {
	pm2 delete all
	cd

	if [ -d "$BBPATH"/"$BBFOLDER"/config/ ]; then
		mkdir /tmp/config/
		cp "$BBPATH"/"$BBFOLDER"/config/* /tmp/config/
	fi

	rm -r "$BBPATH"/"$BBFOLDER"

	## Install packages ##
	install_packages

	## Creating local repository ##
	echo "### Downloading Balance Bot ###"
	
	git clone "$INSTALLREPOSITORY" "$BBPATH"/"$BBFOLDER"
		
	## Recover config files
	mkdir "$BBPATH"/"$BBFOLDER"/config/
	cp /tmp/config/* "$BBPATH"/"$BBFOLDER"/config/

	# Check if installation was successful
	if [ -d "$BBPATH"/"$BBFOLDER"/config/ ]; then
		rm -r /tmp/config/
	fi

	## Start bot ##
	echo "### Starting Balance Bot ###"
	pm2_install

	## Create PM2 startup ##
	pm2 startup

	## Add or update shortcuts
	check_bashrc_shortcuts
	restart_bot
	bbscript_refresh
}

if [[ $EUID -ne 0 ]]; then
   	echo "This script must be run as root"
   	exit 1
fi

press_enter() {
	echo ""
  	echo -n "	Press Enter to continue "
  	read
  	clear
}

incorrect_selection() {
  	echo "Incorrect selection! Try again."
}

## Install or update at startup
bbscript_update
check_bashrc_shortcuts

until [ "$selection" = "0" ]; do
	clear
	echo "---------------------------------------------------------"
	echo ""
	echo "                  Balance Bot Installer"
	echo "                         v"$SCRIPTVERSION
	echo ""
	echo "---------------------------------------------------------"
	echo ""
	echo "      1  -  Install Balance Bot"
	echo "      2  -  Update Balance Bot"
	echo "      3  -  Re-install Balance Bot"
	echo ""
	echo "      s  -  Stop Balance Bot"
	echo "      r  -  Restart Balance Bot"
	echo "" 
	echo "      u  -  Update this installer"
	echo "      i  -  Re-install this installer"
	echo "" 
	echo "      0  -  Exit"
	echo ""
	echo "---------------------------------------------------------"
	echo "" 
	echo -n "  Enter selection: "
	read selection
	echo ""
	INSTALLREPOSITORY=$BBREPOSITORY
	case $selection in
		1 ) clear ; new_install ;;
		2 ) clear ; bb_update ; restart_bot 2>/dev/null ; press_enter ;;
		3 ) clear ; reinstall_bot;;
		1s ) clear ; INSTALLREPOSITORY=$BBREPOSITORYSTAGING ; new_install ;;
		2s ) clear ; bb_update ; restart_bot 2>/dev/null ; press_enter ;;
		3s) clear ; INSTALLREPOSITORY=$BBREPOSITORYSTAGING ; reinstall_bot ;;
		s ) clear ; stop_bot ; press_enter ;;
		r ) clear ; restart_bot ; press_enter ;;
		u ) clear ; bbscript_update ; check_bashrc_shortcuts; press_enter ;bbscript_refresh ;;	
		i ) clear ; bbscript_install ; check_bashrc_shortcuts; press_enter ;bbscript_refresh ;;	
		0 ) clear ; reload_shell ;;
		* ) clear ; incorrect_selection ; press_enter ;;
	esac
done