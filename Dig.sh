#!/bin/bash

scriptVersion="0.7.2"

# The URL of the script project is:
# https://github.com/MohsenHNSJ/TunlDigr

# The URL of the script is:
# https://raw.githubusercontent.com/MohsenHNSJ/TunlDigr/main/Dig.sh

# If the script executes incorrectly, go to:
# https://github.com/MohsenHNSJ/TunlDigr/issues


# Generates a random variable and echos it back.
# <<<Options
#   username: generate and return a random short ( 6 - 10 ) username
#   password: generate and return a random long ( 18 - 22 ) password
generateRandom() {
    # We read the argument supplied to the function to determine which type of random variable to generate and echo back.
    case "$1" in
	    username)
            choose() { echo ${1:RANDOM%${#1}:1} $RANDOM; }
	            local randomVariable="$({ choose 'abcdefghijklmnopqrstuvwxyz'
	            for i in $( seq 1 $(( 6 + RANDOM % 4 )) )
	            do
	            choose 'abcdefghijklmnopqrstuvwxyz'
	            done
	            } | sort -R | awk '{printf "%s",$1}')"
			;;
        password)
        	# We avoid adding symbols inside the password as it sometimes caused problems, therefore the password lenght is high.
        	choose() { echo ${1:RANDOM%${#1}:1} $RANDOM; }
		        local randomVariable="$({ choose '123456789'
		        choose 'abcdefghijklmnopqrstuvwxyz'
		        choose 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
		        for i in $( seq 1 $(( 18 + RANDOM % 4 )) )
			    do
				choose '123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
			    done
		        } | sort -R | awk '{printf "%s",$1}')"
            ;;
	    esac
    echo $randomVariable
    }

# Asks the user to select a tunneling method by entering a numeric value from 1 to 3.
# Can be skipped by -tm and specifing a method in the argument.
# Checks input for validity and if it's a valid, it will convert it to a string and save it in (tunnelingMethod) variable.
# Current available tunnels: (1) Hysteria 2, (2) Reality, (3) ShadowSocks
askTunnelingMethod() {
	echo "========================================================================="
	echo "|             Select the desired tunneling method to set up             |"
	echo "|                   Enter only numbers between 1 - 3                    |"
	echo "========================================================================="
	echo "1 - Hysteria 2 (Sing-Box)"
	echo "2 - Reality (XTLS VLESS)"
	echo "3 - Shadowsocks-libev (Obsolete)"
    # We ask the user to select the desired tunneling method.
	# We limit the input character count to 1 by using (-n) argument.
	read -n 1 -p "Select tunneling method: " tunnelingMethod
	# We validate user input and show an error if it's invalid, then loop the process until the value is valid.
	until [[ $tunnelingMethod == +([1-3]) ]]; do
		echo
		read -n 1 -p "Invalid input, please only input a number from 1 - 3: " tunnelingMethod
	    done
    # We convert the input value from user, to a string for better code readability.
    case $tunnelingMethod in
	    1)
	        tunnelingMethod="hysteria2"
	    ;;
	    2)
	        tunnelingMethod="reality"
	    ;;
	    3)
	        tunnelingMethod="shadowsocks"
	    ;;
        esac
    echo
    }

# Installs the required packages for specified tunneling method.
# Can be disabled by -dpakup
installPackages() {
	echo "========================================================================="
	echo "|       Updating repositories and installing the required packages      |"
	echo "|              (This may take a few minutes, Please wait...)            |"
	echo "========================================================================="
	# We update 'apt' repository.
	# We install/update the packages we use during the process to ensure optimal performance.
	# This installation must run without confirmation (-y)
	sudo apt update
    # We define the tunnel specific package
    case $tunnelingMethod in
        hysteria2)
            local tunnelSpecificPackage=tar
            ;;
        reality)
	        local tunnelSpecificPackage=unzip
            ;;
        shadowsocks)
            local tunnelSpecificPackage=snapd
            ;;
        esac
    # We install the general + tunnel specific packages
    sudo apt -y install wget openssl gawk sshpass ufw coreutils curl adduser sed grep util-linux qrencode haveged $tunnelSpecificPackage
    }

# Shows a startup message and version of the script.
# can be disabled by -dstartmsg
showStartupMessage() {
	echo "========================================================================="
	echo "|                    TunlDigr by @MohsenHNSJ (Github)                   |"
	echo "========================================================================="
	echo "Check out the github page, contribute and suggest ideas/bugs/improvments."
	echo
	echo "=========================="
	echo "| Script version $scriptVersion   |"
	echo "=========================="
    }

# Optimizes the server settings (sysctl.conf, limits.conf) to better handle connections.
# Can be disabled by -dservopti
optimizeServerSettings() {
	echo "========================================================================="
	echo "|                       Optimizing server settings                      |"
	echo "========================================================================="
	# We optimise 'sysctl.conf' file for better performance.
	sudo echo "net.ipv4.tcp_keepalive_time = 90" >> /etc/sysctl.conf
	sudo echo "net.ipv4.ip_local_port_range = 1024 65535" >> /etc/sysctl.conf
	sudo echo "net.ipv4.tcp_fastopen = 3" >> /etc/sysctl.conf
	sudo echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
	sudo echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
	sudo echo "fs.file-max = 65535000" >> /etc/sysctl.conf
    # ShadowSocks specific optimizations
    if [ $tunnelingMethod == shadowsocks ]; then
	    sudo echo "net.core.netdev_max_backlog = 250000" >> /etc/sysctl.conf
        sudo echo "net.core.somaxconn = 4096" >> /etc/sysctl.conf
        sudo echo "net.ipv4.tcp_syncookies = 1" >> /etc/sysctl.conf
        sudo echo "net.ipv4.tcp_tw_reuse = 1" >> /etc/sysctl.conf
        sudo echo "net.ipv4.tcp_tw_recycle = 0" >> /etc/sysctl.conf
        sudo echo "net.ipv4.tcp_fin_timeout = 30" >> /etc/sysctl.conf
        sudo echo "net.ipv4.tcp_max_syn_backlog = 8192" >> /etc/sysctl.conf
        sudo echo "net.ipv4.tcp_max_tw_buckets = 5000" >> /etc/sysctl.conf
        sudo echo "net.ipv4.tcp_mtu_probing = 1" >> /etc/sysctl.conf
        sudo echo "net.core.rmem_max = 67108864" >> /etc/sysctl.conf
        sudo echo "net.core.wmem_max = 67108864" >> /etc/sysctl.conf
        sudo echo "net.ipv4.tcp_mem = 25600 51200 102400" >> /etc/sysctl.conf
        sudo echo "net.ipv4.tcp_rmem = 4096 87380 67108864" >> /etc/sysctl.conf
        sudo echo "net.ipv4.tcp_wmem = 4096 65536 67108864" >> /etc/sysctl.conf
        fi
	# We optimise 'limits.conf' file for better performance.
	sudo echo "* soft     nproc          655350" >> /etc/security/limits.conf
	sudo echo "* hard     nproc          655350" >> /etc/security/limits.conf
	sudo echo "* soft     nofile         655350" >> /etc/security/limits.conf
	sudo echo "* hard     nofile         655350" >> /etc/security/limits.conf
	sudo echo "root soft     nproc          655350" >> /etc/security/limits.conf
	sudo echo "root hard     nproc          655350" >> /etc/security/limits.conf
	sudo echo "root soft     nofile         655350" >> /etc/security/limits.conf
	sudo echo "root hard     nofile         655350" >> /etc/security/limits.conf
	# We apply the changes.
	sudo sysctl -p
    }

# Saves the new user's name and password as well as the latest version of selected tunneling method to be used after switching to the new user.
saveAndTransferCredentials() {
	echo "========================================================================="
	echo "|                           Saving Credentials                          |"
	echo "========================================================================="
    # We save the new user credentials to use after switching user.
	# We first must check if it already exists or not.
	# If it does exist, we must delete it and make a new one to store new temporary data.
	if [ -d "/tunlDigrTemp" ]
	    then
	    sudo rm -r /tunlDigrTemp
		sudo mkdir /tunlDigrTemp
	    else
		sudo mkdir /tunlDigrTemp
	    fi
    # We save the credentials into files to access later.
	echo $newAccUsername > /tunlDigrTemp/tempNewAccUsername.txt
	echo $newAccPassword > /tunlDigrTemp/tempNewAccPassword.txt
    # If selected tunneling method is not shadowsocks, We save the latest version of tunneling method.
    if[ ! $tunnelingMethod == shadowsocks ]; then
	    echo $latestPackageVersion > /tunlDigrTemp/tempLatestPackageVersion.txt
        fi
	# We transfer ownership of the temp folder to the new user, so the new user is able to Access and delete the senstive information when it's no longer needed.
	sudo chown -R $newAccUsername /tunlDigrTemp/
    }

# Reads the new user's name and password as well as the latest version of selected tunneling method, then removed the files containing these information.
readAndRemoveCredentials() {
	echo "========================================================================="
	echo "|                           Reading Credentials                          |"
	echo "========================================================================="
	# We read the saved credentials.
	tempNewAccUsername=$(</tunlDigrTemp/tempNewAccUsername.txt)
	tempNewAccPassword=$(</tunlDigrTemp/tempNewAccPassword.txt)
    # If selected tunneling method is not shadowsocks, We read the latest version of tunneling method.
    if[ ! $tunnelingMethod == shadowsocks ]; then
        tempLatestPackageVersion=$(</tunlDigrTemp/tempLatestPackageVersion.txt)
        sudo rm /tunlDigrTemp/tempLatestPackageVersion.txt
        fi
	# We delete senstive inforamtion.
	sudo rm /tunlDigrTemp/tempNewAccUsername.txt
	sudo rm /tunlDigrTemp/tempNewAccPassword.txt
    }

# Allows the specified port (tunnelPort) on ufw.
# If port is not provided, 443 is used by default.
allowPortOnUfw() {
    echo "========================================================================="
	echo "|                             Allowing Port                             |"
	echo "========================================================================="
	# We provide password to 'sudo' command and open protocol port.
    # We check whether user has provided custom port and if so, we check if it's in the acceptable range (0 - 65535).
    # If not, we will use the dafault 443.
    if [ ! -v tunnelPort ] || [[ $tunnelPort != +([0-9]) ]] || [ $tunnelPort -gt 65535 ]; then       
        tunnelPort=443
        fi
	echo $tempNewAccPassword | sudo -S ufw allow $tunnelPort
    }

# Creates a new user.
# Uses the supplied newAccUsername(-setusername) & newAccPassword(-setuserpass) if available.
# if not, it will randomly generate unavailable ones, using (generateRandom) function.
addNewUser() {
	echo "========================================================================="
	echo "|                  Adding a new user and configuring                    |"
	echo "========================================================================="
	# We check whether user has provided custom username.
	# If not, we will generate a random username.
	if [ ! -v newAccUsername ]; then
        newAccUsername=$(generateRandom username)
	    fi
	# We check whether user has provided custom password.
	# If not, we will generate a random password.
	if [ ! -v newAccPassword ]; then
		newAccPassword=$(generateRandom password)
	    fi
	 # We create a new user.
	adduser --gecos "" --disabled-password $newAccUsername
	# We set a password for the new user.
	chpasswd <<<"$newAccUsername:$newAccPassword"
	# We grant root privileges to the new user.
	usermod -aG sudo $newAccUsername	
    }

# Creates the required service file for the selected tunnel and saves it the specific service path.
# TODO: Rework the reality service to use reality as name not xray (this makes some confusion later on).
createService() {
    # We create some local variables to hold tunnel specific data.
    # Hysteria 2
    local hysteria2ServicePath="/etc/systemd/system/hysteria2.service"
    local hysteria2serviceDescription="sing-box service"
    local hysteria2ServiceDocumentation="https://sing-box.sagernet.org"
    local hysteria2ServiceAfter="network.target nss-lookup.target"
    local hysteriaCapabilityBoundingSet="CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_SYS_PTRACE CAP_DAC_READ_SEARCH"
    local hysteriaAmbientCapabilities="CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_SYS_PTRACE CAP_DAC_READ_SEARCH"
    local hysteriaExecStart="/home/$newAccUsername/hysteria2/sing-box -D /home/$newAccUsername/hysteria2/ run -c /home/$newAccUsername/hysteria2/config.json"
    local hysteriaLimitNOFILE="infinity"
    # Reality
    local realityServicePath="/etc/systemd/system/xray.service"
    local realityServiceDescription="XTLS Xray-Core a VMESS/VLESS Server"
    local realityServiceAfter="network.target nss-lookup.target"
    local realityCapabilityBoundingSet="CAP_NET_ADMIN CAP_NET_BIND_SERVICE"
    local realityAmbientCapabilities="CAP_NET_ADMIN CAP_NET_BIND_SERVICE"
    local realityExecStart="/home/$newAccUsername/xray/xray run -config /home/$newAccUsername/xray/config.json"
    local realityLimitNOFILE="1000000"
    # ShadowSocks
    local shadowsocksServicePath="/etc/systemd/system/shadowsocks-libev-server@.service"
    local shadowsocksServiceDescription="Shadowsocks-Libev Custom Server Service"
    local shadowsocksServiceDocumentation="man:ss-server(1)"
    local shadowsocksServiceAfter="network-online.target"
    local shadowsocksExecStart="/usr/bin/snap run shadowsocks-libev.ss-server -c /var/snap/shadowsocks-libev/common/etc/shadowsocks-libev/config.json"
    # We determine the selected tunneling method and set service variables accordingly.
    case $tunnelingMethod in
        hysteria2)
            local servicePath=$hysteria2ServicePath
            local serviceName="Hysteria 2"
            local serviceDescription=$hysteria2serviceDescription
            local serviceDocumentation=$hysteria2ServiceDocumentation
            local serviceAfter=$hysteria2ServiceAfter
            local serviceCapabilityBoundingSet=$hysteriaCapabilityBoundingSet
            local serviceAmbientCapabilities=$hysteriaAmbientCapabilities
            local serviceExecStart=$hysteriaExecStart
            local serviceLimitNOFILE=$hysteriaLimitNOFILE
            ;;
        reality)
            local servicePath=$realityServicePath
            local serviceName="Reality"
            local serviceDescription=$realityServiceDescription
            local serviceAfter=$realityServiceAfter
            local serviceCapabilityBoundingSet=$realityCapabilityBoundingSet
            local serviceAmbientCapabilities=$realityAmbientCapabilities
            local serviceExecStart=$realityExecStart
            local serviceLimitNOFILE=$realityLimitNOFILE
            ;;
        shadowsocks)
            local servicePath=$shadowsocksServicePath
            local serviceDescription=$shadowsocksServiceDescription
            local serviceDocumentation=$shadowsocksServiceDocumentation
            local serviceAfter=$shadowsocksServiceAfter
            local serviceExecStart=$shadowsocksExecStart
            ;;
        esac
	echo "========================================================================="
	echo "|                      Creating $serviceName service                     "
	echo "========================================================================="
	# We create a service file using preset variables.
	sudo echo "[Unit]" > $servicePath
	sudo echo "Description=$serviceDescription" >> $servicePath
    # Hysteria 2 & ShadowSocks have Documentation.
        case $tunnelingMethod in
        hysteria2 || shadowsocks)
            sudo echo "Documentation=$serviceDocumentation" >> $servicePath
            ;;
        esac
	sudo echo "After=$serviceAfter" >> $servicePath
    # ShadowSocks Wants
    if [ $tunnelingMethod == shadowsocks ]; then
        sudo echo "Wants=network-online.target" >> $servicePath
        fi
	sudo echo "[Service]" >> $servicePath
    # ShadowSocks Type
    if [ $tunnelingMethod == shadowsocks ]; then
        sudo echo "Type=simple" >> $servicePath
        fi
    # Hysteria 2 & Reality User, Group, CapabilityBoundingSet, AmbientCapabilities
    case $tunnelingMethod in
        hysteria2 || reality)
            	sudo echo "User=$newAccUsername" >> $servicePath
	            sudo echo "Group=$newAccUsername" >> $servicePath
	            sudo echo "CapabilityBoundingSet=$serviceCapabilityBoundingSet" >> $servicePath
	            sudo echo "AmbientCapabilities=$serviceAmbientCapabilities" >> $servicePath
            ;;
        esac
    # Reality NoNewPrivileges
    if [ $tunnelingMethod == reality ]; then
        sudo echo "NoNewPrivileges=true" >> $servicePath
        fi
	sudo echo "ExecStart=$serviceExecStart" >> $servicePath
    # Hysteria 2 ExecReload
    if [ $tunnelingMethod == hysteria2 ]; then
	    sudo echo "ExecReload=/bin/kill -HUP \$MAINPID" >> $servicePath
        fi  
    # Hysteria 2 & Reality Restart
    case $tunnelingMethod in
        hysteria2 || reality)
            sudo echo "Restart=on-failure" >> $servicePath
            ;;
        esac
    # Reality RestartPreventExitStatus and StandardOutput 
    if [ $tunnelingMethod == reality ]; then
        sudo echo "RestartPreventExitStatus=23" >> $servicePath
        sudo echo "StandardOutput=journal" >> $servicePath
        fi
    # Hysteria 2 RestartSec
    if [ $tunnelingMethod == hysteria2 ]; then
	    sudo echo "RestartSec=10s" >> $servicePath
        fi
    # Reality LimitNPROC
    if [ $tunnelingMethod == reality ]; then
        sudo echo "LimitNPROC=100000" >> $servicePath
        fi
    # Hysteria 2 & Reality LimitNOFILE
    case $tunnelingMethod in
        hysteria2 || reality)
	        sudo echo "LimitNOFILE=$serviceLimitNOFILE" >> $servicePath
            ;;
        esac
	sudo echo "" >> $servicePath
	sudo echo "[Install]" >> $servicePath
	sudo echo "WantedBy=multi-user.target" >> $servicePath
    }

# Switches to the newly created user.
switchUser() {
	echo "========================================================================="
	echo "|                           Switching user                              |"
	echo "========================================================================="
	# We now switch to the new user.
	sshpass -p $newAccPassword ssh -o "StrictHostKeyChecking=no" $newAccUsername@127.0.0.1
    }

# Shows an error message and exits the script.
hardwareNotSupported() {
    echo "This architecture is NOT Supported by $tunnelName. exiting ..."
    exit
    }

# Gets the current machine's hardware architecture and translates it to appropriate string based on selected tunneling method.
# If the tunnel does not supprt the current hardware architecture, an error message will be shown and the script will exit.
getHardwareArch() {
    # We check and save the hardware architecture of current machine.
	local hwarch="$(uname -m)"
    # We translate it to appropriate string based on each tunneling method.
    # If the architecture is not supported by the selected tunneling method, we will show an error message and exit the script.
	case $hwarch in
        # x86 - 64 Bit
	    x86_64)
            case $tunnelingMethod in
                hysteria2)
                    # We check if cpu supprt AVX.
	                avxsupport="$(lscpu | grep -o avx)"
	                if [ -z "$avxsupport" ]; then 
		                hwarch="amd64"
	                else
                        # If so, we will use the package with AVX functions for faster performance
		                hwarch="amd64v3"
	                    fi
                    ;;
                xray)
                    hwarch="64"
                    ;;
                    esac
	        ;;
        # x86 - 32 Bit
        i386)
            case $tunnelingMethod in
                hysteria2)
                    hwarch="386"
                    ;;
                xray)
                    hwarch="32"
                    ;;
                    esac
            ;;
        # Arm - 64 Bit - V8
	    aarch64)
            case $tunnelingMethod in
                hysteria2)
                    hwarch="arm64"
                    ;;
                xray)
                    hwarch="arm64-v8a"
                    ;;
                    esac
            ;;
        # Arm - 32 Bit - V7
	    armv7l)
            case $tunnelingMethod in
                hysteria2)
                    hwarch="armv7"
                    ;;
                xray)
                    hwarch="arm32-v7a"
                    ;;
                    esac
            ;;
        # Arm - 32 Bit - V6
        armv6l)
            case $tunnelingMethod in
                # Hysteria does not support armv6l, we will show an error and exit the script
                hysteria2)
                    hardwareNotSupported
                    ;;
                xray)
                    hwarch="arm32-v6"
                    ;;
                    esac
            ;;
        # PowerPC - 64 Bit
        ppc64)
            case $tunnelingMethod in
                # Hysteria does not support armv6l, we will show an error and exit the script
                hysteria2)
                    hardwareNotSupported
                    ;;
                xray)
                    hwarch="ppc64"
                    ;;
                    esac
            ;;
        # IBM System/390
        # Because there is no difference, we don't check anything here.
        s390x)
            hwarch="s390x"
            ;;
        # If nothing matched, either it's not implemented yet OR the tunnels don't support such architecture.
        # We show an error message and exit the script.
	    *)
	        echo "This architecture is NOT Supported by this script. exiting ..."
	        exit
            ;;
	    esac
    # We echo back the tranlated hardware architecture.
    echo $hwarch
    }

# Creates SSL certificate key pairs.
# Uses the supplied sslcn(-seth2sslcn) if available.
# If not, will use the default (google-analytics.com)
createSSLCertificateKeyPairs() {
    # We create certificate keys.
	openssl ecparam -genkey -name prime256v1 -out ca.key
	# We check whether user has provided custom common name for SSL certificate.
	# If not, we will use default.
	if [ ! -v sslcn ]; then
		sslcn="google-analytics.com"
	    fi
	openssl req -new -x509 -days 36500 -key ca.key -out ca.crt -subj "/CN=$sslcn"
    }

