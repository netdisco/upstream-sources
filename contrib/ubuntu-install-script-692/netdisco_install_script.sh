#!/bin/bash

#### Inform User Section#####
echo -e "\e[1m"
echo -e "\e[47m"
echo -e "\e[31m"

echo "This script is designed to run on a clean version of Ubuntu 18.04 server and works well with VMs."
echo ""
echo "It should be used in a lab setting to help you become familiar with Netdisco."
echo ""
echo "DO NOT USE IT ON A PRODUCTION server!!!"
echo ""
echo "Use at your own risk!"
echo ""
echo "No warranties are provided and are hereby denied."
echo ""
echo "Review the ReamMe.txt file that will be created in this directory during installation for further instructions."
echo ""
echo ""
echo "Do you agree? [Y/n]:"

read agree

echo -e "\e[21m"
echo -e "\e[39m"
echo -e "\e[49m"


if [ "$agree" != "Y"  ]
then

  if [ "$agree" != "y"  ]
  then
    echo "Exiting Script"
    exit
  fi

fi


######Collect Information From User###########

echo -e "\e[96m"
echo "Before you begin you will need the following information:"
echo ""
echo "1.) You will need the RO community string of your router and or switch"
echo "2.) You will need the domain suffix of your server (this is optional)"
echo ""
echo "You will be asked to provide a user name and two passwords"
echo "The username can be anything you want and the passwords do not need to match each other"
echo ""
echo "Run this program as root. If you are not root, exit script"
echo ""
echo "MAKE SURE YOU READ THE ReadMe.txt file"
echo "It will be created in the directory where you run the script"
echo "It give you information on logging in, testing and starting discovery"
echo ""
echo "Are you ready to proceed? [Y/n]"
read ready

if [ "$ready" != "Y"  ]
then

  if [ "$ready" != "y"  ]
  then
    echo "Exiting Script"
    exit
  fi

fi

echo ""
echo ""

echo "This step will create the username and password that you will use to log into netdisco web page"
echo "The information will be stored in the file netdiscoweblogin.txt"
echo ""
echo ""
echo "What do you want the username to be?"
read myusername
echo ""
echo ""
echo "What do you want the password to be?"
read mypassword

echo "Username: $myusername Password: $mypassword"  > netdiscoweblogin.txt


echo ""
echo ""
echo "This Part of the install program will create the netdisco user in the Postgres DB"
echo "This next step will ask you for the password you want to use for the netdisco Postgres DB user"
echo "The password will be written twice in the file postgrespassword.txt and stored in this directory"
echo "You can review this file and save the password for future reference"
echo ""
echo "Enter password for netdisco user in Postgres DB"

read postpass
echo "$postpass" > postgrespassword.txt
echo "$postpass" >> postgrespassword.txt

echo ""
echo ""
echo "Enter SNMP RO string for your devices"
read snmpstring

echo ""
echo ""
echo "The domain suffix makes it easier to go to navigate to netdisco from your computername"
echo "However, if you plan on using the ip address of your server instead of the name, it is not required "
echo "In the next step enter your domain suffix or anything.com if you plan you using your server ip address"
echo ""
echo "enter your domain"
read domain




echo ""
echo "First we are going to install some dependencies"
echo ""
echo "This part of the process can take a long time. Around 10 min."
echo ""
echo "However, it can take much longer depending on your server, connection speed and other variables"
echo ""


sleep 5
echo -e "\e[39m"



apt-get update
echo "Y" | apt-get install libdbd-pg-perl libsnmp-perl libssl-dev libio-socket-ssl-perl curl postgresql build-essential expect

echo -e "\e[96m"
echo "Now we are going to create the netdisco user. The user will not have a password. You will have to use sudo su netdisco if you ever want to login as user"
echo -e "\e[39m"



useradd -m -p x -s /bin/bash netdisco
echo ""
echo ""




echo -e "\e[96m"
echo "These next steps will be run as the postgres user"
echo "It will prepare the Postgres environment for Netdisco"
echo ""
echo ""
echo -e "\e[39m"




su -c "cat postgrespassword.txt | createuser -DRSP netdisco" postgres
su -c "createdb -O netdisco netdisco" postgres


echo -e "\e[96m"
echo ""
echo ""
echo "The next steps will be run as the netdisco linux user"
echo ""

echo -e "\e[39m"


su -c "curl -L https://cpanmin.us/ | perl - --notest --local-lib ~/perl5 App::Netdisco" netdisco
su -c "mkdir ~/bin" netdisco
su -c "ln -s ~/perl5/bin/{localenv,netdisco-*} ~/bin/" netdisco
su -c "mkdir ~/environments" netdisco
su -c "cp ~/perl5/lib/perl5/auto/share/dist/App-Netdisco/environments/deployment.yml ~/environments" netdisco
su -c "chmod 600 ~/environments/deployment.yml" netdisco

