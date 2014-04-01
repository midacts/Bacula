#!/bin/bash
# Bacula 5.2.13 Install on Debian Wheezy
# Author: John McCarthy
# <http://www.midactstech.blogspot.com> <https://www.github.com/Midacts>
# Date: 30th of December, 2013
# Version 1.0
#
# To God only wise, be glory through Jesus Christ forever. Amen.
# Romans 16:27, I Corinthians 15:1-4
#---------------------------------------------------------------
######## VARIABLES ########
bacula_ver=7.0.0
######## FUNCTIONS ########
function baculaInstall()
{
	# Install Required Packages
		echo ''
		echo -e '\e[01;34m+++ Installing prerequisite packages...\e[0m'
		echo ''
		apt-get update
		apt-get install -y build-essential libpq-dev postgresql-9.1 postgresql-common openssl sudo
		echo ''
		echo -e '\e[01;37;42mThe prerequisite packages were successfully installed!\e[0m'

	# Download the Latest Bacula Version (5.2.13)
		echo ''
		echo -e '\e[01;34m+++ Downloading the Latest Bacula installation files...\e[0m'
		echo ''
		wget http://sourceforge.net/projects/bacula/files/bacula/$bacula_ver/bacula-$bacula_ver.tar.gz
		echo -e '\e[01;37;42mThe Bacula installation files were successfully downloaded!\e[0m'

	# Untarring the Bacula Files
		echo ''
		echo -e '\e[01;34m+++ Untarrring the Bacula installation files...\e[0m'
		tar xzf bacula-$bacula_ver.tar.gz
		cd bacula-$bacula_ver
		echo ''
		echo -e '\e[01;37;42mThe Bacula installation files were successfully untarred!\e[0m'

	# Configure and Install Bacula
		echo ''
		echo -e '\e[01;34m+++ Installing Bacula with PostreSQL...\e[0m'
		echo ''
		./configure --with-postgresql --with-openssl
		make
		make install
		echo -e '\e[01;37;42mBacula has been successfully installed!\e[0m'
}
function databaseCreation()
{
	# Temporarily Add Postgres User to Root Group To Create the Bacula Database
		echo ''
		echo -e '\e[01;34m+++ Adding postgres user group privileges...\e[0m'
		echo ''
		usermod -a -G root postgres
		sudo adduser postgres sudo
		echo ''
		echo -e '\e[01;37;42mThe postgres user'\''s group privileges have been successfully added!\e[0m'

	# Create the Bacula Database
		echo ''
		echo -e '\e[01;34m+++ Creating the Bacula database...\e[0m'
		echo ''
		su - postgres -c /etc/bacula/create_postgresql_database
		su - postgres -c /etc/bacula/make_postgresql_tables
		su - postgres -c /etc/bacula/grant_postgresql_privileges
		echo ''
		echo -e '\e[01;37;42mThe Bacula database has been successfully created!\e[0m'
}
function databaseConfiguration()
{
	# Initial Configuration of the PostgreSQL Database Permissions
		echo ''
		echo -e '\e[01;34m+++ Modifying the PostgreSQL database permissions...\e[0m'
		sed -i '/local   all             all                                     peer/a\
		\nlocal   bacula          bacula                                  trust' /etc/postgresql/9.1/main/pg_hba.conf
		sed -i 's/local   all             all                                     peer/#local   all             all                                     peer/g' /etc/postgresql/9.1/main/pg_hba.conf
		echo ''
		echo -e '\e[01;37;42mThe PostgreSQL database permissions have been successfully modified!\e[0m'

	# Restart PostgreSQL for these Permission Changes to Take Effect
		echo ''
		echo -e '\e[01;34m+++ Restarting the PostgreSQL service...\e[0m'
		echo ''
		service postgresql restart

	# Add the Password to the bacula-dir.conf File and the Bacula Database
		echo ''
		echo -e '\e[01;34m+++ Setting the Bacula database password...\e[0m'
		echo ''
		echo -e '\e[33mPlease choose a Bacula database password\e[0m'
		read dbpassword
		sed -i "s/dbname = \"bacula\"; dbuser = \"bacula\"; dbpassword = \"\"/dbname = \"bacula\"; dbuser = \"bacula\"; dbpassword = \"$dbpassword\"/g" /etc/bacula/bacula-dir.conf
		echo ''
		echo -e '\e[01;37;42mThe Bacula database password was successfully added to the /etc/bacula/bacula-dir.conf file!\e[0m'
	# Add a Password to the Bacula User in the Bacula Database
		echo ''
		echo -e '\e[01;34m+++ Setting the Bacula database password in the Bacula database...\e[0m'
		echo ''
		su - postgres -c "psql -U bacula -d bacula -c \"alter user bacula with password '$dbpassword';\""
		echo ''
		echo -e '\e[01;37;42mThe Bacula database password was successfully added to the Bacula PostgreSQL database!\e[0m'

	# Securing the Bacula Database to Require the Bacula User to Use a Password
		echo ''
		echo -e '\e[01;34m+++ Setting up a md5 password requirement for the bacula user in the Bacula database...\e[0m'
		sed -i 's/local   bacula          bacula                                  trust/local   bacula          bacula                                  md5/g' /etc/postgresql/9.1/main/pg_hba.conf
		echo ''
		echo -e '\e[01;37;42mThe The bacula user password requirement has been successfully set!\e[0m'

	# Restart PostgreSQL for these Permission Changes to Take Effect
		echo ''
		echo -e '\e[01;34m+++ Restarting the PostgreSQL service...\e[0m'
		echo ''
		service postgresql restart

	# Remove Postgres User from Root Group
		echo ''
		echo -e '\e[01;34m+++ Modifying the postgres user group privileges...\e[0m'
		echo ''
		gpasswd -d postgres root
		echo ''
		echo -e '\e[01;37;42mThe postgres user'\''s group privileges have been successfully modified!\e[0m'
}
function bootBacula()
{
	# Setup the Bacula Service Scripts
		echo ''
		echo -e '\e[01;34m+++ Creating Bacula Init files...\e[0m'
		echo ''
		cp /etc/bacula/bacula-ctl-dir /etc/init.d/bacula-dir
		cp /etc/bacula/bacula-ctl-fd /etc/init.d/bacula-fd
		cp /etc/bacula/bacula-ctl-sd /etc/init.d/bacula-sd
		chmod 755 /etc/init.d/bacula-sd
		chmod 755 /etc/init.d/bacula-fd
		chmod 755 /etc/init.d/bacula-dir
		update-rc.d bacula-sd defaults 90
		update-rc.d bacula-fd defaults 91
		update-rc.d bacula-dir defaults 92
		echo ''
		echo -e '\e[01;37;42mBacula has been successfully configured to start at boot time!\e[0m'
}
function emailConfiguration()
{
	# Install Sendmail
		echo ''
		echo -e '\e[01;34m+++ Installing sendmail packages...\e[0m'
		echo ''
		apt-get install -y sendmail sendmail-bin
		echo ''
		echo -e '\e[01;37;42mThe sendmail packages were successfully installed!\e[0m'

	# Setup Bacula Email Alerts
		echo ''
		echo -e '\e[01;34m+++ Setting up Bacula Email Alerts...\e[0m'
		echo ''
		echo -e '\e[33mWhat email address would you like to RECEIVE Bacula email alerts?\e[0m'
		read BACULA_EMAIL_RECIPIENT
		echo -e '\e[33mWhat email address would you like to be used to SEND Bacula emails?\e[0m'
		read BACULA_EMAIL_SENDER

	# Add Bacula Email Sender and Recipient(s)
		echo ''
		echo -e '\e[01;34m+++ Adding Bacula Email Alerts to the /etc/bacula/bacula-dir.conf file...\e[0m'
		sed -i "s/mail = root@localhost = all, \!skipped/mail = $BACULA_EMAIL_RECIPIENT = all, \!skipped/g" /etc/bacula/bacula-dir.conf
		sed -i "s/operator = root@localhost = mount/operator = $BACULA_EMAIL_RECIPIENT = mount/g" /etc/bacula/bacula-dir.conf
		sed -i 's/mailcommand = "\/sbin\/bsmtp -h localhost -f \\"\\(Bacula\\) \\<%r\\>\\" -s \\"Bacula: %t %e of %c %l\\" %r"/mailcommand = "\/sbin\/bsmtp -h localhost -f \"\(Bacula\)'"$BACULA_EMAIL_SENDER"' \<%r\>\" -s \"Bacula: %t %e of %c %l\" %r"/g' /etc/bacula/bacula-dir.conf
		sed -i 's/mailcommand = "\/sbin\/bsmtp -h localhost -f \\"\\(Bacula\\) \\<%r\\>\\" -s \\"Bacula daemon message\\" %r"/mailcommand = "\/sbin\/bsmtp -h localhost -f \"\(Bacula\)'"$BACULA_EMAIL_SENDER"' \<%r\>\" -s \"Bacula daemon message\" %r"/g' /etc/bacula/bacula-dir.conf
		sed -i 's/operatorcommand = "\/sbin\/bsmtp -h localhost -f \\"\\(Bacula\\) \\<%r\\>\\" -s \\"Bacula: Intervention needed for %j\\" %r"/operatorcommand = "\/sbin\/bsmtp -h localhost -f \"\(Bacula\)'"$BACULA_EMAIL_SENDER"' \<%r\>\" -s \"Bacula: Intervention needed for %j\" %r"/g' /etc/bacula/bacula-dir.conf
		echo ''
		echo -e '\e[01;37;42mBacula email notifications have been successfully setup!\e[0m'
}
function dirConfiguration()
{
	# Bacula Modification Check
		num=$(wc -l < /etc/bacula/bacula-dir.conf)
		if [ $num -lt 300 ];then
			return 0
			echo "It looks like you have already modified your /etc/bacula/bacula-dir.conf file"
			batinstall
		fi

	# Copy bacula-dir.conf settings to Individual Files
		echo ''
		echo -e '\e[01;34m+++ Creating Bacula Director sub-files...\e[0m'
		sed -n 154,165p /etc/bacula/bacula-dir.conf > /etc/bacula/clients.conf
		sed -n '88,94p;109,110p;116,125p;143,152p' /etc/bacula/bacula-dir.conf > /etc/bacula/filesets.conf
		sed -n '26,39p;55,85p' /etc/bacula/bacula-dir.conf > /etc/bacula/jobs.conf
		sed -n 279,304p /etc/bacula/bacula-dir.conf > /etc/bacula/pools.conf
		sed -n 130,141p /etc/bacula/bacula-dir.conf > /etc/bacula/schedules.conf
		sed -n 182,191p /etc/bacula/bacula-dir.conf > /etc/bacula/storage.conf
		echo ''
		echo -e '\e[01;37;42mThe Bacula Directoru sub-files have been successfully created!\e[0m'

	# Clean up bacula-dir.conf
		echo ''
		echo -e '\e[01;34m+++ Cleaning up the bacula-dir.conf file...\e[0m'
		sed -i "26,229d;233,234d;238,239d;242,253d;259,263d;268,269d;279,308d" /etc/bacula/bacula-dir.conf
		echo ''
		echo -e '\e[01;37;42mThe bacula-dir.conf has been successfully cleaned up!\e[0m'

	# Adding the Additional Configuration Files to bacula-dir.conf File
		echo ''
		echo -e '\e[01;34m+++ Adding the new sub-files to the bacula-dir.conf file...\e[0m'
		sed -i '26i\# Include configs with @ symbol:\
@/etc/bacula/clients.conf\
@/etc/bacula/filesets.conf\
@/etc/bacula/jobs.conf\
@/etc/bacula/pools.conf\
@/etc/bacula/schedules.conf\
@/etc/bacula/storage.conf\n' /etc/bacula/bacula-dir.conf
		echo ''
		echo -e '\e[01;37;42mThe bacula-dir.conf sub-files have been successfully added to the bacula-dir.conf file!\e[0m'

	# Add Labels to Bacula Pools
		echo ''
		echo -e '\e[01;34m+++ Adding labels to the Bacula pools...\e[0m'
		sed -i '8i\  Label Format = "Default-${Year}_${Month}_${Day}"' /etc/bacula/pools.conf
		sed -i '20i\  Label Format = "File-${Year}_${Month}_${Day}"' /etc/bacula/pools.conf
		echo ''
		echo -e '\e[01;37;42mLabels have been successfully added to your Bacula pools!\e[0m'

	# Setting the Storage Daemon's Name
		echo ''
		echo -e '\e[01;34m+++ Correctly setting up the Bacula Storage Daemon'\''s name...\e[0m'
		SD=$(sed -n 14p /etc/bacula/bacula-sd.conf)
		STOR=$(sed -n 3p /etc/bacula/storage.conf)

	# Copy the Storage Daemon Name from bacula-sd.conf to storage.conf
		sed -i "s;$STOR;$SD;g" /etc/bacula/storage.conf

	# Setting the Correct Storage Device Name in jobs.conf
		SDName=$(sed -n 3p /etc/bacula/storage.conf | awk '{print substr($0,10); }')
		sed -i "s/Storage = File/Storage = $SDName/g" /etc/bacula/jobs.conf
		echo ''
		echo -e '\e[01;37;42mThe Bacula Storage Daemon'\''s name has been successfully set!\e[0m'

	# Setting the Storage Daemon's Address
		echo ''
		echo -e '\e[01;34m+++ Setting up the Bacula Storage Daemon'\''s IP address...\e[0m'
		ADDRESS=$(sed -n 5p /etc/bacula/storage.conf)
		IP=$(/sbin/ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1)
		sed -i "s;$ADDRESS;  Address = $IP;g" /etc/bacula/storage.conf
		echo ''
		echo -e '\e[01;37;42mThe Bacula Storage Daemon'\''s IP address has been successfully set!\e[0m'
}
function storageConfiguration()
{
	# Change bacula-sd.conf Archive Device Directory
		echo ''
		echo -e '\e[01;34m+++ Setting the Bacula Storage Daemon'\''s directory...\e[0m'
		echo ''
		echo -e '\e[33mPlease specify where you would like Bacula to store its backup files:\e[0m'
		read BACKUP_DIR
		sed -i "s;Archive Device = \/tmp;Archive Device = $BACKUP_DIR;g" /etc/bacula/bacula-sd.conf
		echo ''
		echo -e '\e[01;37;42mThe Bacula Storage Daemon'\''s directory has been successfully added to the /etc/bacula/bacula-sd.conf file!\e[0m'

# Create the Archive Device Directory
		echo ''
		echo -e '\e[01;34m+++ Creating the Bacula Storage Daemon'\''s directory...\e[0m'
		mkdir -p $BACKUP_DIR
		echo ''
		echo -e "\e[01;37;42mThe Bacula Storage Daemon's directory has been successfully set to $BACKUP_DIR"'!'"\e[0m"
}
function batInstall()
{
	# Install BAT
		echo ''
		echo -e '\e[01;34m+++ Installing BAT...\e[0m'
		echo ''
		apt-get install -y bacula-console-qt
		echo ''
		echo -e '\e[01;37;42mBAT has been successfully installed!\e[0m'

	# Make Sure bat.conf and bconsole.conf Have the Same Password
		echo ''
		echo -e '\e[01;34m+++ Configuring BAT...\e[0m'
		BAT=$(sed -n 9,9p /etc/bacula/bat.conf)
		BCON=$(sed -n 9,9p /etc/bacula/bconsole.conf)

	# Copies the password from bconsole.conf to bat.conf
		sed -i "s;$BAT;$BCON;g" /etc/bacula/bat.conf
		echo ''
		echo -e '\e[01;37;42mBAT has been successfully configured!\e[0m'
}
function baculaWeb()
{
	# Download the Required Packages
		echo ''
		echo -e '\e[01;34m+++ Installing prerequisite packages...\e[0m'
		echo ''
		apt-get install -y apache2 libapache2-mod-php5 php5-pgsql php5-gd
		echo ''
		echo -e '\e[01;37;42mThe prerequisite packages were successfully installed!\e[0m'

	# Download the Latest Version of Bacula-web (6.0.0)
		echo ''
		echo -e '\e[01;34m+++ Downloading the Latest Bacula Web files...\e[0m'
		echo ''
		wget http://www.bacula-web.org/files/bacula-web.org/downloads/bacula-web-latest.tgz
		echo -e '\e[01;37;42mThe Bacula Web installation files were successfully downloaded!\e[0m'

	# Unzip the Bacula-Web Tar File
		echo ''
		echo -e '\e[01;34m+++ Untarrring the Bacula Web files...\e[0m'
		tar xzf bacula-web-latest.tgz -C /var/www/
		echo ''
		echo -e '\e[01;37;42mThe Bacula Web installation files were successfully untarred!\e[0m'

	# Move the Bacula-Web Directory and Change It's Permissions
		echo ''
		echo -e '\e[01;34m+++ Setting up the Bacula Web installation file permissions...\e[0m'
		mv /var/www/bacula-web-6.0.0 /var/www/bacula-web
		cd /var/www
		chown -R www-data: ./bacula-web
		chmod -R 755 ./bacula-web
		cd bacula-web
		echo ''
		echo -e '\e[01;37;42mThe Bacula Web installation files have the correct permissions set!\e[0m'

	# Move and Edit the config.ini file
		echo ''
		echo -e '\e[01;34m+++ Moving the config.php file...\e[0m'
		mv application/config/config.php.sample application/config/config.php
		chown www-data: application/config/config.php
		echo ''
		echo -e '\e[01;37;42mThe config.php file has been successfully moved!\e[0m'

	# Database Password for the config.ini file
		echo ''
		echo -e '\e[01;34m+++ Adding the Bacula Database password to the config.php file...\e[0m'
		DBPass=$(sed -n 37p /etc/bacula/bacula-dir.conf | awk '{print substr($0,55, length($0) - 55); }')
		echo ''
		echo -e '\e[01;37;42mThe Bacula database password has been successfully added to the config.php file!\e[0m'

	# Edit the config.ini
		echo ''
		echo -e '\e[01;34m+++ Configuring the config.php file...\e[0m'
cat << 'EOT' > /var/www/bacula-web/application/config/config.php
<?php
// Show inactive clients (false by default)
$config['show_inactive_clients'] = true;

// Hide empty pools (displayed by default)
$config['hide_empty_pools'] = false;

// Jobs per page (Jobs report page)
$config['jobs_per_page'] = 25;

// Translations
$config['language'] = 'en_US';

// PostgreSQL bacula catalog
$config[0]['label'] = 'Prod Server';
$config[0]['host'] = 'localhost';
$config[0]['login'] = 'bacula';
$config[0]['password'] = 'pwd';
$config[0]['db_name'] = 'bacula';
$config[0]['db_type'] = 'pgsql';
$config[0]['db_port'] = '5432';

?>
EOT
	# Insert database password
		sed -i "s;pwd;$DBPass;g" /var/www/bacula-web/application/config/config.php
		echo ''
		echo -e '\e[01;37;42mThe config.php file has been successfully configured!\e[0m'

	# Restart the Apache2 Service For these Changes to Go into Effect
		echo ''
		echo -e '\e[01;34m+++ Restarting the Apache2 service...\e[0m'
		echo ''
		service apache2 restart

	# Test Bacula-Web
		echo ''
		echo -e '\e[01;37mGo to the following link to view the Bacula Web UI:\e[0m'
		echo ''
		echo -e '\e[01;37mhttp://ip_or_fqdn/bacula-web/test.php\e[0m'
}
function phpTimezone()
{
###############
## VARIABLES ##
###############
# These variables are used in the each country's text function
main_menu="\e[1;37mPress the Esc Key then ENTER to return to the Main Menu\e[0m"
pick_region="\e[33mPick a Region:\e[0m"
pick_number="\e[33mPlease type in the number corresponding to the timezone you wish to choose:\e[0m"

# Prints all the available countries
function country_text()
{
# Creates a heredoc stored in a variable containing a list of all the countries to choose from
CTRY=$(cat <<EOT
\e[33mPick a Country:\e[0m
$ERROR
\e[36m 1.) Africa                     5.) Asia                 9.) Indian
 2.) America                    6.) Atlantic            10.) Pacific
 3.) Antarctica                 7.) Australia           11.) Others
 4.) Arctic                     8.) Europe\e[0m

\e[33mPlease type in the number corresponding to the country you wish to choose:\e[0m
EOT
)

# Checks if there is any errors by seeing if the ERROR Variable is set
if [ -n "$ERROR" ]; then
# If there was an error message, this unsets the ERROR variable so if there is another error, it will only print the latest one.
	unset ERROR
fi

# Prints the list of available countries
echo -e "$CTRY" | more

# Calls the country_read function
country_read
}

# Reads user's Input for their selected country and checks if it passes certain checks
function country_read()
{
# Stores the country number read by the user's input
read COUNTRY

# This requires that the user's selection be numeric
if [[ $COUNTRY != *[0-9]* ]] || [[ $COUNTRY = *[!0-9]* ]]; then
	clear
# If the user's input is non-numeric, the function will recall the country_text function and print this error message
	ERROR="\e[31mPlease type in ONLY the numeric value to the corresponding country. Please try again\e[0m"$'\n'
	country_text
	return 0
fi
# This requires the user to choose a number between 1 to 11, one for each country
if [ $COUNTRY -gt 11 ]; then
	clear
# If the user's input is greater than the total number of countries, the function will recall the country_text function and print this error message
	ERROR="\e[31mPlease select a an integer between 1-11"$'\n'
	country_text
	return 0
fi

# Sets the Country array
Country[1]='Africa'
Country[2]='America'
Country[3]='Antarctica'
Country[4]='Arctic'
Country[5]='Asia'
Country[6]='Atlantic'
Country[7]='Australia'
Country[8]='Europe'
Country[9]='Indian'
Country[10]='Pacific'
Country[11]='Others'

# Searches through the Country array until the user's country selection is found
for i in "${!Country[@]}"
do
  if [ $i -eq $COUNTRY ]; then
  # The COUNTRY variable stores the user's numeric selection into the associated country's name
	NAME=${Country[$i]}
  fi
done

country_yn
}

# Checks whether the correct country was chosen.
function country_yn()
{
echo -e "\e[33mYou have chosen $NAME as your Country. Is this correct ? (y/n)\e[0m"
# Gets the user's input to check If the selected country is correct
read yesno
# If the user type "y", this functions calls the check function
if [ "$yesno" = "y" ]; then
	check
fi
# If the user types "n", this function calls the country_text function
if [ "$yesno" = "n" ]; then
	clear
	country_text
# If the user types in anything other than "y" or "n", this function calls the country_text function
elif [ "$yesno" != "y" ] && [ "$yesno" != "n" ]; then
	clear
# this variable is printed in the country_text function if this error is reached
	ERROR="\e[31mYou must select either y or n. Please try again.\e[0m"$'\n'
	country_text
fi
}

# Checks the COUNTRY variable to call the corresponding country's text function
# Each country's number of timezone's is stored in the variable NUM
function check()
{
clear
if [ $COUNTRY -eq 1 ]; then
	NUM="54"
	''$NAME'_text'
elif [ $COUNTRY -eq 2 ]; then
	NUM="164"
	''$NAME'_text'
elif [ $COUNTRY -eq 3 ]; then
	NUM="11"
	''$NAME'_text'
elif [ $COUNTRY -eq 4 ]; then
	NUM="1"
	''$NAME'_text'
elif [ $COUNTRY -eq 5 ]; then
	NUM="90"
	''$NAME'_text'
elif [ $COUNTRY -eq 6 ]; then
	NUM="12"
	''$NAME'_text'
elif [ $COUNTRY -eq 7 ]; then
	NUM="23"
	''$NAME'_text'
elif [ $COUNTRY -eq 8 ]; then
	NUM="59"
	''$NAME'_text'
elif [ $COUNTRY -eq 9 ]; then
	NUM="11"
	''$NAME'_text'
elif [ $COUNTRY -eq 10 ]; then
	NUM="42"
	''$NAME'_text'
elif [ $COUNTRY -eq 11 ]; then
	NUM="111"
	''$NAME'_text'
fi
}

function Africa_text ()
{
RGN=$(cat <<EOA
$main_menu
$pick_region
$ERROR
\e[36m 1.)  Africa/Abidjan	  21.) Africa/Douala	   41.) Africa/Mbabane
 2.)  Africa/Accra	  22.) Africa/El_Aaiun	   42.) Africa/Mogadishu
 3.)  Africa/Addis_Ababa  23.) Africa/Freetown	   43.) Africa/Monrovia
 4.)  Africa/Algiers	  24.) Africa/Gaborone	   44.) Africa/Nairobi
 5.)  Africa/Asmara	  25.) Africa/Harare	   45.) Africa/Ndjamena
 6.)  Africa/Asmera	  26.) Africa/Johannesburg 46.) Africa/Niamey
 7.)  Africa/Bamako	  27.) Africa/Juba	   47.) Africa/Nouakchott
 8.)  Africa/Bangui	  28.) Africa/Kampala	   48.) Africa/Ouagadougou
 9.)  Africa/Banjul	  29.) Africa/Khartoum	   49.) Africa/Porto-Novo