# Downloads the required files for selected tunnel and extracts them, then removes the downloaded package.
# TODO: Rework the reality downloader to use reality as name not xray (this makes some confusion later on).
downloadFiles() {
    # If selected tunnel is ShadowSocks, only one command is needed and other steps are not required.
    if [ $tunnelingMethod == shadowsocks ]; then
        # We check whether user has requested to install edge channel or not.
	    # If so, we will use edge channel.
        if [ -v ssUseEdgeChannel ]; then
            snap install shadowsocks-libev --edge
        else
            snap install shadowsocks-libev
        fi
        return
        fi
    # Hysteria 2
    local singBoxUrl="https://github.com/SagerNet/sing-box/releases/download/v$tempLatestPackageVersion/sing-box-$tempLatestPackageVersion-linux-$hardwareArch.tar.gz"
    local singBoxPackageName="sing-box-$tempLatestPackageVersion-linux-$hardwareArch.tar.gz"
    # Reality
    local xrayUrl="https://github.com/XTLS/Xray-core/releases/download/v$tempLatestPackageVersion/Xray-linux-$hardwareArch.zip"
    local xrayPackageName="Xray-linux-$hardwareArch.zip"
    # We determine the selected tunneling method and set download variables accordingly.
    case $tunnelingMethod in
        hysteria2)
            local protocolName="Hysteria 2"
            local packageUrl=$singBoxUrl
            local packageName=$singBoxPackageName
            local directoryName="hysteria2"
            ;;
        reality)
            local protocolName="Xray"
            local packageUrl=$xrayUrl
            local packageName=$xrayPackageName
            local directoryName="xray"
            ;;
            esac
    echo "========================================================================="
	echo "|               Downloading $protocolName and required files                 |"
	echo "========================================================================="
	# We create directory to hold files.
	# If it does exist, we must delete it and make a new one to avoid conflicts.
	if [ -d "/$directoryName" ]; then
		sudo rm -r /$directoryName
	    fi
	mkdir $directoryName
	# We navigate to directory we created.
	cd $directoryName/
	# We download the latest suitable package for current machine.
	wget $packageUrl
    # If we running Reality, we also download geoasset file.
    if [ $tunnelingMethod == reality ]; then
        wget https://github.com/bootmortis/iran-hosted-domains/releases/latest/download/iran.dat
        fi
    # We extract the package.
    case $tunnelingMethod in
        hysteria2)
            tar -xzf $packageName --strip-components=1 sing-box-$tempLatestPackageVersion-linux-$hwarch/sing-box
            ;;
        reality)
            unzip $packageName
            ;;
            esac
	# We remove downloaded file.
	sudo rm $packageName
    }

