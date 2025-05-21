#!/bin/sh

#set -x
getHwInfo()
{
	grep $1 /bak/hardinfo.bin | awk -F '>'  '{print $2}' | awk -F '<' '{print $1}'
}

getHwCfg()
{
	grep $1 /bak/hwcfg.ini | awk '{printf $3}'
}

getHwdefCfg()
{
        grep $1 /bak/defalut.config | awk '{printf $3}'
}

mountBakRW()
{
		echo "mounting /bak read & write ..."
		mount -o rw,remount /bak
}

mountBakRO()
{
		echo "mounting /bak readonly ..."
		mount -o ro,remount /bak
}

rmBakFile()
{
	if [ -f $1 ]; then
		echo "mounting /bak read & write ..."
		mount -o rw,remount /bak
	
		echo "rm $1"
		rm -f $1
	
		echo "mounting /bak readonly ..."
		mount -o ro,remount /bak
	fi
}
getHwInfoPins()
{
	echo $(getHwInfo $1) | awk -F '_'  '{print $1}'
}
mkdir /var/run

#check if stop app auto run
read -t 1 -p "Press 'q' in 1 seconds to exit: " q
if [ $? -eq 0 -a "$q" = "q" ]; then exit; fi

ulimit -s 256
export LD_LIBRARY_PATH=/tmp
export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/root/bin:/bak/ap
kill -9 `ps | grep "telnet" | grep -v grep | awk '{printf $1}'`
devmem 0x80001648 32 0
devmem 0x80001828 32 1
devmem 0x800015a4 32 0
devmem 0x80001810 32 0x808280
mount -t tmpfs tmpfs /opt
#drivers
insmod /bak/drv/gio.ko.lzma
insmod /bak/drv/exfat.ko.lzma
mdev -s
ifconfig eth0 up
#run custom init for board OEM
/bak/custom_init.sh
#pwm
/bak/custom_pre_init.sh

