#!/bin/sh
# lol weed
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

WF_OS=$(uname -s)

wf_host="$(hostname)"
wf_uptime="$(uptime | awk -F, '{sub(".*up ",x,$1);print $1}' | sed -e 's/^[ \t]*//')"

if [ $wf_os = "Debian" ]; then
	wf_packages="$(dpkg -l | grep -c '^ii') (dpkg)"
elif [ $wf_os = "Ubuntu" ]; then
	wf_packages="$(dpkg -l | grep -c '^ii') (dpkg)"
elif [ $wf_os = "OpenBSD" ]; then
	wf_packages="$(pkg_info -A | wc -l | sed -e 's/^[ \t]*//') (pkg_info)"
elif [ $wf_os = "VoidLinux" ]; then
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
	if [ -z $WF_PACKAGES ]; then
		wf_packages="Unknown"
	else
		wf_packages=$WF_PACKAGES
	fi
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
		if [ -z $WF_TERM ]; then
			if [ $WF_OS = "Linux" ]; then
				wf_term="$(ls -l /proc/$$/fd/0 | awk '{ print $11 }')"
			else
				wf_term="Unknown"
			fi
		else
			wf_term=$WF_TERM
		fi
		break
	fi
done

wf_wm=""

# Support for all (most) EWMH-compliant window managers
which_xprop="$(which xprop)"
if [ -x $which_xprop ]; then
    rootwin="$(xprop -root -notype _NET_SUPPORTING_WM_CHECK | awk '{print $5}')"
    ewmhwinprops="$(xprop -id "$rootwin" -notype -len 100 -f _NET_WM_NAME 8t)"
    wf_wm="$(echo "$ewmhwinprops" | grep '_NET_WM_NAME' |\
        sed -E 's/_NET_WM_NAME\s=\s"(.*)"/\1/')"
else
        process_list=$(ps -A -o comm)
        for i in $process_list; do
	        case $i in
        		xfce4-session) wf_wm="xfce4";break;;
		        xfwm4) wf_wm="xfwm4";break;;
	        	i3) wf_wm="i3wm";break;;
        		*cwm) wf_wm="cwm";break;;
	        	fvwm) wf_wm="fvwm";break;;
        		fvwm95) wf_wm="fvwm95";break;;
		        araiwm) wf_wm="araiwm";break;;
	        	dwm) wf_wm="dwm";break;;
        		herbstluftwm) wf_wm="herbstluftwm";break;;
		        awesome) wf_wm="awesome";break;;
                        custard) wf_wm"custard";break;;
        	esac
        done
fi

if [ -z $wf_wm ]; then
	if [ $wf_warnings = y ]; then
		printf "Warning: Couldn't detect WM.\n" >&2
		printf "         Set the WF_WM variable to manually specify it.\n" >&2
		printf "         (If you add support for this WM and send a PR, that'd be great)\n" >&2
		printf "         Suppress this warning with -w.\n\n" >&2
	fi
	if [ -z $WF_WM ]; then
		wf_wm="Unknown"
	else
		wf_wm=$WF_WM
	fi
	break
fi

sh_green="$(tput sgr0)$(tput setaf 2)"
sh_reset="$(tput sgr0)"
sh_bold="$(tput sgr0)$(tput bold)"

echo $sh_green '     \      ,  ' $sh_bold " $USER@$wf_host"
echo $sh_green '     l\   ,/   ' $sh_bold OS:$sh_reset $wf_os $wf_osver
echo $sh_green '._   `|] /j    ' $sh_bold UPTIME:$sh_reset $wf_uptime
echo $sh_green ' `\\\\, \|f7 _,/'"'" $sh_bold PACK:$sh_reset $wf_packages
echo $sh_green '   "`=,k/,x-'"'"'  ' $sh_bold TERM:$sh_reset $wf_term
echo $sh_green '    ,z/fY-=-   ' $sh_bold SHELL:$sh_reset $wf_shell
echo $sh_green "  -'"'" .y \     ' $sh_bold WM/DE:$sh_reset $wf_wm
echo $sh_green "      '   \itz " $sh_bold MEM:$sh_reset $wf_usedmem / $wf_totalmem
echo ""
