#!/bin/bash

Help(){
    echo -e "Bash script that automatically and regularly writes to a log file SysMonitor.log with timestamped detailed information about significant changes to\n
    1) The Current users logged IN
    2) Current Processes
    3) Top 5 CPU Utilizing processes
    4) Devices Plugged in
    5) Disk Usage
    6) Network Interfaces and their state"
    echo
    echo "Usage: ./`basename "$0"` [Option 1[2[3...]]]"
    echo
    echo "   -h         Shows this help page"
    echo "   -d         Runs the script in DEBUG mode"
}
#Help function shows available options

DEBUGFUNC(){
    if who > /dev/null 2>&1; then
        echo "OK..."
    else
        echo "Error in usercurrentlyloggedin function"
    fi
    if ps > /dev/null 2>&1; then
        echo "OK..."
    else
        echo "Error in currrentprocesses function"
    fi
    if top -bn 1 > /dev/null 2>&1; then
        echo "OK..."
    else 
        echo "Error in top5processes function"
    fi
    if lsusb > /dev/null 2>&1; then
        echo "OK..."
    else
        echo "Error in devicepluggedin function"
    fi
    if [du -h /home/`whoami`] > /dev/null 2>&1; then
        echo "Error in diskusage function"
    else
        echo "OK..."
    fi
    if [nmcli device status] > /dev/null 2>&1; then
        echo "Error in networkinter function"
    else
        echo "OK..."
        echo "All checks performed..."
    fi
}

while getopts ":h:d" option; do
    case $option in
        h) Help       #calls help function
        exit;;
        d) DEBUGFUNC
        exit;;
        \?) echo "Error: Invalid option"              #error on invalid options
        exit;;
    esac
done

SCRIPT_LOG=./SysMonitor.log
touch $SCRIPT_LOG                      #creates a file SysMonitor.log

test -d "./tmp" || mkdir ./tmp         #create a tmp directory if it does not exists

SCRIPT_STARTS_HERE(){                  #script start indication function
 timeAndDate=`date`
 script_name=`basename "$0"`
 script_name="${script_name%.*}"
 echo "[$timeAndDate] [DEBUG]  > $script_name $FUNCNAME" >> $SCRIPT_LOG
}

SCRIPT_EXITS_HERE(){
 script_name=`basename "$0"`
 script_name="${script_name%.*}"
 echo "[$timeAndDate] [DEBUG]  < $script_name $FUNCNAME" >> $SCRIPT_LOG
}

userscurrentlyloggedin(){                                            #shows the current users logged in
    touch ./tmp/uold; touch ./tmp/unew
    uold=./tmp/uold; unew=./tmp/unew; timeAndDate=`date`
    mv -f $unew $uold
    who | cut -d' ' -f1 | sort | uniq > $unew
    cmp --silent $unew $uold || echo -e "[$timeAndDate] [DEBUG] Scanning for Users Currently Logged In... \n`diff <(sort $unew) <(sort $uold) | tail -n +2 | sed 's/^/                                         /'`" >> $SCRIPT_LOG
}

currentprocesses(){                                                  #shows the current running processes
    touch ./tmp/pold; touch ./tmp/pnew
    pold=./tmp/pold; pnew=./tmp/pnew; timeAndDate=`date`
    mv -f $pnew $pold
    ps -Ao user,uid,pid,tty --sort=-pcpu | head -n 7 > $pnew
    cmp --silent $pnew $pold || echo -e "[$timeAndDate] [DEBUG] Showing current processes... \n`diff <(sort $pnew) <(sort $pold) | tail -n +2 | sed 's/^/                                         /'`" >> $SCRIPT_LOG
} 

top5processes(){                                                     #shows top 5 CPU utilizing processes
    timeAndDate=`date`
    echo -e "[$timeAndDate] [DEBUG] Scanning Top 5 CPU Utilizing processes... \n`top -bn 1 | grep "^ " | awk '{ printf("%-8s  %-8s  %-8s\n", $9, $10, $12); }' | head -n 6 | sed 's/^/                                          /'`" >> $SCRIPT_LOG
} 

devicesplugedin(){                                                   #lists the connected device
    touch ./tmp/dold; touch ./tmp/dnew
    dold=./tmp/dold; dnew=./tmp/dnew; timeAndDate=`date`
    mv -f $dnew $dold
    lsusb > $dnew
    cmp --silent $dnew $dold || echo -e "[$timeAndDate] [DEBUG] Scanning for PluggedIn devices... \n`diff <(sort $dnew) <(sort $dold) | tail -n +2 | sed 's/^/                                         /'`" >> $SCRIPT_LOG
}

diskusage(){                                                         #indicates the disk usage by user
    touch ./tmp/duold; touch ./tmp/dunew
    duold=./tmp/duold; dunew=./tmp/dunew; timeAndDate=`date`
    mv -f $dunew $duold
    du -h /home/`whoami` | tail -n 1 > $dunew
    cmp --silent $dunew $duold || echo -e "[$timeAndDate] [DEBUG] Disk Usage by `whoami`.... \n`diff <(sort $dunew) <(sort $duold) | tail -n +2 | sed 's/^/                                         /'`" >> $SCRIPT_LOG
}

networkinter(){                                                      #shows intwork interfaces and their status
    touch ./tmp/nold; touch ./tmp/nnew
    nold=./tmp/nold; nnew=./tmp/nnew; timeAndDate=`date`
    mv -f $nnew $nold
    nmcli device status > $nnew
    cmp --silent $nnew $nold || echo -e "[$timeAndDate] [DEBUG] Scanning for Network Interfaces.... \n`diff <(sort $nnew) <(sort $nold) | tail -n +2 | sed 's/^/                                         /'`" >> $SCRIPT_LOG
}

mainpro(){                              #driver function
    userscurrentlyloggedin
    currentprocesses
    top5processes
    devicesplugedin
    diskusage
    networkinter
}

control_c(){                    #cleanup function
    echo
    echo "Cleaning up..."
    SCRIPT_EXITS_HERE
    rm -rf ./tmp                #removes the tmp files
    exit
}

trap control_c SIGINT           #execute cleanup function when keyboard interupt occurs

if [ $UID == 0 ]; then           #checking if the current user is root
    echo "Do not run this script with root previlages"
    echo
    echo "Exiting script..."
else                             #if not execute the script
    source ./SysMonitor.conf
    SCRIPT_STARTS_HERE
    while true; do
        mainpro
        sleep $timetosleep
    done
fi