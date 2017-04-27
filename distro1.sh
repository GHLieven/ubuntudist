#!/bin/bash

#this script requires the file distro2.sh. You may also use the optional files remove.txt and packages.txt
#before using, you should make this script executable (sudo chmod 700 distro1.sh)
sudo apt-get update
sudo apt install --yes debootstrap
mkdir -p work/chroot
#the next line is only necessary if you want to add an installer to your image, comment it out otherwise.
sudo cp remove.txt work/
cd work
#in the next line, change 'zesty' to the name of the release you are building. If you are building for 16.04, use 'xenial' 
#you can also build for another architecture, if you need to build for i386, replace '--arch=amd64' by '--arch=i386' 
#it's a good idea to use the same architecture of the system you're building on
sudo debootstrap --arch=amd64 zesty chroot
sudo cp ../distro2.sh chroot
sudo cp ../packages.txt chroot
sudo mount -o bind /run/ chroot/run
sudo cp /etc/apt/sources.list chroot/etc/apt/sources.list
sudo chroot chroot /bin/bash -c "./distro2.sh"
sudo rm chroot/distro2.sh
sudo rm chroot/packages.txt
#in the next line, add files or folders you want to have in the home-folder of your image to the CONFIG variable.
#this way, you can customize the look and feel of your image. you should separate different files or folders by a space. 
CONFIG='.config'
cd ~ && for i in $CONFIG
do
        sudo cp -rpv --parents $i work/chroot/etc/skel
done
#the next line copies the settings of the Clearlooks theme to your image. you can comment it out if you don't need it. 
sudo cp -r /usr/share/themes/Clearlooks work/chroot/usr/share/themes/
#the next line changes the default slim background. if you're using another login manager, you can comment it out. 
sudo cp /usr/share/backgrounds/warty-final-ubuntu.png work/chroot/usr/share/slim/themes/debian-lines/background.png
#the next line copies your actual keyboard layout to your image, which is probably want you want.
sudo cp /etc/default/keyboard work/chroot/etc/default/
#the next line is a fix for network-manager, if you're using something else like wicd, comment it out.
sudo touch work/chroot/etc/NetworkManager/conf.d/10-globally-managed-devices.conf
sudo apt install --yes xorriso syslinux isolinux squashfs-tools genisoimage
mkdir -p work/image/{casper,isolinux,install}
export kversion=`cd work/chroot/boot && ls -1 vmlinuz-* | tail -1 | sed 's@vmlinuz-@@'`
sudo cp -vp work/chroot/boot/vmlinuz-${kversion} work/image/casper/vmlinuz
sudo cp -vp work/chroot/boot/initrd.img-${kversion} work/image/casper/initrd.gz
sudo cp /usr/lib/ISOLINUX/isolinux.bin work/image/isolinux/
sudo cp /usr/lib/syslinux/modules/bios/menu.c32 work/image/isolinux/
cp /usr/lib/ISOLINUX/isolinux.bin image/isolinux/
cp /usr/lib/syslinux/modules/bios/ldlinux.c32 image/isolinux/
cp /usr/lib/syslinux/modules/bios/libcom32.c32 image/isolinux/
cp /usr/lib/syslinux/modules/bios/libutil.c32 image/isolinux/
cd work/image/isolinux
#the lines below generate a boot menu for your image.
#in the line starting with 'echo "menu title', you can change the text 'Ubuntu 17.04 JWM' to your liking.
echo "ui menu.c32" > isolinux.cfg
echo "prompt 0" >> isolinux.cfg
echo "menu title Ubuntu 17.04 JWM" >> isolinux.cfg
echo "timeout 300" >> isolinux.cfg
echo "LABEL live" >> isolinux.cfg
#in the next line, change 'Start Ubuntu met JWM' to your liking.
echo "  menu label ^Start Ubuntu met JWM" >> isolinux.cfg
echo "  menu default" >> isolinux.cfg
echo "  linux /casper/vmlinuz" >> isolinux.cfg
echo "  append file=/cdrom/preseed/ubuntu.seed boot=casper initrd=/casper/initrd.gz quiet splash --" >> isolinux.cfg
cd ../..
#the following 6 lines are only necessary if you added an installer to your image. Comment them out otherwise.
sudo chroot chroot dpkg-query -W --showformat='${Package} ${Version}\n' | sudo tee image/casper/filesystem.manifest
sudo cp -v image/casper/filesystem.manifest image/casper/filesystem.manifest-desktop
for i in $(cat remove.txt)
do
        sudo sed -i "/${i}/d" image/casper/filesystem.manifest-desktop
done
#the next line will generate a lot of terminal output. You don't have to worry about that.
#you can add the options '-b 1048576' and '-comp xz' at the end of next line. That will reduce the size
#of the resulting image although it will take a bit longer to finish.
sudo mksquashfs chroot image/casper/filesystem.squashfs
printf $(sudo du -sx --block-size=1 chroot | cut -f1) > image/casper/filesystem.size
#you should change the next line to match your release.
echo "#define DISKNAME  Ubuntu 17.04 'Zesty Zapus' - Release amd64" > image/README.diskdefines
echo "#define TYPE  binary" >> ${CD}/README.diskdefines
echo "#define TYPEbinary  1" >> ${CD}/README.diskdefines
echo "#define ARCH  amd64" >> ${CD}/README.diskdefines
echo "#define ARCHamd64  1" >> ${CD}/README.diskdefines
echo "#define DISKNUM  1" >> ${CD}/README.diskdefines
echo "#define DISKNUM1  1" >> ${CD}/README.diskdefines
echo "#define TOTALNUM  0" >> ${CD}/README.diskdefines
echo "#define TOTALNUM0  1" >> ${CD}/README.diskdefines
touch image/ubuntu
mkdir image/.disk
touch image/.disk/base_installable
echo "full_cd/single" > image/.disk/cd_type
#you should change the next two lines to match your release. 
echo "Ubuntu 17.04 'Zesty Zapus' - Release amd64 (20170413)" > image/.disk/info
echo "https://wiki.ubuntu.com/ZestyZapus/ReleaseNotes" > image/.disk/release_notes_url
sudo /bin/bash -c "cd image && find . -type f -print0 | xargs -0 md5sum | grep -v "\./md5sum.txt" > md5sum.txt"
#in the next 5 lines, you may change the text 'Ubuntu JWM' and the name of the resulting iso in the last line.
xorriso -as genisoimage -r -J -joliet-long -l \
-isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin -partition_offset 16 \
-A "Ubuntu JWM"  -b isolinux/isolinux.bin -c \
isolinux/boot.cat -no-emul-boot -boot-load-size 4 \
-boot-info-table -o ubuntu-jwm.iso image