10.) Africa/Bissau	  30.) Africa/Kigali	   50.) Africa/Sao_Tome
11.) Africa/Blantyre	  31.) Africa/Kinshasa	   51.) Africa/Timbuktu
12.) Africa/Brazzaville	  32.) Africa/Lagos	   52.) Africa/Tripoli
13.) Africa/Bujumbura	  33.) Africa/Libreville   53.) Africa/Tunis
14.) Africa/Cairo	  34.) Africa/Lome	   54.) Africa/Windhoek
15.) Africa/Casablanca	  35.) Africa/Luanda
16.) Africa/Ceuta	  36.) Africa/Lubumbashi
17.) Africa/Conakry	  37.) Africa/Lusaka
18.) Africa/Dakar	  38.) Africa/Malabo
19.) Africa/Dar_es_Salaam 39.) Africa/Maputo
20.) Africa/Djibouti	  40.) Africa/Maseru\e[0m

$pick_number
EOA
)

# Calls the timezone_list function
timezone_list
}
function Africa_array()
{
# Sets the Africa array
Africa[1]='Africa/Abidjan'
Africa[2]='Africa/Accra'
Africa[3]='Africa/Addis_Ababa'
Africa[4]='Africa/Algiers'
Africa[5]='Africa/Asmara'
Africa[6]='Africa/Asmera'
Africa[7]='Africa/Bamako'
Africa[8]='Africa/Bangui'
Africa[9]='Africa/Banjul'
Africa[10]='Africa/Bissau'
Africa[11]='Africa/Blantyre'
Africa[12]='Africa/Brazzaville'
Africa[13]='Africa/Bujumbura'
Africa[14]='Africa/Cairo'
Africa[15]='Africa/Casablanca'
Africa[16]='Africa/Ceuta'
Africa[17]='Africa/Conakry'
Africa[18]='Africa/Dakar'
Africa[19]='Africa/Dar_es_Salaam'
Africa[20]='Africa/Djibouti'
Africa[21]='Africa/Douala'
Africa[22]='Africa/El_Aaiun'
Africa[23]='Africa/Freetown'
Africa[24]='Africa/Gaborone'
Africa[25]='Africa/Harare'
Africa[26]='Africa/Johannesburg'
Africa[27]='Africa/Juba'
Africa[28]='Africa/Kampala'
Africa[29]='Africa/Khartoum'
Africa[30]='Africa/Kigali'
Africa[31]='Africa/Kinshasa'
Africa[32]='Africa/Lagos'
Africa[33]='Africa/Libreville'
Africa[34]='Africa/Lome'
Africa[35]='Africa/Luanda'
Africa[36]='Africa/Lubumbashi'
Africa[37]='Africa/Lusaka'
Africa[38]='Africa/Malabo'
Africa[39]='Africa/Maputo'
Africa[40]='Africa/Maseru'
Africa[41]='Africa/Mbabane'
Africa[42]='Africa/Mogadishu'
Africa[43]='Africa/Monrovia'
Africa[44]='Africa/Nairobi'
Africa[45]='Africa/Ndjamena'
Africa[46]='Africa/Niamey'
Africa[47]='Africa/Nouakchott'
Africa[48]='Africa/Ouagadougou'
Africa[49]='Africa/Porto-Novo'
Africa[50]='Africa/Sao_Tome'
Africa[51]='Africa/Timbuktu'
Africa[52]='Africa/Tripoli'
Africa[53]='Africa/Tunis'
Africa[54]='Africa/Windhoek'

# Searches through the Africa array until the user's timezone selection is found
for i in "${!Africa[@]}"
do
if [ $i -eq $REGION ]; then
# The TOWN variable stores the user's numeric selection into the associated timezone's name
	TOWN=${Africa[$i]}
fi
done

# Calls the Yes_No function
Yes_No
}