#防止升级失败，把驱动删除 ENG Translate -> To prevent upgrade failure, delete the driver.
support_4g=$(getHwCfg support_4g)
def_support_4g=$(getHwInfo Support4G)
rm_useless_ko=0
rmUselessKo()
{
	if [ "$rm_useless_ko" == "1" ]; then
	       return 
       	fi	       
	rm_useless_ko=1
	sleep 1
	mountBakRW
	#wifi&4g init 
	idProduct=`cat /sys/bus/usb/devices/1-1/idProduct`
	idVendor=`cat /sys/bus/usb/devices/1-1/idVendor`
	WIFIDRVS="rtl8188f 9083h 8821cu ssv6x5x rdawfmac 4gdev ZT9101xV20 rtl8731 aic8800d80 ssv6355 txw901"
	DRVPATH=/bak/drv  # for /dev  only loop0 loop1 ,here reuse loop1

	if [ "$idVendor" = "2310" -a "$idProduct" = "9086" ]; then
		WIFIDRV=9083h
	elif [ "$idVendor" = "0bda" -a "$idProduct" = "f179" ]; then
		WIFIDRV=rtl8188f
		touch /tmp/8188fu_new
	elif [ "$idVendor" = "0bda" -a "$idProduct" = "c811" ]; then
		WIFIDRV=8821cu
	elif [ "$idVendor" = "8065" -a "$idProduct" = "6000" ]; then #nan fang
		WIFIDRV=ssv6x5x
		touch /tmp/ssv6x5x
	elif [ "$idVendor" = "8065" -a "$idProduct" = "6011" ]; then #nan fang ssv6355
		WIFIDRV=ssv6355
		touch /tmp/ssv6355
		cp /bak/ble_app /tmp/ble_app
	elif [ "$idVendor" = "1e04" -a "$idProduct" = "8888" ]; then #ziguang
		WIFIDRV=rdawfmac
		touch /tmp/rdawfmac
	elif [ "$idVendor" = "350b" -a "$idProduct" = "9101" ]; then #zhaotong
		WIFIDRV=ZT9101xV20
		touch /tmp/ZT9101xV20
	elif [ "$idVendor" = "0bda" -a "$idProduct" = "f72b" ]; then #rel8731
		WIFIDRV=rtl8731
		touch /tmp/rtl8731
	elif [ "$idVendor" = "a69c" -a "$idProduct" = "8d80" ]; then #aic8800d80
		WIFIDRV=aic8800d80                                                               
    	touch /tmp/aic8800d80
	elif [ "$idVendor" = "a69c" -a "$idProduct" = "88dc" ]; then #aic8800d80
		WIFIDRV=aic8800d80                                                               
		touch /tmp/aic8800d80
	elif [ "$idVendor" = "350b" -a "$idProduct" = "9106" ]; then #zhaotong
		WIFIDRV=ZT9101xV20
		touch /tmp/ZT9101xV20
	elif [ "$idVendor" = "a012" -a "$idProduct" = "8000" ]; then #txw901
		WIFIDRV=txw901
		touch /tmp/txw901
	elif [ "$idVendor" = "007a" -a "$idProduct" = "8890" ]; then #atbm6x3x
		WIFIDRV=atbm6x3x
		touch /tmp/atbm6x3x
	else
		if [ "$def_support_4g" = "1" -o "$support_4g" = "1" ]; then
			WIFIDRV=4gdev
		fi
	fi

	#删除多余的驱动 ENG Translate -> Delete redundant drivers
	if [ -n "$WIFIDRV" ]; then
		for w in $WIFIDRVS; do
			if [ $w != $WIFIDRV ]; then rm -f $DRVPATH/$w.ko*; fi
		done
	fi

	#这里删除多余的驱动配置 ENG Translate -> Delete redundant driver configurations here
	if [ -n "$WIFIDRV" ]; then
		if [ ! -f $DRVPATH/rdawfmac.ko.lzma ]; then
			 rm -f $DRVPATH/rda*;
		fi 
			
		if [ ! -f $DRVPATH/ssv6x5x.ko.lzma ]; then
			 rm -f $DRVPATH/ssv6x5x*; 
		fi

		if [ ! -f $DRVPATH/ssv6355.ko.lzma ]; then
			 rm -f $DRVPATH/ssv6355*; 
			 rm /bak/ble_app
		fi
	
		if [ ! -f $DRVPATH/ZT9101xV20.ko.lzma ]; then
			 rm -f $DRVPATH/ZT9101*;
		fi
	
		if [ "$WIFIDRV" != "aic8800d80" ]; then
			rm -rf $DRVPATH/aic8800*/                                                                                                                                      
		fi

		if [ "$WIFIDRV" != "txw901" ]; then
			rm -rf $DRVPATH/hgics*
		fi

		if [ "$WIFIDRV" != "atbm6x3x" ]; then
			rm -rf $DRVPATH/atbm6x3x*
		fi
	fi
	mountBakRO
}


#check from /tmp/sensor, if 1080, modify uboot args
#/bak/check_mem.sh

BOARD_ID=$(getHwInfo BoardType)

#upgrade flash firmware
if [ -f /home/firmware.bin ]; then
	#mount app partition read & write before upgrade
	mountBakRW
	sdc_tool -d $BOARD_ID -c /home/model.ini /home/firmware.bin
	rm -f /home/firmware.bin
	#mount app partition readonly after upgrade
	mountBakRO
fi

TIMES=11
MD5=md5sum