configureSingBox() {
    echo "========================================================================="
    echo "|                       Configuring Sing-Box                            |"
    echo "========================================================================="
    # We restart the service and enable auto-start
    sudo systemctl daemon-reload && sudo systemctl enable hysteria2

    # We check whether user has provided custom hysteria obfs password
	# If not, we will generate a random password for salamander obfs
	if [ ! -v h2ObfsPass ]; then
    	h2ObfsPass=$(generateRandom password)
        fi

    # We check whether user has provided custom hysteria authentication password
    # If not, we will generate a random password for hysteria user
    if [ ! -v h2UserPass ]; then
        h2UserPass=$(generateRandom password)
        fi

    # We store path of 'config.json' file
    local configfile=/home/$tempNewAccUsername/hysteria2/config.json

    # We create 'config.json' file
    cat > $configfile << EOL
    {
       "log":{
          "level":"info",
          "timestamp":true
       },
       "inbounds":[
          {
             "type":"hysteria2",
             "tag":"hy2-in",
             "listen":"::",
             "listen_port":$tunnelPort,
             "domain_strategy":"prefer_ipv4",
             "up_mbps":0,
             "down_mbps":0,
             "obfs":{
                "type":"salamander",
                "password":"$h2ObfsPass"
             },
             "users":[
                {
                   "name":"user",
                   "password":"$h2UserPass"
                }
             ],
             "ignore_client_bandwidth":true,
             "tls":{
                "enabled":true,
                "certificate_path":"/home/$tempNewAccUsername/hysteria2/ca.crt",
                "key_path":"/home/$tempNewAccUsername/hysteria2/ca.key"
             }
          }
       ],
       "outbounds":[
          {
             "type":"direct",
             "tag":"direct"
          },
          {
             "type":"block",
             "tag":"block"
          },
          {
             "type":"dns",
             "tag":"dns-out"
          }
       ],
       "dns":{
          "servers":[
             {
                "tag":"dns-out",
                "address":"https://1.1.1.1/dns-query",
                "address_strategy":"prefer_ipv4",
                "strategy":"prefer_ipv4",
                "detour":"direct"
             }
          ]
       },
       "route":{
          "geosite":{
             "path":"iran-geosite.db",
             "download_url":"https://github.com/bootmortis/iran-hosted-domains/releases/latest/download/iran-geosite.db"
          },
          "geoip":{
             "path":"geoip.db",
             "download_url":"https://github.com/SagerNet/sing-geoip/releases/latest/download/geoip.db"
          },
          "rules":[
             {
                "port":53,
                "outbound":"dns-out"
             },
             {
                "domain_suffix":".ir",
                "outbound":"block"
             },
             {
                "outbound":"block",
                "geosite":[
                   "ir",
                   "other",
                   "ads"
                ]
             },
             {
                "outbound":"block",
                "geoip":[
                   "ir",
                   "private"
                ]
             },
             {
                "outbound":"block",
                "domain":[
                   "sb24.com",
                   "sheypoor.com",
                   "tebyan.net",
                   "beytoote.com",
                   "telewebion.com",
                   "Film2movie.ws",
                   "Setare.com",
                   "Filimo.com",
                   "Torob.com",
                   "Tgju.org",
                   "Sarzamindownload.com",
                   "downloadha.com",
                   "P30download.com",
                   "Sanjesh.org",
                   "patriciamolina.org",
                   "ajl.net",
                   "akidoo.top",
                   "orbsrv.com",
                   "s.orbsrv.com",
                   "syndication.realsrv.com",
                   "realsrv.com",
                   "nsimg.net",
                   "app.adjust.com",
                   "dbankcloud.asia",
                   "sckm.org",
                   "ubzrr.net",
                   "cgqv.net",
                   "xz2.d0d.com",
                   "www.xz2.d0d.com",
                   "d0d.com",
                   "magicfiles123.com",
                   "15ty.gx6.org",
                   "intrack.ir",
                   "divar.ir",
                   "irancell.ir",
                   "yooz.ir",
                   "iran-cell.com",
                   "irancell.i-r",
                   "shaparak.ir",
                   "learnit.ir",
                   "yooz.ir",
                   "baadesaba.ir",
                   "webgozar.ir",
                   "balad.ir",
                   "web.bale.ir",
                   "bale.ir",
                   "bale.ai",
                   "bale.io",
                   "dt.beyla.site",
                   "beyla.site"
                ]
             },
             {
                "outbound":"block",
                "ip_cidr":[
                   "6.0.0.0/8",
                   "7.0.0.0/8",
                   "11.0.0.0/8",
                   "21.0.0.0/8",
                   "22.0.0.0/8",
                   "26.0.0.0/8",
                   "28.0.0.0/8",
                   "29.0.0.0/8",
                   "30.0.0.0/8",
                   "33.0.0.0/8",
                   "2.144.0.0/14",
                   "2.176.0.0/12",
                   "5.1.43.0/24",
                   "5.22.0.0/17",
                   "5.22.192.0/21",
                   "5.22.200.0/22",
                   "5.23.112.0/21",
                   "5.34.192.0/20",
                   "5.42.217.0/24",
                   "5.42.223.0/24",
                   "5.52.0.0/16",
                   "5.53.32.0/19",
                   "5.56.128.0/22",
                   "5.56.132.0/24",
                   "5.56.134.0/23",
                   "5.57.32.0/21",
                   "5.61.24.0/23",
                   "5.61.26.0/24",
                   "5.61.28.0/22",
                   "5.62.160.0/19",
                   "5.62.192.0/18",
                   "5.63.8.0/21",
                   "5.72.0.0/15",
                   "5.74.0.0/16",
                   "5.75.0.0/17",
                   "5.104.208.0/21",
                   "5.106.0.0/16",
                   "5.112.0.0/12",
                   "5.134.128.0/18",
                   "5.134.192.0/21",
                   "5.135.116.200/30",
                   "5.144.128.0/21",
                   "5.145.112.0/22",
                   "5.145.116.0/24",
                   "5.159.48.0/21",
                   "5.160.0.0/16",
                   "5.182.44.0/22",
                   "5.190.0.0/16",
                   "5.198.160.0/19",
                   "5.200.64.0/18",
                   "5.200.128.0/17",
                   "5.201.128.0/17",
                   "5.202.0.0/16",
                   "5.208.0.0/12",
                   "5.213.255.36/31",
                   "5.232.0.0/14",
                   "5.236.0.0/17",
                   "5.236.128.0/20",
                   "5.236.144.0/21",
                   "5.236.156.0/22",
                   "5.236.160.0/19",
                   "5.236.192.0/18",
                   "5.237.0.0/16",
                   "5.238.0.0/15",
                   "5.250.0.0/17",
                   "5.252.216.0/22",
                   "5.253.24.0/22",
                   "5.253.96.0/22",
                   "5.253.225.0/24",
                   "8.27.67.32/32",
                   "8.27.67.41/32",
                   "31.2.128.0/17",
                   "31.7.64.0/21",
                   "31.7.72.0/22",
                   "31.7.76.0/23",
                   "31.7.88.0/22",
                   "31.7.96.0/19",
                   "31.7.128.0/20",
                   "31.14.80.0/20",
                   "31.14.112.0/20",
                   "31.14.144.0/20",
                   "31.24.85.64/27",
                   "31.24.200.0/21",
                   "31.24.232.0/21",
                   "31.25.90.0/23",
                   "31.25.92.0/22",
                   "31.25.104.0/21",
                   "31.25.128.0/21",
                   "31.25.232.0/23",
                   "31.40.0.0/22",
                   "31.40.4.0/24",
                   "31.41.35.0/24",
                   "31.47.32.0/19",
                   "31.56.0.0/14",
                   "31.130.176.0/20",
                   "31.170.48.0/22",
                   "31.170.52.0/23",
                   "31.170.54.0/24",
                   "31.170.56.0/21",
                   "31.171.216.0/21",
                   "31.184.128.0/18",
                   "31.193.112.0/21",
                   "31.193.186.0/24",
                   "31.214.132.0/23",
                   "31.214.146.0/23",
                   "31.214.154.0/24",
                   "31.214.168.0/21",
                   "31.214.200.0/23",
                   "31.214.228.0/22",
                   "31.214.248.0/21",
                   "31.216.62.0/24",
                   "31.217.208.0/21",
                   "37.9.248.0/21",
                   "37.10.64.0/22",
                   "37.10.109.0/24",
                   "37.10.117.0/24",
                   "37.19.80.0/20",
                   "37.32.0.0/19",
                   "37.32.16.0/27",
                   "37.32.17.0/27",
                   "37.32.18.0/27",
                   "37.32.19.0/27",
                   "37.32.32.0/20",
                   "37.32.112.0/20",
                   "37.44.56.0/21",
                   "37.63.128.0/17",
                   "37.75.240.0/21",
                   "37.98.0.0/17",
                   "37.114.192.0/18",
                   "37.129.0.0/16",
                   "37.130.200.0/21",
                   "37.137.0.0/16",
                   "37.143.144.0/21",
                   "37.148.0.0/17",
                   "37.148.248.0/22",
                   "37.152.160.0/19",
                   "37.153.128.0/22",
                   "37.153.176.0/20",
                   "37.156.0.0/22",
                   "37.156.8.0/21",
                   "37.156.16.0/20",
                   "37.156.48.0/20",
                   "37.156.100.0/22",
                   "37.156.112.0/20",
                   "37.156.128.0/20",
                   "37.156.144.0/22",
                   "37.156.152.0/21",
                   "37.156.160.0/21",
                   "37.156.176.0/22",
                   "37.156.212.0/22",
                   "37.156.232.0/21",
                   "37.156.240.0/22",
                   "37.156.248.0/22",
                   "37.191.64.0/19",
                   "37.202.128.0/17",
                   "37.221.0.0/18",
                   "37.228.131.0/24",
                   "37.228.133.0/24",
                   "37.228.135.0/24",
                   "37.228.136.0/22",
                   "37.235.16.0/20",
                   "37.254.0.0/16",
                   "37.255.0.0/17",
                   "37.255.128.0/26",
                   "37.255.128.64/27",
                   "37.255.128.96/28",
                   "37.255.128.128/25",
                   "37.255.129.0/24",
                   "37.255.130.0/23",
                   "37.255.132.0/22",
                   "37.255.136.0/21",
                   "37.255.144.0/20",
                   "37.255.160.0/19",
                   "37.255.192.0/18",
                   "45.8.160.0/22",
                   "45.9.144.0/22",
                   "45.9.252.0/22",
                   "45.15.200.0/22",
                   "45.15.248.0/22",
                   "45.81.16.0/22",
                   "45.82.136.0/22",
                   "45.84.156.0/22",
                   "45.84.248.0/22",
                   "45.86.4.0/22",
                   "45.86.87.0/24",
                   "45.86.196.0/22",
                   "45.87.4.0/22",
                   "45.89.136.0/22",
                   "45.89.200.0/22",
                   "45.89.236.0/22",
                   "45.90.72.0/22",
                   "45.91.152.0/22",
                   "45.92.92.0/22",
                   "45.94.212.0/22",
                   "45.94.252.0/22",
                   "45.128.140.0/22",
                   "45.129.36.0/22",
                   "45.129.116.0/22",
                   "45.132.32.0/24",
                   "45.132.168.0/21",
                   "45.135.240.0/22",
                   "45.138.132.0/22",
                   "45.139.9.0/24",
                   "45.139.10.0/23",
                   "45.139.100.0/22",
                   "45.140.28.0/22",
                   "45.140.224.0/21",
                   "45.142.188.0/22",
                   "45.144.16.0/22",
                   "45.144.124.0/22",
                   "45.147.76.0/22",
                   "45.148.248.0/22",
                   "45.149.76.0/22",
                   "45.150.88.0/22",
                   "45.150.150.0/24",
                   "45.155.192.0/22",
                   "45.156.180.0/22",
                   "45.156.184.0/22",
                   "45.156.192.0/21",
                   "45.156.200.0/22",
                   "45.157.244.0/22",
                   "45.158.120.0/22",
                   "45.159.112.0/22",
                   "45.159.148.0/22",
                   "45.159.196.0/22",
                   "46.18.248.0/21",
                   "46.21.80.0/20",
                   "46.28.72.0/21",
                   "46.32.0.0/19",
                   "46.34.96.0/19",
                   "46.34.160.0/19",
                   "46.36.96.0/20",
                   "46.38.128.0/23",
                   "46.38.130.0/24",
                   "46.38.131.0/25",
                   "46.38.131.128/26",
                   "46.38.132.0/22",
                   "46.38.136.0/21",
                   "46.38.144.0/20",
                   "46.41.192.0/18",
                   "46.51.0.0/17",
                   "46.62.128.0/17",
                   "46.100.0.0/16",
                   "46.102.120.0/21",
                   "46.102.128.0/20",
                   "46.102.184.0/22",
                   "46.143.0.0/17",
                   "46.143.204.0/22",
                   "46.143.208.0/21",
                   "46.143.244.0/22",
                   "46.143.248.0/22",
                   "46.148.32.0/20",
                   "46.164.64.0/18",
                   "46.167.128.0/19",
                   "46.182.32.0/21",
                   "46.209.0.0/16",
                   "46.224.0.0/15",
                   "46.235.76.0/23",
                   "46.245.0.0/17",
                   "46.248.32.0/19",
                   "46.249.96.0/24",
                   "46.249.120.0/21",
                   "46.251.224.0/25",
                   "46.251.224.128/28",
                   "46.251.224.144/29",
                   "46.251.226.0/24",
                   "46.251.237.0/24",
                   "46.255.216.0/21",
                   "62.3.14.0/24",
                   "62.3.41.0/24",
                   "62.3.42.0/24",
                   "62.32.49.128/26",
                   "62.32.49.192/27",
                   "62.32.49.224/29",
                   "62.32.49.240/28",
                   "62.32.50.0/24",
                   "62.32.53.64/26",
                   "62.32.53.168/29",
                   "62.32.53.224/28",
                   "62.32.61.96/27",
                   "62.32.61.224/27",
                   "62.32.63.128/26",
                   "62.60.128.0/22",
                   "62.60.136.0/21",
                   "62.60.144.0/22",
                   "62.60.152.0/21",
                   "62.60.160.0/22",
                   "62.60.196.0/22",
                   "62.60.208.0/20",
                   "62.95.84.234/32",
                   "62.95.85.246/32",
                   "62.95.100.236/32",
                   "62.95.103.210/32",
                   "62.95.117.78/32",
                   "62.95.119.76/32",
                   "62.102.128.0/20",
                   "62.133.46.0/24",
                   "62.193.0.0/19",
                   "62.204.61.0/24",
                   "62.220.96.0/19",
                   "63.243.185.0/24",
                   "64.214.116.16/32",
                   "66.79.96.0/19",
                   "67.16.178.147/32",
                   "67.16.178.148/31",
                   "67.16.178.150/32",
                   "69.194.64.0/18",
                   "72.14.201.40/30",
                   "77.36.128.0/17",
                   "77.42.0.0/17",
                   "77.77.64.0/18",
                   "77.81.32.0/20",
                   "77.81.76.0/24",
                   "77.81.78.0/24",
                   "77.81.82.0/23",
                   "77.81.128.0/21",
                   "77.81.144.0/20",
                   "77.81.192.0/19",
                   "77.90.139.180/30",
                   "77.95.220.0/24",
                   "77.104.64.0/18",
                   "77.237.64.0/19",
                   "77.237.160.0/19",
                   "77.238.104.0/21",
                   "77.238.112.0/20",
                   "77.245.224.0/20",
                   "78.31.232.0/22",
                   "78.38.0.0/15",
                   "78.47.208.144/28",
                   "78.109.192.0/20",
                   "78.110.112.0/20",
                   "78.111.0.0/20",
                   "78.154.32.0/19",
                   "78.157.32.0/19",
                   "78.158.160.0/19",
                   "79.127.0.0/17",
                   "79.132.192.0/23",
                   "79.132.200.0/21",
                   "79.132.208.0/20",
                   "79.143.84.0/23",
                   "79.143.86.0/24",
                   "79.174.160.0/21",
                   "79.175.128.0/19",
                   "79.175.160.0/22",
                   "79.175.164.0/23",
                   "79.175.166.0/24",
                   "79.175.167.0/25",
                   "79.175.167.128/30",
                   "79.175.167.132/31",
                   "79.175.167.144/28",
                   "79.175.167.160/27",
                   "79.175.167.192/26",
                   "79.175.168.0/21",
                   "79.175.176.0/20",
                   "80.66.176.0/20",
                   "80.71.112.0/20",
                   "80.71.149.0/24",
                   "80.75.0.0/20",
                   "80.85.82.80/29",
                   "80.91.208.0/24",
                   "80.191.0.0/17",
                   "80.191.128.0/18",
                   "80.191.192.0/19",
                   "80.191.224.0/20",
                   "80.191.240.0/24",
                   "80.191.241.128/25",
                   "80.191.242.0/23",
                   "80.191.244.0/22",
                   "80.191.248.0/21",
                   "80.210.0.0/18",
                   "80.210.128.0/17",
                   "80.241.70.250/31",
                   "80.242.0.0/20",
                   "80.249.112.0/22",
                   "80.250.192.0/20",
                   "80.253.128.0/19",
                   "80.255.3.160/27",
                   "81.12.0.0/17",
                   "81.12.28.16/29",
                   "81.16.112.0/20",
                   "81.28.32.0/19",
                   "81.29.240.0/20",
                   "81.31.160.0/19",
                   "81.31.224.0/22",
                   "81.31.228.0/23",
                   "81.31.230.0/24",
                   "81.31.233.0/24",
                   "81.31.234.0/23",
                   "81.31.236.0/22",
                   "81.31.240.0/23",
                   "81.31.248.0/22",
                   "81.90.144.0/20",
                   "81.91.128.0/19",
                   "81.92.216.0/24",
                   "81.163.0.0/21",
                   "82.97.240.0/20",
                   "82.99.192.0/18",
                   "82.138.140.0/25",
                   "82.180.192.0/18",
                   "82.198.136.76/30",
                   "83.120.0.0/14",
                   "83.123.255.56/31",
                   "83.147.192.0/23",
                   "83.147.194.0/24",
                   "83.147.222.0/23",
                   "83.147.240.0/22",
                   "83.147.252.0/24",
                   "83.147.254.0/24",
                   "83.149.208.65/32",
                   "83.150.192.0/22",
                   "84.17.168.32/27",
                   "84.47.192.0/18",
                   "84.241.0.0/18",
                   "85.9.64.0/18",
                   "85.15.0.0/18",
                   "85.133.128.0/21",
                   "85.133.137.0/24",
                   "85.133.138.0/23",
                   "85.133.140.0/22",
                   "85.133.144.0/23",
                   "85.133.147.0/24",
                   "85.133.148.0/22",
                   "85.133.152.0/21",
                   "85.133.160.0/22",
                   "85.133.165.0/24",
                   "85.133.166.0/23",
                   "85.133.168.0/21",
                   "85.133.176.0/20",
                   "85.133.192.0/21",
                   "85.133.200.0/23",
                   "85.133.203.0/24",
                   "85.133.204.0/22",
                   "85.133.208.0/21",
                   "85.133.216.0/23",
                   "85.133.219.0/24",
                   "85.133.220.0/23",
                   "85.133.223.0/24",
                   "85.133.224.0/24",
                   "85.133.226.0/23",
                   "85.133.228.0/22",
                   "85.133.232.0/22",
                   "85.133.237.0/24",
                   "85.133.238.0/23",
                   "85.133.240.0/20",
                   "85.185.0.0/16",
                   "85.198.0.0/19",
                   "85.198.48.0/20",
                   "85.204.30.0/23",
                   "85.204.76.0/23",
                   "85.204.80.0/20",
                   "85.204.104.0/23",
                   "85.204.128.0/22",
                   "85.204.208.0/20",
                   "85.208.252.0/22",
                   "85.239.192.0/19",
                   "86.55.0.0/16",
                   "86.57.0.0/17",
                   "86.104.32.0/20",
                   "86.104.80.0/20",
                   "86.104.96.0/20",
                   "86.104.232.0/21",
                   "86.104.240.0/21",
                   "86.105.40.0/21",
                   "86.105.128.0/20",
                   "86.106.142.0/24",
                   "86.106.192.0/21",
                   "86.107.0.0/20",
                   "86.107.80.0/20",
                   "86.107.144.0/20",
                   "86.107.172.0/22",
                   "86.107.208.0/20",
                   "86.109.32.0/19",
                   "87.107.0.0/16",
                   "87.128.22.75/32",
                   "87.236.208.0/26",
                   "87.236.209.0/24",
                   "87.236.210.0/23",
                   "87.236.213.0/24",
                   "87.236.214.0/24",
                   "87.247.168.0/21",
                   "87.247.176.0/20",
                   "87.248.128.0/24",
                   "87.248.139.0/24",
                   "87.248.140.0/23",
                   "87.248.142.0/24",
                   "87.248.147.0/24",
                   "87.248.150.0/24",
                   "87.248.152.0/22",
                   "87.248.156.0/24",
                   "87.248.159.0/24",
                   "87.251.128.0/19",
                   "87.252.206.24/29",
                   "87.252.206.64/29",
                   "88.131.151.198/32",
                   "88.131.172.60/32",
                   "88.131.205.98/32",
                   "88.131.233.244/32",
                   "88.131.234.222/32",
                   "88.131.235.24/32",
                   "88.131.240.122/31",
                   "88.135.32.0/20",
                   "88.135.68.0/24",
                   "89.32.0.0/19",
                   "89.32.96.0/20",
                   "89.32.196.0/23",
                   "89.32.248.0/22",
                   "89.33.18.0/23",
                   "89.33.100.0/22",
                   "89.33.128.0/23",
                   "89.33.204.0/23",
                   "89.33.234.0/23",
                   "89.33.240.0/23",
                   "89.34.20.0/23",
                   "89.34.32.0/19",
                   "89.34.88.0/23",
                   "89.34.94.0/23",
                   "89.34.128.0/19",
                   "89.34.168.0/23",
                   "89.34.176.0/23",
                   "89.34.200.0/23",
                   "89.34.248.0/21",
                   "89.35.58.0/23",
                   "89.35.68.0/22",
                   "89.35.120.0/22",
                   "89.35.132.0/23",
                   "89.35.156.0/23",
                   "89.35.176.0/23",
                   "89.35.180.0/22",
                   "89.35.194.0/23",
                   "89.36.16.0/23",
                   "89.36.48.0/20",
                   "89.36.96.0/20",
                   "89.36.176.0/20",
                   "89.36.194.0/23",
                   "89.36.226.0/23",
                   "89.36.252.0/23",
                   "89.37.0.0/20",
                   "89.37.30.0/23",
                   "89.37.42.0/23",
                   "89.37.102.0/23",
                   "89.37.144.0/21",
                   "89.37.152.0/22",
                   "89.37.168.0/22",
                   "89.37.198.0/23",
                   "89.37.208.0/22",
                   "89.37.218.0/23",
                   "89.37.240.0/20",
                   "89.38.24.0/23",
                   "89.38.80.0/20",
                   "89.38.102.0/23",
                   "89.38.184.0/21",
                   "89.38.192.0/21",
                   "89.38.212.0/22",
                   "89.38.242.0/23",
                   "89.38.244.0/22",
                   "89.39.8.0/22",
                   "89.39.186.0/23",
                   "89.39.208.0/24",
                   "89.40.78.0/23",
                   "89.40.106.0/23",
                   "89.40.110.0/23",
                   "89.40.128.0/23",
                   "89.40.152.0/21",
                   "89.40.240.0/20",
                   "89.41.8.0/21",
                   "89.41.16.0/21",
                   "89.41.32.0/23",
                   "89.41.40.0/22",
                   "89.41.58.0/23",
                   "89.41.184.0/22",
                   "89.41.192.0/19",
                   "89.41.240.0/21",
                   "89.42.32.0/23",
                   "89.42.44.0/22",
                   "89.42.56.0/23",
                   "89.42.68.0/23",
                   "89.42.96.0/21",
                   "89.42.136.0/22",
                   "89.42.150.0/23",
                   "89.42.184.0/21",
                   "89.42.196.0/22",
                   "89.42.208.0/23",
                   "89.42.210.0/25",
                   "89.42.210.128/27",
                   "89.42.210.160/28",
                   "89.42.210.176/29",
                   "89.42.210.184/30",
                   "89.42.210.188/32",
                   "89.42.210.190/31",
                   "89.42.210.192/26",
                   "89.42.211.0/24",
                   "89.42.228.0/23",
                   "89.43.0.0/20",
                   "89.43.36.0/23",
                   "89.43.70.0/23",
                   "89.43.88.0/21",
                   "89.43.96.0/21",
                   "89.43.144.0/21",
                   "89.43.182.0/23",
                   "89.43.188.0/23",
                   "89.43.204.0/23",
                   "89.43.216.0/21",
                   "89.43.224.0/21",
                   "89.44.112.0/23",
                   "89.44.118.0/23",
                   "89.44.128.0/21",
                   "89.44.146.0/23",
                   "89.44.176.0/21",
                   "89.44.190.0/23",
                   "89.44.202.0/23",
                   "89.44.240.0/22",
                   "89.45.48.0/20",
                   "89.45.68.0/23",
                   "89.45.80.0/23",
                   "89.45.89.0/24",
                   "89.45.112.0/21",
                   "89.45.126.0/23",
                   "89.45.152.0/21",
                   "89.45.230.0/23",
                   "89.46.44.0/23",
                   "89.46.60.0/23",
                   "89.46.94.0/23",
                   "89.46.184.0/21",
                   "89.46.216.0/22",
                   "89.47.64.0/20",
                   "89.47.128.0/19",
                   "89.47.196.0/22",
                   "89.47.200.0/22",
                   "89.144.128.0/18",
                   "89.165.0.0/17",
                   "89.196.0.0/16",
                   "89.198.0.0/15",
                   "89.219.64.0/18",
                   "89.219.192.0/18",
                   "89.221.80.0/20",
                   "89.235.64.0/18",
                   "91.92.104.0/24",
                   "91.92.114.0/24",
                   "91.92.121.0/24",
                   "91.92.122.0/23",
                   "91.92.124.0/22",
                   "91.92.129.0/24",
                   "91.92.130.0/23",
                   "91.92.132.0/22",
                   "91.92.145.0/24",
                   "91.92.146.0/23",
                   "91.92.148.0/22",
                   "91.92.156.0/22",
                   "91.92.164.0/22",
                   "91.92.172.0/22",
                   "91.92.180.0/22",
                   "91.92.184.0/21",
                   "91.92.192.0/23",
                   "91.92.204.0/22",
                   "91.92.208.0/21",
                   "91.92.220.0/22",
                   "91.92.228.0/23",
                   "91.92.231.0/24",
                   "91.92.236.0/22",
                   "91.98.0.0/15",
                   "91.106.64.0/19",
                   "91.108.128.0/19",
                   "91.109.104.0/21",
                   "91.129.4.216/32",
                   "91.129.18.175/32",
                   "91.129.18.177/32",
                   "91.129.27.160/31",
                   "91.129.27.186/31",
                   "91.129.27.188/31",
                   "91.133.128.0/17",
                   "91.147.64.0/20",
                   "91.184.64.0/19",
                   "91.185.128.0/19",
                   "91.186.192.0/23",
                   "91.186.201.0/24",
                   "91.186.216.0/23",
                   "91.186.218.0/24",
                   "91.190.88.0/21",
                   "91.194.6.0/24",
                   "91.199.9.0/24",
                   "91.199.18.0/24",
                   "91.199.27.0/24",
                   "91.199.30.0/24",
                   "91.207.138.0/23",
                   "91.207.205.0/24",
                   "91.208.165.0/24",
                   "91.209.96.0/24",
                   "91.209.179.0/24",
                   "91.209.183.0/24",
                   "91.209.184.0/24",
                   "91.209.186.0/24",
                   "91.209.242.0/24",
                   "91.212.16.0/24",
                   "91.212.252.0/24",
                   "91.213.151.0/24",
                   "91.213.157.0/24",
                   "91.213.167.0/24",
                   "91.213.172.0/24",
                   "91.216.4.0/24",
                   "91.217.64.0/23",
                   "91.217.177.0/24",
                   "91.220.79.0/24",
                   "91.220.113.0/24",
                   "91.220.243.0/24",
                   "91.221.240.0/23",
                   "91.222.196.0/22",
                   "91.222.204.0/22",
                   "91.224.20.0/23",
                   "91.224.110.0/23",
                   "91.224.176.0/23",
                   "91.225.52.0/22",
                   "91.226.224.0/23",
                   "91.227.84.0/22",
                   "91.227.246.0/23",
                   "91.228.22.0/23",
                   "91.228.132.0/23",
                   "91.228.189.0/24",
                   "91.229.46.0/23",
                   "91.229.214.0/23",
                   "91.230.32.0/24",
                   "91.232.64.0/22",
                   "91.232.68.0/23",
                   "91.232.72.0/22",
                   "91.233.56.0/22",
                   "91.234.52.0/24",
                   "91.236.168.0/23",
                   "91.237.254.0/23",
                   "91.238.0.0/24",
                   "91.239.14.0/24",
                   "91.239.108.0/22",
                   "91.239.210.0/24",
                   "91.239.214.0/24",
                   "91.240.60.0/22",
                   "91.240.116.0/24",
                   "91.240.180.0/22",
                   "91.241.20.0/23",
                   "91.241.92.0/24",
                   "91.242.44.0/23",
                   "91.243.126.0/23",
                   "91.243.160.0/20",
                   "91.244.120.0/22",
                   "91.245.228.0/22",
                   "91.246.44.0/24",
                   "91.247.66.0/23",
                   "91.247.171.0/24",
                   "91.247.174.0/24",
                   "91.250.224.0/20",
                   "91.251.0.0/16",
                   "92.42.48.0/21",
                   "92.43.160.0/22",
                   "92.61.176.0/20",
                   "92.114.16.0/20",
                   "92.114.16.80/28",
                   "92.114.48.0/22",
                   "92.114.64.0/20",
                   "92.119.57.0/24",
                   "92.119.58.0/24",
                   "92.119.68.0/22",
                   "92.242.192.0/19",
                   "92.246.144.0/22",
                   "92.246.156.0/22",
                   "92.249.56.0/22",
                   "93.88.64.0/21",
                   "93.88.72.0/23",
                   "93.93.204.0/24",
                   "93.110.0.0/16",
                   "93.113.224.0/20",
                   "93.114.16.0/20",
                   "93.114.104.0/21",
                   "93.115.120.0/21",
                   "93.115.144.0/21",
                   "93.115.216.0/21",
                   "93.115.224.0/20",
                   "93.117.0.0/19",
                   "93.117.32.0/20",
                   "93.117.96.0/19",
                   "93.117.176.0/20",
                   "93.118.96.0/19",
                   "93.118.128.0/19",
                   "93.118.160.0/20",
                   "93.118.180.0/22",
                   "93.118.184.0/22",
                   "93.119.32.0/19",
                   "93.119.64.0/19",
                   "93.119.208.0/20",
                   "93.126.0.0/18",
                   "93.190.24.0/21",
                   "94.24.0.0/20",
                   "94.24.16.0/21",
                   "94.24.80.0/20",
                   "94.24.96.0/21",
                   "94.74.128.0/23",
                   "94.74.130.1/32",
                   "94.74.130.2/31",
                   "94.74.130.4/30",
                   "94.74.130.8/29",
                   "94.74.130.16/28",
                   "94.74.130.32/27",
                   "94.74.130.64/26",
                   "94.74.130.128/25",
                   "94.74.131.0/24",
                   "94.74.142.0/23",
                   "94.74.144.1/32",
                   "94.74.144.2/31",
                   "94.74.144.4/30",
                   "94.74.144.8/29",
                   "94.74.144.16/28",
                   "94.74.144.32/27",
                   "94.74.144.64/26",
                   "94.74.144.128/25",
                   "94.74.148.0/24",
                   "94.74.150.0/23",
                   "94.74.152.0/23",
                   "94.74.155.0/24",
                   "94.74.161.0/24",
                   "94.74.162.0/24",
                   "94.74.167.0/24",
                   "94.74.178.0/23",
                   "94.74.180.0/24",
                   "94.74.182.0/24",
                   "94.74.188.0/23",
                   "94.74.190.0/24",
                   "94.101.128.0/20",
                   "94.101.176.0/20",
                   "94.101.182.0/27",
                   "94.101.240.0/20",
                   "94.139.160.0/19",
                   "94.176.8.0/21",
                   "94.176.32.0/21",
                   "94.177.72.0/21",
                   "94.182.0.0/15",
                   "94.184.0.0/16",
                   "94.199.136.0/22",
                   "94.232.168.0/21",
                   "94.241.164.0/22",
                   "95.38.0.0/16",
                   "95.64.0.0/17",
                   "95.80.128.0/18",
                   "95.81.64.0/18",
                   "95.130.56.0/21",
                   "95.130.225.0/24",
                   "95.130.240.0/21",
                   "95.142.224.0/20",
                   "95.156.222.0/23",
                   "95.156.233.0/24",
                   "95.156.234.0/23",
                   "95.156.236.0/23",
                   "95.156.248.0/23",
                   "95.156.252.0/22",
                   "95.162.0.0/16",
                   "95.215.59.0/24",
                   "95.215.160.0/22",
                   "95.215.173.0/24",
                   "103.130.144.0/24",
                   "103.130.146.0/24",
                   "103.215.220.0/22",
                   "103.216.60.0/22",
                   "103.231.136.0/23",
                   "103.231.138.0/24",
                   "104.28.11.28/31",
                   "104.28.11.30/32",
                   "104.28.37.237/32",
                   "104.28.37.238/31",
                   "104.28.37.240/31",
                   "104.28.51.83/32",
                   "104.28.51.84/30",
                   "104.28.80.85/32",
                   "104.28.80.86/31",
                   "104.28.80.88/31",
                   "104.28.106.57/32",
                   "104.28.106.58/31",
                   "104.28.106.60/31",
                   "104.28.131.38/31",
                   "104.28.131.40/32",
                   "104.28.194.219/32",
                   "104.28.194.220/30",
                   "104.28.194.224/31",
                   "104.28.214.161/32",
                   "104.28.214.162/31",
                   "104.28.214.164/30",
                   "104.28.214.168/32",
                   "104.28.226.219/32",
                   "104.28.226.220/30",
                   "104.28.226.224/31",
                   "104.28.246.161/32",
                   "104.28.246.162/31",
                   "104.28.246.164/30",
                   "104.28.246.168/32",
                   "109.70.237.0/24",
                   "109.72.192.0/20",
                   "109.74.232.0/21",
                   "109.94.164.0/22",
                   "109.95.60.0/22",
                   "109.95.64.0/21",
                   "109.107.131.0/24",
                   "109.108.160.0/19",
                   "109.109.32.0/19",
                   "109.110.160.0/19",
                   "109.122.193.0/24",
                   "109.122.199.0/24",
                   "109.122.209.0/24",
                   "109.122.217.0/24",
                   "109.122.224.0/20",
                   "109.122.240.0/21",
                   "109.122.248.0/22",
                   "109.122.252.0/23",
                   "109.125.128.0/18",
                   "109.162.128.0/17",
                   "109.201.0.0/19",
                   "109.203.128.0/19",
                   "109.203.176.0/22",
                   "109.206.252.0/22",
                   "109.225.128.0/18",
                   "109.230.64.0/19",
                   "109.230.192.0/23",
                   "109.230.200.0/24",
                   "109.230.204.0/22",
                   "109.230.221.0/24",
                   "109.230.223.0/24",
                   "109.230.242.0/24",
                   "109.230.246.0/23",
                   "109.230.251.0/24",
                   "109.232.0.0/21",
                   "109.238.176.0/20",
                   "109.239.0.0/20",
                   "113.203.0.0/17",
                   "128.65.160.0/19",
                   "130.185.72.0/21",
                   "130.193.77.0/24",
                   "130.244.3.200/32",
                   "130.244.35.176/32",
                   "130.244.41.211/32",
                   "130.244.41.213/32",
                   "130.244.71.67/32",
                   "130.244.71.72/31",
                   "130.244.71.74/32",
                   "130.244.71.80/31",
                   "130.244.85.151/32",
                   "130.244.93.166/32",
                   "130.244.115.156/32",
                   "130.244.171.236/32",
                   "130.255.192.0/18",
                   "134.255.196.0/23",
                   "134.255.200.0/21",
                   "134.255.245.0/24",
                   "134.255.246.0/24",
                   "134.255.248.0/23",
                   "140.248.34.128/30",
                   "140.248.36.146/31",
                   "140.248.36.148/31",
                   "141.11.42.0/24",
                   "146.19.104.0/24",
                   "146.19.217.0/24",
                   "146.75.132.146/31",
                   "146.75.132.148/31",
                   "146.75.169.128/30",
                   "146.75.180.36/30",
                   "151.232.0.0/14",
                   "151.238.0.0/15",
                   "151.240.0.0/13",
                   "152.89.12.0/22",
                   "152.89.44.0/22",
                   "157.119.188.0/22",
                   "158.58.0.0/17",
                   "158.58.184.0/21",
                   "158.255.74.0/24",
                   "158.255.77.238/31",
                   "158.255.78.0/24",
                   "159.20.96.0/20",
                   "164.138.16.0/21",
                   "164.138.128.0/18",
                   "164.215.56.0/21",
                   "164.215.128.0/17",
                   "171.22.24.0/22",
                   "172.80.128.0/17",
                   "172.225.187.16/28",
                   "172.225.191.160/27",
                   "172.225.196.144/28",
                   "172.225.196.184/29",
                   "172.225.228.128/27",
                   "172.225.229.96/28",
                   "176.12.64.0/20",
                   "176.56.144.0/20",
                   "176.62.144.0/21",
                   "176.65.160.0/19",
                   "176.65.192.0/18",
                   "176.67.64.0/20",
                   "176.97.218.0/24",
                   "176.97.220.0/24",
                   "176.101.32.0/20",
                   "176.101.48.0/21",
                   "176.102.224.0/19",
                   "176.105.245.0/24",
                   "176.116.7.0/24",
                   "176.122.210.0/23",
                   "176.123.64.0/18",
                   "176.124.64.0/22",
                   "176.126.120.0/24",
                   "176.221.64.0/21",
                   "176.223.80.0/21",
                   "178.21.40.0/21",
                   "178.21.160.0/21",
                   "178.22.72.0/21",
                   "178.22.120.0/21",
                   "178.131.0.0/16",
                   "178.157.0.0/23",
                   "178.169.0.0/19",
                   "178.173.128.0/18",
                   "178.173.192.0/19",
                   "178.211.145.0/24",
                   "178.215.0.0/18",
                   "178.216.248.0/21",
                   "178.219.224.0/20",
                   "178.236.32.0/22",
                   "178.236.96.0/20",
                   "178.238.192.0/20",
                   "178.239.144.0/20",
                   "178.248.40.0/21",
                   "178.251.208.0/21",
                   "178.252.128.0/18",
                   "178.253.16.0/24",
                   "178.253.31.0/24",
                   "178.253.32.0/24",
                   "178.253.38.0/23",
                   "185.1.77.0/24",
                   "185.2.12.0/22",
                   "185.3.124.0/22",
                   "185.3.200.0/22",
                   "185.3.212.0/22",
                   "185.4.0.0/22",
                   "185.4.16.0/22",
                   "185.4.28.0/22",
                   "185.4.104.0/22",
                   "185.4.220.0/22",
                   "185.5.156.0/22",
                   "185.7.212.0/24",
                   "185.8.172.0/22",
                   "185.10.71.0/24",
                   "185.10.72.0/22",
                   "185.11.68.0/22",
                   "185.11.88.0/22",
                   "185.11.176.0/22",
                   "185.12.60.0/22",
                   "185.12.100.0/23",
                   "185.12.102.0/24",
                   "185.13.228.0/22",
                   "185.14.80.0/22",
                   "185.14.160.0/22",
                   "185.16.232.0/22",
                   "185.17.115.176/30",
                   "185.18.156.0/22",
                   "185.18.212.0/22",
                   "185.19.201.0/24",
                   "185.20.160.0/22",
                   "185.21.68.0/22",
                   "185.21.76.0/22",
                   "185.22.28.0/22",
                   "185.23.128.0/22",
                   "185.24.136.0/22",
                   "185.24.148.0/22",
                   "185.24.228.0/22",
                   "185.24.252.0/22",
                   "185.25.172.0/22",
                   "185.26.32.0/22",
                   "185.26.232.0/22",
                   "185.29.220.0/22",
                   "185.30.4.0/22",
                   "185.30.76.0/22",
                   "185.31.124.0/22",
                   "185.32.128.0/22",
                   "185.33.25.0/24",
                   "185.34.160.0/22",
                   "185.36.228.0/24",
                   "185.36.231.0/24",
                   "185.37.52.0/22",
                   "185.39.180.0/22",
                   "185.40.16.0/24",
                   "185.40.240.0/22",
                   "185.41.0.0/22",
                   "185.41.220.0/22",
                   "185.42.24.0/24",
                   "185.42.26.0/23",
                   "185.42.212.0/22",
                   "185.42.224.0/22",
                   "185.44.36.0/22",
                   "185.44.100.0/22",
                   "185.44.112.0/22",
                   "185.45.188.0/22",
                   "185.46.0.0/22",
                   "185.46.108.0/22",
                   "185.46.216.0/22",
                   "185.47.48.0/22",
                   "185.49.84.0/22",
                   "185.49.96.0/22",
                   "185.49.104.0/22",
                   "185.49.231.0/24",
                   "185.50.36.0/22",
                   "185.51.40.0/22",
                   "185.51.200.0/22",
                   "185.53.140.0/22",
                   "185.55.224.0/22",
                   "185.56.92.0/22",
                   "185.56.96.0/22",
                   "185.57.132.0/22",
                   "185.57.164.0/22",
                   "185.57.200.0/22",
                   "185.58.240.0/22",
                   "185.59.112.0/23",
                   "185.60.32.0/22",
                   "185.60.136.0/22",
                   "185.62.232.0/22",
                   "185.63.113.0/24",
                   "185.63.114.0/24",
                   "185.63.236.0/22",
                   "185.64.176.0/22",
                   "185.66.224.0/21",
                   "185.67.12.0/22",
                   "185.67.100.0/22",
                   "185.67.156.0/22",
                   "185.67.212.0/22",
                   "185.69.108.0/22",
                   "185.70.60.0/22",
                   "185.71.152.0/22",
                   "185.71.192.0/22",
                   "185.72.24.0/22",
                   "185.72.80.0/22",
                   "185.73.0.0/22",
                   "185.73.76.0/22",
                   "185.73.112.0/24",
                   "185.73.114.0/24",
                   "185.73.226.0/24",
                   "185.74.164.0/22",
                   "185.74.221.0/24",
                   "185.75.196.0/22",
                   "185.75.204.0/22",
                   "185.76.248.0/22",
                   "185.78.20.0/22",
                   "185.79.60.0/22",
                   "185.79.96.0/22",
                   "185.79.156.0/22",
                   "185.80.100.0/22",
                   "185.80.198.0/23",
                   "185.81.40.0/22",
                   "185.81.96.0/23",
                   "185.81.99.0/24",
                   "185.82.28.0/22",
                   "185.82.64.0/22",
                   "185.82.136.0/22",
                   "185.82.164.0/22",
                   "185.82.180.0/22",
                   "185.83.28.0/22",
                   "185.83.76.0/22",
                   "185.83.80.0/22",
                   "185.83.88.0/22",
                   "185.83.112.0/24",
                   "185.83.114.0/23",
                   "185.83.180.0/22",
                   "185.83.184.0/22",
                   "185.83.196.0/22",
                   "185.83.208.0/22",
                   "185.84.220.0/22",
                   "185.85.68.0/22",
                   "185.85.136.0/22",
                   "185.86.36.0/22",
                   "185.86.180.0/22",
                   "185.88.48.0/22",
                   "185.88.152.0/22",
                   "185.88.176.0/22",
                   "185.88.252.0/22",
                   "185.89.22.0/24",
                   "185.89.112.0/22",
                   "185.92.4.0/22",
                   "185.92.8.0/22",
                   "185.92.40.0/22",
                   "185.94.96.0/23",
                   "185.94.98.0/24",
                   "185.94.99.0/25",
                   "185.94.99.136/29",
                   "185.94.99.144/28",
                   "185.94.99.160/27",
                   "185.94.99.192/26",
                   "185.95.60.0/22",
                   "185.95.152.0/22",
                   "185.95.180.0/22",
                   "185.96.240.0/22",
                   "185.97.116.0/22",
                   "185.98.112.0/22",
                   "185.99.212.0/22",
                   "185.100.44.0/22",
                   "185.101.228.0/22",
                   "185.103.84.0/22",
                   "185.103.128.0/22",
                   "185.103.244.0/22",
                   "185.103.248.0/22",
                   "185.104.192.0/24",
                   "185.104.228.0/22",
                   "185.104.232.0/22",
                   "185.104.240.0/22",
                   "185.105.100.0/22",
                   "185.105.120.0/22",
                   "185.105.184.0/22",
                   "185.105.236.0/22",
                   "185.106.136.0/22",
                   "185.106.144.0/22",
                   "185.106.200.0/22",
                   "185.106.228.0/22",
                   "185.107.28.0/22",
                   "185.107.32.0/23",
                   "185.107.244.0/22",
                   "185.107.248.0/22",
                   "185.108.96.0/22",
                   "185.108.164.0/22",
                   "185.109.60.0/22",
                   "185.109.72.0/22",
                   "185.109.80.0/22",
                   "185.109.128.0/22",
                   "185.109.244.0/22",
                   "185.109.248.0/22",
                   "185.110.28.0/22",
                   "185.110.216.0/22",
                   "185.110.228.0/22",
                   "185.110.236.0/22",
                   "185.110.244.0/22",
                   "185.110.252.0/22",
                   "185.111.8.0/21",
                   "185.111.64.0/22",
                   "185.111.80.0/22",
                   "185.111.136.0/22",
                   "185.112.32.0/21",
                   "185.112.130.0/23",
                   "185.112.148.0/22",
                   "185.112.168.0/22",
                   "185.113.56.0/22",
                   "185.113.112.0/22",
                   "185.114.188.0/22",
                   "185.115.76.0/22",
                   "185.115.148.0/22",
                   "185.115.168.0/22",
                   "185.116.20.0/22",
                   "185.116.24.0/22",
                   "185.116.44.0/22",
                   "185.116.160.0/22",
                   "185.117.48.0/22",
                   "185.117.136.0/22",
                   "185.117.204.0/23",
                   "185.117.206.0/24",
                   "185.118.12.0/22",
                   "185.118.136.0/22",
                   "185.118.152.0/22",
                   "185.119.4.0/22",
                   "185.119.164.0/22",
                   "185.119.240.0/22",
                   "185.120.120.0/22",
                   "185.120.136.0/22",
                   "185.120.160.0/22",
                   "185.120.168.0/22",
                   "185.120.192.0/21",
                   "185.120.200.0/22",
                   "185.120.208.0/20",
                   "185.120.224.0/20",
                   "185.120.240.0/21",
                   "185.120.248.0/22",
                   "185.121.56.0/22",
                   "185.121.128.0/22",
                   "185.122.80.0/22",
                   "185.123.68.0/22",
                   "185.123.208.0/22",
                   "185.124.112.0/22",
                   "185.124.156.0/22",
                   "185.124.172.0/22",
                   "185.125.20.0/22",
                   "185.125.244.0/22",
                   "185.125.248.0/21",
                   "185.126.0.0/20",
                   "185.126.16.0/22",
                   "185.126.40.0/22",
                   "185.126.132.0/23",
                   "185.126.200.0/22",
                   "185.127.232.0/22",
                   "185.128.40.0/24",
                   "185.128.48.0/22",
                   "185.128.80.0/22",
                   "185.128.136.0/22",
                   "185.128.152.0/22",
                   "185.128.164.0/22",
                   "185.129.80.0/22",
                   "185.129.168.0/22",
                   "185.129.184.0/21",
                   "185.129.196.0/22",
                   "185.129.200.0/22",
                   "185.129.212.0/22",
                   "185.129.216.0/22",
                   "185.129.228.0/22",
                   "185.129.232.0/21",
                   "185.129.240.0/22",
                   "185.130.76.0/22",
                   "185.131.28.0/22",
                   "185.131.84.0/22",
                   "185.131.88.0/21",
                   "185.131.100.0/22",
                   "185.131.108.0/22",
                   "185.131.112.0/21",
                   "185.131.124.0/22",
                   "185.131.128.0/22",
                   "185.131.136.0/21",
                   "185.131.148.0/22",
                   "185.131.152.0/21",
                   "185.131.164.0/22",
                   "185.131.168.0/22",
                   "185.132.80.0/22",
                   "185.132.212.0/22",
                   "185.133.152.0/22",
                   "185.133.164.0/22",
                   "185.133.244.0/23",
                   "185.133.246.0/24",
                   "185.134.96.0/22",
                   "185.135.28.0/22",
                   "185.135.228.0/22",
                   "185.136.100.0/22",
                   "185.136.172.0/22",
                   "185.136.180.0/22",
                   "185.136.192.0/22",
                   "185.136.220.0/22",
                   "185.137.24.0/22",
                   "185.137.60.0/22",
                   "185.137.108.0/23",
                   "185.137.110.0/24",
                   "185.139.64.0/22",
                   "185.140.4.0/22",
                   "185.140.56.0/22",
                   "185.140.232.0/22",
                   "185.140.240.0/22",
                   "185.141.36.0/22",
                   "185.141.48.0/22",
                   "185.141.104.0/22",
                   "185.141.132.0/22",
                   "185.141.168.0/22",
                   "185.141.212.0/22",
                   "185.141.244.0/22",
                   "185.142.92.0/22",
                   "185.142.124.0/22",
                   "185.142.156.0/22",
                   "185.142.232.0/22",
                   "185.143.72.0/22",
                   "185.143.204.0/22",
                   "185.143.232.0/22",
                   "185.144.64.0/22",
                   "185.145.8.0/22",
                   "185.145.184.0/22",
                   "185.147.40.0/22",
                   "185.147.84.0/22",
                   "185.147.160.0/22",
                   "185.147.176.0/22",
                   "185.149.192.0/24",
                   "185.150.108.0/22",
                   "185.153.184.0/22",
                   "185.153.208.0/22",
                   "185.154.184.0/22",
                   "185.155.8.0/21",
                   "185.155.72.0/22",
                   "185.155.236.0/22",
                   "185.157.8.0/22",
                   "185.158.172.0/22",
                   "185.159.152.0/22",
                   "185.159.176.0/22",
                   "185.159.189.0/24",
                   "185.160.104.0/22",
                   "185.160.176.0/22",
                   "185.161.36.0/22",
                   "185.161.112.0/22",
                   "185.162.40.0/22",
                   "185.162.216.0/22",
                   "185.163.88.0/22",
                   "185.164.73.0/24",
                   "185.164.74.0/23",
                   "185.164.252.0/22",
                   "185.165.28.0/22",
                   "185.165.40.0/22",
                   "185.165.100.0/22",
                   "185.165.116.0/22",
                   "185.165.204.0/22",
                   "185.166.60.0/22",
                   "185.166.104.0/22",
                   "185.166.112.0/22",
                   "185.167.72.0/22",
                   "185.167.100.0/22",
                   "185.167.124.0/22",
                   "185.168.28.0/22",
                   "185.169.6.0/24",
                   "185.169.20.0/22",
                   "185.169.36.0/22",
                   "185.170.8.0/24",
                   "185.170.236.0/22",
                   "185.171.52.0/22",
                   "185.172.0.0/22",
                   "185.172.68.0/22",
                   "185.172.212.0/22",
                   "185.173.104.0/22",
                   "185.173.129.0/24",
                   "185.173.130.0/24",
                   "185.173.168.0/22",
                   "185.174.132.0/24",
                   "185.174.134.0/24",
                   "185.174.200.0/22",
                   "185.174.248.0/22",
                   "185.175.76.0/22",
                   "185.175.240.0/22",
                   "185.176.32.0/22",
                   "185.176.56.0/22",
                   "185.177.156.0/22",
                   "185.177.232.0/22",
                   "185.178.104.0/22",
                   "185.178.220.0/22",
                   "185.179.90.0/24",
                   "185.179.168.0/22",
                   "185.179.220.0/22",
                   "185.180.52.0/22",
                   "185.180.128.0/22",
                   "185.181.180.0/22",
                   "185.182.220.0/22",
                   "185.182.248.0/22",
                   "185.184.32.0/22",
                   "185.184.48.0/22",
                   "185.185.16.0/22",
                   "185.185.240.0/22",
                   "185.186.48.0/22",
                   "185.186.240.0/22",
                   "185.187.48.0/22",
                   "185.187.84.0/22",
                   "185.188.104.0/22",
                   "185.188.112.0/22",
                   "185.189.120.0/22",
                   "185.190.20.0/22",
                   "185.190.25.128/25",
                   "185.190.39.0/24",
                   "185.191.76.0/22",
                   "185.192.8.0/22",
                   "185.192.112.0/22",
                   "185.193.47.0/24",
                   "185.193.208.0/22",
                   "185.194.76.0/22",
                   "185.194.244.0/22",
                   "185.195.72.0/22",
                   "185.196.148.0/22",
                   "185.197.68.0/22",
                   "185.197.112.0/22",
                   "185.198.160.0/22",
                   "185.199.64.0/22",
                   "185.199.208.0/24",
                   "185.199.210.0/23",
                   "185.201.48.0/22",
                   "185.202.56.0/22",
                   "185.203.160.0/22",
                   "185.204.180.0/22",
                   "185.204.197.0/24",
                   "185.205.203.0/24",
                   "185.205.220.0/22",
                   "185.206.92.0/22",
                   "185.206.229.0/24",
                   "185.206.231.0/24",
                   "185.206.236.0/22",
                   "185.207.52.0/22",
                   "185.207.72.0/22",
                   "185.208.76.0/22",
                   "185.208.148.0/22",
                   "185.208.174.0/23",
                   "185.208.180.0/22",
                   "185.209.188.0/22",
                   "185.210.200.0/22",
                   "185.211.56.0/22",
                   "185.211.84.0/22",
                   "185.211.88.0/22",
                   "185.212.48.0/22",
                   "185.212.192.0/22",
                   "185.213.8.0/22",
                   "185.213.164.0/22",
                   "185.213.195.0/24",
                   "185.214.36.0/22",
                   "185.215.124.0/22",
                   "185.215.152.0/22",
                   "185.215.228.0/22",
                   "185.215.232.0/22",
                   "185.218.139.0/24",
                   "185.219.112.0/22",
                   "185.220.224.0/22",
                   "185.221.112.0/22",
                   "185.221.192.0/22",
                   "185.221.239.0/24",
                   "185.222.120.0/22",
                   "185.222.180.0/22",
                   "185.222.184.0/22",
                   "185.222.210.0/24",
                   "185.223.160.0/24",
                   "185.224.176.0/22",
                   "185.225.80.0/22",
                   "185.225.180.0/22",
                   "185.225.240.0/22",
                   "185.226.97.0/24",
                   "185.226.116.0/22",
                   "185.226.132.0/22",
                   "185.226.140.0/22",
                   "185.227.64.0/22",
                   "185.227.116.0/22",
                   "185.228.236.0/22",
                   "185.228.238.0/28",
                   "185.229.0.0/22",
                   "185.229.28.0/22",
                   "185.229.204.0/24",
                   "185.231.65.0/24",
                   "185.231.112.0/22",
                   "185.231.180.0/22",
                   "185.232.152.0/22",
                   "185.232.176.0/22",
                   "185.233.12.0/22",
                   "185.233.84.0/22",
                   "185.233.131.0/24",
                   "185.234.14.0/24",
                   "185.234.192.0/22",
                   "185.235.136.0/24",
                   "185.235.138.0/23",
                   "185.235.245.0/24",
                   "185.236.36.0/22",
                   "185.236.45.0/24",
                   "185.236.88.0/22",
                   "185.237.8.0/22",
                   "185.237.84.0/22",
                   "185.238.20.0/22",
                   "185.238.44.0/22",
                   "185.238.92.0/22",
                   "185.238.140.0/24",
                   "185.238.143.0/24",
                   "185.239.0.0/22",
                   "185.239.104.0/22",
                   "185.240.56.0/22",
                   "185.240.148.0/22",
                   "185.243.48.0/22",
                   "185.244.52.0/22",
                   "185.246.4.0/22",
                   "185.248.32.0/24",
                   "185.251.76.0/22",
                   "185.252.28.0/22",
                   "185.252.200.0/24",
                   "185.254.165.0/24",
                   "185.254.166.0/24",
                   "185.255.68.0/22",
                   "185.255.88.0/22",
                   "185.255.208.0/22",
                   "188.0.240.0/20",
                   "188.75.64.0/18",
                   "188.94.188.0/24",
                   "188.95.89.0/24",
                   "188.118.64.0/18",
                   "188.121.96.0/19",
                   "188.121.128.0/19",
                   "188.122.96.0/19",
                   "188.136.128.0/18",
                   "188.136.192.0/19",
                   "188.158.0.0/16",
                   "188.159.112.0/20",
                   "188.159.128.0/18",
                   "188.159.192.0/19",
                   "188.191.176.0/21",
                   "188.208.56.0/21",
                   "188.208.64.0/19",
                   "188.208.144.0/20",
                   "188.208.160.0/19",
                   "188.208.200.0/22",
                   "188.208.208.0/21",
                   "188.208.224.0/19",
                   "188.209.0.0/19",
                   "188.209.32.0/20",
                   "188.209.64.0/20",
                   "188.209.116.0/22",
                   "188.209.152.0/23",
                   "188.209.192.0/20",
                   "188.210.64.0/20",
                   "188.210.80.0/21",
                   "188.210.96.0/19",
                   "188.210.128.0/18",
                   "188.210.192.0/20",
                   "188.210.232.0/22",
                   "188.211.0.0/20",
                   "188.211.32.0/19",
                   "188.211.64.0/18",
                   "188.211.128.0/19",
                   "188.211.176.0/20",
                   "188.211.192.0/19",
                   "188.212.22.0/24",
                   "188.212.48.0/20",
                   "188.212.64.0/19",
                   "188.212.96.0/22",
                   "188.212.144.0/21",
                   "188.212.160.0/19",
                   "188.212.200.0/21",
                   "188.212.208.0/20",
                   "188.212.224.0/20",
                   "188.212.240.0/21",
                   "188.213.64.0/20",
                   "188.213.96.0/19",
                   "188.213.144.0/20",
                   "188.213.176.0/20",
                   "188.213.192.0/21",
                   "188.213.208.0/22",
                   "188.214.4.0/22",
                   "188.214.84.0/22",
                   "188.214.96.0/22",
                   "188.214.120.0/23",
                   "188.214.160.0/19",
                   "188.214.216.0/21",
                   "188.215.24.0/22",
                   "188.215.88.0/22",
                   "188.215.128.0/20",
                   "188.215.160.0/19",
                   "188.215.192.0/19",
                   "188.215.240.0/22",
                   "188.229.0.0/17",
                   "188.240.196.0/24",
                   "188.240.212.0/24",
                   "188.240.248.0/21",
                   "188.253.2.0/23",
                   "188.253.32.0/21",
                   "188.253.40.0/24",
                   "188.253.42.0/23",
                   "188.253.44.0/22",
                   "188.253.48.0/20",
                   "188.253.64.0/19",
                   "192.15.0.0/16",
                   "192.167.140.66/32",
                   "193.0.156.0/24",
                   "193.3.31.0/24",
                   "193.3.182.0/24",
                   "193.3.231.0/24",
                   "193.3.255.0/24",
                   "193.8.139.0/24",
                   "193.19.144.0/23",
                   "193.22.20.0/24",
                   "193.28.181.0/24",
                   "193.29.24.0/24",
                   "193.29.26.0/24",
                   "193.32.80.0/23",
                   "193.34.244.0/22",
                   "193.35.62.0/24",
                   "193.35.230.0/24",
                   "193.38.247.0/24",
                   "193.39.9.0/24",
                   "193.56.59.0/24",
                   "193.56.61.0/24",
                   "193.56.107.0/24",
                   "193.56.118.0/24",
                   "193.104.22.0/24",
                   "193.104.29.0/24",
                   "193.104.212.0/24",
                   "193.105.2.0/24",
                   "193.105.6.0/24",
                   "193.105.234.0/24",
                   "193.106.190.0/24",
                   "193.107.48.0/24",
                   "193.108.242.0/23",
                   "193.111.234.0/23",
                   "193.134.100.0/23",
                   "193.141.64.0/23",
                   "193.141.126.0/23",
                   "193.142.30.0/24",
                   "193.142.232.0/23",
                   "193.142.254.0/23",
                   "193.148.64.0/22",
                   "193.150.66.0/24",
                   "193.151.128.0/19",
                   "193.162.129.0/24",
                   "193.176.240.0/22",
                   "193.178.200.0/22",
                   "193.186.4.40/30",
                   "193.186.32.0/24",
                   "193.189.122.0/23",
                   "193.200.102.0/23",
                   "193.200.148.0/24",
                   "193.201.72.0/23",
                   "193.201.192.0/22",
                   "193.222.51.0/24",
                   "193.228.90.0/23",
                   "193.228.136.0/24",
                   "193.240.187.76/30",
                   "193.240.207.0/28",
                   "193.242.194.0/23",
                   "193.242.208.0/23",
                   "193.246.160.0/23",
                   "193.246.164.0/23",
                   "193.246.174.0/23",
                   "193.246.200.0/23",
                   "194.5.40.0/22",
                   "194.5.175.0/24",
                   "194.5.176.0/22",
                   "194.5.188.0/24",
                   "194.5.195.0/24",
                   "194.5.205.0/24",
                   "194.9.56.0/23",
                   "194.9.80.0/23",
                   "194.24.160.161/32",
                   "194.24.160.162/31",
                   "194.26.2.0/23",
                   "194.26.20.0/23",
                   "194.26.117.0/24",
                   "194.26.195.0/24",
                   "194.31.108.0/24",
                   "194.31.194.0/24",
                   "194.33.104.0/22",
                   "194.33.122.0/23",
                   "194.33.124.0/22",
                   "194.34.163.0/24",
                   "194.36.0.0/24",
                   "194.36.174.0/24",
                   "194.39.36.0/22",
                   "194.41.48.0/22",
                   "194.50.204.0/24",
                   "194.50.209.0/24",
                   "194.50.216.0/24",
                   "194.50.218.0/24",
                   "194.53.118.0/23",
                   "194.53.122.0/23",
                   "194.56.148.0/24",
                   "194.59.170.0/23",
                   "194.59.214.0/23",
                   "194.60.208.0/22",
                   "194.60.228.0/22",
                   "194.62.17.0/24",
                   "194.62.43.0/24",
                   "194.143.140.0/23",
                   "194.146.148.0/22",
                   "194.146.239.0/24",
                   "194.147.164.0/22",
                   "194.147.212.0/24",
                   "194.147.222.0/24",
                   "194.150.68.0/22",
                   "194.156.140.0/22",
                   "194.180.224.0/24",
                   "194.225.0.0/16",
                   "195.2.234.0/24",
                   "195.8.102.0/24",
                   "195.8.110.0/24",
                   "195.8.112.0/24",
                   "195.8.114.0/24",
                   "195.20.136.0/24",
                   "195.27.14.0/29",
                   "195.28.10.0/23",
                   "195.28.168.0/23",
                   "195.88.188.0/23",
                   "195.96.128.0/24",
                   "195.96.135.0/24",
                   "195.96.153.0/24",
                   "195.110.38.0/23",
                   "195.114.4.0/23",
                   "195.114.8.0/23",
                   "195.146.32.0/19",
                   "195.181.0.0/17",
                   "195.182.38.0/24",
                   "195.190.130.0/24",
                   "195.190.139.0/24",
                   "195.190.144.0/24",
                   "195.191.22.0/23",
                   "195.191.44.0/23",
                   "195.191.74.0/23",
                   "195.211.44.0/22",
                   "195.214.235.0/24",
                   "195.217.44.172/30",
                   "195.219.71.0/24",
                   "195.225.232.0/24",
                   "195.226.223.0/24",
                   "195.230.97.0/24",
                   "195.230.105.0/24",
                   "195.230.107.0/24",
                   "195.230.124.0/24",
                   "195.234.191.0/24",
                   "195.238.231.0/24",
                   "195.238.240.0/24",
                   "195.238.247.0/24",
                   "195.245.70.0/23",
                   "196.3.91.0/24",
                   "196.197.103.0/24",
                   "196.198.103.0/24",
                   "196.199.103.0/24",
                   "204.18.0.0/16",
                   "204.245.22.24/30",
                   "204.245.22.29/32",
                   "204.245.22.30/31",
                   "209.28.123.0/26",
                   "210.5.196.64/26",
                   "210.5.197.64/26",
                   "210.5.198.32/29",
                   "210.5.198.64/28",
                   "210.5.198.96/27",
                   "210.5.198.128/26",
                   "210.5.198.192/27",
                   "210.5.204.0/25",
                   "210.5.205.0/26",
                   "210.5.208.0/26",
                   "210.5.208.128/25",
                   "210.5.209.0/25",
                   "210.5.214.192/26",
                   "210.5.218.64/26",
                   "210.5.218.128/25",
                   "210.5.232.0/25",
                   "210.5.233.0/25",
                   "210.5.233.128/26",
                   "212.1.192.0/21",
                   "212.16.64.0/19",
                   "212.18.108.0/24",
                   "212.23.201.0/24",
                   "212.23.214.0/24",
                   "212.23.216.0/24",
                   "212.33.192.0/19",
                   "212.46.45.0/24",
                   "212.73.88.0/24",
                   "212.80.0.0/19",
                   "212.86.64.0/19",
                   "212.120.146.128/29",
                   "212.120.192.0/19",
                   "212.151.26.66/32",
                   "212.151.53.58/32",
                   "212.151.56.189/32",
                   "212.151.60.189/32",
                   "212.151.177.130/32",
                   "212.151.182.155/32",
                   "212.151.182.156/31",
                   "212.151.186.154/31",
                   "212.151.186.156/32",
                   "212.214.49.106/32",
                   "212.214.51.140/32",
                   "212.214.52.240/32",
                   "212.214.72.62/32",
                   "212.214.72.160/32",
                   "212.214.145.178/32",
                   "212.214.151.192/32",
                   "212.214.224.216/32",
                   "212.214.233.144/32",
                   "212.214.234.126/32",
                   "212.214.234.194/32",
                   "212.214.235.126/32",
                   "212.214.235.228/32",
                   "213.50.17.236/32",
                   "213.50.20.144/32",
                   "213.50.44.228/32",
                   "213.50.56.86/32",
                   "213.50.56.92/32",
                   "213.50.58.18/32",
                   "213.50.61.198/32",
                   "213.50.97.76/32",
                   "213.50.144.4/32",
                   "213.50.144.92/32",
                   "213.50.147.82/32",
                   "213.50.147.88/32",
                   "213.50.148.8/32",
                   "213.50.169.225/32",
                   "213.50.186.36/32",
                   "213.50.188.76/32",
                   "213.50.216.216/32",
                   "213.50.236.46/32",
                   "213.50.236.88/32",
                   "213.88.162.204/32",
                   "213.108.240.0/23",
                   "213.108.242.0/24",
                   "213.109.199.0/24",
                   "213.109.240.0/20",
                   "213.131.137.154/32",
                   "213.168.224.216/30",
                   "213.168.240.96/29",
                   "213.176.0.0/20",
                   "213.176.16.0/21",
                   "213.176.28.0/22",
                   "213.176.64.0/18",
                   "213.195.0.0/20",
                   "213.195.16.0/21",
                   "213.195.32.0/19",
                   "213.207.192.0/18",
                   "213.217.32.0/19",
                   "213.232.124.0/22",
                   "213.233.160.0/19",
                   "217.11.16.0/20",
                   "217.24.144.0/20",
                   "217.25.48.0/20",
                   "217.60.0.0/16",
                   "217.66.192.0/19",
                   "217.77.112.0/20",
                   "217.114.40.0/24",
                   "217.114.46.0/24",
                   "217.144.104.0/22",
                   "217.146.208.0/20",
                   "217.161.16.0/24",
                   "217.170.240.0/20",
                   "217.171.145.0/24",
                   "217.171.148.0/22",
                   "217.171.191.220/30",
                   "217.172.98.0/23",
                   "217.172.102.0/23",
                   "217.172.104.0/21",
                   "217.172.112.0/22",
                   "217.172.116.0/23",
                   "217.172.118.0/24",
                   "217.172.120.0/21",
                   "217.174.16.0/20",
                   "217.198.190.0/24",
                   "217.218.0.0/16",
                   "217.219.0.0/17",
                   "217.219.128.0/18",
                   "217.219.192.0/21",
                   "217.219.200.0/22",
                   "217.219.204.0/24",
                   "217.219.205.64/26",
                   "217.219.205.128/25",
                   "217.219.206.0/23",
                   "217.219.208.0/20",
                   "217.219.224.0/19",
                   "192.168.0.0/16",
                   "10.0.0.0/8",
                   "172.16.0.0/12",
                   "127.0.0.0/8",
                   "100.64.0.0/10"
                ]
             }
          ],
          "auto_detect_interface":true
       }
}
EOL
}