function America_text ()
{
RGN=$(cat <<EOB
$main_menu
$pick_region
$ERROR
\e[36m 1.) America/Adak			 83.) America/Jamaica
 2.) America/Anchorage			 84.) America/Jujuy
 3.) America/Anguilla			 85.) America/Juneau
 4.) America/Antigua			 86.) America/Kentucky/Louisville
 5.) America/Araguaina			 87.) America/Kentucky/Monticello
 6.) America/Argentina/Buenos_Aires	 88.) America/Knox_IN
 7.) America/Argentina/Catamarca	 89.) America/Kralendijk
 8.) America/Argentina/ComodRivadavia	 90.) America/La_Paz
 9.) America/Argentina/Cordoba		 91.) America/Lima
10.) America/Argentina/Jujuy		 92.) America/Los_Angeles
11.) America/Argentina/La_Rioja		 93.) America/Louisville
12.) America/Argentina/Mendoza		 94.) America/Lower_Princes
13.) America/Argentina/Rio_Gallegos	 95.) America/Maceio
14.) America/Argentina/Salta		 96.) America/Managua
15.) America/Argentina/San_Juan		 97.) America/Manaus
16.) America/Argentina/San_Luis		 98.) America/Marigot
17.) America/Argentina/Tucuman		 99.) America/Martinique
18.) America/Argentina/Ushuaia		100.) America/Matamoros
19.) America/Aruba			101.) America/Mazatlan
20.) America/Asuncion			102.) America/Mendoza
21.) America/Atikokan			103.) America/Menominee
22.) America/Atka			104.) America/Merida
23.) America/Bahia			105.) America/Metlakatla
24.) America/Bahia_Banderas		106.) America/Mexico_City
25.) America/Barbados			107.) America/Miquelon
26.) America/Belem			108.) America/Moncton
27.) America/Belize			109.) America/Monterrey
28.) America/Blanc-Sablon		110.) America/Montevideo
29.) America/Boa_Vista			111.) America/Montreal
30.) America/Bogota			112.) America/Montserrat
31.) America/Boise			113.) America/Nassau
32.) America/Buenos_Aires		114.) America/New_York
33.) America/Cambridge_Bay		115.) America/Nipigon
34.) America/Campo_Grande		116.) America/Nome
35.) America/Cancun			117.) America/Noronha
36.) America/Caracas			118.) America/North_Dakota/Beulah
37.) America/Catamarca			119.) America/North_Dakota/Center
38.) America/Cayenne			120.) America/North_Dakota/New_Salem
39.) America/Cayman			121.) America/Ojinaga
40.) America/Chicago			122.) America/Panama
41.) America/Chihuahua			123.) America/Pangnirtung
42.) America/Coral_Harbour		124.) America/Paramaribo
43.) America/Cordoba			125.) America/Phoenix
44.) America/Costa_Rica			126.) America/Port_of_Spain
45.) America/Creston			127.) America/Port-au-Prince
46.) America/Cuiaba			128.) America/Porto_Acre
47.) America/Curacao			129.) America/Porto_Velho
48.) America/Danmarkshavn		130.) America/Puerto_Rico
49.) America/Dawson			131.) America/Rainy_River
50.) America/Dawson_Creek		132.) America/Rankin_Inlet
51.) America/Denver			133.) America/Recife
52.) America/Detroit			134.) America/Regina
53.) America/Dominica			135.) America/Resolute
54.) America/Edmonton			136.) America/Rio_Branco
55.) America/Eirunepe			137.) America/Rosario
56.) America/El_Salvador		138.) America/Santa_Isabel
57.) America/Ensenada			139.) America/Santarem
58.) America/Fort_Wayne			140.) America/Santiago
59.) America/Fortaleza			141.) America/Santo_Domingo
60.) America/Glace_Bay			142.) America/Sao_Paulo
61.) America/Godthab			143.) America/Scoresbysund
62.) America/Goose_Bay			144.) America/Shiprock
63.) America/Grand_Turk			145.) America/Sitka
64.) America/Grenada			146.) America/St_Barthelemy
65.) America/Guadeloupe			147.) America/St_Johns
66.) America/Guatemala			148.) America/St_Kitts
67.) America/Guayaquil			149.) America/St_Lucia
68.) America/Guyana			150.) America/St_Thomas
69.) America/Halifax			151.) America/St_Vincent
70.) America/Havana			152.) America/Swift_Current
71.) America/Hermosillo			153.) America/Tegucigalpa
72.) America/Indiana/Indianapolis	154.) America/Thule
73.) America/Indiana/Knox		155.) America/Thunder_Bay
74.) America/Indiana/Marengo		156.) America/Tijuana
75.) America/Indiana/Petersburg		157.) America/Toronto
76.) America/Indiana/Tell_City		158.) America/Tortola
77.) America/Indiana/Vevay		159.) America/Vancouver
78.) America/Indiana/Vincennes		160.) America/Virgin
79.) America/Indiana/Winamac		161.) America/Whitehorse
80.) America/Indianapolis		162.) America/Winnipeg
81.) America/Inuvik			163.) America/Yakutat
82.) America/Iqaluit			164.) America/Yellowknife\e[0m

$pick_number
EOB
)

