#!/bin/sh

wf_warnings=y

while getopts ":w" opt; do
	case "$opt" in
		w) wf_warnings=n;;
		\?) echo "invalid paramter: -$OPTARG" >&2
			exit;;
	esac
done

if type lsb_release >/dev/null 2>&1; then
	wf_os=$(lsb_release -si)
	wf_osver=$(lsb_release -sr)
elif [ -f /etc/lsb-release ]; then
	. /etc/lsb-release
	wf_os=$DISTRIB_ID
	wf_osver=$DISTRIB_RELEASE
elif [ -f /etc/debian_version ]; then
	wf_os=Debian
	wf_osver=$(cat /etc/debian_version)
else
	wf_os=$(uname -s)
	wf_osver=$(uname -r)
fi

wf_host="$(hostname)"
wf_uptime="$(uptime | awk -F, '{sub(".*up ",x,$1);print $1}' | sed -e 's/^[ \t]*//')"

if [ $wf_os = "Debian" ]; then
	wf_packages="$(dpkg -l | grep -c '^ii') (dpkg)"
elif [ $wf_os = "OpenBSD" ]; then
	wf_packages="$(pkg_info -A | wc -l | sed -e 's/^[ \t]*//') (pkg_info)"
elif [ $wf_os = "Void" ]; then
	wf_packages="$(xbps-query -l | wc -l) (xbps)"
elif [ $wf_os = "ManjaroLinux" ]; then
	wf_packages="$(pacman -Q | wc -l) (pacman)"
else
	if [ $wf_warnings = y ]; then
		printf "Warning: Couldn't detect the number of installed packages.\n" >&2
		printf "         Set the WF_PACKAGES variable to manually specify it.\n" >&2
		printf "         (If you add support for this OS/distro and send a PR, that'd be great)\n" >&2
		printf "         Suppress this warning with -w.\n\n" >&2
	fi
	wf_packages=$WF_PACKAGES
	break
fi

wf_shell="$(basename $SHELL)"

wf_totalmem="$(free -m | awk 'NR==2 { print $2 }')MiB"
wf_usedmem="$(free -m | awk 'NR==2 { print $3 }')MiB"

cur_pid=$$
while true; do
	cur_pid=$(ps -h -o ppid -p $cur_pid 2>/dev/null)
	case $(ps -h -o comm -p $cur_pid 2>/dev/null) in
		gnome-terminal) wf_term="GNOME Terminal";break;;
		xfce4-terminal) wf_term="xfce4 Terminal";break;;
		xterm) wf_term="xterm";break;;
		rxvt) wf_term="rxvt";break;;
		st) wf_term="st";break;;
		konsole) wf_term="Konsole";break;;
		urxvt) wf_term="urxvt";break;;
	esac
	if [ $cur_pid = 1 ]; then
		if [ $wf_warnings = y ]; then
			printf "Warning: Couldn't detect terminal emulator.\n" >&2
			printf "         Set the WF_TERM variable to manually specify it.\n" >&2
			printf "         (If you add support for this terminal and send a PR, that'd be great)\n" >&2
			printf "         Suppress this warning with -w.\n\n" >&2
		fi
		wf_term=$WF_TERM
		break
	fi
done

wf_wm=""
process_list=$(ps -A -o comm)
for i in $process_list; do
	case $i in
		xfce4-session) wf_wm="xfce4";break;;
		xfwm4) wf_wm="xfwm4";break;;
		i3wm) wf_wm="i3wm";break;;
		fvwm) wf_wm="fvwm";break;;
		fvwm95) wf_wm="fvwm95";break;;
		araiwm) wf_wm="araiwm";break;;
	esac
done
if [ -z $wf_wm ]; then
	if [ $wf_warnings = y ]; then
		printf "Warning: Couldn't detect WM.\n" >&2
		printf "         Set the WF_WM variable to manually specify it.\n" >&2
		printf "         (If you add support for this WM and send a PR, that'd be great)\n" >&2
		printf "         Suppress this warning with -w.\n\n" >&2
	fi
	wf_wm=$WF_WM
	break
fi

bc="$(tput bold)"
rc="$(tput sgr0)"

echo ${rc} '     \      ,  ' ${bc} " $USER@$wf_host"
echo ${rc} '     l\   ,/   ' ${bc} OS:       $wf_os $wf_osver
echo ${rc} '._   `|] /j    ' ${bc} UPTIME:   $wf_uptime
echo ${rc} ' `\\\\, \|f7 _,/'"'" ${bc} PACK:     $wf_packages
echo ${rc} '   "`=,k/,x-'"'"'  ' ${bc} TERM:     $wf_term
echo ${rc} '    ,z/fY-=-   ' ${bc} SHELL:    $wf_shell
echo ${rc} "  -'"'" .y \     ' ${bc} WM/DE:    $wf_wm
echo ${rc} "      '   \itz " ${bc} MEM:       $wf_usedmem / $wf_totalmem