configureXray() {
    echo "========================================================================="
    echo "|                         Configuring xray                              |"
    echo "========================================================================="
    
    # We check whether user has provided custom UUID or not.
	# If not, we will generate a random UUID.
	if [ ! -v realityUUID ]; then
        realityUUID=$(./xray uuid -i $(generateRandom password))
        fi

    # We check whether user has provided custom public & private key or not.
    # If one or both of them are missing, generate a new public and private key.
    if [ ! -v $realityPrivateKey || ! -v $realityPublicKey ]; then
        # We generate public and private keys and temporarily save them.
        local temp=$(./xray x25519)
        # We extract private key
        local temp2="${temp#Private key: }"
        realityPrivateKey=`echo "${temp2}" | head -1`
        # We extract the public key
        local temp3="${temp2#$privatekey}"
        realityPublicKey="${temp3#*Public key: }"
        fi

    # We check whether user has provided custom short ID or not.
    # If not, we will generate a random short ID.
    if [ ! -v $realityShortID ]; then
        # We generate a short id.
        realityShortID=$(openssl rand -hex 8)
        fi

    # We restart the service and enable auto-start.
    sudo systemctl daemon-reload && sudo systemctl enable xray

    # We store the path of the 'config.json' file.
    local configfile=/home/$tempNewAccUsername/xray/config.json

    cat > $configfile << EOL
    {
       "log":{
          "loglevel":"warning"
       },
       "policy":{
          "levels":{
             "0":{
                "handshake":3,
                "connIdle":180
             }
          }
       },
       "inbounds":[
          {
             "listen":"0.0.0.0",
             "port":$tunnelPort,
             "protocol":"vless",
             "settings":{
                "clients":[
                   {
                      "id":"$realityUUID",
                      "flow":"xtls-rprx-vision"
                   }
                ],
                "decryption":"none"
             },
             "streamSettings":{
                "network":"tcp",
                "security":"reality",
                "realitySettings":{
                   "show":false,
                   "dest":"www.google-analytics.com:$tunnelPort",
                   "xver":0,
                   "serverNames":[
                      "www.google-analytics.com"
                   ],
                   "privateKey":"$realityPrivateKey",
                   "minClientVer":"1.8.0",
                   "maxClientVer":"",
                   "maxTimeDiff":0,
                   "shortIds":[
                      "$realityShortID"
                   ]
                }
             },
             "sniffing":{
                "enabled":true,
                "destOverride":[
                   "http",
                   "tls",
                   "quic"
                ]
             }
          }
       ],
       "routing":{
          "domainStrategy":"IPIfNonMatch",
          "rules":[
             {
                "type":"field",
                "outboundTag":"block",
                "ip":[
                   "geoip:ir",
                   "geoip:private",
                   "2.144.0.0/14",
                   "2.176.0.0/12",
                   "5.1.43.0/24",
                   "5.22.0.0/17",
                   "5.22.192.0/21",
                   "5.22.200.0/22",
                   "5.23.112.0/21",
                   "5.34.192.0/20",
                   "5.42.217.0/24",
                   "5.42.223.0/24",
                   "5.52.0.0/16",
                   "5.53.32.0/19",
                   "5.56.128.0/22",
                   "5.56.132.0/24",
                   "5.56.134.0/23",
                   "5.57.32.0/21",
                   "5.61.24.0/23",
                   "5.61.26.0/24",
                   "5.61.28.0/22",
                   "5.62.160.0/19",
                   "5.62.192.0/18",
                   "5.63.8.0/21",
                   "5.72.0.0/15",
                   "5.74.0.0/16",
                   "5.75.0.0/17",
                   "5.104.208.0/21",
                   "5.106.0.0/16",
                   "5.112.0.0/12",
                   "5.134.128.0/18",
                   "5.134.192.0/21",
                   "5.135.116.200/30",
                   "5.144.128.0/21",
                   "5.145.112.0/22",
                   "5.145.116.0/24",
                   "5.159.48.0/21",
                   "5.160.0.0/16",
                   "5.182.44.0/22",
                   "5.190.0.0/16",
                   "5.198.160.0/19",
                   "5.200.64.0/18",
                   "5.200.128.0/17",
                   "5.201.128.0/17",
                   "5.202.0.0/16",
                   "5.208.0.0/12",
                   "5.213.255.36/31",
                   "5.232.0.0/14",
                   "5.236.0.0/17",
                   "5.236.128.0/20",
                   "5.236.144.0/21",
                   "5.236.156.0/22",
                   "5.236.160.0/19",
                   "5.236.192.0/18",
                   "5.237.0.0/16",
                   "5.238.0.0/15",
                   "5.250.0.0/17",
                   "5.252.216.0/22",
                   "5.253.24.0/22",
                   "5.253.96.0/22",
                   "5.253.225.0/24",
                   "8.27.67.32/32",
                   "8.27.67.41/32",
                   "31.2.128.0/17",
                   "31.7.64.0/21",
                   "31.7.72.0/22",
                   "31.7.76.0/23",
                   "31.7.88.0/22",
                   "31.7.96.0/19",
                   "31.7.128.0/20",
                   "31.14.80.0/20",
                   "31.14.112.0/20",
                   "31.14.144.0/20",
                   "31.24.85.64/27",
                   "31.24.200.0/21",
                   "31.24.232.0/21",
                   "31.25.90.0/23",
                   "31.25.92.0/22",
                   "31.25.104.0/21",
                   "31.25.128.0/21",
                   "31.25.232.0/23",
                   "31.40.0.0/22",
                   "31.40.4.0/24",
                   "31.41.35.0/24",
                   "31.47.32.0/19",
                   "31.56.0.0/14",
                   "31.130.176.0/20",
                   "31.170.48.0/22",
                   "31.170.52.0/23",
                   "31.170.54.0/24",
                   "31.170.56.0/21",
                   "31.171.216.0/21",
                   "31.184.128.0/18",
                   "31.193.112.0/21",
                   "31.193.186.0/24",
                   "31.214.132.0/23",
                   "31.214.146.0/23",
                   "31.214.154.0/24",
                   "31.214.168.0/21",
                   "31.214.200.0/23",
                   "31.214.228.0/22",
                   "31.214.248.0/21",
                   "31.216.62.0/24",
                   "31.217.208.0/21",
                   "37.9.248.0/21",
                   "37.10.64.0/22",
                   "37.10.109.0/24",
                   "37.10.117.0/24",
                   "37.19.80.0/20",
                   "37.32.0.0/19",
                   "37.32.16.0/27",
                   "37.32.17.0/27",
                   "37.32.18.0/27",
                   "37.32.19.0/27",
                   "37.32.32.0/20",
                   "37.32.112.0/20",
                   "37.44.56.0/21",
                   "37.63.128.0/17",
                   "37.75.240.0/21",
                   "37.98.0.0/17",
                   "37.114.192.0/18",
                   "37.129.0.0/16",
                   "37.130.200.0/21",
                   "37.137.0.0/16",
                   "37.143.144.0/21",
                   "37.148.0.0/17",
                   "37.148.248.0/22",
                   "37.152.160.0/19",
                   "37.153.128.0/22",
                   "37.153.176.0/20",
                   "37.156.0.0/22",
                   "37.156.8.0/21",
                   "37.156.16.0/20",
                   "37.156.48.0/20",
                   "37.156.100.0/22",
                   "37.156.112.0/20",
                   "37.156.128.0/20",
                   "37.156.144.0/22",
                   "37.156.152.0/21",
                   "37.156.160.0/21",
                   "37.156.176.0/22",
                   "37.156.212.0/22",
                   "37.156.232.0/21",
                   "37.156.240.0/22",
                   "37.156.248.0/22",
                   "37.191.64.0/19",
                   "37.202.128.0/17",
                   "37.221.0.0/18",
                   "37.228.131.0/24",
                   "37.228.133.0/24",
                   "37.228.135.0/24",
                   "37.228.136.0/22",
                   "37.235.16.0/20",
                   "37.254.0.0/16",
                   "37.255.0.0/17",
                   "37.255.128.0/26",
                   "37.255.128.64/27",
                   "37.255.128.96/28",
                   "37.255.128.128/25",
                   "37.255.129.0/24",
                   "37.255.130.0/23",
                   "37.255.132.0/22",
                   "37.255.136.0/21",
                   "37.255.144.0/20",
                   "37.255.160.0/19",
                   "37.255.192.0/18",
                   "45.8.160.0/22",
                   "45.9.144.0/22",
                   "45.9.252.0/22",
                   "45.15.200.0/22",
                   "45.15.248.0/22",
                   "45.81.16.0/22",
                   "45.82.136.0/22",
                   "45.84.156.0/22",
                   "45.84.248.0/22",
                   "45.86.4.0/22",
                   "45.86.87.0/24",
                   "45.86.196.0/22",
                   "45.87.4.0/22",
                   "45.89.136.0/22",
                   "45.89.200.0/22",
                   "45.89.236.0/22",
                   "45.90.72.0/22",
                   "45.91.152.0/22",
                   "45.92.92.0/22",
                   "45.94.212.0/22",
                   "45.94.252.0/22",
                   "45.128.140.0/22",
                   "45.129.36.0/22",
                   "45.129.116.0/22",
                   "45.132.32.0/24",
                   "45.132.168.0/21",
                   "45.135.240.0/22",
                   "45.138.132.0/22",
                   "45.139.9.0/24",
                   "45.139.10.0/23",
                   "45.139.100.0/22",
                   "45.140.28.0/22",
                   "45.140.224.0/21",
                   "45.142.188.0/22",
                   "45.144.16.0/22",
                   "45.144.124.0/22",
                   "45.147.76.0/22",
                   "45.148.248.0/22",
                   "45.149.76.0/22",
                   "45.150.88.0/22",
                   "45.150.150.0/24",
                   "45.155.192.0/22",
                   "45.156.180.0/22",
                   "45.156.184.0/22",
                   "45.156.192.0/21",
                   "45.156.200.0/22",
                   "45.157.244.0/22",
                   "45.158.120.0/22",
                   "45.159.112.0/22",
                   "45.159.148.0/22",
                   "45.159.196.0/22",
                   "46.18.248.0/21",
                   "46.21.80.0/20",
                   "46.28.72.0/21",
                   "46.32.0.0/19",
                   "46.34.96.0/19",
                   "46.34.160.0/19",
                   "46.36.96.0/20",
                   "46.38.128.0/23",
                   "46.38.130.0/24",
                   "46.38.131.0/25",
                   "46.38.131.128/26",
                   "46.38.132.0/22",
                   "46.38.136.0/21",
                   "46.38.144.0/20",
                   "46.41.192.0/18",
                   "46.51.0.0/17",
                   "46.62.128.0/17",
                   "46.100.0.0/16",
                   "46.102.120.0/21",
                   "46.102.128.0/20",
                   "46.102.184.0/22",
                   "46.143.0.0/17",
                   "46.143.204.0/22",
                   "46.143.208.0/21",
                   "46.143.244.0/22",
                   "46.143.248.0/22",
                   "46.148.32.0/20",
                   "46.164.64.0/18",
                   "46.167.128.0/19",
                   "46.182.32.0/21",
                   "46.209.0.0/16",
                   "46.224.0.0/15",
                   "46.235.76.0/23",
                   "46.245.0.0/17",
                   "46.248.32.0/19",
                   "46.249.96.0/24",
                   "46.249.120.0/21",
                   "46.251.224.0/25",
                   "46.251.224.128/28",
                   "46.251.224.144/29",
                   "46.251.226.0/24",
                   "46.251.237.0/24",
                   "46.255.216.0/21",
                   "62.3.14.0/24",
                   "62.3.41.0/24",
                   "62.3.42.0/24",
                   "62.32.49.128/26",
                   "62.32.49.192/27",
                   "62.32.49.224/29",
                   "62.32.49.240/28",
                   "62.32.50.0/24",
                   "62.32.53.64/26",
                   "62.32.53.168/29",
                   "62.32.53.224/28",
                   "62.32.61.96/27",
                   "62.32.61.224/27",
                   "62.32.63.128/26",
                   "62.60.128.0/22",
                   "62.60.136.0/21",
                   "62.60.144.0/22",
                   "62.60.152.0/21",
                   "62.60.160.0/22",
                   "62.60.196.0/22",
                   "62.60.208.0/20",
                   "62.95.84.234/32",
                   "62.95.85.246/32",
                   "62.95.100.236/32",
                   "62.95.103.210/32",
                   "62.95.117.78/32",
                   "62.95.119.76/32",
                   "62.102.128.0/20",
                   "62.133.46.0/24",
                   "62.193.0.0/19",
                   "62.204.61.0/24",
                   "62.220.96.0/19",
                   "63.243.185.0/24",
                   "64.214.116.16/32",
                   "66.79.96.0/19",
                   "67.16.178.147/32",
                   "67.16.178.148/31",
                   "67.16.178.150/32",
                   "69.194.64.0/18",
                   "72.14.201.40/30",
                   "77.36.128.0/17",
                   "77.42.0.0/17",
                   "77.77.64.0/18",
                   "77.81.32.0/20",
                   "77.81.76.0/24",
                   "77.81.78.0/24",
                   "77.81.82.0/23",
                   "77.81.128.0/21",
                   "77.81.144.0/20",
                   "77.81.192.0/19",
                   "77.90.139.180/30",
                   "77.95.220.0/24",
                   "77.104.64.0/18",
                   "77.237.64.0/19",
                   "77.237.160.0/19",
                   "77.238.104.0/21",
                   "77.238.112.0/20",
                   "77.245.224.0/20",
                   "78.31.232.0/22",
                   "78.38.0.0/15",
                   "78.47.208.144/28",
                   "78.109.192.0/20",
                   "78.110.112.0/20",
                   "78.111.0.0/20",
                   "78.154.32.0/19",
                   "78.157.32.0/19",
                   "78.158.160.0/19",
                   "79.127.0.0/17",
                   "79.132.192.0/23",
                   "79.132.200.0/21",
                   "79.132.208.0/20",
                   "79.143.84.0/23",
                   "79.143.86.0/24",
                   "79.174.160.0/21",
                   "79.175.128.0/19",
                   "79.175.160.0/22",
                   "79.175.164.0/23",
                   "79.175.166.0/24",
                   "79.175.167.0/25",
                   "79.175.167.128/30",
                   "79.175.167.132/31",
                   "79.175.167.144/28",
                   "79.175.167.160/27",
                   "79.175.167.192/26",
                   "79.175.168.0/21",
                   "79.175.176.0/20",
                   "80.66.176.0/20",
                   "80.71.112.0/20",
                   "80.71.149.0/24",
                   "80.75.0.0/20",
                   "80.85.82.80/29",
                   "80.91.208.0/24",
                   "80.191.0.0/17",
                   "80.191.128.0/18",
                   "80.191.192.0/19",
                   "80.191.224.0/20",
                   "80.191.240.0/24",
                   "80.191.241.128/25",
                   "80.191.242.0/23",
                   "80.191.244.0/22",
                   "80.191.248.0/21",
                   "80.210.0.0/18",
                   "80.210.128.0/17",
                   "80.241.70.250/31",
                   "80.242.0.0/20",
                   "80.249.112.0/22",
                   "80.250.192.0/20",
                   "80.253.128.0/19",
                   "80.255.3.160/27",
                   "81.12.0.0/17",
                   "81.12.28.16/29",
                   "81.16.112.0/20",
                   "81.28.32.0/19",
                   "81.29.240.0/20",
                   "81.31.160.0/19",
                   "81.31.224.0/22",
                   "81.31.228.0/23",
                   "81.31.230.0/24",
                   "81.31.233.0/24",
                   "81.31.234.0/23",
                   "81.31.236.0/22",
                   "81.31.240.0/23",
                   "81.31.248.0/22",
                   "81.90.144.0/20",
                   "81.91.128.0/19",
                   "81.92.216.0/24",
                   "81.163.0.0/21",
                   "82.97.240.0/20",
                   "82.99.192.0/18",
                   "82.138.140.0/25",
                   "82.180.192.0/18",
                   "82.198.136.76/30",
                   "83.120.0.0/14",
                   "83.123.255.56/31",
                   "83.147.192.0/23",
                   "83.147.194.0/24",
                   "83.147.222.0/23",
                   "83.147.240.0/22",
                   "83.147.252.0/24",
                   "83.147.254.0/24",
                   "83.149.208.65/32",
                   "83.150.192.0/22",
                   "84.17.168.32/27",
                   "84.47.192.0/18",
                   "84.241.0.0/18",
                   "85.9.64.0/18",
                   "85.15.0.0/18",
                   "85.133.128.0/21",
                   "85.133.137.0/24",
                   "85.133.138.0/23",
                   "85.133.140.0/22",
                   "85.133.144.0/23",
                   "85.133.147.0/24",
                   "85.133.148.0/22",
                   "85.133.152.0/21",
                   "85.133.160.0/22",
                   "85.133.165.0/24",
                   "85.133.166.0/23",
                   "85.133.168.0/21",
                   "85.133.176.0/20",
                   "85.133.192.0/21",
                   "85.133.200.0/23",
                   "85.133.203.0/24",
                   "85.133.204.0/22",
                   "85.133.208.0/21",
                   "85.133.216.0/23",
                   "85.133.219.0/24",
                   "85.133.220.0/23",
                   "85.133.223.0/24",
                   "85.133.224.0/24",
                   "85.133.226.0/23",
                   "85.133.228.0/22",
                   "85.133.232.0/22",
                   "85.133.237.0/24",
                   "85.133.238.0/23",
                   "85.133.240.0/20",
                   "85.185.0.0/16",
                   "85.198.0.0/19",
                   "85.198.48.0/20",
                   "85.204.30.0/23",
                   "85.204.76.0/23",
                   "85.204.80.0/20",
                   "85.204.104.0/23",
                   "85.204.128.0/22",
                   "85.204.208.0/20",
                   "85.208.252.0/22",
                   "85.239.192.0/19",
                   "86.55.0.0/16",
                   "86.57.0.0/17",
                   "86.104.32.0/20",
                   "86.104.80.0/20",
                   "86.104.96.0/20",
                   "86.104.232.0/21",
                   "86.104.240.0/21",
                   "86.105.40.0/21",
                   "86.105.128.0/20",
                   "86.106.142.0/24",
                   "86.106.192.0/21",
                   "86.107.0.0/20",
                   "86.107.80.0/20",
                   "86.107.144.0/20",
                   "86.107.172.0/22",
                   "86.107.208.0/20",
                   "86.109.32.0/19",
                   "87.107.0.0/16",
                   "87.128.22.75/32",
                   "87.236.208.0/26",
                   "87.236.209.0/24",
                   "87.236.210.0/23",
                   "87.236.213.0/24",
                   "87.236.214.0/24",
                   "87.247.168.0/21",
                   "87.247.176.0/20",
                   "87.248.128.0/24",
                   "87.248.139.0/24",
                   "87.248.140.0/23",
                   "87.248.142.0/24",
                   "87.248.147.0/24",
                   "87.248.150.0/24",
                   "87.248.152.0/22",
                   "87.248.156.0/24",
                   "87.248.159.0/24",
                   "87.251.128.0/19",
                   "87.252.206.24/29",
                   "87.252.206.64/29",
                   "88.131.151.198/32",
                   "88.131.172.60/32",
                   "88.131.205.98/32",
                   "88.131.233.244/32",
                   "88.131.234.222/32",
                   "88.131.235.24/32",
                   "88.131.240.122/31",
                   "88.135.32.0/20",
                   "88.135.68.0/24",
                   "89.32.0.0/19",
                   "89.32.96.0/20",
                   "89.32.196.0/23",
                   "89.32.248.0/22",
                   "89.33.18.0/23",
                   "89.33.100.0/22",
                   "89.33.128.0/23",
                   "89.33.204.0/23",
                   "89.33.234.0/23",
                   "89.33.240.0/23",
                   "89.34.20.0/23",
                   "89.34.32.0/19",
                   "89.34.88.0/23",
                   "89.34.94.0/23",
                   "89.34.128.0/19",
                   "89.34.168.0/23",
                   "89.34.176.0/23",
                   "89.34.200.0/23",
                   "89.34.248.0/21",
                   "89.35.58.0/23",
                   "89.35.68.0/22",
                   "89.35.120.0/22",
                   "89.35.132.0/23",
                   "89.35.156.0/23",
                   "89.35.176.0/23",
                   "89.35.180.0/22",
                   "89.35.194.0/23",
                   "89.36.16.0/23",
                   "89.36.48.0/20",
                   "89.36.96.0/20",
                   "89.36.176.0/20",
                   "89.36.194.0/23",
                   "89.36.226.0/23",
                   "89.36.252.0/23",
                   "89.37.0.0/20",
                   "89.37.30.0/23",
                   "89.37.42.0/23",
                   "89.37.102.0/23",
                   "89.37.144.0/21",
                   "89.37.152.0/22",
                   "89.37.168.0/22",
                   "89.37.198.0/23",
                   "89.37.208.0/22",
                   "89.37.218.0/23",
                   "89.37.240.0/20",
                   "89.38.24.0/23",
                   "89.38.80.0/20",
                   "89.38.102.0/23",
                   "89.38.184.0/21",
                   "89.38.192.0/21",
                   "89.38.212.0/22",
                   "89.38.242.0/23",
                   "89.38.244.0/22",
                   "89.39.8.0/22",
                   "89.39.186.0/23",
                   "89.39.208.0/24",
                   "89.40.78.0/23",
                   "89.40.106.0/23",
                   "89.40.110.0/23",
                   "89.40.128.0/23",
                   "89.40.152.0/21",
                   "89.40.240.0/20",
                   "89.41.8.0/21",
                   "89.41.16.0/21",
                   "89.41.32.0/23",
                   "89.41.40.0/22",
                   "89.41.58.0/23",
                   "89.41.184.0/22",
                   "89.41.192.0/19",
                   "89.41.240.0/21",
                   "89.42.32.0/23",
                   "89.42.44.0/22",
                   "89.42.56.0/23",
                   "89.42.68.0/23",
                   "89.42.96.0/21",
                   "89.42.136.0/22",
                   "89.42.150.0/23",
                   "89.42.184.0/21",
                   "89.42.196.0/22",
                   "89.42.208.0/23",
                   "89.42.210.0/25",
                   "89.42.210.128/27",
                   "89.42.210.160/28",
                   "89.42.210.176/29",
                   "89.42.210.184/30",
                   "89.42.210.188/32",
                   "89.42.210.190/31",
                   "89.42.210.192/26",
                   "89.42.211.0/24",
                   "89.42.228.0/23",
                   "89.43.0.0/20",
                   "89.43.36.0/23",
                   "89.43.70.0/23",
                   "89.43.88.0/21",
                   "89.43.96.0/21",
                   "89.43.144.0/21",
                   "89.43.182.0/23",
                   "89.43.188.0/23",
                   "89.43.204.0/23",
                   "89.43.216.0/21",
                   "89.43.224.0/21",
                   "89.44.112.0/23",
                   "89.44.118.0/23",
                   "89.44.128.0/21",
                   "89.44.146.0/23",
                   "89.44.176.0/21",
                   "89.44.190.0/23",
                   "89.44.202.0/23",
                   "89.44.240.0/22",
                   "89.45.48.0/20",
                   "89.45.68.0/23",
                   "89.45.80.0/23",
                   "89.45.89.0/24",
                   "89.45.112.0/21",
                   "89.45.126.0/23",
                   "89.45.152.0/21",
                   "89.45.230.0/23",
                   "89.46.44.0/23",
                   "89.46.60.0/23",
                   "89.46.94.0/23",
                   "89.46.184.0/21",
                   "89.46.216.0/22",
                   "89.47.64.0/20",
                   "89.47.128.0/19",
                   "89.47.196.0/22",
                   "89.47.200.0/22",
                   "89.144.128.0/18",
                   "89.165.0.0/17",
                   "89.196.0.0/16",
                   "89.198.0.0/15",
                   "89.219.64.0/18",
                   "89.219.192.0/18",
                   "89.221.80.0/20",
                   "89.235.64.0/18",
                   "91.92.104.0/24",
                   "91.92.114.0/24",
                   "91.92.121.0/24",
                   "91.92.122.0/23",
                   "91.92.124.0/22",
                   "91.92.129.0/24",
                   "91.92.130.0/23",
                   "91.92.132.0/22",
                   "91.92.145.0/24",
                   "91.92.146.0/23",
                   "91.92.148.0/22",
                   "91.92.156.0/22",
                   "91.92.164.0/22",
                   "91.92.172.0/22",
                   "91.92.180.0/22",
                   "91.92.184.0/21",
                   "91.92.192.0/23",
                   "91.92.204.0/22",
                   "91.92.208.0/21",
                   "91.92.220.0/22",
                   "91.92.228.0/23",
                   "91.92.231.0/24",
                   "91.92.236.0/22",
                   "91.98.0.0/15",
                   "91.106.64.0/19",
                   "91.108.128.0/19",
                   "91.109.104.0/21",
                   "91.129.4.216/32",
                   "91.129.18.175/32",
                   "91.129.18.177/32",
                   "91.129.27.160/31",
                   "91.129.27.186/31",
                   "91.129.27.188/31",
                   "91.133.128.0/17",
                   "91.147.64.0/20",
                   "91.184.64.0/19",
                   "91.185.128.0/19",
                   "91.186.192.0/23",
                   "91.186.201.0/24",
                   "91.186.216.0/23",
                   "91.186.218.0/24",
                   "91.194.6.0/24",
                   "91.199.9.0/24",
                   "91.199.18.0/24",
                   "91.199.27.0/24",
                   "91.199.30.0/24",
                   "91.207.138.0/23",
                   "91.207.205.0/24",
                   "91.208.165.0/24",
                   "91.209.96.0/24",
                   "91.209.179.0/24",
                   "91.209.183.0/24",
                   "91.209.184.0/24",
                   "91.209.186.0/24",
                   "91.209.242.0/24",
                   "91.212.16.0/24",
                   "91.212.252.0/24",
                   "91.213.151.0/24",
                   "91.213.157.0/24",
                   "91.213.167.0/24",
                   "91.213.172.0/24",
                   "91.216.4.0/24",
                   "91.217.64.0/23",
                   "91.217.177.0/24",
                   "91.220.79.0/24",
                   "91.220.113.0/24",
                   "91.220.243.0/24",
                   "91.221.240.0/23",
                   "91.222.196.0/22",
                   "91.222.204.0/22",
                   "91.224.20.0/23",
                   "91.224.110.0/23",
                   "91.224.176.0/23",
                   "91.225.52.0/22",
                   "91.226.224.0/23",
                   "91.227.84.0/22",
                   "91.227.246.0/23",
                   "91.228.22.0/23",
                   "91.228.132.0/23",
                   "91.228.189.0/24",
                   "91.229.46.0/23",
                   "91.229.214.0/23",
                   "91.230.32.0/24",
                   "91.232.64.0/22",
                   "91.232.68.0/23",
                   "91.232.72.0/22",
                   "91.233.56.0/22",
                   "91.234.52.0/24",
                   "91.236.168.0/23",
                   "91.237.254.0/23",
                   "91.238.0.0/24",
                   "91.239.14.0/24",
                   "91.239.108.0/22",
                   "91.239.210.0/24",
                   "91.239.214.0/24",
                   "91.240.60.0/22",
                   "91.240.116.0/24",
                   "91.240.180.0/22",
                   "91.241.20.0/23",
                   "91.241.92.0/24",
                   "91.242.44.0/23",
                   "91.243.126.0/23",
                   "91.243.160.0/20",
                   "91.244.120.0/22",
                   "91.245.228.0/22",
                   "91.246.44.0/24",
                   "91.247.66.0/23",
                   "91.247.171.0/24",
                   "91.247.174.0/24",
                   "91.250.224.0/20",
                   "91.251.0.0/16",
                   "92.42.48.0/21",
                   "92.43.160.0/22",
                   "92.61.176.0/20",
                   "92.114.16.0/20",
                   "92.114.16.80/28",
                   "92.114.48.0/22",
                   "92.114.64.0/20",
                   "92.119.57.0/24",
                   "92.119.58.0/24",
                   "92.119.68.0/22",
                   "92.242.192.0/19",
                   "92.246.144.0/22",
                   "92.246.156.0/22",
                   "92.249.56.0/22",
                   "93.88.64.0/21",
                   "93.88.72.0/23",
                   "93.93.204.0/24",
                   "93.110.0.0/16",
                   "93.113.224.0/20",
                   "93.114.16.0/20",
                   "93.114.104.0/21",
                   "93.115.120.0/21",
                   "93.115.144.0/21",
                   "93.115.216.0/21",
                   "93.115.224.0/20",
                   "93.117.0.0/19",
                   "93.117.32.0/20",
                   "93.117.96.0/19",
                   "93.117.176.0/20",
                   "93.118.96.0/19",
                   "93.118.128.0/19",
                   "93.118.160.0/20",
                   "93.118.180.0/22",
                   "93.118.184.0/22",
                   "93.119.32.0/19",
                   "93.119.64.0/19",
                   "93.119.208.0/20",
                   "93.126.0.0/18",
                   "93.190.24.0/21",
                   "94.24.0.0/20",
                   "94.24.16.0/21",
                   "94.24.80.0/20",
                   "94.24.96.0/21",
                   "94.74.128.0/23",
                   "94.74.130.1/32",
                   "94.74.130.2/31",
                   "94.74.130.4/30",
                   "94.74.130.8/29",
                   "94.74.130.16/28",
                   "94.74.130.32/27",
                   "94.74.130.64/26",
                   "94.74.130.128/25",
                   "94.74.131.0/24",
                   "94.74.142.0/23",
                   "94.74.144.1/32",
                   "94.74.144.2/31",
                   "94.74.144.4/30",
                   "94.74.144.8/29",
                   "94.74.144.16/28",
                   "94.74.144.32/27",
                   "94.74.144.64/26",
                   "94.74.144.128/25",
                   "94.74.148.0/24",
                   "94.74.150.0/23",
                   "94.74.152.0/23",
                   "94.74.155.0/24",
                   "94.74.161.0/24",
                   "94.74.162.0/24",
                   "94.74.167.0/24",
                   "94.74.178.0/23",
                   "94.74.180.0/24",
                   "94.74.182.0/24",
                   "94.74.188.0/23",
                   "94.74.190.0/24",
                   "94.101.128.0/20",
                   "94.101.176.0/20",
                   "94.101.182.0/27",
                   "94.101.240.0/20",
                   "94.139.160.0/19",
                   "94.176.8.0/21",
                   "94.176.32.0/21",
                   "94.177.72.0/21",
                   "94.182.0.0/15",
                   "94.184.0.0/16",
                   "94.199.136.0/22",
                   "94.232.168.0/21",
                   "94.241.164.0/22",
                   "95.38.0.0/16",
                   "95.64.0.0/17",
                   "95.80.128.0/18",
                   "95.81.64.0/18",
                   "95.130.56.0/21",
                   "95.130.225.0/24",
                   "95.130.240.0/21",
                   "95.142.224.0/20",
                   "95.156.222.0/23",
                   "95.156.233.0/24",
                   "95.156.234.0/23",
                   "95.156.236.0/23",
                   "95.156.248.0/23",
                   "95.156.252.0/22",
                   "95.162.0.0/16",
                   "95.215.59.0/24",
                   "95.215.160.0/22",
                   "95.215.173.0/24",
                   "103.130.144.0/24",
                   "103.130.146.0/24",
                   "103.215.220.0/22",
                   "103.216.60.0/22",
                   "103.231.136.0/23",
                   "103.231.138.0/24",
                   "104.28.11.28/31",
                   "104.28.11.30/32",
                   "104.28.37.237/32",
                   "104.28.37.238/31",
                   "104.28.37.240/31",
                   "104.28.51.83/32",
                   "104.28.51.84/30",
                   "104.28.80.85/32",
                   "104.28.80.86/31",
                   "104.28.80.88/31",
                   "104.28.106.57/32",
                   "104.28.106.58/31",
                   "104.28.106.60/31",
                   "104.28.131.38/31",
                   "104.28.131.40/32",
                   "104.28.194.219/32",
                   "104.28.194.220/30",
                   "104.28.194.224/31",
                   "104.28.214.161/32",
                   "104.28.214.162/31",
                   "104.28.214.164/30",
                   "104.28.214.168/32",
                   "104.28.226.219/32",
                   "104.28.226.220/30",
                   "104.28.226.224/31",
                   "104.28.246.161/32",
                   "104.28.246.162/31",
                   "104.28.246.164/30",
                   "104.28.246.168/32",
                   "109.70.237.0/24",
                   "109.72.192.0/20",
                   "109.74.232.0/21",
                   "109.94.164.0/22",
                   "109.95.60.0/22",
                   "109.95.64.0/21",
                   "109.107.131.0/24",
                   "109.108.160.0/19",
                   "109.109.32.0/19",
                   "109.110.160.0/19",
                   "109.122.193.0/24",
                   "109.122.199.0/24",
                   "109.122.209.0/24",
                   "109.122.217.0/24",
                   "109.122.224.0/20",
                   "109.122.240.0/21",
                   "109.122.248.0/22",
                   "109.122.252.0/23",
                   "109.125.128.0/18",
                   "109.162.128.0/17",
                   "109.201.0.0/19",
                   "109.203.128.0/19",
                   "109.203.176.0/22",
                   "109.206.252.0/22",
                   "109.225.128.0/18",
                   "109.230.64.0/19",
                   "109.230.192.0/23",
                   "109.230.200.0/24",
                   "109.230.204.0/22",
                   "109.230.221.0/24",
                   "109.230.223.0/24",
                   "109.230.242.0/24",
                   "109.230.246.0/23",
                   "109.230.251.0/24",
                   "109.232.0.0/21",
                   "109.238.176.0/20",
                   "109.239.0.0/20",
                   "113.203.0.0/17",
                   "128.65.160.0/19",
                   "130.185.72.0/21",
                   "130.193.77.0/24",
                   "130.244.3.200/32",
                   "130.244.35.176/32",
                   "130.244.41.211/32",
                   "130.244.41.213/32",
                   "130.244.71.67/32",
                   "130.244.71.72/31",
                   "130.244.71.74/32",
                   "130.244.71.80/31",
                   "130.244.85.151/32",
                   "130.244.93.166/32",
                   "130.244.115.156/32",
                   "130.244.171.236/32",
                   "130.255.192.0/18",
                   "134.255.196.0/23",
                   "134.255.200.0/21",
                   "134.255.245.0/24",
                   "134.255.246.0/24",
                   "134.255.248.0/23",
                   "140.248.34.128/30",
                   "140.248.36.146/31",
                   "140.248.36.148/31",
                   "141.11.42.0/24",
                   "146.19.104.0/24",
                   "146.19.217.0/24",
                   "146.66.128.0/21",
                   "146.75.132.146/31",
                   "146.75.132.148/31",
                   "146.75.169.128/30",
                   "146.75.180.36/30",
                   "151.232.0.0/14",
                   "151.238.0.0/15",
                   "151.240.0.0/13",
                   "152.89.12.0/22",
                   "152.89.44.0/22",
                   "157.119.188.0/22",
                   "158.58.0.0/17",
                   "158.58.184.0/21",
                   "158.255.74.0/24",
                   "158.255.77.238/31",
                   "158.255.78.0/24",
                   "159.20.96.0/20",
                   "164.138.16.0/21",
                   "164.138.128.0/18",
                   "164.215.56.0/21",
                   "164.215.128.0/17",
                   "171.22.24.0/22",
                   "172.80.128.0/17",
                   "172.225.187.16/28",
                   "172.225.191.160/27",
                   "172.225.196.144/28",
                   "172.225.196.184/29",
                   "172.225.228.128/27",
                   "172.225.229.96/28",
                   "176.12.64.0/20",
                   "176.56.144.0/20",
                   "176.62.144.0/21",
                   "176.65.160.0/19",
                   "176.65.192.0/18",
                   "176.67.64.0/20",
                   "176.97.218.0/24",
                   "176.97.220.0/24",
                   "176.101.32.0/20",
                   "176.101.48.0/21",
                   "176.102.224.0/19",
                   "176.105.245.0/24",
                   "176.116.7.0/24",
                   "176.122.210.0/23",
                   "176.123.64.0/18",
                   "176.124.64.0/22",
                   "176.126.120.0/24",
                   "176.221.64.0/21",
                   "176.223.80.0/21",
                   "178.21.40.0/21",
                   "178.21.160.0/21",
                   "178.22.72.0/21",
                   "178.22.120.0/21",
                   "178.131.0.0/16",
                   "178.157.0.0/23",
                   "178.169.0.0/19",
                   "178.173.128.0/18",
                   "178.173.192.0/19",
                   "178.211.145.0/24",
                   "178.215.0.0/18",
                   "178.216.248.0/21",
                   "178.219.224.0/20",
                   "178.236.32.0/22",
                   "178.236.96.0/20",
                   "178.238.192.0/20",
                   "178.239.144.0/20",
                   "178.248.40.0/21",
                   "178.251.208.0/21",
                   "178.252.128.0/18",
                   "178.253.16.0/24",
                   "178.253.31.0/24",
                   "178.253.32.0/24",
                   "178.253.38.0/23",
                   "185.1.77.0/24",
                   "185.2.12.0/22",
                   "185.3.124.0/22",
                   "185.3.200.0/22",
                   "185.3.212.0/22",
                   "185.4.0.0/22",
                   "185.4.16.0/22",
                   "185.4.28.0/22",
                   "185.4.104.0/22",
                   "185.4.220.0/22",
                   "185.5.156.0/22",
                   "185.7.212.0/24",
                   "185.8.172.0/22",
                   "185.10.71.0/24",
                   "185.10.72.0/22",
                   "185.11.68.0/22",
                   "185.11.88.0/22",
                   "185.11.176.0/22",
                   "185.12.60.0/22",
                   "185.12.100.0/23",
                   "185.12.102.0/24",
                   "185.13.228.0/22",
                   "185.14.80.0/22",
                   "185.14.160.0/22",
                   "185.16.232.0/22",
                   "185.17.115.176/30",
                   "185.18.156.0/22",
                   "185.18.212.0/22",
                   "185.19.201.0/24",
                   "185.20.160.0/22",
                   "185.21.68.0/22",
                   "185.21.76.0/22",
                   "185.22.28.0/22",
                   "185.23.128.0/22",
                   "185.24.136.0/22",
                   "185.24.148.0/22",
                   "185.24.228.0/22",
                   "185.24.252.0/22",
                   "185.25.172.0/22",
                   "185.26.32.0/22",
                   "185.26.232.0/22",
                   "185.29.220.0/22",
                   "185.30.4.0/22",
                   "185.30.76.0/22",
                   "185.31.124.0/22",
                   "185.32.128.0/22",
                   "185.33.25.0/24",
                   "185.34.160.0/22",
                   "185.36.228.0/24",
                   "185.36.231.0/24",
                   "185.37.52.0/22",
                   "185.39.180.0/22",
                   "185.40.16.0/24",
                   "185.40.240.0/22",
                   "185.41.0.0/22",
                   "185.41.220.0/22",
                   "185.42.24.0/24",
                   "185.42.26.0/23",
                   "185.42.212.0/22",
                   "185.42.224.0/22",
                   "185.44.36.0/22",
                   "185.44.100.0/22",
                   "185.44.112.0/22",
                   "185.45.188.0/22",
                   "185.46.0.0/22",
                   "185.46.108.0/22",
                   "185.46.216.0/22",
                   "185.47.48.0/22",
                   "185.49.84.0/22",
                   "185.49.96.0/22",
                   "185.49.104.0/22",
                   "185.49.231.0/24",
                   "185.50.36.0/22",
                   "185.51.40.0/22",
                   "185.51.200.0/22",
                   "185.53.140.0/22",
                   "185.55.224.0/22",
                   "185.56.92.0/22",
                   "185.56.96.0/22",
                   "185.57.132.0/22",
                   "185.57.164.0/22",
                   "185.57.200.0/22",
                   "185.58.240.0/22",
                   "185.59.112.0/23",
                   "185.60.32.0/22",
                   "185.60.136.0/22",
                   "185.62.232.0/22",
                   "185.63.113.0/24",
                   "185.63.114.0/24",
                   "185.63.236.0/22",
                   "185.64.176.0/22",
                   "185.66.224.0/21",
                   "185.67.12.0/22",
                   "185.67.100.0/22",
                   "185.67.156.0/22",
                   "185.67.212.0/22",
                   "185.69.108.0/22",
                   "185.70.60.0/22",
                   "185.71.152.0/22",
                   "185.71.192.0/22",
                   "185.72.24.0/22",
                   "185.72.80.0/22",
                   "185.73.0.0/22",
                   "185.73.76.0/22",
                   "185.73.112.0/24",
                   "185.73.114.0/24",
                   "185.73.226.0/24",
                   "185.74.164.0/22",
                   "185.74.221.0/24",
                   "185.75.196.0/22",
                   "185.75.204.0/22",
                   "185.76.248.0/22",
                   "185.78.20.0/22",
                   "185.79.60.0/22",
                   "185.79.96.0/22",
                   "185.79.156.0/22",
                   "185.80.100.0/22",
                   "185.80.198.0/23",
                   "185.81.40.0/22",
                   "185.81.96.0/23",
                   "185.81.99.0/24",
                   "185.82.28.0/22",
                   "185.82.64.0/22",
                   "185.82.136.0/22",
                   "185.82.164.0/22",
                   "185.82.180.0/22",
                   "185.83.28.0/22",
                   "185.83.76.0/22",
                   "185.83.80.0/22",
                   "185.83.88.0/22",
                   "185.83.112.0/24",
                   "185.83.114.0/23",
                   "185.83.180.0/22",
                   "185.83.184.0/22",
                   "185.83.196.0/22",
                   "185.83.208.0/22",
                   "185.84.220.0/22",
                   "185.85.68.0/22",
                   "185.85.136.0/22",
                   "185.86.36.0/22",
                   "185.86.180.0/22",
                   "185.88.48.0/22",
                   "185.88.152.0/22",
                   "185.88.176.0/22",
                   "185.88.252.0/22",
                   "185.89.22.0/24",
                   "185.89.112.0/22",
                   "185.92.4.0/22",
                   "185.92.8.0/22",
                   "185.92.40.0/22",
                   "185.94.96.0/23",
                   "185.94.98.0/24",
                   "185.94.99.0/25",
                   "185.94.99.136/29",
                   "185.94.99.144/28",
                   "185.94.99.160/27",
                   "185.94.99.192/26",
                   "185.95.60.0/22",
                   "185.95.152.0/22",
                   "185.95.180.0/22",
                   "185.96.240.0/22",
                   "185.97.116.0/22",
                   "185.98.112.0/22",
                   "185.99.212.0/22",
                   "185.100.44.0/22",
                   "185.101.228.0/22",
                   "185.103.84.0/22",
                   "185.103.128.0/22",
                   "185.103.244.0/22",
                   "185.103.248.0/22",
                   "185.104.192.0/24",
                   "185.104.228.0/22",
                   "185.104.232.0/22",
                   "185.104.240.0/22",
                   "185.105.100.0/22",
                   "185.105.120.0/22",
                   "185.105.184.0/22",
                   "185.105.236.0/22",
                   "185.106.136.0/22",
                   "185.106.144.0/22",
                   "185.106.200.0/22",
                   "185.106.228.0/22",
                   "185.107.28.0/22",
                   "185.107.32.0/23",
                   "185.107.244.0/22",
                   "185.107.248.0/22",
                   "185.108.96.0/22",
                   "185.108.164.0/22",
                   "185.109.60.0/22",
                   "185.109.72.0/22",
                   "185.109.80.0/22",
                   "185.109.128.0/22",
                   "185.109.244.0/22",
                   "185.109.248.0/22",
                   "185.110.28.0/22",
                   "185.110.216.0/22",
                   "185.110.228.0/22",
                   "185.110.236.0/22",
                   "185.110.244.0/22",
                   "185.110.252.0/22",
                   "185.111.8.0/21",
                   "185.111.64.0/22",
                   "185.111.80.0/22",
                   "185.111.136.0/22",
                   "185.112.32.0/21",
                   "185.112.130.0/23",
                   "185.112.148.0/22",
                   "185.112.168.0/22",
                   "185.113.56.0/22",
                   "185.113.112.0/22",
                   "185.114.188.0/22",
                   "185.115.76.0/22",
                   "185.115.148.0/22",
                   "185.115.168.0/22",
                   "185.116.20.0/22",
                   "185.116.24.0/22",
                   "185.116.44.0/22",
                   "185.116.160.0/22",
                   "185.117.48.0/22",
                   "185.117.136.0/22",
                   "185.117.204.0/23",
                   "185.117.206.0/24",
                   "185.118.12.0/22",
                   "185.118.136.0/22",
                   "185.118.152.0/22",
                   "185.119.4.0/22",
                   "185.119.164.0/22",
                   "185.119.240.0/22",
                   "185.120.120.0/22",
                   "185.120.136.0/22",
                   "185.120.160.0/22",
                   "185.120.168.0/22",
                   "185.120.192.0/21",
                   "185.120.200.0/22",
                   "185.120.208.0/20",
                   "185.120.224.0/20",
                   "185.120.240.0/21",
                   "185.120.248.0/22",
                   "185.121.56.0/22",
                   "185.121.128.0/22",
                   "185.122.80.0/22",
                   "185.123.68.0/22",
                   "185.123.208.0/22",
                   "185.124.112.0/22",
                   "185.124.156.0/22",
                   "185.124.172.0/22",
                   "185.125.20.0/22",
                   "185.125.244.0/22",
                   "185.125.248.0/21",
                   "185.126.0.0/20",
                   "185.126.16.0/22",
                   "185.126.40.0/22",
                   "185.126.132.0/23",
                   "185.126.200.0/22",
                   "185.127.232.0/22",
                   "185.128.40.0/24",
                   "185.128.48.0/22",
                   "185.128.80.0/22",
                   "185.128.136.0/22",
                   "185.128.152.0/22",
                   "185.128.164.0/22",
                   "185.129.80.0/22",
                   "185.129.168.0/22",
                   "185.129.184.0/21",
                   "185.129.196.0/22",
                   "185.129.200.0/22",
                   "185.129.212.0/22",
                   "185.129.216.0/22",
                   "185.129.228.0/22",
                   "185.129.232.0/21",
                   "185.129.240.0/22",
                   "185.130.76.0/22",
                   "185.131.28.0/22",
                   "185.131.84.0/22",
                   "185.131.88.0/21",
                   "185.131.100.0/22",
                   "185.131.108.0/22",
                   "185.131.112.0/21",
                   "185.131.124.0/22",
                   "185.131.128.0/22",
                   "185.131.136.0/21",
                   "185.131.148.0/22",
                   "185.131.152.0/21",
                   "185.131.164.0/22",
                   "185.131.168.0/22",
                   "185.132.80.0/22",
                   "185.132.212.0/22",
                   "185.133.152.0/22",
                   "185.133.164.0/22",
                   "185.133.244.0/23",
                   "185.133.246.0/24",
                   "185.134.96.0/22",
                   "185.135.28.0/22",
                   "185.135.228.0/22",
                   "185.136.100.0/22",
                   "185.136.172.0/22",
                   "185.136.180.0/22",
                   "185.136.192.0/22",
                   "185.136.220.0/22",
                   "185.137.24.0/22",
                   "185.137.60.0/22",
                   "185.137.108.0/23",
                   "185.137.110.0/24",
                   "185.139.64.0/22",
                   "185.140.4.0/22",
                   "185.140.56.0/22",
                   "185.140.232.0/22",
                   "185.140.240.0/22",
                   "185.141.36.0/22",
                   "185.141.48.0/22",
                   "185.141.104.0/22",
                   "185.141.132.0/22",
                   "185.141.168.0/22",
                   "185.141.212.0/22",
                   "185.141.244.0/22",
                   "185.142.92.0/22",
                   "185.142.124.0/22",
                   "185.142.156.0/22",
                   "185.142.232.0/22",
                   "185.143.72.0/22",
                   "185.143.204.0/22",
                   "185.143.232.0/22",
                   "185.144.64.0/22",
                   "185.145.8.0/22",
                   "185.145.184.0/22",
                   "185.147.40.0/22",
                   "185.147.84.0/22",
                   "185.147.160.0/22",
                   "185.147.176.0/22",
                   "185.149.192.0/24",
                   "185.150.108.0/22",
                   "185.153.184.0/22",
                   "185.153.208.0/22",
                   "185.154.184.0/22",
                   "185.155.8.0/21",
                   "185.155.72.0/22",
                   "185.155.236.0/22",
                   "185.157.8.0/22",
                   "185.158.172.0/22",
                   "185.159.152.0/22",
                   "185.159.176.0/22",
                   "185.159.189.0/24",
                   "185.160.104.0/22",
                   "185.160.176.0/22",
                   "185.161.36.0/22",
                   "185.161.112.0/22",
                   "185.162.40.0/22",
                   "185.162.216.0/22",
                   "185.163.88.0/22",
                   "185.164.73.0/24",
                   "185.164.74.0/23",
                   "185.164.252.0/22",
                   "185.165.28.0/22",
                   "185.165.40.0/22",
                   "185.165.100.0/22",
                   "185.165.116.0/22",
                   "185.165.204.0/22",
                   "185.166.60.0/22",
                   "185.166.104.0/22",
                   "185.166.112.0/22",
                   "185.167.72.0/22",
                   "185.167.100.0/22",
                   "185.167.124.0/22",
                   "185.168.28.0/22",
                   "185.169.6.0/24",
                   "185.169.20.0/22",
                   "185.169.36.0/22",
                   "185.170.8.0/24",
                   "185.170.236.0/22",
                   "185.171.52.0/22",
                   "185.172.0.0/22",
                   "185.172.68.0/22",
                   "185.172.212.0/22",
                   "185.173.104.0/22",
                   "185.173.129.0/24",
                   "185.173.130.0/24",
                   "185.173.168.0/22",
                   "185.174.132.0/24",
                   "185.174.134.0/24",
                   "185.174.200.0/22",
                   "185.174.248.0/22",
                   "185.175.76.0/22",
                   "185.175.240.0/22",
                   "185.176.32.0/22",
                   "185.176.56.0/22",
                   "185.177.156.0/22",
                   "185.177.232.0/22",
                   "185.178.104.0/22",
                   "185.178.220.0/22",
                   "185.179.90.0/24",
                   "185.179.168.0/22",
                   "185.179.220.0/22",
                   "185.180.52.0/22",
                   "185.180.128.0/22",
                   "185.181.180.0/22",
                   "185.182.220.0/22",
                   "185.182.248.0/22",
                   "185.184.32.0/22",
                   "185.184.48.0/22",
                   "185.185.16.0/22",
                   "185.185.240.0/22",
                   "185.186.48.0/22",
                   "185.186.240.0/22",
                   "185.187.48.0/22",
                   "185.187.84.0/22",
                   "185.188.104.0/22",
                   "185.188.112.0/22",
                   "185.189.120.0/22",
                   "185.190.20.0/22",
                   "185.190.25.128/25",
                   "185.190.39.0/24",
                   "185.191.76.0/22",
                   "185.192.8.0/22",
                   "185.192.112.0/22",
                   "185.193.47.0/24",
                   "185.193.208.0/22",
                   "185.194.76.0/22",
                   "185.194.244.0/22",
                   "185.195.72.0/22",
                   "185.196.148.0/22",
                   "185.197.68.0/22",
                   "185.197.112.0/22",
                   "185.198.160.0/22",
                   "185.199.64.0/22",
                   "185.199.208.0/24",
                   "185.199.210.0/23",
                   "185.201.48.0/22",
                   "185.202.56.0/22",
                   "185.203.160.0/22",
                   "185.204.180.0/22",
                   "185.204.197.0/24",
                   "185.205.203.0/24",
                   "185.205.220.0/22",
                   "185.206.92.0/22",
                   "185.206.229.0/24",
                   "185.206.231.0/24",
                   "185.206.236.0/22",
                   "185.207.52.0/22",
                   "185.207.72.0/22",
                   "185.208.76.0/22",
                   "185.208.148.0/22",
                   "185.208.174.0/23",
                   "185.208.180.0/22",
                   "185.209.188.0/22",
                   "185.210.200.0/22",
                   "185.211.56.0/22",
                   "185.211.84.0/22",
                   "185.211.88.0/22",
                   "185.212.48.0/22",
                   "185.212.192.0/22",
                   "185.213.8.0/22",
                   "185.213.164.0/22",
                   "185.213.195.0/24",
                   "185.214.36.0/22",
                   "185.215.124.0/22",
                   "185.215.152.0/22",
                   "185.215.228.0/22",
                   "185.215.232.0/22",
                   "185.218.139.0/24",
                   "185.219.112.0/22",
                   "185.220.224.0/22",
                   "185.221.112.0/22",
                   "185.221.192.0/22",
                   "185.221.239.0/24",
                   "185.222.120.0/22",
                   "185.222.180.0/22",
                   "185.222.184.0/22",
                   "185.222.210.0/24",
                   "185.223.160.0/24",
                   "185.224.176.0/22",
                   "185.225.80.0/22",
                   "185.225.180.0/22",
                   "185.225.240.0/22",
                   "185.226.97.0/24",
                   "185.226.116.0/22",
                   "185.226.132.0/22",
                   "185.226.140.0/22",
                   "185.227.64.0/22",
                   "185.227.116.0/22",
                   "185.228.236.0/22",
                   "185.228.238.0/28",
                   "185.229.0.0/22",
                   "185.229.28.0/22",
                   "185.229.204.0/24",
                   "185.231.65.0/24",
                   "185.231.112.0/22",
                   "185.231.180.0/22",
                   "185.232.152.0/22",
                   "185.232.176.0/22",
                   "185.233.12.0/22",
                   "185.233.84.0/22",
                   "185.233.131.0/24",
                   "185.234.14.0/24",
                   "185.234.192.0/22",
                   "185.235.136.0/24",
                   "185.235.138.0/23",
                   "185.235.245.0/24",
                   "185.236.36.0/22",
                   "185.236.45.0/24",
                   "185.236.88.0/22",
                   "185.237.8.0/22",
                   "185.237.84.0/22",
                   "185.238.20.0/22",
                   "185.238.44.0/22",
                   "185.238.92.0/22",
                   "185.238.140.0/24",
                   "185.238.143.0/24",
                   "185.239.0.0/22",
                   "185.239.104.0/22",
                   "185.240.56.0/22",
                   "185.240.148.0/22",
                   "185.243.48.0/22",
                   "185.244.52.0/22",
                   "185.246.4.0/22",
                   "185.248.32.0/24",
                   "185.251.76.0/22",
                   "185.252.28.0/22",
                   "185.252.200.0/24",
                   "185.254.165.0/24",
                   "185.254.166.0/24",
                   "185.255.68.0/22",
                   "185.255.88.0/22",
                   "185.255.208.0/22",
                   "188.0.240.0/20",
                   "188.75.64.0/18",
                   "188.94.188.0/24",
                   "188.95.89.0/24",
                   "188.118.64.0/18",
                   "188.121.96.0/19",
                   "188.121.128.0/19",
                   "188.122.96.0/19",
                   "188.136.128.0/18",
                   "188.136.192.0/19",
                   "188.158.0.0/16",
                   "188.159.112.0/20",
                   "188.159.128.0/18",
                   "188.159.192.0/19",
                   "188.191.176.0/21",
                   "188.208.56.0/21",
                   "188.208.64.0/19",
                   "188.208.144.0/20",
                   "188.208.160.0/19",
                   "188.208.200.0/22",
                   "188.208.208.0/21",
                   "188.208.224.0/19",
                   "188.209.0.0/19",
                   "188.209.32.0/20",
                   "188.209.64.0/20",
                   "188.209.116.0/22",
                   "188.209.152.0/23",
                   "188.209.192.0/20",
                   "188.210.64.0/20",
                   "188.210.80.0/21",
                   "188.210.96.0/19",
                   "188.210.128.0/18",
                   "188.210.192.0/20",
                   "188.210.232.0/22",
                   "188.211.0.0/20",
                   "188.211.32.0/19",
                   "188.211.64.0/18",
                   "188.211.128.0/19",
                   "188.211.176.0/20",
                   "188.211.192.0/19",
                   "188.212.22.0/24",
                   "188.212.48.0/20",
                   "188.212.64.0/19",
                   "188.212.96.0/22",
                   "188.212.144.0/21",
                   "188.212.160.0/19",
                   "188.212.200.0/21",
                   "188.212.208.0/20",
                   "188.212.224.0/20",
                   "188.212.240.0/21",
                   "188.213.64.0/20",
                   "188.213.96.0/19",
                   "188.213.144.0/20",
                   "188.213.176.0/20",
                   "188.213.192.0/21",
                   "188.213.208.0/22",
                   "188.214.4.0/22",
                   "188.214.84.0/22",
                   "188.214.96.0/22",
                   "188.214.120.0/23",
                   "188.214.160.0/19",
                   "188.214.216.0/21",
                   "188.215.24.0/22",
                   "188.215.88.0/22",
                   "188.215.128.0/20",
                   "188.215.160.0/19",
                   "188.215.192.0/19",
                   "188.215.240.0/22",
                   "188.229.0.0/17",
                   "188.240.196.0/24",
                   "188.240.212.0/24",
                   "188.240.248.0/21",
                   "188.253.2.0/23",
                   "188.253.32.0/21",
                   "188.253.40.0/24",
                   "188.253.42.0/23",
                   "188.253.44.0/22",
                   "188.253.48.0/20",
                   "188.253.64.0/19",
                   "192.15.0.0/16",
                   "192.167.140.66/32",
                   "193.0.156.0/24",
                   "193.3.31.0/24",
                   "193.3.182.0/24",
                   "193.3.231.0/24",
                   "193.3.255.0/24",
                   "193.8.139.0/24",
                   "193.19.144.0/23",
                   "193.22.20.0/24",
                   "193.28.181.0/24",
                   "193.29.24.0/24",
                   "193.29.26.0/24",
                   "193.32.80.0/23",
                   "193.34.244.0/22",
                   "193.35.62.0/24",
                   "193.35.230.0/24",
                   "193.38.247.0/24",
                   "193.39.9.0/24",
                   "193.56.59.0/24",
                   "193.56.61.0/24",
                   "193.56.107.0/24",
                   "193.56.118.0/24",
                   "193.104.22.0/24",
                   "193.104.29.0/24",
                   "193.104.212.0/24",
                   "193.105.2.0/24",
                   "193.105.6.0/24",
                   "193.105.234.0/24",
                   "193.106.190.0/24",
                   "193.107.48.0/24",
                   "193.108.242.0/23",
                   "193.111.234.0/23",
                   "193.134.100.0/23",
                   "193.141.64.0/23",
                   "193.141.126.0/23",
                   "193.142.30.0/24",
                   "193.142.232.0/23",
                   "193.142.254.0/23",
                   "193.148.64.0/22",
                   "193.150.66.0/24",
                   "193.151.128.0/19",
                   "193.162.129.0/24",
                   "193.176.240.0/22",
                   "193.178.200.0/22",
                   "193.186.4.40/30",
                   "193.186.32.0/24",
                   "193.189.122.0/23",
                   "193.200.102.0/23",
                   "193.200.148.0/24",
                   "193.201.72.0/23",
                   "193.201.192.0/22",
                   "193.222.51.0/24",
                   "193.228.90.0/23",
                   "193.228.136.0/24",
                   "193.240.187.76/30",
                   "193.240.207.0/28",
                   "193.242.194.0/23",
                   "193.242.208.0/23",
                   "193.246.160.0/23",
                   "193.246.164.0/23",
                   "193.246.174.0/23",
                   "193.246.200.0/23",
                   "194.5.40.0/22",
                   "194.5.175.0/24",
                   "194.5.176.0/22",
                   "194.5.188.0/24",
                   "194.5.195.0/24",
                   "194.5.205.0/24",
                   "194.9.56.0/23",
                   "194.9.80.0/23",
                   "194.24.160.161/32",
                   "194.24.160.162/31",
                   "194.26.2.0/23",
                   "194.26.20.0/23",
                   "194.26.117.0/24",
                   "194.26.195.0/24",
                   "194.31.108.0/24",
                   "194.31.194.0/24",
                   "194.33.104.0/22",
                   "194.33.122.0/23",
                   "194.33.124.0/22",
                   "194.34.163.0/24",
                   "194.36.0.0/24",
                   "194.36.174.0/24",
                   "194.39.36.0/22",
                   "194.41.48.0/22",
                   "194.50.204.0/24",
                   "194.50.209.0/24",
                   "194.50.216.0/24",
                   "194.50.218.0/24",
                   "194.53.118.0/23",
                   "194.53.122.0/23",
                   "194.56.148.0/24",
                   "194.59.170.0/23",
                   "194.59.214.0/23",
                   "194.60.208.0/22",
                   "194.60.228.0/22",
                   "194.62.17.0/24",
                   "194.62.43.0/24",
                   "194.87.23.0/24",
                   "194.143.140.0/23",
                   "194.146.148.0/22",
                   "194.146.239.0/24",
                   "194.147.164.0/22",
                   "194.147.212.0/24",
                   "194.147.222.0/24",
                   "194.150.68.0/22",
                   "194.156.140.0/22",
                   "194.180.224.0/24",
                   "194.225.0.0/16",
                   "195.2.234.0/24",
                   "195.8.102.0/24",
                   "195.8.110.0/24",
                   "195.8.112.0/24",
                   "195.8.114.0/24",
                   "195.20.136.0/24",
                   "195.27.14.0/29",
                   "195.28.10.0/23",
                   "195.28.168.0/23",
                   "195.88.188.0/23",
                   "195.96.128.0/24",
                   "195.96.135.0/24",
                   "195.96.153.0/24",
                   "195.110.38.0/23",
                   "195.114.4.0/23",
                   "195.114.8.0/23",
                   "195.146.32.0/19",
                   "195.181.0.0/17",
                   "195.182.38.0/24",
                   "195.190.130.0/24",
                   "195.190.139.0/24",
                   "195.190.144.0/24",
                   "195.191.22.0/23",
                   "195.191.44.0/23",
                   "195.191.74.0/23",
                   "195.211.44.0/22",
                   "195.214.235.0/24",
                   "195.217.44.172/30",
                   "195.219.71.0/24",
                   "195.225.232.0/24",
                   "195.226.223.0/24",
                   "195.230.97.0/24",
                   "195.230.105.0/24",
                   "195.230.107.0/24",
                   "195.230.124.0/24",
                   "195.234.191.0/24",
                   "195.238.231.0/24",
                   "195.238.240.0/24",
                   "195.238.247.0/24",
                   "195.245.70.0/23",
                   "196.3.91.0/24",
                   "196.197.103.0/24",
                   "196.198.103.0/24",
                   "196.199.103.0/24",
                   "204.18.0.0/16",
                   "204.245.22.24/30",
                   "204.245.22.29/32",
                   "204.245.22.30/31",
                   "209.28.123.0/26",
                   "210.5.196.64/26",
                   "210.5.197.64/26",
                   "210.5.198.32/29",
                   "210.5.198.64/28",
                   "210.5.198.96/27",
                   "210.5.198.128/26",
                   "210.5.198.192/27",
                   "210.5.204.0/25",
                   "210.5.205.0/26",
                   "210.5.208.0/26",
                   "210.5.208.128/25",
                   "210.5.209.0/25",
                   "210.5.214.192/26",
                   "210.5.218.64/26",
                   "210.5.218.128/25",
                   "210.5.232.0/25",
                   "210.5.233.0/25",
                   "210.5.233.128/26",
                   "212.1.192.0/21",
                   "212.16.64.0/19",
                   "212.18.108.0/24",
                   "212.23.201.0/24",
                   "212.23.214.0/24",
                   "212.23.216.0/24",
                   "212.33.192.0/19",
                   "212.46.45.0/24",
                   "212.73.88.0/24",
                   "212.80.0.0/19",
                   "212.86.64.0/19",
                   "212.120.146.128/29",
                   "212.120.192.0/19",
                   "212.151.26.66/32",
                   "212.151.53.58/32",
                   "212.151.56.189/32",
                   "212.151.60.189/32",
                   "212.151.177.130/32",
                   "212.151.182.155/32",
                   "212.151.182.156/31",
                   "212.151.186.154/31",
                   "212.151.186.156/32",
                   "212.214.49.106/32",
                   "212.214.51.140/32",
                   "212.214.52.240/32",
                   "212.214.72.62/32",
                   "212.214.72.160/32",
                   "212.214.145.178/32",
                   "212.214.151.192/32",
                   "212.214.224.216/32",
                   "212.214.233.144/32",
                   "212.214.234.126/32",
                   "212.214.234.194/32",
                   "212.214.235.126/32",
                   "212.214.235.228/32",
                   "213.50.17.236/32",
                   "213.50.20.144/32",
                   "213.50.44.228/32",
                   "213.50.56.86/32",
                   "213.50.56.92/32",
                   "213.50.58.18/32",
                   "213.50.61.198/32",
                   "213.50.97.76/32",
                   "213.50.144.4/32",
                   "213.50.144.92/32",
                   "213.50.147.82/32",
                   "213.50.147.88/32",
                   "213.50.148.8/32",
                   "213.50.169.225/32",
                   "213.50.186.36/32",
                   "213.50.188.76/32",
                   "213.50.216.216/32",
                   "213.50.236.46/32",
                   "213.50.236.88/32",
                   "213.88.162.204/32",
                   "213.108.240.0/23",
                   "213.108.242.0/24",
                   "213.109.199.0/24",
                   "213.109.240.0/20",
                   "213.131.137.154/32",
                   "213.168.224.216/30",
                   "213.168.240.96/29",
                   "213.176.0.0/20",
                   "213.176.16.0/21",
                   "213.176.28.0/22",
                   "213.176.64.0/18",
                   "213.195.0.0/20",
                   "213.195.16.0/21",
                   "213.195.32.0/19",
                   "213.207.192.0/18",
                   "213.217.32.0/19",
                   "213.232.124.0/22",
                   "213.233.160.0/19",
                   "217.11.16.0/20",
                   "217.24.144.0/20",
                   "217.25.48.0/20",
                   "217.60.0.0/16",
                   "217.66.192.0/19",
                   "217.77.112.0/20",
                   "217.114.40.0/24",
                   "217.114.46.0/24",
                   "217.144.104.0/22",
                   "217.146.208.0/20",
                   "217.161.16.0/24",
                   "217.170.240.0/20",
                   "217.171.145.0/24",
                   "217.171.148.0/22",
                   "217.171.191.220/30",
                   "217.172.98.0/23",
                   "217.172.102.0/23",
                   "217.172.104.0/21",
                   "217.172.112.0/22",
                   "217.172.116.0/23",
                   "217.172.118.0/24",
                   "217.172.120.0/21",
                   "217.174.16.0/20",
                   "217.198.190.0/24",
                   "217.218.0.0/16",
                   "217.219.0.0/17",
                   "217.219.128.0/18",
                   "217.219.192.0/21",
                   "217.219.200.0/22",
                   "217.219.204.0/24",
                   "217.219.205.64/26",
                   "217.219.205.128/25",
                   "217.219.206.0/23",
                   "217.219.208.0/20",
                   "217.219.224.0/19",
                   "192.168.0.0/16",
                   "10.0.0.0/8",
                   "172.16.0.0/12",
                   "127.0.0.0/8",
                   "100.64.0.0/10"
                ]
             },
             {
                "type":"field",
                "outboundTag":"block",
                "domain":[
                   "geosite:private",
                   "ext:iran.dat:ir",
                   "regexp:.*\\\\.ir$",
                   "geosite:category-ir",
                   "snapp",
                   "digikala",
                   "tapsi",
                   "blogfa",
                   "bank",
                   "sb24.com",
                   "sheypoor.com",
                   "tebyan.net",
                   "beytoote.com",
                   "telewebion.com",
                   "Film2movie.ws",
                   "Setare.com",
                   "Filimo.com",
                   "Torob.com",
                   "Tgju.org",
                   "Sarzamindownload.com",
                   "downloadha.com",
                   "P30download.com",
                   "Sanjesh.org",
                   "domain:intrack.ir",
                   "domain:divar.ir",
                   "domain:irancell.ir",
                   "domain:yooz.ir",
                   "domain:iran-cell.com",
                   "domain:irancell.i-r",
                   "domain:shaparak.ir",
                   "domain:learnit.ir",
                   "domain:yooz.ir",
                   "domain:baadesaba.ir",
                   "domain:webgozar.ir"
                ]
             }
          ]
       },
       "outbounds":[
          {
             "protocol":"freedom",
             "tag":"direct"
          },
          {
             "protocol":"blackhole",
             "tag":"block"
          }
       ]
}
EOL
}

