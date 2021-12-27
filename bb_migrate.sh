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
PM2FILE=bb.js

############################## Functions #########################################

migrate_bot() {
	pm2 delete all
	cd

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
    node install 1
		
	## Recover config files
	mkdir "$BBPATH"/"$BBFOLDER"/bb/config/
	cp /tmp/config/* "$BBPATH"/"$BBFOLDER"/bb/config/

	# Check if installation was successful
	if [ -d "$BBPATH"/"$BBFOLDER"/bb/config/ ]; then
		rm -r /tmp/config/
	fi

	## Start bot ##
	echo "### Starting Balance Bot ###"
	pm2_install
	pm2 startup
	pm2 restart BalanceBot
}

pm2_install () { 
	cd "$BBPATH"/"$BBFOLDER";pm2 start "$PM2FILE" --name=BalanceBot
	pm2 save
}

press_enter() {
	echo ""
  	echo -n "	Press Enter to continue "
  	read
  	clear
}

incorrect_selection() {
  	echo "Incorrect selection! Try again."
}

until [ "$selection" = "0" ]; do
	clear
	echo "---------------------------------------------------------"
	echo ""
	echo "                  Balance Bot Migration"
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
		* ) clear ; incorrect_selection ; press_enter ;;
	esac
done