# Calls the timezone_list function
timezone_list
}
function America_array()
{
# Sets the America array
America[1]='America/Adak'
America[2]='America/Anchorage'
America[3]='America/Anguilla'
America[4]='America/Antigua'
America[5]='America/Araguaina'
America[6]='America/Argentina/Buenos_Aires'
America[7]='America/Argentina/Catamarca'
America[8]='America/Argentina/ComodRivadavia'
America[9]='America/Argentina/Cordoba'
America[10]='America/Argentina/Jujuy'
America[11]='America/Argentina/La_Rioja'
America[12]='America/Argentina/Mendoza'
America[13]='America/Argentina/Rio_Gallegos'
America[14]='America/Argentina/Salta'
America[15]='America/Argentina/San_Juan'
America[16]='America/Argentina/San_Luis'
America[17]='America/Argentina/Tucuman'
America[18]='America/Argentina/Ushuaia'
America[19]='America/Aruba'
America[20]='America/Asuncion'
America[21]='America/Atikokan'
America[22]='America/Atka'
America[23]='America/Bahia'
America[24]='America/Bahia_Banderas'
America[25]='America/Barbados'
America[26]='America/Belem'
America[27]='America/Belize'
America[28]='America/Blanc-Sablon'
America[29]='America/Boa_Vista'
America[30]='America/Bogota'
America[31]='America/Boise'
America[32]='America/Buenos_Aires'
America[33]='America/Cambridge_Bay'
America[34]='America/Campo_Grande'
America[35]='America/Cancun'
America[36]='America/Caracas'
America[37]='America/Catamarca'
America[38]='America/Cayenne'
America[39]='America/Cayman'
America[40]='America/Chicago'
America[41]='America/Chihuahua'
America[42]='America/Coral_Harbour'
America[43]='America/Cordoba'
America[44]='America/Costa_Rica'
America[45]='America/Creston'
America[46]='America/Cuiaba'
America[47]='America/Curacao'
America[48]='America/Danmarkshavn'
America[49]='America/Dawson'
America[50]='America/Dawson_Creek'
America[51]='America/Denver'
America[52]='America/Detroit'
America[53]='America/Dominica'
America[54]='America/Edmonton'
America[55]='America/Eirunepe'
America[56]='America/El_Salvador'
America[57]='America/Ensenada'
America[58]='America/Fort_Wayne'
America[59]='America/Fortaleza'
America[60]='America/Glace_Bay'
America[61]='America/Godthab'
America[62]='America/Goose_Bay'
America[63]='America/Grand_Turk'
America[64]='America/Grenada'
America[65]='America/Guadeloupe'
America[66]='America/Guatemala'
America[67]='America/Guayaquil'
America[68]='America/Guyana'
America[69]='America/Halifax'
America[70]='America/Havana'
America[71]='America/Hermosillo'
America[72]='America/Indiana/Indianapolis'
America[73]='America/Indiana/Knox'
America[74]='America/Indiana/Marengo'
America[75]='America/Indiana/Petersburg'
America[76]='America/Indiana/Tell_City'
America[77]='America/Indiana/Vevay'
America[78]='America/Indiana/Vincennes'
America[79]='America/Indiana/Winamac'
America[80]='America/Indianapolis'
America[81]='America/Inuvik'
America[82]='America/Iqaluit'
America[83]='America/Jamaica'
America[84]='America/Jujuy'
America[85]='America/Juneau'
America[86]='America/Kentucky/Louisville'
America[87]='America/Kentucky/Monticello'
America[88]='America/Knox_IN'
America[89]='America/Kralendijk'
America[90]='America/La_Paz'
America[91]='America/Lima'
America[92]='America/Los_Angeles'
America[93]='America/Louisville'
America[94]='America/Lower_Princes'
America[95]='America/Maceio'
America[96]='America/Managua'
America[97]='America/Manaus'
America[98]='America/Marigot'
America[99]='America/Martinique'
America[100]='America/Matamoros'
America[101]='America/Mazatlan'
America[102]='America/Mendoza'
America[103]='America/Menominee'
America[104]='America/Merida'
America[105]='America/Metlakatla'
America[106]='America/Mexico_City'
America[107]='America/Miquelon'
America[108]='America/Moncton'
America[109]='America/Monterrey'
America[110]='America/Montevideo'
America[111]='America/Montreal'
America[112]='America/Montserrat'
America[113]='America/Nassau'
America[114]='America/New_York'
America[115]='America/Nipigon'
America[116]='America/Nome'
America[117]='America/Noronha'
America[118]='America/North_Dakota/Beulah'
America[119]='America/North_Dakota/Center'
America[120]='America/North_Dakota/New_Salem'
America[121]='America/Ojinaga'
America[122]='America/Panama'
America[123]='America/Pangnirtung'
America[124]='America/Paramaribo'
America[125]='America/Phoenix'
America[126]='America/Port_of_Spain'
America[127]='America/Port-au-Prince'
America[128]='America/Porto_Acre'
America[129]='America/Porto_Velho'
America[130]='America/Puerto_Rico'
America[131]='America/Rainy_River'
America[132]='America/Rankin_Inlet'
America[133]='America/Recife'
America[134]='America/Regina'
America[135]='America/Resolute'
America[136]='America/Rio_Branco'
America[137]='America/Rosario'
America[138]='America/Santa_Isabel'
America[139]='America/Santarem'
America[140]='America/Santiago'
America[141]='America/Santo_Domingo'
America[142]='America/Sao_Paulo'
America[143]='America/Scoresbysund'
America[144]='America/Shiprock'
America[145]='America/Sitka'
America[146]='America/St_Barthelemy'
America[147]='America/St_Johns'
America[148]='America/St_Kitts'
America[149]='America/St_Lucia'
America[150]='America/St_Thomas'
America[151]='America/St_Vincent'
America[152]='America/Swift_Current'
America[153]='America/Tegucigalpa'
America[154]='America/Thule'
America[155]='America/Thunder_Bay'
America[156]='America/Tijuana'
America[157]='America/Toronto'
America[158]='America/Tortola'
America[159]='America/Vancouver'
America[160]='America/Virgin'
America[161]='America/Whitehorse'
America[162]='America/Winnipeg'
America[163]='America/Yakutat'
America[164]='America/Yellowknife'

# Searches through the America array until the user's timezone selection is found
for i in "${!America[@]}"
do
if [ $i -eq $REGION ]; then
# The TOWN variable stores the user's numeric selection into the associated timezone's name
	TOWN=${America[$i]}
fi
done

# Calls the Yes_No function
Yes_No
}

