if [ -z "$DISPLAY" ]; then
    echo "WM Options: (y) Default (i) i3 (a) Awesome (k) KDE (m) MATE (x) XFCE (l) LXDE"
    read -p "Start X? [y/n] " -n 1 choice
    declare -A wms
    declare -A wmspkg
    declare -A wmspost
    wms[y]=twm
    wms[Y]=twm
    wms[i]=i3
    wms[a]=awesome
    wms[k]=startkde
    wms[m]=mate-session
    wms[x]=startxfce4
    wms[l]=startlxde
    wmpkgs[y]=twm
    wmspkg[Y]=twm
    wmspkg[i]=i3
    wmspkg[a]=awesome
    wmspkg[k]=plasma-desktop
    wmspkg[m]=mate
    wmspkg[x]=xfce4-meta
    wmspkg[l]=lxde-meta
    wmspost[y]="feh --bg-max wallpaper.png"
    wmspost[Y]="feh --bg-max wallpaper.png"
    wmspost[i]="feh --bg-max wallpaper.png"
    wmspost[a]="feh --bg-max wallpaper.png"
    wmspost[k]=""
    wmspost[m]=""
    wmspost[x]="feh --bg-max wallpaper.png"
    wmspost[l]="feh --bg-max wallpaper.png"
    if [ -n "${wms[$choice] + 1}" ]; then
        if [ ! -f /usr/bin/${wms[$choice]} ]; then
            echo
            echo ${wms[$choice]} is not installed. Install it by running:
            echo $ sudo emerge ${wmspkg[$choice]}
            read -p "Install now? [y/n] " -n 1 installyn
            if [[ "$installyn" == "y" || "$installyn" == "Y" ]]; then
                sudo emerge -v ${wmspkg[$choice]}
                export DISPLAY=:0
                X&
                sleep 1
                ${wms[$choice]}&
                ${wmspost[$choice]}&
            fi
        else
            export DISPLAY=:0
            X&
            sleep 1
            ${wms[$choice]}&
            ${wmspost[$choice]}&
        fi
    fi
fi