# check if file mv from /home to /bak
if [ -f /home/eye.conf -o -f /home/hardinfo.bin -o -f /home/hwcfg.ini -o -f /home/ptz.cfg -o -f /home/image.ini -o -f /home/VOICE.tgz ]; then
	if [ -d /bak ]; then		
		echo "mounting /bak read & write ..."
		mountBakRW
	if [ -s "/home/eye.conf" ]; then
		homeMd5=`$MD5 /home/eye.conf | awk '{printf $1}'`
		useMd5=0
		retry=0
		while [ $retry -lt $TIMES -a "$homeMd5" != "$useMd5" ]
		do
			cp /home/eye.conf /bak/eye.conf
			sleep 1
			sync
			useMd5=`$MD5 /bak/eye.conf | awk '{printf $1}'` 
			retry=$(($retry+1))
		done
		rm -f /home/eye.conf	
	fi
	
	if [ -s "/home/hardinfo.bin" ]; then
		homeMd5=`$MD5 /home/hardinfo.bin | awk '{printf $1}'`
		useMd5=0
		retry=0
		while [ $retry -lt $TIMES -a "$homeMd5" != "$useMd5" ]
		do
			cp /home/hardinfo.bin /bak/hardinfo.bin
			sleep 1
			sync
			useMd5=`$MD5 /bak/hardinfo.bin | awk '{printf $1}'` 
			retry=$(($retry+1))
		done
		rm -f /home/hardinfo.bin
	fi
	
	if [ -s "/home/hwcfg.ini" ]; then
		homeMd5=`$MD5 /home/hwcfg.ini | awk '{printf $1}'`
		useMd5=0
		retry=0
		while [ $retry -lt $TIMES -a "$homeMd5" != "$useMd5" ]
		do
			cp /home/hwcfg.ini /bak/hwcfg.ini
			sleep 1
			sync
			useMd5=`$MD5 /bak/hwcfg.ini | awk '{printf $1}'` 
			retry=$(($retry+1))
		done
		rm -f /home/hwcfg.ini
	fi
	
	if [ -s "/home/ptz.cfg" ]; then
		homeMd5=`$MD5 /home/ptz.cfg | awk '{printf $1}'`
		useMd5=0
		retry=0
		while [ $retry -lt $TIMES -a "$homeMd5" != "$useMd5" ]
		do
			cp /home/ptz.cfg /bak/ptz.cfg
			sleep 1
			sync
			useMd5=`$MD5 /bak/ptz.cfg | awk '{printf $1}'` 
			retry=$(($retry+1))
		done
		rm -f /home/ptz.cfg
	fi
	
	if [ -s "/home/image.ini" ]; then	
		homeMd5=`$MD5 /home/image.ini | awk '{printf $1}'`
		useMd5=0
		retry=0
		while [ $retry -lt $TIMES -a "$homeMd5" != "$useMd5" ]
		do
			cp /home/image.ini /bak/image.ini
			sleep 1
			sync
			useMd5=`$MD5 /bak/image.ini | awk '{printf $1}'` 
			retry=$(($retry+1))
		done
		rm -f /home/image.ini
	fi
	
	if [ -s "/home/VOICE.tgz" ]; then	
		homeMd5=`$MD5 /home/VOICE.tgz | awk '{printf $1}'`
		useMd5=0
		retry=0
		while [ $retry -lt $TIMES -a "$homeMd5" != "$useMd5" ]
		do
			cp /home/VOICE.tgz /bak/VOICE.tgz
			sleep 1
			sync
			useMd5=`$MD5 /bak/VOICE.tgz | awk '{printf $1}'` 
			retry=$(($retry+1))
		done
		rm -f /home/VOICE.tgz
	fi

		echo "mounting /bak readonly ..."
		mountBakRO
	fi
fi

if [ -f /home/SD_CHECK -o -f /home/SD_NOMOUNT ]; then
	echo "SD Need Check"
	if [ ! -s /bak/hwcfg.ini -o ! -s /bak/ptz.cfg ]; then
		#Run facoty_tool.sh for burn id and mv hwcfg, hardinfo, ptz.cfg image.ini
		mountBakRW
		cp -f /bak/factory_tool.sh /tmp/factory_tool.sh
		/tmp/factory_tool.sh
		mountBakRO
	fi