function Antarctica_text()
{
RGN=$(cat <<EOC
$main_menu
$pick_region
$ERROR
\e[36m 1.) Antarctica/Casey	 		 7.) Antarctica/Palmer
 2.) Antarctica/Davis	 		 8.) Antarctica/Rothera
 3.) Antarctica/DumontDUrville		 9.) Antarctica/South_Pole
 4.) Antarctica/Macquarie		10.) Antarctica/Syowa
 5.) Antarctica/Mawson			11.) Antarctica/Vostok
 6.) Antarctica/McMurdo\e[0m

$pick_number
EOC
)

# Calls the timezone_list function
timezone_list
}
function Antarctica_array()
{
# Sets the Antarctica array
Antarctica[1]=Antarctica/Casey
Antarctica[2]=Antarctica/Davis
Antarctica[3]=Antarctica/DumontDUrville
Antarctica[4]=Antarctica/Macquarie
Antarctica[5]=Antarctica/Mawson
Antarctica[6]=Antarctica/McMurdo
Antarctica[7]=Antarctica/Palmer
Antarctica[8]=Antarctica/Rothera
Antarctica[9]=Antarctica/South_Pole
Antarctica[10]=Antarctica/Syowa
Antarctica[11]=Antarctica/Vostok

# Searches through the Antarctica array until the user's timezone selection is found
for i in "${!Antarctica[@]}"
do
if [ $i -eq $REGION ]; then
# The TOWN variable stores the user's numeric selection into the associated timezone's name
	TOWN=${Antarctica[$i]}
fi
done

# Calls the Yes_No function
Yes_No
}

function Arctic_text()
{
RGN=$(cat <<EOD
$main_menu
$pick_region
$ERROR
\e[36m 1.) Arctic/Longyearbyen\e[0m

$pick_number
EOD
)

# Calls the timezone_list function
timezone_list
}
function Arctic_array()
{
# Sets the Arctic rray
Arctic[1]='Arctic/Longyearbyen'

# Searches through the Arctic array until the user's timezone selection is found
for i in "${!Arctic[@]}"
do
if [ $i -eq $REGION ]; then
# The TOWN variable stores the user's numeric selection into the associated timezone's name
	TOWN=${Arctic[$i]}
fi
done

# Calls the Yes_No function
Yes_No
}

function Asia_text()
{
RGN=$(cat <<EOE
$main_menu
$pick_region
$ERROR
\e[36m 1.) Asia/Aden		31.) Asia/Hong_Kong	61.) Asia/Phnom_Penh
 2.) Asia/Almaty	32.) Asia/Hovd		62.) Asia/Pontianak
 3.) Asia/Amman		33.) Asia/Irkutsk	63.) Asia/Pyongyang
 4.) Asia/Anadyr	34.) Asia/Istanbul	64.) Asia/Qatar
 5.) Asia/Aqtau		35.) Asia/Jakarta	65.) Asia/Qyzylorda
 6.) Asia/Aqtobe	36.) Asia/Jayapura	66.) Asia/Rangoon
 7.) Asia/Ashgabat	37.) Asia/Jerusalem	67.) Asia/Riyadh
 8.) Asia/Ashkhabad	38.) Asia/Kabul		68.) Asia/Saigon
 9.) Asia/Baghdad	39.) Asia/Kamchatka	69.) Asia/Sakhalin
10.) Asia/Bahrain	40.) Asia/Karachi	70.) Asia/Samarkand
11.) Asia/Baku		41.) Asia/Kashgar	71.) Asia/Seoul
12.) Asia/Bangkok	42.) Asia/Kathmandu	72.) Asia/Shanghai
13.) Asia/Beirut	43.) Asia/Katmandu	73.) Asia/Singapore
14.) Asia/Bishkek	44.) Asia/Khandyga	74.) Asia/Taipei
15.) Asia/Brunei	45.) Asia/Kolkata	75.) Asia/Tashkent
16.) Asia/Calcutta	46.) Asia/Krasnoyarsk	76.) Asia/Tbilisi
17.) Asia/Choibalsan	47.) Asia/Kuala_Lumpur	77.) Asia/Tehran
18.) Asia/Chongqing	48.) Asia/Kuching	78.) Asia/Tel_Aviv
19.) Asia/Chungking	49.) Asia/Kuwait	79.) Asia/Thimbu
20.) Asia/Colombo	50.) Asia/Macao		80.) Asia/Thimphu
21.) Asia/Dacca		51.) Asia/Macau		81.) Asia/Tokyo
22.) Asia/Damascus	52.) Asia/Magadan	82.) Asia/Ujung_Pandang
23.) Asia/Dhaka		53.) Asia/Makassar	83.) Asia/Ulaanbaatar
24.) Asia/Dili		54.) Asia/Manila	84.) Asia/Ulan_Bator
25.) Asia/Dubai		55.) Asia/Muscat	85.) Asia/Urumqi
26.) Asia/Dushanbe	56.) Asia/Nicosia	86.) Asia/Ust-Nera
27.) Asia/Gaza		57.) Asia/Novokuznetsk	87.) Asia/Vientiane
28.) Asia/Harbin	58.) Asia/Novosibirsk	88.) Asia/Vladivostok
29.) Asia/Hebron	59.) Asia/Omsk		89.) Asia/Yakutsk
30.) Asia/Ho_Chi_Minh	60.) Asia/Oral		90.) Asia/Yekaterinburg\e[0m

$pick_number
EOE
)

# Calls the timezone_list function
timezone_list
}
function Asia_array()
{
# Sets the Asia array
Asia[1]='Asia/Aden'
Asia[2]='Asia/Almaty'
Asia[3]='Asia/Amman'
Asia[4]='Asia/Anadyr'
Asia[5]='Asia/Aqtau'
Asia[6]='Asia/Aqtobe'
Asia[7]='Asia/Ashgabat'
Asia[8]='Asia/Ashkhabad'
Asia[9]='Asia/Baghdad'
Asia[10]='Asia/Bahrain'
Asia[11]='Asia/Baku'
Asia[12]='Asia/Bangkok'
Asia[13]='Asia/Beirut'
Asia[14]='Asia/Bishkek'
Asia[15]='Asia/Brunei'
Asia[16]='Asia/Calcutta'
Asia[17]='Asia/Choibalsan'
Asia[18]='Asia/Chongqing'
Asia[19]='Asia/Chungking'
Asia[20]='Asia/Colombo'
Asia[21]='Asia/Dacca'
Asia[22]='Asia/Damascus'
Asia[23]='Asia/Dhaka'
Asia[24]='Asia/Dili'
Asia[25]='Asia/Dubai'
Asia[26]='Asia/Dushanbe'
Asia[27]='Asia/Gaza'
Asia[28]='Asia/Harbin'
Asia[29]='Asia/Hebron'
Asia[30]='Asia/Ho_Chi_Minh'
Asia[31]='Asia/Hong_Kong'
Asia[32]='Asia/Hovd'
Asia[33]='Asia/Irkutsk'
Asia[34]='Asia/Istanbul'
Asia[35]='Asia/Jakarta'
Asia[36]='Asia/Jayapura'
Asia[37]='Asia/Jerusalem'
Asia[38]='Asia/Kabul'
Asia[39]='Asia/Kamchatka'
Asia[40]='Asia/Karachi'
Asia[41]='Asia/Kashgar'
Asia[42]='Asia/Kathmandu'
Asia[43]='Asia/Katmandu'
Asia[44]='Asia/Khandyga'
Asia[45]='Asia/Kolkata'
Asia[46]='Asia/Krasnoyarsk'
Asia[47]='Asia/Kuala_Lumpur'
Asia[48]='Asia/Kuching'
Asia[49]='Asia/Kuwait'
Asia[50]='Asia/Macao'
Asia[51]='Asia/Macau'
Asia[52]='Asia/Magadan'
Asia[53]='Asia/Makassar'
Asia[54]='Asia/Manila'
Asia[55]='Asia/Muscat'
Asia[56]='Asia/Nicosia'
Asia[57]='Asia/Novokuznetsk'
Asia[58]='Asia/Novosibirsk'
Asia[59]='Asia/Omsk'
Asia[60]='Asia/Oral'
Asia[61]='Asia/Phnom_Penh'
Asia[62]='Asia/Pontianak'
Asia[63]='Asia/Pyongyang'
Asia[64]='Asia/Qatar'
Asia[65]='Asia/Qyzylorda'
Asia[66]='Asia/Rangoon'
Asia[67]='Asia/Riyadh'
Asia[68]='Asia/Saigon'
Asia[69]='Asia/Sakhalin'
Asia[70]='Asia/Samarkand'
Asia[71]='Asia/Seoul'
Asia[72]='Asia/Shanghai'
Asia[73]='Asia/Singapore'
Asia[74]='Asia/Taipei'
Asia[75]='Asia/Tashkent'
Asia[76]='Asia/Tbilisi'
Asia[77]='Asia/Tehran'
Asia[78]='Asia/Tel_Aviv'
Asia[79]='Asia/Thimbu'
Asia[80]='Asia/Thimphu'
Asia[81]='Asia/Tokyo'
Asia[82]='Asia/Ujung_Pandang'
Asia[83]='Asia/Ulaanbaatar'
Asia[84]='Asia/Ulan_Bator'
Asia[85]='Asia/Urumqi'
Asia[86]='Asia/Ust-Nera'
Asia[87]='Asia/Vientiane'
Asia[88]='Asia/Vladivostok'
Asia[89]='Asia/Yakutsk'
Asia[90]='Asia/Yekaterinburg'

# Searches through the Others array until the user's timezone selection is found
for i in "${!Asia[@]}"
do
if [ $i -eq $REGION ]; then
# The TOWN variable stores the user's numeric selection into the associated timezone's name
	TOWN=${Asia[$i]}
fi
done

# Calls the Yes_No function
Yes_No
}