# Creates a config file for ShadowSocks-libev
configureShadowsocks() {
    # We create some local variables to hold tunnel specific data.
    local configDirectoryPath="/var/snap/shadowsocks-libev/common/etc/shadowsocks-libev"
    local configFilePath="$configDirectoryPath/config.json"
    echo "========================================================================="
    echo "|                     Configuring ShadowSocks                           |"
    echo "========================================================================="
    # We will create the directory path for config file.
    sudo mkdir -p $configDirectoryPath
    # We create an empty config file.
    sudo touch $configFilePath
    # We generate a password for ShadowSocks authentication
    ssPassword=$(generateRandom password)
    # Configure ShadowSocks config file
    sudo echo "{" > $configFilePath
    sudo echo "    \"server\":[\"[::0]\", \"0.0.0.0\"]," >> $configFilePath
    sudo echo "    \"mode\":\"tcp_and_udp\"," >> $configFilePath
    sudo echo "    \"server_port\":$tunnelPort," >> $configFilePath
    sudo echo "    \"password\":\"$ssPassword\"," >> $configFilePath
    sudo echo "    \"timeout\":600," >> $configFilePath
    sudo echo "    \"method\":\"chacha20-ietf-poly1305\"," >> $configFilePath
    sudo echo "    \"nameserver\":\"1.1.1.1\"" >> $configFilePath
    sudo echo "}" >> $configFilePath
    }

