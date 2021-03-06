#!/bin/bash

# command info
if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "-help" ]; then
 echo "small config script to switch WebGUI RideTheLightning on or off"
 echo "bonus.rtl.sh [on|off]"
 exit 1
fi

# check and load raspiblitz config
# to know which network is running
source /mnt/hdd/raspiblitz.conf
if [ ${#network} -eq 0 ]; then
 echo "FAIL - missing /mnt/hdd/raspiblitz.conf"
 exit 1
fi

# add default value to raspi config if needed
if [ ${#rtlWebinterface} -eq 0 ]; then
  echo "rtlWebinterface=off" >> /mnt/hdd/raspiblitz.conf
fi

# stop services
echo "making sure services are not running"
sudo systemctl stop RTL 2>/dev/null

# switch on
if [ "$1" = "1" ] || [ "$1" = "on" ]; then
  echo "*** INSTALL RTL ***"

  # setting value in raspi blitz config
  sudo sed -i "s/^rtlWebinterface=.*/rtlWebinterface=on/g" /mnt/hdd/raspiblitz.conf

  isInstalled=$(sudo ls /etc/systemd/system/RTL.service 2>/dev/null | grep -c 'RTL.service')
  if [ ${isInstalled} -eq 0 ]; then

    # disable RPC listen
    # to prevent tls cer auth error
    echo "*** Modify lnd.conf ***"
    sudo sed -i "s/^rpclisten=0.0.0.0:10009/#rpclisten=0.0.0.0:10009/g" /mnt/hdd/lnd/lnd.conf
    echo ""

    # install latest nodejs
    echo "*** Install NodeJS ***"
    curl -sL https://deb.nodesource.com/setup_11.x | sudo -E bash -
    sudo apt-get install -y nodejs
    echo ""

    # close source code
    echo "*** Get the RTL Source Code ***"
    git clone https://github.com/ShahanaFarooqui/RTL.git
    cd RTL
    npm install
    cd ..
    echo ""

    # open firewall
    echo "*** Updating Firewall ***"
    sudo ufw allow 3000
    sudo ufw --force enable
    echo ""

    # install service
    echo "*** Install RTL systemd for ${network} on ${chain} ***"
    sudo cp /home/admin/assets/RTL.service /etc/systemd/system/RTL.service
    sudo sed -i "s|chain/bitcoin/mainnet|chain/${network}/${chain}net|" /etc/systemd/system/RTL.service
    sudo systemctl enable RTL
    echo "OK - RTL is now ACTIVE"
  else 
    echo "RTL already installed."
  fi

  echo "needs reboot to activate new setting"
  exit 0
fi

# switch off
if [ "$1" = "0" ] || [ "$1" = "off" ]; then

  # setting value in raspi blitz config
  sudo sed -i "s/^rtlWebinterface=.*/rtlWebinterface=off/g" /mnt/hdd/raspiblitz.conf

  isInstalled=$(sudo ls /etc/systemd/system/RTL.service 2>/dev/null | grep -c 'RTL.service')
  if [ ${isInstalled} -eq 1 ]; then
    echo "*** REMOVING RTL ***"
    sudo systemctl stop RTL
    sudo systemctl disable RTL
    sudo rm /etc/systemd/system/RTL.service
    sudo rm -r /home/admin/RTL
    echo "OK RTL removed."
  else 
    echo "RTL is not installed."
  fi

  echo "needs reboot to activate new setting"
  exit 0
fi

echo "FAIL - Unknown Paramter $1"
echo "may needs reboot to run normal again"
exit 1