function Atlantic_text()
{
RGN=$(cat <<EOF
$main_menu
$pick_region
$ERROR
\e[36m 1.) Atlantic/Azores	 	 7.) Atlantic/Jan_Mayen
 2.) Atlantic/Bermuda	 	 8.) Atlantic/Madeira
 3.) Atlantic/Canary	 	 9.) Atlantic/Reykjavik
 4.) Atlantic/Cape_Verde	10.) Atlantic/South_Georgia
 5.) Atlantic/Faeroe		11.) Atlantic/St_Helena
 6.) Atlantic/Faroe		12.) Atlantic/Stanley\e[0m

$pick_number
EOF
)

# Calls the timezone_list function
timezone_list
}
function Atlantic_array()
{
# Sets the Atlantic Array
Atlantic[1]='Atlantic/Azores'
Atlantic[2]='Atlantic/Bermuda'
Atlantic[3]='Atlantic/Canary'
Atlantic[4]='Atlantic/Cape_Verde'
Atlantic[5]='Atlantic/Faeroe'
Atlantic[6]='Atlantic/Faroe'
Atlantic[7]='Atlantic/Jan_Mayen'
Atlantic[8]='Atlantic/Madeira'
Atlantic[9]='Atlantic/Reykjavik'
Atlantic[10]='Atlantic/South_Georgia'
Atlantic[11]='Atlantic/St_Helena'
Atlantic[12]='Atlantic/Stanley'

# Searches through the Atlantic array until the user's timezone selection is found
for i in "${!Atlantic[@]}"
do
if [ $i -eq $REGION ]; then
# The TOWN variable stores the user's numeric selection into the associated timezone's name
	TOWN=${Atlantic[$i]}
fi
done

# Calls the Yes_No function
Yes_No
}

function Australia_text()
{
RGN=$(cat <<EOG
$main_menu
$pick_region
$ERROR
\e[36m 1.) Australia/ACT		13.) Australia/Melbourne
 2.) Australia/Adelaide		14.) Australia/North
 3.) Australia/Brisbane		15.) Australia/NSW
 4.) Australia/Broken_Hill	16.) Australia/Perth
 5.) Australia/Canberra		17.) Australia/Queensland
 6.) Australia/Currie		18.) Australia/South
 7.) Australia/Darwin		19.) Australia/Sydney
 8.) Australia/Eucla		20.) Australia/Tasmania
 9.) Australia/Hobart		21.) Australia/Victoria
10.) Australia/LHI		22.) Australia/West
11.) Australia/Lindeman		23.) Australia/Yancowinna
12.) Australia/Lord_Howe\e[0m

$pick_number
EOG
)

# Calls the timezone_list function
timezone_list
}
function Australia_array()
{
# Sets the Australia Array
Australia[1]='Australia/ACT'
Australia[2]='Australia/Adelaide'
Australia[3]='Australia/Brisbane'
Australia[4]='Australia/Broken_Hill'
Australia[5]='Australia/Canberra'
Australia[6]='Australia/Currie'
Australia[7]='Australia/Darwin'
Australia[8]='Australia/Eucla'
Australia[9]='Australia/Hobart'
Australia[10]='Australia/LHI'
Australia[11]='Australia/Lindeman'
Australia[12]='Australia/Lord_Howe'
Australia[13]='Australia/Melbourne'
Australia[14]='Australia/North'
Australia[15]='Australia/NSW'
Australia[16]='Australia/Perth'
Australia[17]='Australia/Queensland'
Australia[18]='Australia/South'
Australia[19]='Australia/Sydney'
Australia[20]='Australia/Tasmania'
Australia[21]='Australia/Victoria'
Australia[22]='Australia/West'
Australia[23]='Australia/Yancowinna'

# Searches through the Australia array until the user's timezone selection is found
for i in "${!Australia[@]}"
do
if [ $i -eq $REGION ]; then
# The TOWN variable stores the user's numeric selection into the associated timezone's name
	TOWN=${Australia[$i]}
fi
done

# Calls the Yes_No function
Yes_No
}

function Europe_text()
{
RGN=$(cat <<EOH
$main_menu
$pick_region
$ERROR
\e[36m 1.) Europe/Amsterdam 	21.) Europe/Kaliningrad	41.) Europe/San_Marino
 2.) Europe/Andorra	22.) Europe/Kiev	42.) Europe/Sarajevo
 3.) Europe/Athens	23.) Europe/Lisbon	43.) Europe/Simferopol
 4.) Europe/Belfast	24.) Europe/Ljubljana	44.) Europe/Skopje
 5.) Europe/Belgrade	25.) Europe/London	45.) Europe/Sofia
 6.) Europe/Berlin	26.) Europe/Luxembourg	46.) Europe/Stockholm
 7.) Europe/Bratislava	27.) Europe/Madrid	47.) Europe/Tallinn
 8.) Europe/Brussels	28.) Europe/Malta	48.) Europe/Tirane
 9.) Europe/Bucharest	29.) Europe/Mariehamn	49.) Europe/Tiraspol
10.) Europe/Budapest	30.) Europe/Minsk	50.) Europe/Uzhgorod
11.) Europe/Busingen	31.) Europe/Monaco	51.) Europe/Vaduz
12.) Europe/Chisinau	32.) Europe/Moscow	52.) Europe/Vatican
13.) Europe/Copenhagen	33.) Europe/Nicosia	53.) Europe/Vienna
14.) Europe/Dublin	34.) Europe/Oslo	54.) Europe/Vilnius
15.) Europe/Gibraltar	35.) Europe/Paris	55.) Europe/Volgograd
16.) Europe/Guernsey	36.) Europe/Podgorica	56.) Europe/Warsaw
17.) Europe/Helsinki	37.) Europe/Prague	57.) Europe/Zagreb
18.) Europe/Isle_of_Man	38.) Europe/Riga	58.) Europe/Zaporozhye
19.) Europe/Istanbul	39.) Europe/Rome	59.) Europe/Zurich
20.) Europe/Jersey	40.) Europe/Samara\e[0m

$pick_number
EOH
)

# Calls the timezone_list function
timezone_list
}
function Europe_array()
{
# Sets the Europe array
Europe[1]='Europe/Amsterdam'
Europe[2]='Europe/Andorra'
Europe[3]='Europe/Athens'
Europe[4]='Europe/Belfast'
Europe[5]='Europe/Belgrade'
Europe[6]='Europe/Berlin'
Europe[7]='Europe/Bratislava'
Europe[8]='Europe/Brussels'
Europe[9]='Europe/Bucharest'
Europe[10]='Europe/Budapest'
Europe[11]='Europe/Busingen'
Europe[12]='Europe/Chisinau'
Europe[13]='Europe/Copenhagen'
Europe[14]='Europe/Dublin'
Europe[15]='Europe/Gibraltar'
Europe[16]='Europe/Guernsey'
Europe[17]='Europe/Helsinki'
Europe[18]='Europe/Isle_of_Man'
Europe[19]='Europe/Istanbul'
Europe[20]='Europe/Jersey'
Europe[21]='Europe/Kaliningrad'
Europe[22]='Europe/Kiev'
Europe[23]='Europe/Lisbon'
Europe[24]='Europe/Ljubljana'
Europe[25]='Europe/London'
Europe[26]='Europe/Luxembourg'
Europe[27]='Europe/Madrid'
Europe[28]='Europe/Malta'
Europe[29]='Europe/Mariehamn'
Europe[30]='Europe/Minsk'
Europe[31]='Europe/Monaco'
Europe[32]='Europe/Moscow'
Europe[33]='Europe/Nicosia'
Europe[34]='Europe/Oslo'
Europe[35]='Europe/Paris'
Europe[36]='Europe/Podgorica'
Europe[37]='Europe/Prague'
Europe[38]='Europe/Riga'
Europe[39]='Europe/Rome'
Europe[40]='Europe/Samara'
Europe[41]='Europe/San_Marino'
Europe[42]='Europe/Sarajevo'
Europe[43]='Europe/Simferopol'
Europe[44]='Europe/Skopje'
Europe[45]='Europe/Sofia'
Europe[46]='Europe/Stockholm'
Europe[47]='Europe/Tallinn'
Europe[48]='Europe/Tirane'
Europe[49]='Europe/Tiraspol'
Europe[50]='Europe/Uzhgorod'
Europe[51]='Europe/Vaduz'
Europe[52]='Europe/Vatican'
Europe[53]='Europe/Vienna'
Europe[54]='Europe/Vilnius'
Europe[55]='Europe/Volgograd'
Europe[56]='Europe/Warsaw'
Europe[57]='Europe/Zagreb'
Europe[58]='Europe/Zaporozhye'
Europe[59]='Europe/Zurich'

# Searches through the Europe array until the user's timezone selection is found
for i in "${!Europe[@]}"
do
if [ $i -eq $REGION ]; then
# The TOWN variable stores the user's numeric selection into the associated timezone's name
	TOWN=${Europe[$i]}
fi
done

# Calls the Yes_No function
Yes_No
}

function Indian_text()
{
RGN=$(cat <<EOI
$main_menu
$pick_region
$ERROR
\e[36m 1.) Indian/Antananarivo 5.) Indian/Comoro     9.) Indian/Mauritius
 2.) Indian/Chagos	 6.) Indian/Kerguelen 10.) Indian/Mayotte
 3.) Indian/Christmas	 7.) Indian/Mahe      11.) Indian/Reunion
 4.) Indian/Cocos	 8.) Indian/Maldives\e[0m

$pick_number
EOI
)