# Starts the tunnel service based on the specified tunneling method.
startService() {
    # We determine the selected tunneling method and set service name accordingly.
    case $tunnelingMethod in
        hysteria2)
            local serviceName="hysteria2"
            ;;
        reality)
            local serviceName="xray"
            ;;
        shadowsocks)
            local serviceName="shadowsocks-libev-server@config"
        esac
    echo "========================================================================="
    echo "|                         Starting Service                              |"
    echo "========================================================================="
    # If the selected tunnel is ShadowSocks, We must manually enable the service to start on boot.
    if [ $tunnelingMethod == shadowsocks ]; then
        sudo systemctl enable $serviceName
        fi
    # We now start the tunnel service.
    sudo systemctl start $serviceName && sudo systemctl status $serviceName
    }

# Shows the information and credentials for connecting to the tunnel.
# Can be disabled by -dconinfo
showConnectionInformation() {
    echo "========================================================================="
    echo "|                                DONE                                   |"
    echo "========================================================================="
    # We get server IP.
    serverIp=$(hostname -I | awk '{ print $1}')
    # We check whether user has provided custom server name or not.
	# If not, we will use hostname as server name.
    if [ ! -v serverName ]; then
        serverName=$('hostname')
        fi
    # We show connection information.
    echo 
    # We determine the selected tunneling method and set fields accordingly.
    case $tunnelingMethod in
        hysteria2)
            echo "NAME : $serverName"
            ;;
        reality || shadowsocks)
            echo "REMARKS : $serverName"
            ;;
            esac
    echo "ADDRESS : $serverIp"
    echo "PORT : $tunnelPort"
    # We determine the selected tunneling method and set fields accordingly.
    case $tunnelingMethod in
        hysteria2)
            echo "OBFUSCATION PASSWORD: $h2ObfsPass"
            echo "AUTHENTICATION PASSWORD: $h2UserPass"
            echo "ALLOW INSECURE: TRUE"
            ;;
        reality)
            echo "ID: $realityUUID"
            echo "FLOW: xtls-rprx-vision"
            echo "ENCRYPTION: none"
            echo "NETWORK: TCP"
            echo "HEAD TYPE: none"
            echo "TLS: reality"
            echo "SNI: www.google-analytics.com"
            echo "FINGERPRINT: randomized"
            echo "PUBLIC KEY: $realityPublicKey"
            echo "SHORT ID: $realityShortID"
            ;;
        shadowsocks)
            echo "PASSWORD: $ssPassword"
            echo "SECURITY: CHACHA20-IETF-POLY1305"
            ;;
            esac
    echo "=========="
    # Reality Private Key
    if [ $tunnelingMethod == reality ]; then
        echo "PRIVATE KEY : $realityPrivateKey"
        fi
    echo "LOCAL USERNAME : $tempNewAccUsername"
    echo "LOCAL PASSWORD : $tempNewAccPassword"
    echo 
    echo "Write down the LOCAL USERNAME & LOCAL PASSWORD"
    echo "you may need it for updating later"
    echo "Usage of country-based routing is highly advised!"
    }