else
	#mount SD card
	if [ -b /dev/mmcblk0p1 ]; then
		mount -t vfat /dev/mmcblk0p1 /mnt || mount -t exfat /dev/mmcblk0p1  /mnt
	elif [ -b /dev/mmcblk0 ]; then
		mount -t vfat /dev/mmcblk0 /mnt || mount -t exfat /dev/mmcblk0 /mnt
	fi

	#Upgrade firmware from TF card
	if [ -f /mnt/firmware.bin ]; then
		#mount app partition read & write before upgrade
		rmUselessKo
		mountBakRW

		sdc_tool -d $BOARD_ID -c /home/model.ini /mnt/firmware.bin

		#check upgrade from OTA or factory test
		if [ -f /mnt/OTA ]; then
			rm /mnt/firmware.bin -f
			rm /mnt/OTA -f
		else
			touch /opt/upgrading
		fi
	
		#mount app partition readonly after upgrade
		mountBakRO
	fi

	#Run debug_cmd.sh
	if [ -f /mnt/debug_cmd.sh ]; then
		mountBakRW

		echo "find debug cmd file, wait for cmd running..."
		/mnt/debug_cmd.sh

		mountBakRO
	fi

	if [ -f /mnt/FSRW -o -f /mnt/rmid ]; then
		#Run facoty_tool.sh for burn id and mv hwcfg, hardinfo, ptz.cfg image.ini
		rmUselessKo
		mountBakRW
		cp -f /bak/factory_tool.sh /tmp/factory_tool.sh
		/tmp/factory_tool.sh
		mountBakRO
	elif [ ! -s /bak/hwcfg.ini -o ! -s /bak/ptz.cfg ]; then
		#Run facoty_tool.sh for burn id and mv hwcfg, hardinfo, ptz.cfg image.ini
		rmUselessKo
		mountBakRW
		cp -f /bak/factory_tool.sh /tmp/factory_tool.sh
		/tmp/factory_tool.sh
		mountBakRO
	fi
fi

#init isp
/bak/sensor.sh
#set image param env
if [ -f /tmp/dip_extend.ini ];then
	export DIP_INTL_INI_PATH=/tmp/dip_extend.ini
	export DIP_INTL_INI_TUNING=1
fi

if [ -f /mnt/FSRW -o ! -f /bak/eye.conf ]; then
	#run tees for debug info
	tees -s -v -b 20 -e ps -e 'ifconfig; route -n' -e 'wpa_cli status' -e 'mount' -e 'uptime' -e 'df' -e 'netstat -napt' -e free -a /tmp/closelicamera.log -o /mnt/mmc01/0/ipc.log &
fi

cp /bak/auto_test.sh /tmp/auto_test.sh
/tmp/auto_test.sh &

if [ ! -f /bak/eye.conf ]; then
     EXTRA_FLAGS='test_max_pos=1'
else
     EXTRA_FLAGS='test_max_pos=0'
fi
#init ptz
ptz_mcu=$(getHwCfg ptz_mcu)
ptz_def_mcu=$(getHwInfo PtzMcu)
has_ptz=$(getHwInfo SupportPtz)
ptz_no_check=$(getHwCfg ptz_no_selfck)
ptz_def_no_check=1

