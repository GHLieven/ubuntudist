#!/bin/bash

#before using, you should make this script executable (sudo chmod 700 distro2.sh)
mount none -t proc /proc
mount none -t sysfs /sys
mount none -t devpts /dev/pts
export HOME=/root
export LC_ALL=C
#you can uncomment line 8 if you want to add a custom repository (PPA) to your image.
#Substitute "12345678" with the PPA's OpenPGP ID.
#sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 12345678
apt-get update
apt-get install --yes dbus
dbus-uuidgen > /var/lib/dbus/machine-id
dpkg-divert --local --rename --add /sbin/initctl
ln -s /bin/true /sbin/initctl
apt-get --yes upgrade
apt-get install --yes ubuntu-standard casper lupin-casper
apt-get install --yes discover laptop-detect os-prober
apt-get install --yes linux-generic
#the next line is only necessary if you want to add an installer to your image. Comment it out otherwise.
apt-get install --yes ubiquity-frontend-gtk
#the following line is used to install the packages of your choice to the image.
#add the packages you want to the file packages.txt, one per line.
cat packages.txt | sudo xargs apt-get install --yes
#the following lines are added in case you want to customize your image."
#to do so, open another terminal window. the current terminal should remain open.
#you can then copy certain files from your build system to your image, or you can chroot to your image with the command
#sudo chroot work/chroot. Remember to exit chroot when you're done (just type 'exit')
#if you're done customizing, enter 'exit', select the orginal terminal window and press any key
echo
echo "You can now customize your image."
echo "Press any key when you're done."
echo
read N
#the following 4 lines are only necessary if you added an installer. Comment them out otherwise.
rm /usr/share/ubiquity/apt-setup
touch /usr/share/ubiquity/apt-setup
echo "#do nothing" > /usr/share/ubiquity/apt-setup
chmod 755 /usr/share/ubiquity/apt-setup
apt-get autoremove --purge --yes
rm /var/lib/dbus/machine-id
apt-get clean
rm -rf /tmp/*
umount -lf /proc
umount -lf /sys
umount -lf /dev/pts