# Shows the QR Code for easier access to the tunnel.
# Can be disabled by -dqrcode
showQrCode() {
    echo "========================================================================="
    echo "|                               QRCODE                                  |"
    echo "========================================================================="
    # We determine the selected tunneling method and generate config accordingly.
    case $tunnelingMethod in
        hysteria2)
            local serverConfig="hy2://$h2UserPass@$serverIp:$tunnelPort/?insecure=1&obfs=salamander&obfs-password=$h2ObfsPass#$serverName"
            ;;
        reality)
            local serverConfig="vless://$realityUUID@$serverIp:$tunnelPort?security=reality&encryption=none&pbk=$realityPublicKey&headerType=none&fp=randomized&type=tcp&flow=xtls-rprx-vision&sni=www.google-analytics.com&sid=$realityShortID#$serverName"
            ;;
        shadowsocks)
            local encodedSegment=$(openssl base64 <<< "chacha20-ietf-poly1305:$ssPassword")
            local serverConfig="ss://$encodedSegment@$serverIp:$tunnelPort#$serverName"
            ;;
        esac  
    # We output a qrcode to ease connection.
    qrencode -t ansiutf8 $serverConfig
    }

# Checks the repository of the selected tunnel and echos back the latest release version of it.
checkLatestVersion() {
    case $tunnelingMethod in
        hysteria2)
            local url="https://api.github.com/repos/SagerNet/sing-box/releases/latest"
            ;;
        reality)
            local url="https://api.github.com/repos/XTLS/Xray-core/releases/latest"
            ;;
        esac
    # We echo back the latest package version.
    echo "$(curl --silent $url | grep -Po "(?<=\"tag_name\": \").*(?=\")"  | sed 's/^.//' )"
    }