if [ "$has_ptz" = "1" ]; then
    NO_SLFCK=0
	if [ -f /bak/eye.conf ]; then
		if [ -f /home/silent_reboot ]; then 
			NO_SLFCK=1; rm /home/silent_reboot;
		elif [ "$ptz_no_check" = "1" ]; then
			if [ -f /home/devParam.dat ];then
				NO_SLFCK=1;
			fi
		elif [ "$ptz_no_check" = "0" ]; then
				NO_SLFCK=0;
		elif [ "$ptz_def_no_check" = "1" ]; then
			if [ -f /home/devParam.dat ];then
				NO_SLFCK=1;
			fi
		elif [ "$ptz_def_no_check" = "0" ]; then
				NO_SLFCK=0;
		fi
	fi
	
	if [ ! -f /bak/eye.conf ]; then
		PSP_DATA=/tmp/psp.dat
	else
		PSP_DATA=/home/psp.dat
	fi
	
	if [ -f /home/ptz.cfg ]; then
		PTZ_CFG=/home/ptz.cfg 
	else
		PTZ_CFG=/bak/ptz.cfg 
  	fi
	
	if [ "$ptz_mcu" = "1" ]; then
		insmod /bak/drv/hc-dsa.ko.lzma cfg_file=$PTZ_CFG  psp_file=$PSP_DATA no_selfck=$NO_SLFCK $EXTRA_FLAGS
	elif [ "$ptz_mcu" = "2" ]; then
		insmod /bak/drv/hc-2823.ko.lzma cfg_file=$PTZ_CFG psp_file=$PSP_DATA no_selfck=$NO_SLFCK $EXTRA_FLAGS
    elif [ "$ptz_mcu" = "0" ]; then
		insmod /bak/drv/hcptz.ko.lzma cfg_file=$PTZ_CFG psp_file=$PSP_DATA no_selfck=$NO_SLFCK $EXTRA_FLAGS	
	else
		if [ "$ptz_def_mcu" = "1" ]; then
			insmod /bak/drv/hc-dsa.ko.lzma cfg_file=$PTZ_CFG  psp_file=$PSP_DATA no_selfck=$NO_SLFCK $EXTRA_FLAGS
		elif [ "$ptz_def_mcu" = "2" ];then
			insmod /bak/drv/hc-2823.ko.lzma cfg_file=$PTZ_CFG psp_file=$PSP_DATA no_selfck=$NO_SLFCK $EXTRA_FLAGS
		else
			insmod /bak/drv/hcptz.ko.lzma cfg_file=$PTZ_CFG psp_file=$PSP_DATA no_selfck=$NO_SLFCK $EXTRA_FLAGS
		fi
	fi
fi

tar -xvf /bak/VOICE.tgz -C /tmp

cp /bak/ca-bundle-add-closeli.crt /tmp
cp /bak/cloud.ini /tmp
#echo "CST-8" > /etc/TZ

rmUselessKo
#insmod wifi/4g
if [ "$WIFIDRV" = "ssv6x5x" ]; then
	insmod $DRVPATH/$WIFIDRV.ko.lzma stacfgpath=$DRVPATH/ssv6x5x-wifi.cfg
elif [ "$WIFIDRV" = "ssv6355" ]; then
	insmod $DRVPATH/$WIFIDRV.ko.lzma stacfgpath=$DRVPATH/ssv6355-wifi.cfg
elif [ "$WIFIDRV" = "ZT9101xV20" ]; then
	insmod $DRVPATH/$WIFIDRV.ko.lzma cfg=$DRVPATH/ZT9101wifi.cfg
elif [ "$WIFIDRV" = "4gdev" -o $support_4g -gt 0 ]; then
	insmod $DRVPATH/4G/usbserial.ko.lzma
	insmod $DRVPATH/4G/usb_wwan.ko.lzma
	insmod $DRVPATH/4G/option.ko.lzma
	if [ "$support_4g" != "1" ]; then
		sed -ie '/support_4g/d' /bak/hwcfg.ini
		echo  "support_4g = 1" >> /bak/hwcfg.ini
	fi
elif [ "$WIFIDRV" = "aic8800d80" ]; then
	if [ "$idVendor" = "a69c" -a "$idProduct" = "88dc" ]; then
		insmod $DRVPATH/aic8800_single/aic_load_fw.ko.lzma testmode=0 aic_fw_path=$DRVPATH/aic8800_single
		insmod $DRVPATH/aic8800_single/aic8800_fdrv.ko.lzma
		insmod $DRVPATH/aic8800_single/aic_btusb.ko.lzma
		tar -zxf /bak/drv/aic8800_single/aic_ble.tgz -C /tmp
	else
		insmod $DRVPATH/aic8800_dual/aic_load_fw.ko.lzma testmode=0 aic_fw_path=$DRVPATH/aic8800_dual
		insmod $DRVPATH/aic8800_dual/aic8800_fdrv.ko.lzma
		insmod $DRVPATH/aic8800_dual/aic_btusb.ko.lzma
		tar -zxf /bak/drv/aic8800_dual/aic_ble.tgz -C /tmp
	fi
