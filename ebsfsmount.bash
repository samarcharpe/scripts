#!/bin/bash

echo "Checking if the volume is attached on the sdb or xvdb"
volumeid=`/sbin/ebsnvme-id -v /dev/nvme1n1| awk -F : {'print $2'}`
if [ -z "$volumeid" ]
then
      echo "$volumeid is not attached"
	  exit
else
      echo "$volumeid is  attached"
fi

echo "checking if device or patition has filesystem"
partwithfscount=`/usr/sbin/blkid /dev/nvme1n1* |/usr/bin/egrep 'ext2|ext3|ext4|xfs' | /usr/bin/awk -F: {'print $1'} |/usr/bin/wc -l`
    if [ $partwithfscount -eq 0 ];
    then
    echo "no valid filesystem found. exiting...."
	                	echo "checking if device is cofigured with LVM "
                devwithlvmcount=`/usr/sbin/blkid /dev/nvme1n1* |/usr/bin/egrep 'LVM' | /usr/bin/awk -F: {'print $1'} |/usr/bi/wc -l`
                    if [ $devwithlvmcount -eq 0 ];
                    then
                    echo "no valid LVM config found. exiting...."
                	exit
                    else
                    echo "LVM config  exists"
                    fi
                echo "activating LVM volume group"
                for devlvm in `/usr/sbin/blkid /dev/nvme1n1* |/usr/bin/egrep 'LVM' | /usr/bin/awk -F: {'print $1'} `
                do 
                   echo "activating VG"
                   vgname=`/usr/sbin/pvs --noheadings $devlvm | awk {'print $2'}`
                   /usr/sbin/vgimport  $vgname
                   /usr/sbin/vgchange -a y  $vgname
                   lvswithfscount=`/usr/bin/lsblk /dev/mapper/$vgname-* -f  |/usr/bin/egrep 'ext2|ext3|ext4|xfs' | /usr/bin/awk  {'print $1'} |/usr/bin/wc -l`
                    if [ $lvswithfscount -eq 0 ];
                    then
                    echo "no valid filesystem found. exiting...."
                	exit
                    else
                    echo "filesystem exists"
                    fi
                   echo "mounting device or partition"
                   for lvdevname in `/usr/bin/lsblk /dev/mapper/$vgname-* -f  |/usr/bin/egrep 'ext2|ext3|ext4|xfs' | /usr/bin/awk {'print $1'}`
                      do 
                      echo "creating mountpoint"
					  echo "/$volumeid-$lvdevname"
                   
                      /usr/bin/mkdir "/$volumeid-$lvdevname"
                          if [ $? -ne 0 ];
                          then
                          echo "cannot create mountpoint exiting...."
                   	     exit
                          else
                          echo "mount point created "
                          fi
                      echo "mounting filesystem"
                       /usr/bin/mount $lvdevname /$volumeid-$lvdevname
                   	    if [ $? -ne 0 ];
                          then
                          echo "cannot mount fs..exiting...."
                   	     exit
                          else
                          echo "fs mounted  on mountpoint  /\$volumeid-\$lvdevname"
                          fi
                     done
                done
	else
    echo "filesystem exists"
    fi
echo "mounting device or partition"
for fsdevname in `/usr/sbin/blkid /dev/nvme1n1* |/usr/bin/egrep 'ext2|ext3|ext4|xfs' | /usr/bin/awk -F: {'print $1'} `
do 
   echo "creating mountpoint"
   
      /usr/bin/mkdir /$volumeid-$fsdevname
          if [ $? -ne 0 ];
          then
          echo "cannot create mountpoint exiting...."
   	     exit
          else
          echo "mount point created "
          fi
   echo "mounting filesystem"
       /usr/sbin/mount $fsdevname /$volumeid-$fsdevname
   	    if [ $? -ne 0 ];
          then
          echo "cannot mount fs..exiting...."
   	     exit
          else
          echo "fs mounted  on mountpoint  /\$volumeid-\$fsdevname"
          fi
done