su -c "more ~/environments/deployment.yml |  sed 's/user: \x27changeme\x27/user: \x27netdisco\x27/g' > ~/environments/temp.yml" netdisco

su -c "more ~/environments/temp.yml | sed 's/pass: \x27changeme\x27/pass: \x27$postpass\x27/g' > ~/environments/temp2.yml" netdisco

su -c "more ~/environments/temp2.yml |  sed 's/community: \x27public\x27/community: \x27$snmpstring\x27/g' > ~/environments/temp3.yml" netdisco

su -c "more ~/environments/temp3.yml |  sed 's/#domain_suffix/domain_suffix/g' |  sed 's/example.com/$domain/g' > ~/environments/deployment.yml" netdisco

su -c "rm ~/environments/temp.yml" netdisco
su -c "rm ~/environments/temp2.yml" netdisco
su -c "rm ~/environments/temp3.yml" netdisco



echo -e "\e[96m"
echo -e "\e[7m"

echo ""
echo ""
echo "The Next steps will initialize netdisco."
echo ""
echo "MAKE SURE YOU READ THE ReadMe.txt file"
echo ""
echo "It will be created in the directory where you run the script"
echo "It will give you information on logging in, testing and starting discovery"
sleep 5

echo -e "\e[27m"
echo -e "\e[39m"


#####create readme file#######################
echo "Recommended:
1.) Ping a few routers that you are planning to discover.
2.) Use snmpwalk to test snmp and ensure acls are not blocking access to devices.
 apt-get install snmpd
Syntax is as follows: snmpwalk -v 2c -c community ipaddressOfDevice oid
Example: snmpwalk -v 2c -c public 192.51.100.200 .1.3.6.1.2.1.1.5
Will return something like the following:
SNMPv2-MIB::sysName.0 = STRING: hostname

3.) Run the following test as the netdisco user. Switch from root via su netdisco
Syntax: su netdisco
a.) Front end test and back end test
Syntax: ~/bin/netdisco-web status
Syntax: ~/bin/netdisco-backend status
b.) Exit back to root via the exit command

4.) Go to the netdisco website. 
The format is http://yourServerIp:5000 example: http://198.51.100.100:5000
In the box that says: “Discover hostname or IP”, enter the IP of your seed router.
Your passwords written to netdiscoweblogin.txt in this directory.

5.) After you are comfortable that Netdisco is working and you’ve noted passwords etc.
Consider  removing the following files for security reasons.
/home/netdisco/e3.ex,  netdiscoweblogin.txt, postgrespassword.txt 
Example:
rm /home/netdisco/e3.ex
rm netdiscoweblogin.txt 
rm postgrespassword.txt " > ReadMe.txt


######create expect script and execute########

echo "#!/usr/bin/expect -f" > /home/netdisco/e3.ex
echo "set timeout -1" >> /home/netdisco/e3.ex
echo "spawn /home/netdisco/bin/netdisco-deploy" >> /home/netdisco/e3.ex
echo 'expect "is all of the above in place" { send "y\r" }' >> /home/netdisco/e3.ex
echo 'expect "Would you like to deploy the database schema" { send "y\r" }' >> /home/netdisco/e3.ex
echo 'expect "Username:"' >> /home/netdisco/e3.ex
echo "send -- \"$myusername\r\"" >> /home/netdisco/e3.ex
echo 'expect "Password:"' >> /home/netdisco/e3.ex
echo "send -- \"$mypassword\r\"" >> /home/netdisco/e3.ex
echo 'expect "Download and update vendor MAC prefixes" { send "y\r" }' >> /home/netdisco/e3.ex
echo 'expect "Download and update MIB files" { send "y\r" }' >> /home/netdisco/e3.ex
echo 'expect eof' >> /home/netdisco/e3.ex
echo 'spawn ~/bin/netdisco-web start' >> /home/netdisco/e3.ex
echo 'expect "watching" { send "\r\r" }' >> /home/netdisco/e3.ex
echo 'spawn ~/bin/netdisco-backend start' >> /home/netdisco/e3.ex
echo 'expect "watching" { send "\r\r" }' >> /home/netdisco/e3.ex


echo 'spawn ~/bin/netdisco-backend status' >> /home/netdisco/e3.ex
#echo 'expect "running" { send "\r\r" }' >> /home/netdisco/e3.ex
echo 'interact' >> /home/netdisco/e3.ex



chmod a=xr /home/netdisco/e3.ex

sudo -u netdisco -H sh -c "~/e3.ex"
# end of file

