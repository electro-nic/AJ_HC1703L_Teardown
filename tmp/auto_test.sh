#!/bin/sh
#set -x
#default
test_hours=0
test_ircut=0
test_wl=0
test_spk=0
test_ptz=0
test_infra_red=0
test_dualsensor=0

cgi_cmd()
{
    httpclt get 'http://127.0.0.1:8001/'$1
}

# Following variable are set in auto_test.cfg
#如果sd卡和home目录下无配置文件,循环读取 ENG Translated -> If there is no configuration file on the SD card or in the home directory, read in a loop
while true
do
	#判断老化是否已经结束,如果老化完成就直接退出,蓝灯常亮 ENG Translated -> Check whether the burn-in test has finished. If it has complete, exit immediately and keep the blue light on.
	if [ -f /home/START_FLAG -a -f /home/STOP_FLAG ]; then
		cgi_cmd 'buleled?mode=on'
		exit
	fi

	if [ -f /mnt/mmc01/0/auto_test.cfg ]; then
		cp -f /mnt/mmc01/0/auto_test.cfg /home/auto_test.cfg
		touch /home/START_FLAG
		break
	fi

	if [ -f /mnt/auto_test.cfg ]; then
		cp -f /mnt/auto_test.cfg /home/auto_test.cfg
		touch /home/START_FLAG
		break
	fi
	
	if [ -f /home/auto_test.cfg ]; then
		if [ -f /home/START_FLAG ];then
			break
		fi
	fi
	sleep 1
done

getTestCfg()
{
    grep $1 /home/auto_test.cfg | awk '{printf $3}'
}

test_hours=$(getTestCfg test_hours)
test_ircut=$(getTestCfg test_ircut)
test_wl=$(getTestCfg test_wl)
test_spk=$(getTestCfg test_spk)
test_ptz=$(getTestCfg test_ptz)
test_infra_red=$(getTestCfg test_infra_red)
test_dualsensor=$(getTestCfg test_dualsensor)

PTZ_TEST=ptz_test
if [ $test_hours -eq 0 ]; then
    exit
fi

MAXT=$(($test_hours*3600))
#MAXT=$(($test_hours*75))
T=0
FIRST_STATUS=0
LEDSTATUS=0
MARK_IRCUT=0
MARK_WHITELIGHT=0

sleep 30
while [ $T -lt $MAXT ]
do 
   #Ptz
   if [ $test_ptz -gt 0 -a $(($T % $test_ptz)) -eq 0 ]; then
		$PTZ_TEST r &
   fi
   
   #test_infra_red
    if [ $test_ircut -gt 0 ]; then
        if [ $(($T % $test_ircut)) -eq 0 -o $FIRST_STATUS -eq 0 ]; then
			if [ $MARK_IRCUT -eq 0 ]; then
				cgi_cmd 'irctrl?mode=day' 
				cgi_cmd 'ircut_only?mode=day'
				MARK_IRCUT=1
			else
				cgi_cmd 'irctrl?mode=night'
				cgi_cmd 'ircut_only?mode=night'
				MARK_IRCUT=0
			fi
        fi
    fi

    #White light
    if [ $test_wl -gt 0 ]; then
        if [ $(($T % $test_wl)) -eq 0 -o $FIRST_STATUS -eq 0 ]; then
			if [ $MARK_WHITELIGHT -eq 0 ]; then
				cgi_cmd 'whitelight?mode=on'
				MARK_WHITELIGHT=1
				else
				cgi_cmd 'whitelight?mode=off'
				MARK_WHITELIGHT=0
			fi
        fi
    fi

    #Speaker
    if [ $test_spk -gt 0 ]; then
        if [ $(($T % $test_spk)) -eq 0 -o $FIRST_STATUS -eq 0 ]; then
		cgi_cmd 'playaudio?file=/tmp/VOICE/alarm.wav' &
        fi
    fi
    
	FIRST_STATUS=1
	cgi_cmd 'buleled?mode=off'
    if [ $LEDSTATUS -gt 0 ]; then
		LEDSTATUS=0
		cgi_cmd 'redled?mode=on'
		cgi_cmd 'buleled?mode=off'
	else
		LEDSTATUS=1
		cgi_cmd 'redled?mode=off'
		cgi_cmd 'buleled?mode=on'
	fi
	
	#testdualsensor
	#echo $test_dualsensor
	if [ $test_dualsensor -gt 0 ]; then
		if [ $(($T % $test_dualsensor)) -eq 0 ]; then
			if [ $(($T % (2*$test_dualsensor))) -eq 0 ]; then
				cgi_cmd 'testdualsensor?mode=in'
			else
				cgi_cmd 'testdualsensor?mode=out'
			fi
		fi
	fi
	
	#如果停止老化了，这里立刻退出,重新启动脚本 ENG Translated -> If the burn-in test has stopped, exit immediately here and restart the script.
	if [ ! -f /home/START_FLAG ]; then
		cgi_cmd 'buleled?mode=off'
		cgi_cmd 'redled?mode=off'
		rm /home/auto_test.cfg
		/tmp/auto_test.sh &
		exit
	fi
    sleep 1

    T=$(($T+1))
done

cgi_cmd 'ircut?mode=day'
cgi_cmd 'whitelight?mode=off'
cgi_cmd 'redinfra?mode=off'  
cgi_cmd 'redled?mode=off'
cgi_cmd 'buleled?mode=on'
touch /home/STOP_FLAG