# Main installation pipeline for tunnels.
installTunnel() {
    # We determine the selected tunneling method and set tunnel variables accordingly.
    case $tunnelingMethod in
        hysteria2)
            local tunnelName="Hysteria 2"
            ;;
        reality)
            local tunnelName="Reality"
            ;;
        shadowsocks)
            local tunnelName="ShadowSocks"
            ;;
        esac
	echo "========================================================================="
	echo "|                        Installing $tunnelName                          |"
	echo "========================================================================="
    # We check whether the selected tunneling method is available on the current machine architecture or not.
    # If not, we will show and error and exit the script.
    hardwareArch=$(getHardwareArch)
    # We check whether user requested to disable package updating or not.
    # If not, we will update packages.
    if [ ! -v disablePackageUpdating ]; then
	    installPackages
        fi
    # If the selected tunnel is Hysteria 2 or Reality, we check and save the latest package version number.
    # ShadowSocks uses (snap) to install and does not need to check a url.
    case $tunnelingMethod in
        hysteria2 || reality)
            latestPackageVersion=$(checkLatestVersion)
            # We check whether we were able to get the latest package version.
            # If not, we will exit the script to prevent messing up something.
            if [ -z $latestPackageVersion ]; then
                echo "There is a problem while trying to get latest version of $tunnelName!"
                echo "either:"
                echo "1. You are offline"
                echo "2. Access to github is blocked"
                echo "3. repository is unavailable for some reason"
                echo 
                echo "Script will now exit..."
                exit
                fi
            ;;
        esac
    # We check whether user has disabled server settings optimization or not.
	# If not, we will optimize server settings.
	if [ ! -v disableServerOptimization ]; then
		optimizeServerSettings
	    fi
    # We add a new user.
    addNewUser
    # We save new user information and latest package version in a file to access after switching user.
    saveAndTransferCredentials
    # We create a service for tunnel.
    createService
    # We switch to the new user.
    switchUser
    # We read the saved information and delete the files afterwards.
    readAndRemoveCredentials
    # We allow the tunnel port at ufw.
    allowPortOnUfw
    # We download the required files for tunnel.
    downloadFiles
    # Hysteria 2 SSL Certificate creation
    if [ $tunnelingMethod == hysteria2 ]; then
        createSSLCertificateKeyPairs
        fi  
    # We determine the selected tunneling method and configure tunnel accordingly.
    case $tunnelingMethod in
        hysteria2)
            configureSingBox
            ;;
        reality)
            configureXray
            ;;
        shadowsocks)
            configureShadowsocks
            ;;
        esac
    # We start the tunnel service.
    startService
    # We check whether user has disabled showing connection information or not.
	# If not, we will show connection information.
    if [ ! -v disableConnectionInformation ]; then
        showConnectionInformation
        fi
    # We check whether user has disabled showing QR Code or not.
	# If not, we will show QR Code.
    if [ ! -v disableQrCode ]; then
        showQrCode
        fi
    }

# <<< SCRIPT STARTS HERE >>>

# We iterate through all provided arguments.
while [ ! -z "$1" ]; do
	case "$1" in
		# Tunneling method.
		-tm)
			shift
			# Hysteria 2
			if [ $1 == "h2" ]; then
				tunnelingMethod="hysteria2"
			fi
			# Reality
			if [ $1 == "xr" ]; then
				tunnelingMethod="reality"
			fi
			# Shadowsocks
			if [ $1 == "ss" ]; then
				tunnelingMethod="shadowsocks"	
			fi
			;;
		# Disable package updating.
		-dpakup)
			disablePackageUpdating=1
			;;
		# Disable server settings optimization.
		-dservopti)
			disableServerOptimization=1
			;;
        # Disable showing connection information after finishing installation.
        -dconinfo)
            disableConnectionInformation=1
            ;;
        # Disable showing QR code after finishing installation.
        -dqrcode)
            disableQrCode=1
            ;;
        # Disable showing the startup message.
        -dstartmsg)
            disableStartupMessage=1
            ;;
		# Set custom username for new account (default: random).
		-setusername)
			newAccUsername=$2
			;;
		# Set custom password for new account (default: random).
		-setuserpass)
			newAccPassword=$2
			;;
        # Set custom port for protcols.
        -settunnelport)
            tunnelPort=$2
            ;;
        # Set custom server name.
        -setservername)
            serverName=$2
            ;;
        # Hysteria 2
		# Set custom SSL certificate common name for hysteria 2 (CN) (default: google-analytics.com).
		-seth2sslcn)
			h2sslcn=$2
			;;
		# Set custom hysteria 2 obfs password (default: random).
        -seth2obfspass)
            h2ObfsPass=$2
            ;;
        # Set custom password for hysteria 2 protocol authentication password.
        -seth2userpass)
            h2UserPass=$2
            ;;
        # Reality
        # Set custom UUID.
        -setxrUUID)
            realityUUID=$2
            ;;
        # Set custom private key.
        -setxrprivkey)
            realityPrivateKey=$2
            ;;
        # Set custom public key.
        -setxrpubkey)
            realityPublicKey=$2
            ;;
        # Set custom short ID
        -setxrshortid)
            realityShortID=$2
            ;;
        # ShadowSocks
        # Forces snap to use edge channel for shadowsocks-libev package.
        -ssedge)
            ssUseEdgeChannel=1
            ;;
	    esac
    shift
    done

# We check whether user requested to disable startup message or not.
# If not, we will show the startup message.
if [ ! -v disableStartupMessage ]; then
    showStartupMessage
    fi

# We check whether the tunneling method is supplied at execution or not.
# If not, we will ask for it.
if [ ! -v tunnelingMethod ]; then
	askTunnelingMethod
    fi

# We check if the selected tunnel already exists or not.
# TODO: If so, we have to ask for removal or updating.
case $tunnelingMethod in
    reality)
        if [ -f '/etc/systemd/system/xray.service' ]; then
            xrayServiceAlreadyExists=1
            fi
        ;;
    esac

# We call the installation pipeline.
installTunnel