elif [ "$WIFIDRV" = "txw901" ];then
	insmod $DRVPATH/hgics_txw901.ko.lzma fw_file=$DRVPATH/hgics_txw901_fw.bin
	cp $DRVPATH/hgics_ble_app /tmp/ble_app
elif [ "$WIFIDRV" = "atbm6x3x" ];then
	insmod $DRVPATH/atbm6x3x.ko.lzma wifi_bt_comb=1
	cp $DRVPATH/atbm6x3x_ble_app /tmp/ble_app
else
	insmod $DRVPATH/$WIFIDRV.ko.lzma
fi


mdev -s
#patch by wangxing 20240410
#3D215 去掉phy,使用GPIO40 不可以操作GPIO40的寄存器 ENG Translate -> For the 3D215, remove the PHY, and use GPIO40. It is not possible to operate the registers of GPIO40.
pin1=$(getHwInfoPins IrCut2B)
pin2=$(getHwInfoPins IrCut1B)
if [ "$pin1" != "40" -a "$pin2" != "40" ];then
        #phy 芯片 detect  ENG Translate -> phy chip detect
        echo "-----phy detect--------"
        devmem 0x800014A4 32 2
        devmem 0x800015E8 32 0
        echo 40 > /sys/class/gpio/export
        echo in > /sys/class/gpio/gpio40/direction
        phy=`cat /sys/class/gpio/gpio40/value`
        if [ "$phy" == "1" ] ;then
                touch /tmp/phy
        fi
        devmem  0x800014A4 32 0
        devmem  0x800015E8 32 1
        #end phy 芯片 detect ENG Translate -> end phy chip detect
fi

#sleep 1
ifconfig lo 127.0.0.1
ifconfig wlan0 up
ifconfig ra0 up

if [ -f /tmp/phy ]; then
	ifconfig eth0 down

	#todo
	MAC=`ifconfig | awk '/wlan0/{print $NF}'`   
		echo "$MAC"                                                                                    
	MAC1=`ifconfig | awk '/ra0/{print $NF}'`
	echo "$MAC1"

	if [ -n "$MAC" ]; then
		ifconfig eth0 hw ether $MAC
	fi

	if [ -n "$MAC1" ]; then 
		ifconfig eth0 hw ether $MAC1
	fi

	ifconfig eth0 up
fi

rsyscall.hc1703 &

#sdk的网络配置 ENG Translate -> SDK network configuration
/sbin/sysctl -w net.core.rmem_default=524288
/sbin/sysctl -w net.core.wmem_default=524288
/sbin/sysctl -w net.core.rmem_max=624288
/sbin/sysctl -w net.core.wmem_max=724288

echo 1450 > /sys/class/net/wlan0/mtu
echo 1450 > /sys/class/net/ra0/mtu
echo 1450 > /sys/class/net/eth0/mtu

# no id or filesysreadwrite in sd card, remount rw for factory
if [ ! -f /bak/eye.conf -o -f /mnt/FSRW ]; then
	mountBakRW
fi

umount /mnt

cp /bak/ca-bundle-add-closeli.crt /tmp/ca-bundle-add-closeli.crt
mount /bak/p2pcam.sqfs /p2pcam -t squashfs -o loop

#Clear script cache
echo 3 > /proc/sys/vm/drop_caches;free
cd /tmp
(
export CLOSELICAMERA_LOGMAXLINE=1000
/p2pcam/p2pcam 
echo -e '[data]\ntime = '`date +%s` > /home/reboot.time
umount /p2pcam
if [ -f /tmp/firmware.bin ]; then
	echo "mounting /bak read & write ..."
	mount -o rw,remount /bak
    sdc_tool -d $BOARD_ID /tmp/firmware.bin
    sync
else
    echo "Crashed ? dump log..."
    killall -10 tees
    sleep 3
    #Wait for the log to be dumped. Let watchdog reboot system
fi
reboot -f
)&