# Calls the timezone_list function
timezone_list
}
function Indian_array()
{
# Sets the Indian array
Indian[1]='Indian/Antananarivo'
Indian[2]='Indian/Chagos'
Indian[3]='Indian/Christmas'
Indian[4]='Indian/Cocos'
Indian[5]='Indian/Comoro'
Indian[6]='Indian/Kerguelen'
Indian[7]='Indian/Mahe'
Indian[8]='Indian/Maldives'
Indian[9]='Indian/Mauritius'
Indian[10]='Indian/Mayotte'
Indian[11]='Indian/Reunion'

# Searches through the Indian array until the user's timezone selection is found
for i in "${!Indian[@]}"
do
if [ $i -eq $REGION ]; then
# The TOWN variable stores the user's numeric selection into the associated timezone's name
	TOWN=${Indian[$i]}
fi
done

# Calls the Yes_No function
Yes_No
}

function Pacific_text()
{
RGN=$(cat <<EOJ
$main_menu
$pick_region
$ERROR
\e[36m 1.) Pacific/Apia	 22.) Pacific/Midway
 2.) Pacific/Auckland	 23.) Pacific/Nauru
 3.) Pacific/Chatham	 24.) Pacific/Niue
 4.) Pacific/Chuuk	 25.) Pacific/Norfolk
 5.) Pacific/Easter	 26.) Pacific/Noumea
 6.) Pacific/Efate	 27.) Pacific/Pago_Pago
 7.) Pacific/Enderbury	 28.) Pacific/Palau
 8.) Pacific/Fakaofo	 29.) Pacific/Pitcairn
 9.) Pacific/Fiji	 30.) Pacific/Pohnpei
10.) Pacific/Funafuti	 31.) Pacific/Ponape
11.) Pacific/Galapagos	 32.) Pacific/Port_Moresby
12.) Pacific/Gambier	 33.) Pacific/Rarotonga
13.) Pacific/Guadalcanal 34.) Pacific/Saipan
14.) Pacific/Guam	 35.) Pacific/Samoa
15.) Pacific/Honolulu	 36.) Pacific/Tahiti
16.) Pacific/Johnston	 37.) Pacific/Tarawa
17.) Pacific/Kiritimati	 38.) Pacific/Tongatapu
18.) Pacific/Kosrae	 39.) Pacific/Truk
19.) Pacific/Kwajalein	 40.) Pacific/Wake
20.) Pacific/Majuro	 41.) Pacific/Wallis
21.) Pacific/Marquesas	 42.) Pacific/Yap\e[0m

$pick_number
EOJ
)

# Calls the timezone_list function
timezone_list
}
function Pacific_array()
{
# Sets the Pacific array
Pacific[1]='Pacific/Apia'
Pacific[2]='Pacific/Auckland'
Pacific[3]='Pacific/Chatham'
Pacific[4]='Pacific/Chuuk'
Pacific[5]='Pacific/Easter'
Pacific[6]='Pacific/Efate'
Pacific[7]='Pacific/Enderbury'
Pacific[8]='Pacific/Fakaofo'
Pacific[9]='Pacific/Fiji'
Pacific[10]='Pacific/Funafuti'
Pacific[11]='Pacific/Galapagos'
Pacific[12]='Pacific/Gambier'
Pacific[13]='Pacific/Guadalcanal'
Pacific[14]='Pacific/Guam'
Pacific[15]='Pacific/Honolulu'
Pacific[16]='Pacific/Johnston'
Pacific[17]='Pacific/Kiritimati'
Pacific[18]='Pacific/Kosrae'
Pacific[19]='Pacific/Kwajalein'
Pacific[20]='Pacific/Majuro'
Pacific[21]='Pacific/Marquesas'
Pacific[22]='Pacific/Midway'
Pacific[23]='Pacific/Nauru'
Pacific[24]='Pacific/Niue'
Pacific[25]='Pacific/Norfolk'
Pacific[26]='Pacific/Noumea'
Pacific[27]='Pacific/Pago_Pago'
Pacific[28]='Pacific/Palau'
Pacific[29]='Pacific/Pitcairn'
Pacific[30]='Pacific/Pohnpei'
Pacific[31]='Pacific/Ponape'
Pacific[32]='Pacific/Port_Moresby'
Pacific[33]='Pacific/Rarotonga'
Pacific[34]='Pacific/Saipan'
Pacific[35]='Pacific/Samoa'
Pacific[36]='Pacific/Tahiti'
Pacific[37]='Pacific/Tarawa'
Pacific[38]='Pacific/Tongatapu'
Pacific[39]='Pacific/Truk'
Pacific[40]='Pacific/Wake'
Pacific[41]='Pacific/Wallis'
Pacific[42]='Pacific/Yap'

# Searches through the Pacific array until the user's timezone selection is found
for i in "${!Pacific[@]}"
do
if [ $i -eq $REGION ]; then
# The TOWN variable stores the user's numeric selection into the associated timezone's name
	TOWN=${Pacific[$i]}
fi
done

# Calls the Yes_No function
Yes_No
}

function Others_text()
{
RGN=$(cat <<EOK
$main_menu
$pick_region
$ERROR
\e[36m 1 .) Brazil/Acre		38 .) Etc/GMT0	    75 .) Libya
 2 .) Brazil/DeNoronha		39 .) Etc/GMT-0	    76 .) MET
 3 .) Brazil/East		40 .) Etc/GMT-1	    77 .) Mexico/BajaNorte
 4 .) Brazil/West		41 .) Etc/GMT-10    78 .) Mexico/BajaSur
 5 .) Canada/Atlantic		42 .) Etc/GMT-11    79 .) Mexico/General
 6 .) Canada/Central		43 .) Etc/GMT-12    80 .) MST
 7 .) Canada/Eastern		44 .) Etc/GMT-13    81 .) MST7MDT
 8 .) Canada/East-Saskatchewan	45 .) Etc/GMT-14    82 .) Navajo
 9 .) Canada/Mountain		46 .) Etc/GMT-2	    83 .) NZ
10 .) Canada/Newfoundland	47 .) Etc/GMT-3	    84 .) NZ-CHAT
11 .) Canada/Pacific		48 .) Etc/GMT-4	    85 .) Poland
12 .) Canada/Saskatchewan	49 .) Etc/GMT-5	    86 .) Portugal
13 .) Canada/Yukon		50 .) Etc/GMT-6	    87 .) PRC
14 .) CET			51 .) Etc/GMT-7	    88 .) PST8PDT
15 .) Chile/Continental		52 .) Etc/GMT-8	    89 .) ROC
16 .) Chile/EasterIsland	53 .) Etc/GMT-9	    90 .) ROK
17 .) CST6CDT			54 .) Etc/Greenwich 91 .) Singapore
18 .) Cuba			55 .) Etc/UCT	    92 .) Turkey
19 .) EET			56 .) Etc/Universal 93 .) UCT
20 .) Egypt			57 .) Etc/UTC	    94 .) Universal
21 .) Eire			58 .) Etc/Zulu	    95 .) US/Alaska
22 .) EST			59 .) Factory	    96 .) US/Aleutian
23 .) EST5EDT			60 .) GB	    97 .) US/Arizona
24 .) Etc/GMT			61 .) GB-Eire	    98 .) US/Central
25 .) Etc/GMT+0			62 .) GMT	    99 .) US/Eastern
26 .) Etc/GMT+1			63 .) GMT+0	    100.) US/East-Indiana
27 .) Etc/GMT+10		64 .) GMT0	    101.) US/Hawaii
28 .) Etc/GMT+11		65 .) GMT-0	    102.) US/Indiana-Starke
29 .) Etc/GMT+12		66 .) Greenwich	    103.) US/Michigan
30 .) Etc/GMT+2			67 .) Hongkong	    104.) US/Mountain
31 .) Etc/GMT+3			68 .) HST	    105.) US/Pacific
32 .) Etc/GMT+4			69 .) Iceland	    106.) US/Pacific-New
33 .) Etc/GMT+5			70 .) Iran	    107.) US/Samoa
34 .) Etc/GMT+6			71 .) Israel	    108.) UTC
35 .) Etc/GMT+7			72 .) Jamaica	    109.) WET
36 .) Etc/GMT+8			73 .) Japan	    110.) W-SU
37 .) Etc/GMT+9			74 .) Kwajalein	    111.) Zulu\e[0m

$pick_number
EOK
)

