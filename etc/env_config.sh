configure_env() {
 	echo "Configuring environment..."
				# the shell init file works around some 
				# networking anomalies
        SHELL_INIT_FILE=/etc/profile.d/cdemo.sh
        sudo rm -f $SHELL_INIT_FILE

        sudo touch $SHELL_INIT_FILE
        sudo chmod a+w $SHELL_INIT_FILE
        sudo echo PATH=\$PATH:/usr/local/bin >> $SHELL_INIT_FILE
                # ensure internet connectivity on shell startup
        sudo echo "sudo sysctl -w net.ipv4.ip_forward=1" >> $SHELL_INIT_FILE
        sudo echo "sudo dhclient -v" >> $SHELL_INIT_FILE
        sudo chmod go-w $SHELL_INIT_FILE
        sudo chmod +x $SHELL_INIT_FILE
}

main $@
