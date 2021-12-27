##################################################################################
#!/bin/bash
# to use : wget -P /tmp -L https://raw.githubusercontent.com/hodlerhacks/balance-bot-ubuntu-script/master/bb_migrate.sh bb_migrate.sh;bash /tmp/bb_migrate.sh
# Balance Bot UBUNTU/DEBIAN Migration tool
##################################################################################
SCRIPTVERSION="1.0.0"
BBPATH=/var/opt
BBFOLDER=balance-botv2
BBSCRIPTFOLDER=balance-bot-ubuntu-script
BBINSTALLERREPOSITORY=https://github.com/hodlerhacks/balance.git
BBSCRIPTREPOSITORY=https://github.com/hodlerhacks/balance-bot-ubuntu-script.git
PM2FILE=bb.js

############################## Functions #########################################

press_enter() {
	echo ""
  	echo -n "	Press Enter to continue "
  	read
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

migrate_bot() {
	pm2 delete all
	cd

	## Save config files
	if [ -d "$BBPATH"/"$BBFOLDER"/config/ ]; then
		mkdir /tmp/config/
		cp "$BBPATH"/"$BBFOLDER"/config/* /tmp/config/
    else
    	if [ -d "$BBPATH"/"$BBFOLDER"/bb/config/ ]; then
            echo "It seems that migration has already been performed"
        else
            echo "It seems that Balance Bot is not properly installed or setup"
        fi
    fi

	rm -r "$BBPATH"/"$BBFOLDER"

	## Creating local repository ##
	echo "### Downloading Balance Bot ###"
	
	git clone "$BBINSTALLERREPOSITORY" "$BBPATH"/"$BBFOLDER"

    ## Run install.js to do a clean install
    CWD="$PWD"
    cd "$BBPATH"/"$BBFOLDER"
    node install.js 1
	cd

    press_enter

	## Recover config files
	mkdir "$BBPATH"/"$BBFOLDER"/bb/config/
	cp /tmp/config/* "$BBPATH"/"$BBFOLDER"/bb/config/

	# Check if installation was successful
	if [ -d "$BBPATH"/"$BBFOLDER"/bb/config/ ]; then
		rm -r /tmp/config/
	fi

    bbscript_update

	## Start bot ##
	echo "### Starting Balance Bot ###"
	pm2_install
	pm2 startup
	pm2 restart BalanceBot

    exit
}

pm2_install () { 
	cd "$BBPATH"/"$BBFOLDER";pm2 start "$PM2FILE" --name=BalanceBot
	pm2 save
}

until [ "$selection" = "0" ]; do
	clear
	echo "---------------------------------------------------------"
	echo ""
	echo "                  Balance Bot Migration"
	echo "                          v0.0.2"
	echo ""
	echo "---------------------------------------------------------"
	echo ""
	echo "      1  -  Migrate Balance Bot"
	echo "      0  -  Exit"
	echo ""
	echo "---------------------------------------------------------"
	echo "" 
	echo -n "  Enter selection: "
	read selection
	echo ""
	case $selection in
		1 ) clear ; migrate_bot ;;
	esac
done