# Calls the timezone_list function
timezone_list
}
function Others_array()
{
# Sets the Others array
Others[1]='Brazil/Acre'
Others[2]='Brazil/DeNoronha'
Others[3]='Brazil/East'
Others[4]='Brazil/West'
Others[5]='Canada/Atlantic'
Others[6]='Canada/Central'
Others[7]='Canada/Eastern'
Others[8]='Canada/East-Saskatchewan'
Others[9]='Canada/Mountain'
Others[10]='Canada/Newfoundland'
Others[11]='Canada/Pacific'
Others[12]='Canada/Saskatchewan'
Others[13]='Canada/Yukon'
Others[14]='CET'
Others[15]='Chile/Continental'
Others[16]='Chile/EasterIsland'
Others[17]='CST6CDT'
Others[18]='Cuba'
Others[19]='EET'
Others[20]='Egypt'
Others[21]='Eire'
Others[22]='EST'
Others[23]='EST5EDT'
Others[24]='Etc/GMT'
Others[25]='Etc/GMT+0'
Others[26]='Etc/GMT+1'
Others[27]='Etc/GMT+10'
Others[28]='Etc/GMT+11'
Others[29]='Etc/GMT+12'
Others[30]='Etc/GMT+2'
Others[31]='Etc/GMT+3'
Others[32]='Etc/GMT+4'
Others[33]='Etc/GMT+5'
Others[34]='Etc/GMT+6'
Others[35]='Etc/GMT+7'
Others[36]='Etc/GMT+8'
Others[37]='Etc/GMT+9'
Others[38]='Etc/GMT0'
Others[39]='Etc/GMT-0'
Others[40]='Etc/GMT-1'
Others[41]='Etc/GMT-10'
Others[42]='Etc/GMT-11'
Others[43]='Etc/GMT-12'
Others[44]='Etc/GMT-13'
Others[45]='Etc/GMT-14'
Others[46]='Etc/GMT-2'
Others[47]='Etc/GMT-3'
Others[48]='Etc/GMT-4'
Others[49]='Etc/GMT-5'
Others[50]='Etc/GMT-6'
Others[51]='Etc/GMT-7'
Others[52]='Etc/GMT-8'
Others[53]='Etc/GMT-9'
Others[54]='Etc/Greenwich'
Others[55]='Etc/UCT'
Others[56]='Etc/Universal'
Others[57]='Etc/UTC'
Others[58]='Etc/Zulu'
Others[59]='Factory'
Others[60]='GB'
Others[61]='GB-Eire'
Others[62]='GMT'
Others[63]='GMT+0'
Others[64]='GMT0'
Others[65]='GMT-0'
Others[66]='Greenwich'
Others[67]='Hongkong'
Others[68]='HST'
Others[69]='Iceland'
Others[70]='Iran'
Others[71]='Israel'
Others[72]='Jamaica'
Others[73]='Japan'
Others[74]='Kwajalein'
Others[75]='Libya'
Others[76]='MET'
Others[77]='Mexico/BajaNorte'
Others[78]='Mexico/BajaSur'
Others[79]='Mexico/General'
Others[80]='MST'
Others[81]='MST7MDT'
Others[82]='Navajo'
Others[83]='NZ'
Others[84]='NZ-CHAT'
Others[85]='Poland'
Others[86]='Portugal'
Others[87]='PRC'
Others[88]='PST8PDT'
Others[89]='ROC'
Others[90]='ROK'
Others[91]='Singapore'
Others[92]='Turkey'
Others[93]='UCT'
Others[94]='Universal'
Others[95]='US/Alaska'
Others[96]='US/Aleutian'
Others[97]='US/Arizona'
Others[98]='US/Central'
Others[99]='US/Eastern'
Others[100]='US/East-Indiana'
Others[101]='US/Hawaii'
Others[102]='US/Indiana-Starke'
Others[103]='US/Michigan'
Others[104]='US/Mountain'
Others[105]='US/Pacific'
Others[106]='US/Pacific-New'
Others[107]='US/Samoa'
Others[108]='UTC'
Others[109]='WET'
Others[110]='W-SU'
Others[111]='Zulu'

# Searches through the Others array until the user's timezone selection is found
for i in "${!Others[@]}"
do
if [ $i -eq $REGION ]; then
# The TOWN variable stores the user's numeric selection into the associated timezone's name
	TOWN=${Others[$i]}
fi
done

# Calls the Yes_No function
Yes_No
}

# Checks for errors and prints available timezones
function timezone_list(){
# Checks if there is any errors. It checks by seeing if the ERROR variable is set
if [ -n "$ERROR" ]; then
# If there was an error message, this unsets the ERROR variable so if there is another Error, it will only print the latest one.
	unset ERROR
fi

# prints the list of the country's timezones
echo -e "$RGN" | more

nation_read
}

# Gets the user's input for their selected timezone and checks if it passes certain checks
function nation_read()
{
# Stores the number associated with the timezone the user chooses
read REGION

# Allows the user to go back to the country selection Main Menu
if [ $REGION == $'\e' ]; then
	clear
	country_text
	return 0
fi
# This requires that the user's selection be numeric
if [[ $REGION != *[0-9]* ]] || [[ $REGION = *[!0-9]* ]]; then
	clear
# If the user input is non-numeric, the function will recall the associated country's text function and print this error message
	ERROR="\e[31mPlease type in ONLY the numeric value to the corresponding timezone. Please try again\e[0m"$'\n'
	''$NAME'_text'
	return 0
fi
# this if statement is unique in that it is only used when someone tries to select a number other than 1 when the arctic country is chosen
if [ $COUNTRY -eq 4 ] && [ $REGION -gt $NUM ] ; then
	clear
# If the user's input is not 1, the function will recall the associated country's text function and print this error message
	ERROR="\e[31mPlease select the number 1 or proceed back to the main menu\e[0m"$'\n'
	''$NAME'_text'
	return 0
fi
# This requires the user to choose a number in a specific range unique for each country based on the total number of timezones offered in that country.
if [ $REGION -gt $NUM ]; then
	clear
# If the user's input is greater than the total number of timezones for this country, the function will recall the associated country's text function and print this error message
	ERROR="\e[31mPlease select an integer between 1-$NUM\e[0m"$'\n'
	''$NAME'_text'
	return 0
fi

''$NAME'_array'
}

# Checks whether the correct timezone was chosen.
function Yes_No()
{
echo -e "\e[33mYou have chosen $TOWN as your timezone. Is this correct ? (y/n)\e[0m"
# Gets the user's input to check if the selected timezone is correct
read yesno
# If the user types "n", this function calls the country's text function
if [ "$yesno" = "n" ]; then
	clear
	''$NAME'_text'
# If the user types "y", the timezone the user chose will be written to the user's apache2 php.ini file
elif [ "$yesno" = "y" ]; then
	sed -i "s#;date.timezone =#date.timezone = $TOWN#g" /etc/php5/apache2/php.ini
# If the user types in anything other than "y" or "n", this statement calls the country's text function
elif [ "$yesno" != "y" ] && [ "$yesno" != "n" ]; then
	clear
# This variable is printed in the country's text function if this error is reached
	ERROR="\e[31mYou must select either y or n. Please try again.\e[0m"$'\n'
	''$NAME'_text'
fi
}

# The function that calls all the other functions
function bootScript()
{
	# Starts the Set PHP Timezone Script
		echo
		echo -e "\e[33m=== Set PHP Timezone ? (y/n)\e[0m"
	# Read user's input to start the script
		read yesno
	# If the user types "y", the script calls the country_text function
		if [ "$yesno" = "y" ]; then
			country_text
	# If the user types "n", the script exits
		elif [ "$yesno" = "n" ]; then
			return 0
	# If the user types in anything other than "y" or "n", recall the bootScript function
		elif [ "$yesno" != "y" ] && [ "$yesno" != "n" ]; then
			clear
			bootScript
			return 0
		fi

	# End of script text
		echo
		echo -e "\e[01;37;42mWell Done! You have successfully set your PHP Timezone to $TOWN!\e[0m"
		echo
}

	# This case is used to call the bootScript function
		case "$go" in
			*)
				bootScript ;;
		esac
}

# This Function is used to call all the other corresponding functions
function doAll()
{
	#Calls Function 'baculaInstall'
		echo -e "\e[33m=== Install Bacula ? (y/n)\e[0m"
		read yesno
		if [ "$yesno" = "y" ]; then
				baculaInstall
		fi

	#Calls Function 'databaseCreation'
		echo
		echo -e "\e[33m=== Create the Bacula Database ? (y/n)\e[0m"
		read yesno
		if [ "$yesno" = "y" ]; then
				databaseCreation
		fi

	#Calls Function 'databaseConfiguration'
		echo
		echo -e "\e[33m=== Configure the Bacula Database ? (y/n)\e[0m"
		read yesno
		if [ "$yesno" = "y" ]; then
				databaseConfiguration
		fi

	#Calls Function 'bootBacula'
		echo
		echo -e "\e[33m=== Start Bacula at Boot Time ? (y/n)\e[0m"
		read yesno
		if [ "$yesno" = "y" ]; then
				bootBacula
		fi

	#Calls Function 'emailConfiguration'
		echo
		echo -e "\e[33m=== Configure Bacula Email Notifications ? (y/n)\e[0m"
		read yesno
		if [ "$yesno" = "y" ]; then
				emailConfiguration
		fi

	#Calls Function 'dirConfiguration'
		echo
		echo -e "\e[33m=== Configure the Bacula Director ? (y/n)\e[0m"
		read yesno
		if [ "$yesno" = "y" ]; then
				dirConfiguration
		fi

	#Calls Function 'storageConfiguration'
		echo
		echo -e "\e[33m=== Configure the Bacula Storage Daemon ? (y/n)\e[0m"
		read yesno
		if [ "$yesno" = "y" ]; then
				storageConfiguration
		fi

	#Calls Function 'batInstall'
		echo
		echo -e "\e[33m=== Install BAT ? (y/n)\e[0m"
		read yesno
		if [ "$yesno" = "y" ]; then
				batInstall
		fi

	#Calls Function 'baculaWeb'
		echo
		echo -e "\e[33m=== Install Bacula Web ? (y/n)\e[0m"
		read yesno
		if [ "$yesno" = "y" ]; then
				baculaWeb
		fi

	#Calls Function 'phpTimezone'
				phpTimezone

	#End of Script Congratulations, Farewell and Additional Information
		FARE=$(cat << 'EOD'


            \e[01;37;42mWell done! You have completed your Bacula Installation!\e[0m

             \e[01;37;42mProceed to your Bacula web UI, http://fqdn/bacula-web\e[0m
  \e[30;01mCheckout similar material at midactstech.blogspot.com and github.com/Midacts\e[0m


                            \e[01;37m########################\e[0m
                            \e[01;37m#\e[0m \e[31mI Corinthians 15:1-4\e[0m \e[01;37m#\e[0m
                            \e[01;37m########################\e[0m
EOD
)

		#Calls the End of Script variable
		echo -e "$FARE"
		echo
		echo
		exit 0
}

# Check privileges
[ $(whoami) == "root" ] || die "You need to run this script as root."

# Welcome to the script
clear
echo
echo
echo -e '                 \e[01;37;42mWelcome to Midacts Mystery'\''s Bacula Installer!\e[0m'
echo
echo
case "$go" in
        * )
                        doAll ;;
esac

exit 0
