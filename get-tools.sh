#!/bin/bash

# get-tools.sh

red="\e[31m"
green="\e[32m"
yellow="\e[33m"
reset="\e[0m"

if [ "$(env | grep SHELL | awk -F'/' '{print $3}')" != "bash" ]; then
    echo "Please try to execute this script in bash!"
    echo "Try to use: SHELL=/bin/bash ./get-tools.sh -u kali -p all"
    echo "if you are use Kali Linux!"
    exit 1
fi

if [ ${EUID} -ne 0 ]; then
    echo -e "Please, execute this script with ${red}root${reset} or ${red}sudo${reset}..." 
    echo "Because we need install packages using package manager from your distro and configure some tools files in /etc!"
    echo "If you'll use sudo, please run it with -H option 'cause some pip installation!"
    exit 1
fi

final_message(){
    echo -e "\nYour system is ready to hacking..."
    echo -e "\nHave Fun, Happy Hacking!!!"
}

mobile_message(){
    echo -e "\nRemember to install Android Studio:"
    echo -e "  > https://developer.android.com/studio#downloads"

    echo -e "\nIf testing the objection and it doesn't work, perform the steps below."
    echo -e "   python3.8 -m pip install pip"
    echo -e "   virtualenv --python=python3.8 ~/pentest/mobile/virtual-python3.8"
    echo -e "   source ~/pentest/mobile/virtual-python3.8/bin/activate"
    echo -e "   pip3.8 install frida-tools"
    echo -e "   pip3.8 install objection"
    echo -e "\nNote, every time you use the objection you need to activate the newly created virtual-env."
}

usage(){
    (
    echo -e "Usage: ${yellow}$0${reset} ${green}-u${reset} your_user ${green}-p${reset} profile"
    echo -e "Options:"
    echo -e "\t${green}-u${reset}   -  you need specify your user on the system [${red}needed${reset}]"
    echo -e "\t${green}-p${reset}   -  we have 5 profiles: [${red}at least one is needed${reset}]"
    echo -e "\t\t${yellow}>${reset} ${green}linux${reset}: will install and get some tools to help enumerate the linux systems"
    echo -e "\t\t${yellow}>${reset} ${green}mobile${reset}: will install and get some tools to help with pentest in mobile app"
    echo -e "\t\t${yellow}>${reset} ${green}osint${reset}: will install and get some tools to help on OSINT phase"
    echo -e "\t\t${yellow}>${reset} ${green}web${reset}: will install ${red}ONLY${reset} the necessary packages to execute ${green}collector${reset} script on reconnaissance phase"
    echo -e "\t\t${yellow}>${reset} ${green}windows${reset}: will install and get some tools to help enumerate the windows systems"
    echo -e "\t\t${yellow}>${reset} ${green}all${reset}: will execute all functions"
    ) 1>&2 ; exit 1 
}

web_message(){
    echo -e "\nOn your local machine, install:"
    echo "  > Burp and your favorite extensions"
    echo "  > Postman"
    echo "  > Chrome/Firefox and your favorite extensions"
    echo "    - Wappalyzer"
    echo "    - Cookie Editor/Manager"
    echo "    - FoxyProxy"
    echo "    - Retire.js"
    echo -e "\nConfigure the API keys on ~/.config/subfinder/config.yaml to use the subfinder properly"
    echo "  > binaryedge: [] https://binaryedge.io/"
    echo "  > censys: [] https://censys.io/"
    echo "  > certspotter: [] https://certspotter.com/"
    echo "  > passivetotal: [] http://passivetotal.org/"
    echo "  > securitytrails: [] http://securitytrails.com/"
    echo "  > shodan: [] https://shodan.io/"
    echo "  > urlscan: [] https://urlscan.io/"
    echo "  > virustotal: [] https://www.virustotal.com/"
    echo -e "\nRemeber to use:"
    echo "  > Shodan is your friend!"
    echo "  > Censys.io"
    echo "  > Crt.sh" 
    echo -e "\nUse https://apis.guru/graphql-voyager/ to complement the output from GraphQL scripts"
}

while getopts ":u:p:" options; do
    case "${options}" in
        u)
            user=$(echo "${OPTARG}" | tr '[:upper:]' '[:lower:]')
            ;;
        p)
            profile=$(echo "${OPTARG}" | tr '[:upper:]' '[:lower:]')
            ;;
        \?)
            usage
            ;;
    esac
    unset options
done
shift $((OPTIND - 1))

if [ -z "${user}" ] || [ -z "${profile}" ]; then
    usage
elif ! grep -E "^${user}" /etc/passwd | awk -F ":" '{print $1}' > /dev/null || \
    [[ ! -d $(grep -E "^${user}" /etc/passwd | awk -F ":" '{print $6}') ]]; then
    usage
elif [[ "${profile}" != "web"  &&  "${profile}" != "linux" && "${profile}" != "mobile" && "${profile}" != "osint" && "${profile}" != "windows" && "${profile}" != "all" ]]; then
    usage
fi

for file in '/etc/os-release' '/etc/lsb-release'; do
    if [ -s ${file} ] && [ "${file}" == "/etc/os-release" ] && [ -z "${distribution}" ]; then
        distribution="$(grep -E '^NAME' /etc/os-release | awk -F'=' '{print $2}' | sed -e 's/"//g' -e 's/ /_/g' -e 's/\//_/g')"
    elif [ -s ${file} ] && [ "${file}" == "/etc/lsb-release" ] && [ -z "${distribution}" ]; then
        distribution="$(grep DISTRIB_ID /etc/lsb-release | awk -F'=' '{print $2}' | sed -e 's/"//g' -e 's/ /_/g' -e 's/\//_/g')"
    fi
done

echo -e "${yellow}This is my implementation using bash script to setup a remote box or VM with tools to perfome pentest/bug bounty.${reset}"
echo -e "Verifying directories for exploits, tools and wordlists..."
# Principal dirs
user_home=$(su - "${user}" -c "echo \${HOME}")
pentest_dir="${user_home}/pentest"
# Pentest dir structure
exploits_dir="${pentest_dir}/exploits"
infra_dir="${pentest_dir}/infra-tools"
leaks_dir="${pentest_dir}/leaks"
linux_dir="${pentest_dir}/linux-tools"
mobile_dir="${pentest_dir}/mobile-tools"
osint_dir="${pentest_dir}/osint-tools"
pentest_payloads_dir="${pentest_dir}/payloads"
pentest_scripts_dir="${pentest_dir}/pentest-scripts"
web_dir="${pentest_dir}/web-tools"
wifi_dir="${pentest_dir}/wifi-tools"
windows_dir="${pentest_dir}/windows-tools"
wordlists_dir="${pentest_dir}/wordlists"
binary_dir=/usr/local/bin

if [ ! -d "${pentest_dir}" ]; then
    echo -n "pentest directory does not exist, creating... "
    if su - "${user}" -c "mkdir -p ${pentest_dir}" ; then
        echo "Done!"
    else
        echo -e "${red}Fail!${reset}\nSomething got wrong creating the pentest directory."
        exit 1
    fi
else
    echo "pentest directory OK!"
fi

error_log_file="${pentest_dir}/get-tools_error.log"
su - "${user}" -c "touch ${error_log_file}"

if [ -d "${pentest_dir}" ] && [ ! -d "${exploits_dir}" ]; then
    echo -n "exploits directory does not exist, creating... "
    if su - "${user}" -c "mkdir -p ${exploits_dir}" ; then
        echo "Done!"
    else
        echo -e "${red}Fail!${reset}\nSomething got wrong creating the exploits directory."
        exit 1
    fi
else
    echo "exploits directory OK!"
fi

if [ -d "${pentest_dir}" ] && [ ! -d "${infra_dir}" ]; then
    echo -n "infra tools directory does not exist, creating... "
    if su - "${user}" -c "mkdir -p ${infra_dir}" ; then
        echo "Done!"
    else
        echo -e "${red}Fail!${reset}\nSomething got wrong creating the infra tools directory."
        exit 1
    fi
else
    echo "infra-tools directory OK!"
fi


if [ -d "${pentest_dir}" ] && [ ! -d "${leaks_dir}" ]; then
    echo -n "linux tools directory does not exist, creating... "
    if su - "${user}" -c "mkdir -p ${leaks_dir}" ; then
        echo "Done!"
    else
        echo -e "${red}Fail!${reset}\nSomething got wrong creating the leaks directory."
        exit 1
    fi
else
    echo "leaks directory OK!"
fi

if [ -d "${pentest_dir}" ] && [ ! -d "${linux_dir}" ]; then
    echo -n "linux tools directory does not exist, creating... "
    if su - "${user}" -c "mkdir -p ${linux_dir}" ; then
        echo "Done!"
    else
        echo -e "${red}Fail!${reset}\nSomething got wrong creating the linux tools directory."
        exit 1
    fi
else
    echo "linux tools directory OK!"
fi

if [ -d "${pentest_dir}" ] && [ ! -d "${mobile_dir}" ]; then
    echo -n "mobile tools directory does not exist, creating... "
    if su - "${user}" -c "mkdir -p ${mobile_dir}" ; then
        echo "Done!"
    else
        echo -e "${red}Fail!${reset}\nSomething got wrong creating the mobile tools directory."
        exit 1
    fi
else
    echo "mobile tools directory OK!"
fi

if [ -d "${pentest_dir}" ] && [ ! -d "${pentest_scripts_dir}" ]; then
    echo -en "pentest-scripts directory does not exist, creating... "
    if su - "${user}" -c "git clone -q https://github.com/skateforever/pentest-scripts.git ${pentest_scripts_dir}"; then
        echo "Done!"
    else
        echo -e "${red}Fail!${reset}\nSomething got wrong creating the pentest-scripts directory."
        exit 1
    fi
else
    echo "pentest-scripts directory OK!"
fi

if [ -d "${pentest_dir}" ] && [ ! -d "${web_dir}" ]; then
    echo -n "web tools directory does not exist, creating... "
    if su - "${user}" -c "mkdir -p ${web_dir}" ; then
        echo "Done!"
    else
        echo -e "${red}Fail!${reset}\nSomething got wrong creating the web tools directory."
        exit 1
    fi
else
    echo "web tools directory OK!"
fi

if [ -d "${pentest_dir}" ] && [ ! -d "${wifi_dir}" ]; then
    echo -n "wifi tools directory does not exist, creating... "
    if su - "${user}" -c "mkdir -p ${wifi_dir}" ; then
        echo "Done!"
    else
        echo -e "${red}Fail!${reset}\nSomething got wrong creating the wifi tools directory."
        exit 1
    fi
else
    echo "wifi tools directory OK!"
fi

if [ -d "${pentest_dir}" ] && [ ! -d "${windows_dir}" ]; then
    echo -n "windows tools directory does not exist, creating... "
    if su - "${user}" -c "mkdir -p ${windows_dir}" ; then
        echo "Done!"
    else
        echo -e "${red}Fail!${reset}\nSomething got wrong creating the windows tools directory."
        exit 1
    fi
else
    echo "windows tools directory OK!"
fi

if [ -d "${pentest_dir}" ] && [ ! -d "${wordlists_dir}" ]; then
    echo -n "wordlists directory does not exist, creating... "
    if su - "${user}" -c "mkdir -p ${wordlists_dir}" ; then
        echo "Done!"
    else
        echo -e "${red}Fail!${reset}\nSomething got wrong creating the wordlists directory."
        exit 1
    fi
else
    echo "wordlists directory OK!"
fi

prepare_system(){
    echo -e "${yellow}Keep in mind, you need to have your system updated.${reset}"
    if [[ "${distribution}" == 'Arch_Linux' ]]; then
        echo -e "Prepare the system and install packages from ${yellow}pacman${reset}..."
        pacman -Syu --noconfirm
        pacman -Fy --noconfirm
        echo "Installing essential packages from pacman repositories..."
        pacman --noconfirm -S --needed base-devel bind chromium diffutils git jq nmap python-pip ruby whois unzip rubygems openssl p7zip
        echo "Verifying python and pip..."
        [[ -z $(command -v python2) ]] && echo "Installing python2..." ; pacman --noconfirm -S --needed "$(pacman -F /usr/bin/python2 | awk '{print $5}')" 
        [[ -z $(command -v pip2) ]] && echo "Installing pip2..." ; pacman --noconfirm -S --needed "$(pacman -F /usr/bin/pip2 | awk '{print $5}')"
        echo "Installing network tools and offensive tools..."
        pacman --noconfirm -S --needed nmap tcpdump whois openbsd-netcat bind-tools socat nikto sqlmap masscan hydra freerdp openvpn tigervnc john the_silver_searcher
        echo "Installing metasploit..."
        pacman --noconfirm -S --needed metasploit
    elif [[ "${distribution}" == 'Ubuntu' ]] || \
        [[ "${distribution}" == 'Debian' ]] || \
        [[ "${distribution}" == 'Debian_GNU_Linux' ]] || \
        [[ "${distribution}" == 'Kali' ]] || \
        [[ "${distribution}" == 'Kali_GNU_Linux' ]] ; then
        echo -e "Prepare the system and install packages from ${yellow}apt${reset}..."
        apt update
        sleep 10
        apt upgrade -y
        sleep 10
        echo "Installing essential packages from apt repositories..."
        apt -y install build-essential diffutils dnsutils bind9-host git jq nmap python3-pip python3-minimal ruby ruby-dev zlib1g-dev curl whois unzip rubygems-integration apt-file libcurl4-openssl-dev libssl-dev p7zip python3-curl
        sleep 10
        apt-file update
        sleep 10

        echo "Verifying python and pip... "
        [[ -z $(command -v python2) ]] && echo "Installing python2..." ; \
        # Modificado Amarelos # apt update ; \
        apt -y install python2.7
        [[ -z $(command -v pip2) ]] && echo "Installing pip2..." ; \
        # Modificado Amarelos # apt update ;\
        apt -y install "$(apt-file search /usr/bin/pip2 | awk -F':' '{print $1}')"
        python3_new_version=$(apt-file search /usr/bin/python3 | awk -F':' '{print $1}' | grep -E "^python3\..-minimal$" | sort -ru | sed 's/\-.*$//' | head -n1)
        if [[ -z $(command -v python3) ]]; then
            apt -y install "${python3_new_version}"
            sleep 10
        else
            python3_repository_version="$(apt-cache show "${python3_new_version}" | grep "^Version: " | awk -F': ' '{print $2}')"
            python3_installed_version="$(apt-cache show "$(dpkg -S /usr/bin/python3 | awk -F': ' '{print $1}')" | grep -E "^Version: " | awk -F': ' '{print $2}' | head -n1)"
            [[ "${python3_repository_version}" != "${python3_installed_version}" ]] && \
                echo "Installing new python3 version... " ; \
                # Modificado Amarelos # apt update ; \
                sleep 10 ; apt -y install "${python3_new_version}" 
        fi

        if [[ "${distribution}" == 'Ubuntu' ]]; then
            ubuntu_version=$(grep -E ^DISTRIB_RELEASE /etc/lsb-release | awk -F '=' '{print $2}' | awk -F '.' '{print $1}')
            apt -y install chromium-browser
            sleep 10
        else
            apt -y install chromium
            sleep 10
        fi

        echo "Installing network tools and offensive tools..."
        if [[ "${distribution}" == 'Debian' ]] || [[ "${distribution}" == "Debian_GNU_Linux" ]]; then
            nikto_count=$(apt-cache show nikto 2> /dev/null | grep -cE "^Package: nikto$")
            if [ "${nikto_count}" -eq 0 ]; then
                cp /etc/apt/sources.list /etc/apt/sources.list.orig
                sed -i -e '/deb.*main/s/$/ non-free/' /etc/apt/sources.list
                # Modificado Amarelos # apt update
                sleep 10
            fi
        fi
        
        apt -y install nmap tcpdump whois dnsutils bind9-host netcat-openbsd nikto sqlmap masscan hydra openvpn freerdp2-x11 tigervnc-viewer john silversearcher-ag
        sleep 10

        if [[ ! -x /usr/bin/msfconsole ]] && [[ ! -d /opt/metasploit-framework ]] && [[ "${distribution}" == 'Ubuntu' ]] || \
            [[ "${distribution}" == 'Debian' ]] || [[ "${distribution}" == "Debian_GNU_Linux" ]]; then
            echo "Installing Metasploit..."
            curl -s https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb > /tmp/msfinstall
            chmod 755 /tmp/msfinstall
            while [[ -z $(host -t A downloads.metasploit.com | grep "has address" | awk '{print $4}') ]]; do
                sleep 1
            done 
            /tmp/msfinstall
            rm /tmp/msfinstall
        elif [[ ! -x /usr/bin/msfconsole ]] && [[ ! -d /opt/metasploit-framework ]]; then
            echo "Installing Metasploit..."
            while [[ -z $(host -t A downloads.metasploit.com | grep "has address" | awk '{print $4}') ]]; do
                sleep 1
            done 
            apt -y install metasploit
        else
            echo "Metasploit already exists in the system!"
        fi

    else
        echo "This isn't the distribution that you use? What now??"
        echo "Do you want to help me with something? Pull request!"
        exit 1
    fi
}

go_bin(){
    go_version=$(go version 2> /dev/null | awk '{print $3}')
    go_new_version=$(curl -L -k -s https://golang.org/dl/ | grep -E "toggleVisible" | head -n 1 | sed -e 's/">$//' -e 's/<.*id="//')
    go_path_install=/usr/local/go
    go_binary="${go_path_install}/bin/go"
    if [ ! -x "${go_binary}" ]; then
        echo -en "Getting go binary... "
        if [ -d "${go_path_install}" ]; then
            rm -rf "${go_path_install}"
        fi
        if [ ! -d "${go_path_install}" ]; then
            go_package=$(curl -L -k -s https://golang.org/dl/ | grep -E "downloadBox.*${go_new_version}.linux" | sed -e 's/">$//' -e 's/<.*\///' 2> "${error_log_file}")
            if [ -z "${go_package}" ]; then
                echo -e "${red}Fail!${reset}\nUnable to get go new version"
                exit 1
            fi
            curl -k -s -L "https://golang.org/dl/${go_package}" -o "/tmp/${go_package}" 2> "${error_log_file}"
            if [ -s "/tmp/${go_package}" ]; then
                tar -xzf "/tmp/${go_package}" -C "/usr/local"
                if [ -x "${go_path_install}/bin/go" ]; then
                    rm -rf "/tmp/${go_package}"
                    [[ $(grep -q -E -A1 "GOROOT.*go" "${user_home}/.bashrc" 2> /dev/null ; echo $?) -ne 0 ]] && \
                        echo -e "\n#go binary\nexport GOROOT=/usr/local/go\nexport GOPATH=\${HOME}/go\nexport PATH=\${GOROOT}/bin:\"\${PATH}\"" >> "${user_home}/.bashrc"
                    [[ $(grep -q -E -A1 "GOROOT.*go" "/root/.bashrc" 2> /dev/null ; echo $?) -ne 0 ]] && \
                        echo -e "\n#go binary\nexport GOROOT=/usr/local/go\nexport GOPATH=\${HOME}/go\nexport PATH=\${GOROOT}/bin:\"\${PATH}\"" >> "/root/.bashrc"
                else
                    echo -e "${red}Fail!${reset}\nUnable do extract the go binary!"
                    exit 1
                fi
            else
                echo -e "${red}Fail!${reset}\nUnable to download the go package!"
                exit 1
            fi
        fi
        echo "Done!"
    else
        echo "Go binary already exists in the system!"
    fi
}

docker_system(){
    if [[ "${distribution}" == \"Arch\ Linux\" ]] && ! command -v docker > /dev/null 2>&1; then
        echo "Installing Docker..."
        pacman --noconfirm -S docker
    elif [[ "${distribution}" == 'Ubuntu' ]] || \
        [[ "${distribution}" == 'Debian' ]] || \
        [[ "${distribution}" == "Debian_GNU_Linux" ]] || \
        [[ "${distribution}" == "Kali_GNU_Linux" ]] \
        || [[ "${distribution}" == 'Kali' ]] && ! command -v docker > /dev/null 2>&1; then
        echo -en "Installing Docker... "
        curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add 
        echo "deb [arch=amd64] https://download.docker.com/linux/debian stretch stable" >> /etc/apt/sources.list
        # Modificado Amarelos # apt-get update
        # Modificado Amarelos # apt-get -y install docker-ce
    fi

    if [ -x "$(command -v docker)" ]; then
        echo -en "Verifying if docker was started... "
        if ! pgrep dockerd > /dev/null ; then
            echo "Done!"
            echo -en "Starting up the docker and put it to initialize with the system... "
            systemctl start docker.service
            sleep 2
            systemctl enable docker.service
            sleep 2
            echo "Done!"
        else
            echo "Done!"
        fi

        echo -en "Verifying if docker is running... "
        if [[ $(pgrep dockerd > /dev/null ; echo $?) -eq 0 ]]; then
            echo "Done!"
            echo -en "Checking if the user is in the docker group... "
            if [[ -z $(su - "${user}" -c "groups | grep docker") ]]; then
                echo "Done!"
                echo -en "Putting the user in the docker group... "
                if [[ $(usermod -aG docker "${user}" ; echo $?) -eq 0 ]]; then
                    echo "Done!"
                else
                    echo -e "${red}Fail!${reset}\nDoes not possible put the ${user} on docker group!"
                    exit 1
                fi
            else
                echo "Done!"
            fi
            if [[ -n $(su - "${user}" -c "groups | grep docker") ]]; then
                echo -en "Verifying if there is a privoxy image... " 
                privoxy_image="$(su - "${user}" -c "docker images | grep -E \"^[p]rivoxy\" | awk '{print \$1}'")"
                if [[ -z "${privoxy_image}" ]]; then
                    echo "Done!"
                    unset privoxy_image
                    echo -en "Getting the Privoxy Image to use with collector and others tools... "
                    su - "${user}" -c "docker build -t privoxy ${pentest_scripts_dir}/infra/tor/tor-docker/ > /dev/null 2> ${error_log_file}"
                    privoxy_image=$(su - "${user}" -c "docker images | grep -E \"^[p]rivoxy\" | awk '{print \$1}'")
                    if [[ -n "${privoxy_image}" ]]; then
                        echo "Done!"
                    else
                        echo -e "${red}Fail!${reset}\nCouldn't get Privoxy's image!"
                        cat "${error_log_file}"
                        rm -rf "${error_log_file}"
                        exit 1
                    fi
                else
                    echo "Done!"
                    echo "privoxy image already exists in the system!"
                fi     
            else
                echo -e "${red}Fail!${reset}\nUser is not in docker group!"
                exit 1
            fi
        else
            echo -e "${red}Fail!${reset}\nDocker is not running!"
            exit 1
        fi
    else
        echo -e "${red}Fail!${reset}\nMake sure you have docker installed!"
        exit 1
    fi
}

exploits(){
    nuclei_bin=$(command -v nuclei)
    searchsploit_bin=$(command -v searchsploit)

    if [ ! -x "${nuclei_bin}" ]; then
        echo -en "Getting nuclei binary... "
        nuclei_version=$(curl -s https://github.com/projectdiscovery/nuclei/releases/latest | sed -e 's/<.*http.*\/\///' -e 's/".*>$//' | awk -F'/' '{print $6}')
        nuclei_url="https://github.com/projectdiscovery/nuclei/releases/download/${nuclei_version}/nuclei_${nuclei_version:1}_linux_amd64.zip"
        nuclei_file="/tmp/nuclei_${nuclei_version}.zip"
        su - "${user}" -c "curl -sL ${nuclei_url} -o ${nuclei_file} 2> ${error_log_file}"
        if [ -s "${nuclei_file}" ]; then
            unzip -q "${nuclei_file}" nuclei -d "${binary_dir}" nuclei 2> "${error_log_file}"
            if [ -x "$(command -v nuclei)" ]; then
                rm -rf "${nuclei_file}"
                su - "${user}" -c "nuclei -silent -update-directory ${exploits_dir}/ -update-templates 2> ${error_log_file}"
                echo "Done!"
            else
                echo -e "${red}Fail!${reset}\nCould not extract ${nuclei_file}!"
                cat "${error_log_file}"
                rm -rf "${error_log_file}"
                exit 1
            fi
        else
            echo -e "${red}Fail!${reset}\nUnable to download nuclei!"
            exit 1
        fi
    else
        echo "nuclei already exists in the system!"
    fi

    if [ ! -x "${searchsploit_bin}" ]; then
        echo -en "Getting searchsploit... "
        rm -rf "${exploits_dir}/exploitdb" > /dev/null 2>&1
        su - "${user}" -c "git clone -q https://github.com/offensive-security/exploitdb.git ${exploits_dir}/exploitdb 2> ${error_log_file}"
        if [ -x "${exploits_dir}/exploitdb/searchsploit" ]; then
            su - "${user}" -c "sed -i 's-/opt-${exploits_dir}-' ${exploits_dir}/exploitdb/.searchsploit_rc"
            ln -s "${exploits_dir}/exploitdb/searchsploit" "${binary_dir}" 2> "${error_log_file}"
            if [ -x "$(command -v searchsploit)" ]; then
                echo "Done!"
            else
                echo -e "${red}Fail!${reset}\nSearchsploit script symbolic link could not be created!"
                cat "${error_log_file}"
                rm -rf "${error_log_file}"
                exit 1
            fi
        else
            echo -e "${red}Fail!${reset}\nUnable to download searchsploit repository!"
            exit 1
        fi
    else
        echo "searchsploit already exists in the system!"
    fi

    # Exploits
    echo -en "Getting some exploits... "
    [ ! -d "${exploits_dir}/CVE-2019-2725" ] && \
        su - "${user}" -c "git clone -q https://github.com/pimps/CVE-2019-2725.git ${exploits_dir}/CVE-2019-2725 2> /dev/null"
    [ ! -d "${exploits_dir}/CVE-2017-1000486" ] && \
        su - "${user}" -c "git clone -q https://github.com/pimps/CVE-2017-1000486.git ${exploits_dir}/CVE-2017-1000486 2> /dev/null"
    [ ! -d "${exploits_dir}/CVE-2017-5645" ] && \
        su - "${user}" -c "git clone -q https://github.com/pimps/CVE-2017-5645.git ${exploits_dir}/CVE-2017-5645 2> /dev/null"
    [ ! -f "${exploits_dir}/ysoserial-pimps.jar" ] && \
        su - "${user}" -c "wget --quiet -c https://github.com/pimps/ysoserial-modified/raw/master/target/ysoserial-modified.jar -O ${exploits_dir}/ysoserial-pimps.jar 2> /dev/null"
    [ ! -d "${exploits_dir}/CVE-2018-7600" ] && \
        su - "${user}" -c "git clone -q https://github.com/pimps/CVE-2018-7600.git ${exploits_dir}/CVE-2018-7600 2> /dev/null"
    [ ! -d "${exploits_dir}/0xdea-exploits" ] && \
        su - "${user}" -c "git clone -q https://github.com/0xdea/exploits.git ${exploits_dir}/0xdea-exploits 2> /dev/null"
    [ ! -d "${exploits_dir}/Blacklist3r" ] && \
        su - "${user}" -c "git clone -q https://github.com/NotSoSecure/Blacklist3r.git ${exploits_dir}/Blacklist3r 2> /dev/null"
    [ ! -f "${exploits_dir}/Blacklist3r/AspDotNetWrapper.zip" ] && \
        su - "${user}" -c "wget --quiet -c https://github.com/NotSoSecure/Blacklist3r/releases/download/3.0/AspDotNetWrapper.zip -O ${exploits_dir}/Blacklist3r/AspDotNetWrapper.zip 2> /dev/null"
    [ ! -d "${exploits_dir}/MS17-010" ] && \
        su - "${user}" -c "git clone -q https://github.com/worawit/MS17-010.git ${exploits_dir}/MS17-010 2> /dev/null"
    # https://github.com/fnmsd/zimbra_poc
    # https://github.com/jas502n/CVE-2019-13272
    # https://github.com/shelld3v/JSshell
    echo "Done!"

    # Vulns Scan
    echo -en "Vulns Scan... "
    [[ ! -d "${exploits_dir}/vulnscan" ]] && su - "${user}" -c "git clone -q https://github.com/scipag/vulscan ${exploits_dir}/vulnscan 2> /dev/null"
    [[ ! -d "${exploits_dir}/blackhat-arsenal-tools" ]] && su - "${user}" -c "git clone -q https://github.com/toolswatch/blackhat-arsenal-tools ${exploits_dir}/blackhat-arsenal-tools 2> /dev/null"
    [[ ! -d "${exploits_dir}/vuls" ]] && su - "${user}" -c "git clone -q https://github.com/future-architect/vuls ${exploits_dir}/vuls 2> /dev/null"
    # CoronaBlue/SMBGhost
    [[ ! -d "${exploits_dir}/CVE-2020-0796-PoC" ]] && su - "${user}" -c "git clone -q https://github.com/eerykitty/CVE-2020-0796-PoC ${exploits_dir}/CVE-2020-0796-PoC 2> /dev/null"
    [[ ! -d "${exploits_dir}/SMBGhost" ]] && su - "${user}" -c "git clone -q https://github.com/ioncodes/SMBGhost ${exploits_dir}/SMBGhost 2> /dev/null"
    echo "Done!"
}

infra(){
    amass_bin=$(command -v amass)
    massdns_bin=$(command -v massdns)
    dnsrecon_bin=$(command -v dnsrecon)
    dnssearch_bin=$(command -v dnssearch)

    if [ ! -x "${amass_bin}" ]; then
        echo -en "Getting amass binary... "
        amass_version=$(curl -s https://github.com/OWASP/Amass/releases/latest | sed -e 's/<.*http.*\/\///' -e 's/".*>$//' | awk -F'/' '{print $6}')
        amass_url="https://github.com/OWASP/Amass/releases/download/${amass_version}/amass_linux_amd64.zip"
        su - "${user}" -c "curl -k -s -L ${amass_url} -o ${infra_dir}/amass_linux_amd64.zip 2> ${error_log_file}"
        if [ -s "${infra_dir}/amass_linux_amd64.zip" ] ; then
            su - "${user}" -c "unzip -q ${infra_dir}/amass_linux_amd64.zip -d ${infra_dir} 2> ${error_log_file}"
            su - "${user}" -c "mv ${infra_dir}/amass_linux_amd64 ${infra_dir}/amass 2> ${error_log_file}"
            if [ -x "${infra_dir}/amass/amass" ]; then
                mv "${infra_dir}/amass/amass" "${binary_dir}" 2> "${error_log_file}"
                if [ -x "$(command -v amass)" ]; then
                    rm -rf "${infra_dir}/amass_linux_amd64.zip"
                    echo "Done!"
                else
                    echo -e "${red}Fail!${reset}\nCould not possible move amass to ${binary_dir}!"
                    cat "${error_log_file}"
                    rm -rf "${error_log_file}"
                    exit 1
                fi
            else
                echo -e "${red}Fail!${reset}\nCould not possible extract amass!"
                cat "${error_log_file}"
                rm -rf "${error_log_file}"
                exit 1
            fi
        else
            echo -e "${red}Fail!${reset}\nUnable to download amass!"
            cat "${error_log_file}"
            rm -rf "${error_log_file}"
            exit 1
        fi
    else
        echo "amass already exists in the system!"
    fi

    if [ ! -x "${dnsrecon_bin}" ]; then
        echo -en "Getting dnsrecon python script... "
        rm -rf "${infra_dir}/dnsrecon" > /dev/null 2> "${error_log_file}"
        dnsrecon_bin="${binary_dir}/dnsrecon"
        su - "${user}" -c "git clone -q https://github.com/darkoperator/dnsrecon.git ${infra_dir}/dnsrecon 2> ${error_log_file}"
        if [ -d "${infra_dir}/dnsrecon" ]; then
            pip3 install -q -r "${infra_dir}/dnsrecon/requirements.txt" 2> "${error_log_file}"
            ln -s "${infra_dir}/dnsrecon/dnsrecon.py" "${dnsrecon_bin}" 2> "${error_log_file}"
            if [ -x "$(command -v dnsrecon)" ]; then
                echo "Done!"
            else
                echo -e "${red}Fail!${reset}\nSomething got wrong creating symlink for dnsrecon!"
                cat "${error_log_file}"
                rm -rf "${error_log_file}"
                exit 1
            fi
        else
            echo -e "${red}Fail!${reset}\nUnable to download dnsrecon!" 
            cat "${error_log_file}"
            rm -rf "${error_log_file}"
            exit 1
        fi
    else
        echo "dnsrecon already exists in the system!"
    fi

    if [ ! -x "${dnssearch_bin}" ]; then
        echo -en "Getting dnssearch... "
        su - "${user}" -c "export GOROOT=/usr/local/go ; export GOPATH=${user_home}/go ; ${go_binary} get github.com/evilsocket/dnssearch > /dev/null 2> ${error_log_file}"
        if [ -x "${user_home}/go/bin/dnssearch" ] ; then
            mv "${user_home}/go/bin/dnssearch" "${binary_dir}" 2> "${error_log_file}"
            if [ -x "$(command -v dnssearch)" ]; then
                echo "Done!"
            else
                echo -e "${red}Fail!${reset}\nCould not possible move dnssearch to ${binary_dir}!" 
                cat "${error_log_file}"
                rm -rf "${error_log_file}"
                exit 1
            fi
        else
            echo -e "${red}Fail!${reset}\nUnable to download dnssearch!"
            cat "${error_log_file}"
            rm -rf "${error_log_file}"
            exit 1
        fi
    else
        echo "dnssearch already exists in the system!"
    fi

    if [ ! -x "${massdns_bin}" ]; then
        echo -en "Getting massdns binary... "
        rm -rf "${infra_dir}/massdns" 2> "${error_log_file}"
        su - "${user}" -c "git clone -q https://github.com/blechschmidt/massdns.git ${infra_dir}/massdns 2> ${error_log_file}"
        if [ -d "${infra_dir}/massdns" ]; then
            su - "${user}" -c "cd ${infra_dir}/massdns ; make > /dev/null 2> ${error_log_file}"
            if [ -x "${infra_dir}/massdns/bin/massdns" ]; then
                su - "${user}" -c "curl -s https://public-dns.info/nameservers.txt -o ${wordlists_dir}/resolvers.txt 2> ${error_log_file}"
                mv "${infra_dir}/massdns/bin/massdns" "${binary_dir}" 2> "${error_log_file}"
                cp -a "${infra_dir}"/massdns/scripts/* "${binary_dir}" 2> "${error_log_file}"
                sed -i '1s/python/python3/' "${binary_dir}/censys-extract.py"
                sed -i '1s/python/python3/' "${binary_dir}/dnsparse.py"
                sed -i '1s/python/python3/' "${binary_dir}/ptr.py"
                sed -i '1s/python/python3/' "${binary_dir}/subbrute.py"
                if [ -x "$(command -v massdns)" ]; then
                    echo "Done!"
                else
                    echo -e "${red}Fail!${reset}\nCould not possible move httprobe to ${binary_dir}!"
                    cat "${error_log_file}"
                    rm -rf "${error_log_file}"
                    exit 1 
                fi
            else
                echo -e "${red}Fail!${reset}\nmassdns could not be compiled!"
                cat "${error_log_file}"
                rm -rf "${error_log_file}"
                exit 1
            fi
        else
            echo -e "${red}Fail!${reset}\nUnable to download massdns repository!"
            cat "${error_log_file}"
            rm -rf "${error_log_file}"
            exit 1
        fi
    else
        echo "massdns already exists in the system!"
    fi

}

# working
linux_exploitation(){
    if [ ! -d "${linux_dir}/crowbar" ]; then
        echo -en "Getting crowbar... "
        su - "${user}" -c "git clone -q https://github.com/galkan/crowbar.git ${linux_dir}/crowbar 2> /dev/null"
        pip2 install -q paramiko 2> /dev/null
        echo "Done!"
    fi

    echo -en "Getting tools to local enumeration... "
    # Get pyspy
    [[ ! -d "${linux_dir}/LinEnum" ]] && \
        su - "${user}" -c "git clone -q https://github.com/rebootuser/LinEnum.git ${linux_dir}/LinEnum 2> /dev/null"
    [[ ! -d "${linux_dir}/linuxprivchecker" ]] && \
        su - "${user}" -c "git clone -q https://github.com/linted/linuxprivchecker ${linux_dir}/linuxprivchecker 2> /dev/null"
    [[ ! -d "${linux_dir}/linux-smart-enumeration" ]] && \
        su - "${user}" -c "git clone -q https://github.com/diego-treitos/linux-smart-enumeration ${linux_dir}/linux-smart-enumeration 2> /dev/null"
    echo "Done!"

    if [ ! -d "${linux_dir}/ssh-user-enumeration" ]; then 
        echo -en "Getting SSH tools to enumerate users... "
        su - "${user}" -c "git clone -q https://github.com/BlackDiverX/ssh-user-enumeration.git ${linux_dir}/ssh-user-enumeration 2> /dev/null"
        pip3 install -q -r "${linux_dir}/ssh-user-enumeration/requirements.txt" 2> /dev/null
        echo "Done!"
    fi
}

mobile_android(){
    android_dir="${mobile_dir}/android"
    [[ ! -d "${android_dir}" ]] && su - "${user}" -c "mkdir -p ${android_dir}"

    if [ ! -s "${android_dir}/AXMLPrinter2.jar" ]; then
        echo -en "Getting AXMLPrinter... "
        su - "${user}" -c "curl -L -s -k https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/android4me/AXMLPrinter -o ${android_dir}/AXMLPrinter2.jar"
        if [ -s "${android_dir}/AXMLPrinter2.jar" ]; then
            echo "Done!"
        else
            echo -e "\n${red}Fail!${reset}Unable to AXMLPrinter2!"
        fi
    else
        echo "AXMLPrinter2 already exists in the system!"
    fi

    if [ ! -x "${android_dir}/apkleaks/apkleaks.py" ]; then
        echo -en "Getting apkleaks... "
        su - "${user}" -c "git clone -q https://github.com/dwisiswant0/apkleaks.git ${android_dir}/apkleaks"
        if [ -x "${android_dir}/apkleaks/apkleaks.py" ]; then
            echo "Done!"
        else
            echo -e "${red}Fail!${reset}\nUnable to download apkleaks!"
            cat "${error_log_file}"
            rm -rf "${error_log_file}"
            exit 1
        fi
    else
        echo "apkleaks already exists in the system!"
    fi

    if [ ! -s "${android_dir}/apktool.jar" ]; then
        echo -en "Getting apktool... "
        apktool_version=$(su - "${user}" -c "curl -s https://bitbucket.org/iBotPeaches/apktool/downloads/ | grep -E 'apktool.*\.jar' | sed -e 's/<\/a>//' -e 's/^[[:space:]]*.*>//' | head -n1")
        su - "${user}" -c "curl -sL https://bitbucket.org/iBotPeaches/apktool/downloads/${apktool_version} -o ${android_dir}/apktool.jar 2> ${error_log_file}"
        if [ -s "${android_dir}/apktool.jar" ]; then
            echo "Done!"
        else
            echo -e "${red}Fail!${reset}\nUnable to download apktool!"
            cat "${error_log_file}"
            rm -rf "${error_log_file}"
            exit 1
        fi
    else
        echo "apktool already exists in the system!"
    fi

    if [ ! -s "${android_dir}/baksmali.jar" ]; then
        echo -en "Getting baksmali... "
        baksmali_version=$(curl -s https://github.com/JesusFreke/smali/releases | grep -E "releases/tag" | sed -e 's/[[:space:]]*<.*\///' -e 's/">//' | head -n1)
        su - "${user}" -c "curl -sL https://bitbucket.org/JesusFreke/smali/downloads/baksmali-${baksmali_version:1}.jar -o ${android_dir}/baksmali.jar 2> ${error_log_file}"
        if [[ -s "${android_dir}/baksmali.jar" ]]; then
            echo "Done!"
        else
            echo -e "${red}Fail!${reset}\nUnable to download baksmali!"
            cat "${error_log_file}"
            rm -rf "${error_log_file}"
            exit 1
        fi
    else
        echo "baksmali already exists in the system!"
    fi

    if [ ! -s "${android_dir}/bytecode-viewer.jar" ]; then
        echo -en "Getting bytecode-viewer... "
        bytecodeviewer_version=$(curl -s https://github.com/Konloch/bytecode-viewer/releases/latest | sed -e 's/<.*http.*\/\///' -e 's/".*>$//' | awk -F'/' '{print $6}')
        su - "${user}" -c "curl -sL https://github.com/Konloch/bytecode-viewer/releases/download/${bytecodeviewer_version}/Bytecode-Viewer-${bytecodeviewer_version:1}.jar -o ${android_dir}/bytecode-viewer.jar 2> ${error_log_file}"
        if [ -s "${android_dir}/bytecode-viewer.jar" ]; then
            echo "Done!"
        else
            echo -e "${red}Fail!${reset}\nUnable to download bytecode viewer!"
            cat "${error_log_file}"
            rm -rf "${error_log_file}"
            exit 1
        fi
    else
        echo "bytecode viewer already exists in the system!"
    fi

    if [ ! -d "${android_dir}/dex2jar" ]; then
        echo -en "Getting dex2jar... "
        su - "${user}" -c "git clone -q https://gitlab.com/kalilinux/packages/dex2jar ${android_dir}/dex2jar 2> ${error_log_file}"
        if [ -d "${android_dir}/dex2jar" ]; then
            echo "Done!"
        else
            echo -e "${red}Fail!${reset}\nUnable to download dex2jar!"
            cat "${error_log_file}"
            rm -rf "${error_log_file}"
            exit 1
        fi
    else
        echo "dex2jar already exists in the system!"
    fi
    
    android_arch=(arm arm64 x86 x86_64)
    frida_version=$(curl -s https://github.com/frida/frida/releases/latest | sed -e 's/<.*http.*\/\///' -e 's/".*>$//' | awk -F'/' '{print $6}')
    frida_types=(server gadget)
    for arch in "${android_arch[@]}"; do
        for frida_type in "${frida_types[@]}"; do
            if [ "${frida_type}" == "gadget" ]; then
                file_extension=".so"
            fi
            if [ ! -s "${android_dir}/frida-${frida_type}-${arch}${file_extension}" ]; then
                echo -en "Getting frida ${frida_type} android ${arch}... "
                su - "${user}" -c "curl -sL https://github.com/frida/frida/releases/download/${frida_version}/frida-${frida_type}-${frida_version}-android-${arch}${file_extension}.xz -o ${android_dir}/frida-${frida_type}-${frida_version}-android-${arch}${file_extension}.xz 2> ${error_log_file}"
                if [ -s "${android_dir}/frida-${frida_type}-${frida_version}-android-${arch}${file_extension}.xz" ]; then
                    echo "Done!"
                    echo -en "Extracting ${android_dir}/frida-${frida_type}-${frida_version}-android-${arch}${file_extension}... "
                    su - "${user}" -c "xz -d ${android_dir}/frida-${frida_type}-${frida_version}-android-${arch}${file_extension}.xz 2> ${error_log_file}"
                    su - "${user}" -c "mv ${android_dir}/frida-${frida_type}-${frida_version}-android-${arch}${file_extension} ${android_dir}/frida-${frida_type}-${arch}${file_extension} 2> ${error_log_file}"
                    if [ -s "${android_dir}/frida-${frida_type}-${arch}${file_extension}" ]; then
                        echo "Done!"
                    else
                        echo -e "${red}Fail!${reset}\nCould not extract frida-${frida_type}-${frida_version}-android-${arch}${file_extension}!"
                        cat "${error_log_file}"
                        rm -rf "${error_log_file}"
                        exit 1
                    fi
                else
                    echo "Fail!"
                    echo -e "${red}Fail!${reset}Unable to download frida-${frida_type}-${arch}${file_extension}."
                    cat "${error_log_file}"
                    rm -rf "${error_log_file}"
                    exit 1
                fi
            else
                echo "frida ${frida_type} android ${arch} already exists in the system!"
            fi
            unset file_extension
        done
    done

    if [ -z "$(command -v frida)" ]; then
        echo -en "Getting frida client tools... "
        pip3 install -q frida-tools 2> "${error_log_file}"
        if [ -n "$(command -v frida)" ]; then
            echo "Done!"
        else
            echo -e "${red}Fail!${reset}\nUnable to download frida client tools!"
            cat "${error_log_file}"
            rm -rf "${error_log_file}"
            exit 1
        fi
    else
        echo "frida client tools already exists in the system!"
    fi

    if [ ! -x "${android_dir}/jadx/bin/jadx" ]; then
        echo -en "Getting jadx... "
        jadx_version=$(curl -s https://github.com/skylot/jadx/releases/latest | sed -e 's/<.*http.*\/\///' -e 's/".*>$//' | awk -F'/' ' {print $6}')
        jadx_file="${android_dir}/jadx-${jadx_version:1}.zip"
        su - "${user}" -c "curl -sL https://github.com/skylot/jadx/releases/download/${jadx_version}/jadx-${jadx_version:1}.zip -o ${jadx_file} 2> ${error_log_file}"
        if [ -s "${jadx_file}" ]; then
            echo "Done!"
            echo -en "Extracting ${jadx_file}... "
            su - "${user}" -c "unzip -q ${jadx_file} -d ${android_dir}/jadx 2> ${error_log_file}"
            if [ -x "${android_dir}/jadx/bin/jadx" ]; then
                rm -rf "${jadx_file}"
                echo "Done!"
            else
                echo -e "${red}Fail!${reset}\nCould not extract /tmp/jadx-${jadx_version:1}.zip!"
                cat "${error_log_file}"
                rm -rf "${error_log_file}"
                exit 1
            fi 
        else
            echo -e "${red}Fail!${reset}\nUnable to download jadx!"
            cat "${error_log_file}"
            rm -rf "${error_log_file}"
            exit 1
        fi
    else
        echo "jadx already exists in the system!"
    fi

    if [ ! -s "${android_dir}/jd-gui.jar" ]; then
        echo -en "Getting jd-gui... "
        jdgui_version=$(curl -s https://github.com/java-decompiler/jd-gui/releases/latest | sed -e 's/<.*http.*\/\///' -e 's/".*>$//' | awk -F'/' ' {print $6}')
        su - "${user}" -c "curl -sL https://github.com/java-decompiler/jd-gui/releases/download/${jdgui_version}/jd-gui-${jdgui_version:1}.jar -o ${android_dir}/jd-gui.jar 2> ${error_log_file}"
        if [ -s "${android_dir}/jd-gui.jar" ]; then
            echo "Done!"
        else
            echo -e "${red}Fail!${reset}\nUnable to download jd-gui!"
            cat "${error_log_file}"
            rm -rf "${error_log_file}"
            exit 1
        fi
    else
        echo "jd-gui already exists in the system!"
    fi

    if [ ! -d "${android_dir}/MARA_Framework" ]; then
        echo -en "Getting MARA framework... "
        su - "${user}" -c "git clone -q https://github.com/xtiankisutsa/MARA_Framework.git ${android_dir}/MARA_Framework 2> ${error_log_file}"
        if [ -d "${android_dir}/MARA_Framework" ]; then
            echo "Done!"
        else
            echo -e "${red}Fail!${reset}\nUnable to download MARA framework!"
            cat "${error_log_file}"
            rm -rf "${error_log_file}"
            exit 1
        fi
    else
        echo "mara already exists in the system!"
    fi

# Modificado por Amarelos #
    #mobsf_imagem=$(docker images | awk '{print $1}' | grep -E '^opensecurity.*mobsf$' | uniq)
    #if [ -z "${mobsf_imagem}" ]; then
    #    echo -en "Getting mobsf docker image... "
    #    su - "${user}" -c "docker pull -q opensecurity/mobile-security-framework-mobsf > /dev/null 2> ${error_log_file}"
    #    mobsf_imagem=$(docker images | awk '{print $1}' | grep -E '^opensecurity.*mobsf$' | uniq)
    #    if [ -n "${mobsf_imagem}" ]; then
    #        echo "Done!"
    #    else
    #        echo -e "${red}Fail!${reset}\nUnable to download mobsf docker image!"
    #        cat "${error_log_file}"
    #        rm -rf "${error_log_file}"
    #        exit 1
    #    fi
    #else
    #    echo "mobsf docker image already exists in the system!"
    #fi
    
    if [ -z "$(command -v objection)" ]; then
        echo -en "Getting objection... "
        pip3 install -q objection 2> "${error_log_file}"
        if [ -n "$(command -v objection)" ]; then
            echo "Done!"
        else
            echo -e "${red}Fail!${reset}\nUnable to download objection!" 
            cat "${error_log_file}"
            rm -rf "${error_log_file}"
            exit 1
        fi
    else
        echo "objection already exists in the system!"
    fi

    if [ ! -x "$(command -v pidcat)" ]; then
        echo -en "Getting pidcat... "
        su - "${user}" -c "git clone -q https://github.com/JakeWharton/pidcat.git ${android_dir}/pidcat 2> ${error_log_file}"
        if [ -x "${android_dir}/pidcat/pidcat.py" ]; then
            ln -s "${android_dir}/pidcat/pidcat.py" "${binary_dir}/pidcat" 2> "${error_log_file}"
            if [ -x "$(command -v pidcat)" ]; then
                echo "Done!"
            else
                echo -e "${red}Fail!${reset}\nUnable to create symlink for pidcat!"
                cat "${error_log_file}"
                rm -rf "${error_log_file}"
                exit 1
            fi            
        else
            echo -e "${red}Fail!${reset}\nUnable to download pidcat!" 
            cat "${error_log_file}"
            rm -rf "${error_log_file}"
            exit 1
        fi
    else
        echo "pidcat already exists in the system!"
    fi

    if [ ! -s "${android_dir}/smali.jar" ]; then
        echo -en "Getting smali... "
        smali_version=$(curl -s https://github.com/JesusFreke/smali/releases | grep -E "releases/tag" | sed -e 's/[[:space:]]*<.*\///' -e 's/">//' | head -n1)
        su - "${user}" -c "curl -sL https://bitbucket.org/JesusFreke/smali/downloads/smali-${smali_version:1}.jar -o ${android_dir}/smali.jar 2> ${error_log_file}"
        if [ -s "${android_dir}/smali.jar" ]; then
            echo "Done!"
        else
            echo -e "${red}Fail!${reset}\nUnable to download smali!"
            cat "${error_log_file}"
            rm -rf "${error_log_file}"
            exit 1
        fi
    else
        echo "smali already exists in the system!"
    fi
}

osint_exploitation(){
    reconng_bin=$(command -v recon-ng)
    theharvester_bin=$(command -v theHarvester)

    if [ ! -x "${reconng_bin}" ]; then
        echo -en "Getting recon-ng python script... "
        rm -rf "${osint_dir}/recon-ng" > /dev/null 2> "${error_log_file}"
        su - "${user}" -c "git clone -q https://github.com/lanmaster53/recon-ng.git ${osint_dir}/recon-ng 2> ${error_log_file}"
        if [ -d "${osint_dir}/recon-ng" ]; then
            if [ -x "${osint_dir}/recon-ng/recon-ng" ]; then
                pip3 install -q -r "${osint_dir}/recon-ng/REQUIREMENTS" 2> "${error_log_file}"
                ln -s "${osint_dir}/recon-ng/recon-ng" /usr/local/bin/ 2> "${error_log_file}"
                if [ -x "$(command -v recon-ng)" ]; then
                    echo "Done!"
                else
                    echo -e "${red}Fail!${reset}\nRecon-ng script symbolic link could not be created!"
                    cat "${error_log_file}"
                    rm -rf "${error_log_file}"
                    exit 1
                fi
            else
                echo -e "${red}Fail!${reset}\nCould not find recon-ng script!"
                cat "${error_log_file}"
                rm -rf "${error_log_file}"
                exit 1
            fi
        else
            echo -e "${red}Fail!${reset}\nCould not get recon-ng repository!"
            cat "${error_log_file}"
            rm -rf "${error_log_file}"
            exit 1
        fi
    else
        echo "recon-ng already exists in the system!"
    fi

    if [ ! -x "${theharvester_bin}" ]; then
        echo -en "Getting theHarvester python script... "
        rm -rf "${osint_dir}/theHarvester" > /dev/null 2> "${error_log_file}"
        su - "${user}" -c "git clone -q https://github.com/laramies/theHarvester.git ${osint_dir}/theHarvester 2> ${error_log_file}"
        if [ -d "${osint_dir}/theHarvester" ]; then
            if [ -x "${osint_dir}/theHarvester/theHarvester.py" ]; then
                if [[ "${distribution}" == 'Ubuntu' ]] && [[ "${ubuntu_version}" -le 18 ]] && [[ -n $(command -v "${python3_new_version}") ]]; then
                    ${python3_new_version} -m pip install -q pip
                    pip3 install -q -r "${osint_dir}/theHarvester/requirements.txt" > /dev/null 2> "${error_log_file}"
                    su - "${user}" -c "sed -i 's/python3/${python3_new_version}/' ${osint_dir}/theHarvester/theHarvester.py"
                    ln -s "${osint_dir}/theHarvester/theHarvester.py" "${binary_dir}/theHarvester" 2> "${error_log_file}"
                else
                    pip3 install -q -r "${osint_dir}/theHarvester/requirements.txt"
                    ln -s "${osint_dir}/theHarvester/theHarvester.py" "${binary_dir}/theHarvester" 2> "${error_log_file}"
                fi
                if [ -x "$(command -v theHarvester)" ]; then
                    echo "Done!"
                else
                    echo -e "${red}Fail!${reset}\ntheHarvester script symbolic link could not be created!"
                    cat "${error_log_file}"
                    rm -rf "${error_log_file}"
                    exit 1
                fi
            else
                echo -e "${red}Fail!${reset}\nCould not find theHarvester script!"
                cat "${error_log_file}"
                rm -rf "${error_log_file}"
                exit 1
            fi
        else
            echo -e "${red}Fail!${reset}\nCould not get theHarvester repository!"
            cat "${error_log_file}"
            rm -rf "${error_log_file}"
            exit 1
        fi
    else
        echo "theHarvester already exists in the system!"
    fi

    echo -n "Getting some tools to Github OSINT... "
    [ ! -d "${osint_dir}/github-search" ] && \
        su - "${user}" -c "git clone -q https://github.com/gwen001/github-search.git ${osint_dir}/github-search 2> /dev/null"
    [ ! -d "${osint_dir}/GitTools" ] && \
        su - "${user}" -c "git clone -q https://github.com/internetwache/GitTools.git ${osint_dir}/GitTools 2> /dev/null"
    [ ! -d "${osint_dir}/GSIL" ] && \
        su - "${user}" -c "git clone -q https://github.com/FeeiCN/GSIL ${osint_dir}/GSIL 2> /dev/null"
    if [ -z "$(command -v cloudbrute)" ]; then
        cloudbrute_version=$(curl -s https://github.com/0xsha/CloudBrute/releases/latest | sed -e 's/<.*http.*\/\///' -e 's/".*>$//' | awk -F'/' '{print $6}')
        cloudbrute_url="https://github.com/0xsha/CloudBrute/releases/download/v1.0.5/cloudbrute_${cloudbrute_version:1}_Linux_x86_64.tar.gz"
        cloudbrute_file="/tmp/cloudbrute_${cloudbrute_version:1}_Linux_x86_64.tar.gz"
        cloudbrute_dir="${osint_dir}/cloudbrute"
        [[ ! -d "${cloudbrute_dir}" ]] && su - "${user}" -c "mkdir -p ${cloudbrute_dir}"
        su - "${user}" -c "curl -sL ${cloudbrute_url} -o ${cloudbrute_file} 2> /dev/null"
        [[ -e "${cloudbrute_file}" ]] && su - "${user}" -c "tar xf ${cloudbrute_file} -C ${cloudbrute_dir} 2> /dev/null"
        [[ -x "${cloudbrute_dir}/cloudbrute" ]] && ln -s "${cloudbrute_dir}/cloudbrute" "${binary_dir}" 2> /dev/null
        [[ -x "${binary_dir}/cloudbrute" ]] && rm -rf "${cloudbrute_file}"
    fi
    echo "Done!"
}

payloads(){
    su - "${user}" -c "git clone -q https://github.com/payloadbox/sql-injection-payload-list ${pentest_payloads_dir}/sql-injejction-payload-list"
}

web_exploitation(){
    aquatone_bin=$(command -v aquatone)
    dirsearch_bin=$(command -v dirsearch)
    ffuf_bin=$(command -v ffuf)
    gf_bin=$(command -v gf)
    gitdumper_bin=$(command -v git-dumper)
    gitsecret_bin=$(command -v Git-Secret)
    gobuster_bin=$(command -v gobuster)
    httprobe_bin=$(command -v httprobe)
    html2text_bin=$(command -v html2text)
    jexboss_bin=$(command -v jexboss)
    shodan_bin=$(command -v shodan)
    subfinder_bin=$(command -v subfinder)
    wafw00f_bin=$(command -v wafw00f)
    wayback_bin=$(command -v waybackurls)
    wfuzz_bin=$(command -v wfuzz)
    wpscan_bin=$(command -v wpscan)
    ysoserial_bin="${web_dir}/ysoserial/ysoserial.jar"

    # https://github.com/NESCAU-UFLA/FuzzingTool

    if [ ! -x "${aquatone_bin}" ]; then
        echo -en "Getting aquatone binary... "
        aquatone_version=$(curl -s https://github.com/michenriksen/aquatone/releases/latest | sed -e 's/<.*http.*\/\///' -e 's/".*>$//' | awk -F '/' '{print $6}')
        aquatone_url="https://github.com/michenriksen/aquatone/releases/download/${aquatone_version}/aquatone_linux_amd64_${aquatone_version:1}.zip"
        su - "${user}" -c "curl -k -s -L ${aquatone_url} -o ${web_dir}/aquatone_linux_amd64_${aquatone_version:1}.zip 2> ${error_log_file}"
        if [ -s "${web_dir}/aquatone_linux_amd64_${aquatone_version:1}.zip" ]; then
            su - "${user}" -c "unzip -q ${web_dir}/aquatone_linux_amd64_${aquatone_version:1}.zip aquatone -d ${web_dir} 2> ${error_log_file}"
            if [ -x "${web_dir}/aquatone" ]; then
                mv "${web_dir}/aquatone" "${binary_dir}" 2> "${error_log_file}"
                if [ -x "$(command -v aquatone)" ]; then
                    rm -rf "${web_dir}/aquatone_linux_amd64_${aquatone_version:1}.zip"
                    echo "Done!"
                else
                    echo -e "${red}Fail!${reset}\nCould not possible move aquatone to ${binary_dir}!"
                    cat "${error_log_file}"
                    rm -rf "${error_log_file}"
                    exit 1
                fi
            else
                echo -e "${red}Fail!${reset}\nCould not possible extract aquatone binary!"
                cat "${error_log_file}"
                rm -rf "${error_log_file}"
                exit 1
            fi
        else
            echo -e "${red}Fail!${reset}\nUnable to download aquatone!"
            cat "${error_log_file}"
            rm -rf "${error_log_file}"
            exit 1
        fi
    else
        echo "aquatone already exists in the system!"
    fi

    echo -en "Getting tools do bypass CloudFlare... "
    # Tools to recon and bypass CloudFlare
    if [ ! -d "${web_dir}/CloudFail" ]; then
        su - "${user}" -c "git clone -q https://github.com/m0rtem/CloudFail.git ${web_dir}/CloudFail 2> /dev/null"
        pip3 install -q -r "${web_dir}/CloudFail/requirements.txt" > /dev/null 2>&1
    fi

    if [ ! -d "${web_dir}/CloudFlair" ]; then
        # ERROR: dulwich 0.19.15 has requirement urllib3>=1.24.1, but you'll have urllib3 1.22 which is incompatible.
        su - "${user}" -c "git clone -q https://github.com/christophetd/CloudFlair.git ${web_dir}/CloudFlair 2> /dev/null"
        pip3 install -r "${web_dir}/CloudFlair/requirements.txt" > /dev/null 2>&1
    fi

    if [ ! -d "${web_dir}/HatCloud" ]; then
        su - "${user}" -c "git clone -q https://github.com/HatBashBR/HatCloud.git ${web_dir}/HatCloud 2> /dev/null"
        su - "${user}" -c "sed -i '64s/crimeflare.us/crimeflare.org/' ${web_dir}/HatCloud/hatcloud.rb 2> /dev/null"
    fi

    echo "Done!"
    echo "To use cloudflair.py you need:"
    echo "    Register an account (free) on https://censys.io/register"
    echo "    Browse to https://censys.io/account/api, and set two environment variables with your API ID and API secret"
    echo "    $ export CENSYS_API_ID=..."
    echo "    $ export CENSYS_API_SECRET=..."

    if [ ! -x "${dirsearch_bin}" ]; then
        echo -en "Getting dirsearch python script... "
        rm -rf "${web_dir}/dirsearch" > /dev/null 2> "${error_log_file}"
        dirsearch_bin="${binary_dir}/dirsearch"
        su - "${user}" -c "git clone -q https://github.com/maurosoria/dirsearch.git ${web_dir}/dirsearch 2> ${error_log_file}"
        if [ -d "${web_dir}/dirsearch" ]; then
            ln -s "${web_dir}/dirsearch/dirsearch.py" "${dirsearch_bin}" 2> "${error_log_file}"
            if [ -x "$(command -v dirsearch)" ] ; then
                echo "Done!"
            else
                echo -e "${red}Fail!${reset}\nSomething got wrong creating symlink for dirsearch!"
                cat "${error_log_file}"
                rm -rf "${error_log_file}"
                exit 1
            fi
        else
            echo -e "${red}Fail!${reset}\nUnable to download dirsearch!"
            cat "${error_log_file}"
            rm -rf "${error_log_file}"
            exit 1
        fi
    else
        echo "dirsearch already exists in the system!"
    fi

    if [ ! -x "${ffuf_bin}" ]; then
        echo -en "Getting ffuf binary... "
        ffuf_version=$(curl -s https://github.com/ffuf/ffuf/releases/latest | sed -e 's/<.*http.*\/\/// ; s/".*>$//' | awk -F'/' '{print $6}')
        ffuf_url="https://github.com/ffuf/ffuf/releases/download/${ffuf_version}/ffuf_${ffuf_version:1}_linux_amd64.tar.gz"
        su - "${user}" -c "curl -k -s -L ${ffuf_url} -o ${web_dir}/ffuf_${ffuf_version:1}_linux_amd64.tar.gz"
        if [ -s "${web_dir}/ffuf_${ffuf_version:1}_linux_amd64.tar.gz" ]; then
            su - "${user}" -c "tar xf ${web_dir}/ffuf_${ffuf_version:1}_linux_amd64.tar.gz -C ${web_dir} ffuf 2> ${error_log_file}"
            if [ -x "${web_dir}/ffuf" ]; then
                mv "${web_dir}/ffuf" "${binary_dir}"
                if [ -x "$(command -v ffuf)" ]; then
                    rm -rf "${web_dir}/ffuf_${ffuf_version:1}_linux_amd64.tar.gz"
                    echo "Done!"
                else
                    echo -e "${red}Fail!${reset}\nCould not possible move ffuf to ${binary_dir}!"
                    cat "${error_log_file}"
                    rm -rf "${error_log_file}"
                    exit 1
                fi
            else
                echo -e "${red}Fail!${reset}\nCould not possible extract ffuf!"
                cat "${error_log_file}"
                rm -rf "${error_log_file}"
                exit 1
            fi
        else
            echo -e "${red}Fail!${reset}\nUnable to download ffuf!"
            cat "${error_log_file}"
            rm -rf "${error_log_file}"
            exit 1
        fi
    else
        echo "ffuf already exists in the system!"
    fi

    if [ ! -x "${gf_bin}" ]; then
        echo -en "Getting gf... "
        su - "${user}" -c "export GOROOT=/usr/local/go ; export GOPATH=${user_home}/go ; ${go_binary} get -u github.com/tomnomnom/gf > /dev/null 2> ${error_log_file}"
        if [ -x "${user_home}/go/bin/gf" ]; then
            mv "${user_home}/go/bin/gf" "${binary_dir}"
            if [ -x "$(command -v gf)" ]; then
                echo "Done!"
                su - "${user}" -c "echo \"# gf completion configuration\" >> ~/.bashrc"
                su - "${user}" -c "grep -Ev \"^#\" ~/go/src/github.com/tomnomnom/gf/gf-completion.bash >> ~/.bashrc"
                [ ! -d "${user_home}/.gf"  ] && su - "${user}" -c "mkdir -p ${user_home}/.gf"
                [ -d "${user_home}/.gf"  ] && su - "${user}" -c "cp -r ${user_home}/go/src/github.com/tomnomnom/gf/examples/* ${user_home}/.gf/"
                su - "${user}" -c "git clone -q https://github.com/1ndianl33t/Gf-Patterns.git /tmp/gf"
                [ -d /tmp/gf ] && su -c "${user}" -c "mv /tmp/gf/*.json ${user_home}/.gf/ ; rm -rf /tmp/gf"
            else
                echo -e "${red}Fail!${reset}\nCould not possible move gf to ${binary_dir}!"
                cat "${error_log_file}"
                rm -rf "${error_log_file}"
                exit 1
            fi 
        else
            echo -e "${red}Fail!${reset}\nUnable to download ffuf!"
            cat "${error_log_file}"
            rm -rf "${error_log_file}"
            exit 1
        fi
    else
        echo "gf already exists in the system!"
    fi
    
    if [ ! -x "${gitdumper_bin}" ]; then
        echo -en "Getting git-dumper python script... "
        rm -rf "${web_dir}/git-dumper" > /dev/null 2> "${error_log_file}"
        gitdumper_bin="${binary_dir}/git-dumper"
        su - "${user}" -c "git clone -q https://github.com/skateforever/git-dumper.git ${web_dir}/git-dumper 2> ${error_log_file}"
        if [ -x "${web_dir}/git-dumper/git-dumper.py" ]; then
            pip3 install -q -r "${web_dir}/git-dumper/requirements.txt" > /dev/null 2>&1
            ln -s "${web_dir}/git-dumper/git-dumper.py" "${gitdumper_bin}" 2> "${error_log_file}"
            if [ -x "$(command -v git-dumper)" ]; then
                echo "Done!"
            else
                echo -e "${red}Fail!${reset}\nSomething got wrong creating symlink for git-dumper!"
                cat "${error_log_file}"
                rm -rf "${error_log_file}"
                exit 1
            fi
        else
            echo -e "${red}Fail!${reset}\nUnable to download git-dumper!"
            cat "${error_log_file}"
            rm -rf "${error_log_file}"
            exit 1
        fi
    else
        echo "git-dumper already exists in the system!"
    fi

    if [ ! -x "${gitsecret_bin}" ]; then
        echo -en "Getting Git-Secret... "
        su - "${user}" -c "${go_binary} get github.com/daffainfo/Git-Secret 2> ${error_log_file}"
        if [ -x "${user_home}/go/bin/Git-Secret" ]; then
            mv "${user_home}/go/bin/Git-Secret" "${binary_dir}" 2> "${error_log_file}"
            if [ -x "$(command -v Git-Secret)" ]; then
                echo "Done!"
            else
                echo -e "${red}Fail!${reset}\nUnable to move Git-Secret!"
                cat "${error_log_file}"
                exit 1
            fi
        else
            echo -e "${red}Fail!${reset}\nUnable to download Git-Secret!"
            cat "${error_log_file}"
            exit 1
        fi
    fi

    if [ ! -x "${gobuster_bin}" ]; then
        echo -en "Getting gobuster binary... "
        gobuster_version=$(curl -s https://github.com/OJ/gobuster/releases/latest | sed -e 's/<.*http.*\/\/// ; s/".*>$//' | awk -F '/' '{print $6}')
        gobuster_url="https://github.com/OJ/gobuster/releases/download/${gobuster_version}/gobuster-linux-amd64.7z"
        su - "${user}" -c "curl -k -s -L ${gobuster_url} -o ${web_dir}/gobuster-linux-amd64.7z 2> ${error_log_file}"
        if [ -s "${web_dir}/gobuster-linux-amd64.7z" ]; then
            su - "${user}" -c "7z e ${web_dir}/gobuster-linux-amd64.7z gobuster-linux-amd64/gobuster -o${web_dir} -y > /dev/null 2> ${error_log_file}"
            su - "${user}" -c "chmod +x ${web_dir}/gobuster 2> ${error_log_file}"
            if [ -x "${web_dir}/gobuster" ]; then
                mv "${web_dir}/gobuster" "${binary_dir}" 2> "${error_log_file}"
                if [ -x "$(command -v gobuster)" ]; then
                    rm -rf "${web_dir}/gobuster-linux-amd64.7z"
                    echo "Done!"
                else
                    echo -e "${red}Fail!${reset}\nCould not possible move gobuster to ${binary_dir}!"
                    cat "${error_log_file}"
                    rm -rf "${error_log_file}"
                    exit 1
                fi
            else
                echo -e "${red}Fail!${reset}\nCould not possible extract gobuster binary!"
                cat "${error_log_file}"
                rm -rf "${error_log_file}"
                exit 1
            fi
        else
            echo -e "${red}Fail!${reset}\nUnable to download gobuster!"
            cat "${error_log_file}"
            rm -rf "${error_log_file}"
            exit 1
        fi
    else
        echo "gobuster already exists in the system!"
    fi

    echo -n "Getting tools to GraphQL explotation... "
    [ ! -d "${web_dir}/inql" ] && \
        su - "${user}" -c "git clone -q https://github.com/doyensec/inql.git ${web_dir}/inql 2> /dev/null"
    [ ! -d "${web_dir}/GraphQLmap" ] && \
        su - "${user}" -c "git clone -q https://github.com/swisskyrepo/GraphQLmap.git ${web_dir}/GraphQLmap 2> /dev/null"
    echo "Done!"

    if [ ! -x "${httprobe_bin}" ]; then
        echo -en "Getting httprobe binary... "
        su - "${user}" -c "export GOROOT=/usr/local/go ; export GOPATH=${user_home}/go ; ${go_binary} get -u github.com/tomnomnom/httprobe > /dev/null 2> ${error_log_file}"
        if [ -x "${user_home}/go/bin/httprobe" ]; then
            mv "${user_home}/go/bin/httprobe" "${binary_dir}" 2> "${error_log_file}"
            if [ -x "$(command -v httprobe)" ]; then
                echo "Done!"
            else
                echo -e "${red}Fail!${reset}\nCould not possible move httprobe to ${binary_dir}!"
                cat "${error_log_file}"
                rm -rf "${error_log_file}"
                exit 1
            fi
        else
            echo -e "${red}Fail!${reset}\nUnable to download httprobe!"
            cat "${error_log_file}"
            rm -rf "${error_log_file}"
            exit 1
        fi
    else
        echo "httprobe already exists in the system!"
    fi

    if [ ! -x "${html2text_bin}" ]; then
       echo -en "Getting html2text... "
       pip -q install html2text
       echo "Done!"
    fi 

    if [ ! -x "${jexboss_bin}" ]; then
        echo -en "Getting jexboss python script... "
        rm -rf "${web_dir}/jexboss" > /dev/null 2> "${error_log_file}"
        jexboss_bin="${binary_dir}/jexboss"
        su - "${user}" -c "git clone -q https://github.com/joaomatosf/jexboss.git ${web_dir}/jexboss 2> ${error_log_file}"
        if [ -x "${web_dir}/jexboss/jexboss.py" ]; then
            pip3 install -q -r "${web_dir}/jexboss/requires.txt" 2> /dev/null
            ln -s "${web_dir}/jexboss/jexboss.py" "${jexboss_bin}" 2> "${error_log_file}"
            if [ -x "$(command -v jexboss)" ]; then
                echo "Done!"
            else
                echo -e "${red}Fail!${reset}\nSomething got wrong creating symlink for jexboss!"
                cat "${error_log_file}"
                rm -rf "${error_log_file}"
                exit 1
            fi
        else
            echo -e "${red}Fail!${reset}\nUnable to download jexboss repository!"
            cat "${error_log_file}"
            rm -rf "${error_log_file}"
            exit 1
        fi
    else
        echo "jexboss already exists in the system!"
    fi

    if [ ! -x "${shodan_bin}" ]; then
        echo -en "Getting shodan cli binary... "
        pip3 -q install shodan 2> "${error_log_file}"
        if [ -x "$(command -v shodan)" ]; then
            echo "Done!"
        else
            echo -e "${red}Fail!${reset}\nUnable to download shodan cli!"
            cat "${error_log_file}"
            rm -rf "${error_log_file}"
            exit 1
        fi
    fi

    if [ ! -x "${subfinder_bin}" ]; then
        echo -en "Getting subfinder binary... "
        subfinder_version=$(curl -s -k https://github.com/projectdiscovery/subfinder/releases/latest | sed -e 's/<.*http.*\/\/// ; s/".*>$//' | awk -F'/' '{print $6}')
        # Modificado por Amarelos #
        subfinder_url="https://github.com/projectdiscovery/subfinder/releases/download/${subfinder_version}/subfinder_${subfinder_version:1}_linux_amd64.zip"
        su - "${user}" -c "curl -s -k -L ${subfinder_url} -o ${web_dir}/subfinder_${subfinder_version:1}_linux_amd64.zip 2> ${error_log_file}"
        if [ -s "${web_dir}/subfinder_${subfinder_version:1}_linux_amd64.zip" ]; then
            su - "${user}" -c "unzip -q ${web_dir}/subfinder_${subfinder_version:1}_linux_amd64.zip subfinder -d ${web_dir} 2> ${error_log_file}"
            if [ -x "${web_dir}/subfinder" ]; then
                mv "${web_dir}/subfinder" "${binary_dir}"
                if [ -x "$(command -v subfinder)" ]; then
                    rm -rf "${web_dir}/subfinder_${subfinder_version:1}_linux_amd64.zip"
                    echo "Done!"
                else
                    echo -e "${red}Fail!${reset}\nCould not possible move subfinder to ${binary_dir}!"
                    cat "${error_log_file}"
                    rm -rf "${error_log_file}"
                    exit 1
                fi
            else
                echo -e "${red}Fail!${reset}\nCould not possible extract subfinder!"
                cat "${error_log_file}"
                rm -rf "${error_log_file}"
                exit 1
            fi
        else
            echo -e "${red}Fail!${reset}\nUnable to download subfinder!"
            cat "${error_log_file}"
            rm -rf "${error_log_file}"
            exit 1
        fi
    else
        echo "subfinder already exists in the system!"
    fi

    if [ ! -x "${wafw00f_bin}" ]; then
        echo -en "Getting wafw00f binary... "
        pip3 install -q wafw00f > /dev/null 2> "${error_log_file}"
        if [ -x "$(command -v wafw00f)" ]; then
            echo "Done!"
        else
            echo -e "${red}Fail!${reset}\nUnable to download wafw00f!"
            cat "${error_log_file}"
            rm -rf "${error_log_file}"
            exit 1
        fi
    else
        echo "wafw00f already exists in the system!"
    fi

    if [ ! -x "${wayback_bin}" ]; then
        echo -en "Getting waybackurls binary... "
        su - "${user}" -c "export GOROOT=/usr/local/go ; export GOPATH=${user_home}/go ; ${go_binary} get -u github.com/tomnomnom/waybackurls > /dev/null 2> ${error_log_file}"
        if [ -x "${user_home}/go/bin/waybackurls" ]; then
            mv "${user_home}/go/bin/waybackurls" "${binary_dir}" 2> "${error_log_file}"
            if [ -x "$(command -v waybackurls)" ]; then
                echo "Done!"
            else
                echo -e "${red}Fail!${reset}\nCould not possible move subfinder to ${binary_dir}!"
                cat "${error_log_file}"
                rm -rf "${error_log_file}"
                exit 1
            fi
        else
            echo -e "${red}Fail!${reset}\nUnable to download waybackurls!"
            cat "${error_log_file}"
            rm -rf "${error_log_file}"
            exit 1
        fi
    else
        echo "waybackurls already exists in the system!"
    fi

    # https://github.com/xmendez/wfuzz
    if [ ! -x "${wfuzz_bin}" ]; then
        echo -en "Getting wfuzz binary... "
        pip3 install -q wfuzz 2> "${error_log_file}"
        if [ -x "$(command -v wfuzz)" ]; then 
            echo "Done!"
        else
            echo -e "${red}Fail!${reset}\nUnable to download wfuzz!"
            cat "${error_log_file}"
            rm -rf "${error_log_file}"
            exit 1
        fi
    else
        echo "wfuzz already exists in the system!"
    fi

    # https://github.com/wpscanteam/wpscan
    if [ ! -x "${wpscan_bin}" ]; then
        echo -en "Getting wpscan binary... "
        gem install -q -n /usr/local/bin wpscan > /dev/null 2> "${error_log_file}"
        if [ -x "$(command -v wpscan)" ]; then
            echo "Done!"
        else
            echo -e "${red}Fail!${reset}\nUnable to download wpscan!"
            cat "${error_log_file}"
            rm -rf "${error_log_file}"
            exit 1
        fi
    else
        echo "wpscan already exists in the system!"
    fi

    if [ ! -f "${ysoserial_bin}" ]; then
        echo -en "Getting ysoserial jar... "
        su - "${user}" -c "mkdir -p ${web_dir}/ysoserial"
        su - "${user}" -c "wget --quiet -c https://jitpack.io/com/github/frohoff/ysoserial/master-SNAPSHOT/ysoserial-master-SNAPSHOT.jar \
            -O ${web_dir}/ysoserial/ysoserial.jar 2> ${error_log_file}"
        su - "${user}" -c "wget --quiet -c https://github.com/pwntester/ysoserial.net/releases/download/v1.32/ysoserial-1.32.zip -O ${web_dir}/ysoserial/ysoserialdotnet-1.32.zip 2> ${error_log_file}"
        if [ -s "${ysoserial_bin}" ]; then
            echo "Done!"
        else
            echo -e "${red}Fail!${reset}\nUnable to download ysoserial!"
            cat "${error_log_file}"
            rm -rf "${error_log_file}"
            exit 1
        fi
    else
        echo "ysoserial already exists in the system!"
    fi

    # RCE on MobileIron MDM
    # https://github.com/iamnoooob/CVE-Reverse/tree/master/CVE-2020-15505
}


wifi() {
    [ ! -d "${wifi_dir}/DPWO" ] && \
        su - "${user}" -c "git clone https://github.com/caioluders/DPWO.git ${wifi_dir}/DPWO 2> /dev/null"
}

windows_exploitation(){

    #https://github.com/bats3c/ADCSPwn
    #https://github.com/GossiTheDog/SystemNightmare
    #https://github.com/topotam/PetitPotam.git

    echo -en "Getting tools to exploit Windows Network... "
    # AD mapping
    # https://github.com/fox-it/BloodHound.py
    [[ ! -x "$(command -v bloodhound-python)" ]] && pip3 install -q bloodhound > /dev/null 2>&1

    # Share mapping
    [[ ! -d "${windows_dir}/carnivorall" ]] && \
        su - "${user}" -c "git clone -q https://github.com/L0stControl/carnivorall.git ${windows_dir}/carnivorall 2> /dev/null"

    # https://github.com/byt3bl33d3r/CrackMapExec
    # https://mpgn.gitbook.io/crackmapexec/
    if [ ! -x "$(command -v cme)" ]; then
        cme_version=$(curl -sL https://github.com/byt3bl33d3r/CrackMapExec/releases | grep -E "href=.*/tag/" | sed -e 's/<\/.*>// ; s/[[:blank:]]*.*>//' | head -n1 | awk '{print $2}')
        cme_file=$(curl -sL https://github.com/byt3bl33d3r/CrackMapExec/releases | grep "${cme_version}" | grep cme-ubuntu | sed -e 's/[[:blank:]]*.*\/// ; s/".*>//')
        su - "${user}" -c "curl -sL https://github.com/byt3bl33d3r/CrackMapExec/releases/download/${cme_version}/${cme_file} -o /tmp/cme-ubuntu-latest.zip 2> /dev/null"
        unzip -q -o -x /tmp/cme-ubuntu-latest.zip -d /usr/local/bin/ 2> /dev/null
        [[ -s /usr/local/bin/cme ]] && chmod +x /usr/local/bin/cme ; rm -rf /tmp/cme-ubuntu-latest.zip
    fi

    # https://github.com/byt3bl33d3r/CrackMapExec
    # https://mpgn.gitbook.io/crackmapexec/
    if [ ! -x "$(command -v cmedb)" ]; then
        cmedb_version=$(curl -sL https://github.com/byt3bl33d3r/CrackMapExec/releases | grep -E "href=.*/tag/" | sed -e 's/<\/.*>// ; s/[[:blank:]]*.*>//' | head -n1 | awk '{print $2}')
        cmedb_file=$(curl -sL https://github.com/byt3bl33d3r/CrackMapExec/releases | grep "${cmedb_version}" | grep cmedb-ubuntu | sed -e 's/[[:blank:]]*.*\/// ; s/".*>//')
        su - "${user}" -c "curl -sL https://github.com/byt3bl33d3r/CrackMapExec/releases/download/${cmedb_version}/${cmedb_file} -o /tmp/cmedb-ubuntu-latest.zip 2> /dev/null"
        unzip -q -o -x /tmp/cmedb-ubuntu-latest.zip -d /usr/local/bin/ 2> /dev/null
        [[ -s /usr/local/bin/cmedb ]] && chmod +x /usr/local/bin/cmedb ; rm -rf /tmp/cmedb-ubuntu-latest.zip
    fi

    [[ ! -d "${windows_dir}/CredCrack" ]] && \
        su - "${user}" -c "git clone -q https://github.com/gojhonny/CredCrack.git ${windows_dir}/CredCrack 2> /dev/null"

    if [ ! -x "$(command -v empire)" ]; then
        su - "${user}" -c "git clone -q https://github.com/EmpireProject/Empire.git ${windows_dir}/Empire 2> /dev/null"
        if [ -x "${windows_dir}/Empire/empire" ]; then
            #precisa do https://aur.archlinux.org/powershell.git
            pip2 install -q -r "${windows_dir}/Empire/setup/requirements.txt" > /dev/null 2>&1
            pip2 install -q pefile > /dev/null 2>&1
            ln -s "${windows_dir}/Empire/empire" "${binary_dir}/empire" 2> /dev/null
        fi
    fi

    # Enumeration
    [[ ! -x "${windows_dir}/enum4linux/enum4linux.pl" ]] && \
        su - "${user}" -c "git clone -q https://github.com/portcullislabs/enum4linux.git ${windows_dir}/enum4linux 2> /dev/null"

    # https://github.com/Hackplayers/evil-winrm.git
    [[ ! -x "$(command -v evil-winrm)" ]] && \
        gem install -q gssapi winrm winrm-fs stringio evil-winrm > /dev/null 2>&1

    while [[ -z $(host -t A github.com | grep "has address" | awk '{print $4}') ]]; do
        sleep 1
    done 
    [[ ! -d "${windows_dir}/GreatSCT" ]] && \
        su - "${user}" -c "git clone -q https://github.com/GreatSCT/GreatSCT.git ${windows_dir}/GreatSCT 2> /dev/null"

    # Enumeration
    # https://github.com/SecureAuthCorp/impacket.git
    [[ ! -x "$(command -v GetADUsers.py)" ]] && pip3 install -q impacket > /dev/null 2>&1

    while [[ -z $(host -t A gitlab.com | grep "has address" | awk '{print $4}') ]]; do
        sleep 1
    done 
    # Kali windows binaries
    [[ ! -d "${windows_dir}/kali-win-binaries" ]] && \
        su - "${user}" -c "git clone -q https://gitlab.com/kalilinux/packages/windows-binaries.git ${windows_dir}/kali-win-binaries 2> /dev/null"

    # Brute force
    # https://github.com/TarlogicSecurity/kerbrute.git
    [[ ! -x "$(command -v kerbrute)" ]] && pip3 install -q kerbrute > /dev/null 2>&1

    # Mimikatz
    [[ ! -f "${windows_dir}/mimikatz_trunk.7z" ]] && \
        su - "${user}" -c "wget -q -c https://github.com/gentilkiwi/mimikatz/releases/download/2.2.0-20200519/mimikatz_trunk.7z -O ${windows_dir}/mimikatz_trunk.7z 2> /dev/null"

    # Enumeration
    [[ ! -d "${windows_dir}/polenum" ]] && \
        su - "${user}" -c "git clone -q https://github.com/Wh1t3Fox/polenum.git ${windows_dir}/polenum 2> /dev/null"
    
    [[ ! -d "${windows_dir}/PowerZure" ]] && \
        su - "${user}" -c "git clone -q https://github.com/hausec/PowerZure.git ${windows_dir}/PowerZure 2> /dev/null"

    # Local Enumeration
    [[ ! -f "${windows_dir}/Procdump.zip" ]] && \
        su - "${user}" -c "wget -q -c https://download.sysinternals.com/files/Procdump.zip -O ${windows_dir}/Procdump.zip 2> /dev/null"

    [[ ! -d "${windows_dir}/PSTools.zip" ]] &&  \
        su - "${user}" -c "wget -q -c https://download.sysinternals.com/files/PSTools.zip -O ${windows_dir}/PSTools.zip 2> /dev/null"

    [[ ! -d "${windows_dir}/PowerTools" ]] && \
        su - "${user}" -c "git clone -q https://github.com/PowerShellEmpire/PowerTools.git ${windows_dir}/PowerTools 2> /dev/null"

    # Privilege escalation
    [[ ! -d "${windows_dir}/privilege-escalation-awesome-scripts-suite" ]] && \
        su - "${user}" -c "git clone -q https://github.com/carlospolop/privilege-escalation-awesome-scripts-suite.git ${windows_dir}/privilege-escalation-awesome-scripts-suite 2> /dev/null"

    [[ ! -d "${windows_dir}/PowerSploit" ]] && \
        su - "${user}" -c "git clone -q https://github.com/PowerShellMafia/PowerSploit.git ${windows_dir}/PowerSploit 2> /dev/null"

    [[ ! -d "${windows_dir}/PsCabesha-tools" ]] && \
        su - "${user}" -c "git clone -q https://github.com/Hackplayers/PsCabesha-tools.git ${windows_dir}/PsCabesha-tools 2> /dev/null"

    # Local Exploitation
    # https://github.com/skelsec/pypykatz.git
    if [ ! -x "$(command -v pypykatz)" ]; then
        pip3 install -q minidump minikerberos aiowinreg msldap winsspi pypykatz > /dev/null 2>&1
    fi

    # MiTM
    if [ ! -x "${windows_dir}/Responder/Responder.py" ]; then
        su - "${user}" -c "git clone -q https://github.com/lgandx/Responder ${windows_dir}/Responder 2> /dev/null"
        ln -s "${windows_dir}/Responder/Responder.py" "${binary_dir}/Responder.py" 2> /dev/null
    fi

    # Local Exploitation
    [[ ! -d "${windows_dir}/SeBackupPrivilege" ]] && \
        su - "${user}" -c "git clone -q https://github.com/giuliano108/SeBackupPrivilege.git ${windows_dir}/SeBackupPrivilege 2> /dev/null"

    # Share mapping
    [[ ! -d "${windows_dir}/smbmap" ]] && \
        su - "${user}" -c "git clone -q https://github.com/ShawnDEvans/smbmap.git ${windows_dir}/smbmap 2> /dev/null"

    [[ ! -d "${windows_dir}/smbspider" ]] && \
        su - "${user}" -c "git clone -q https://github.com/T-S-A/smbspider ${windows_dir}/smbspider 2> /dev/null"

    # Local Exploitation
    [[ ! -d "${windows_dir}/Windows-Exploit-Suggester" ]] && \
        su - "${user}" -c "git clone -q https://github.com/GDSSecurity/Windows-Exploit-Suggester.git ${windows_dir}/Windows-Exploit-Suggester 2> /dev/null"

    # https://github.com/dirkjanm/CVE-2020-1472.git
    # https://github.com/SecuraBV/CVE-2020-1472.git
    # https://github.com/trustedsec/cve-2019-19781
    echo "Done!"
}

wordlists(){
    cewl_bin="${web_dir}/CeWL/cewl.rb"
    wordlistgen_bin=$(command -v wordlistgen)

    if [ ! -x "${cewl_bin}" ] && [ -d "${web_dir}/CeWL" ]; then
        rm -rf "${web_dir}/CeWL" > /dev/null 2>&1
        su - "${user}" -c "git clone -q https://github.com/digininja/CeWL.git ${web_dir}/CeWL 2> /dev/null"
        cd "${web_dir}/CeWL" ||
        gem install bundler:1.17.2 2> /dev/null
        bundle install > /dev/null 2>&1
        #ruby -W0 ./cewl.rb
    fi

    if [ ! -x "${wordlistgen_bin}" ]; then
        echo -en "Getting wordlistgen binary... "
        su - "${user}" -c "export GOROOT=/usr/local/go ; export GOPATH=${user_home}/go ; ${go_binary} get -u github.com/ameenmaali/wordlistgen 2> ${error_log_file}"
        if [ -x "${user_home}/go/bin/wordlistgen" ]; then
            mv "${user_home}/go/bin/wordlistgen" "${binary_dir}" 2> "${error_log_file}"
            if [ -n "$(command -v wordlistgen)" ]; then
                echo "Done!"
            else
                echo -e "\n${red}Something got wrong with wordlistgen move!${reset}"
                cat "${error_log_file}"
                rm -rf "${error_log_file}"
                exit 1
            fi
        else
            echo -e "\n${red}Unable to download wordlistgen!${reset}"
            cat "${error_log_file}"
            rm -rf "${error_log_file}"
            exit 1
        fi
    else
        echo "wordlistgen binary OK!"
    fi

    if [ -d "${wordlists_dir}" ]; then
        [ ! -d "${wordlists_dir}/dns" ] &&  su - "${user}" -c "mkdir -p ${wordlists_dir}/dns"
        [ ! -d "${wordlists_dir}/web" ] &&  su - "${user}" -c "mkdir -p ${wordlists_dir}/web"
        echo -n "Cloning knock wordlist... "
        [ ! -f "${wordlists_dir}/dns/knock-wl.txt" ] && \
            su - "${user}" -c "wget --quiet -c https://raw.githubusercontent.com/guelfoweb/knock/4.1/knockpy/wordlist/wordlist.txt -O ${wordlists_dir}/dns/knock-wl.txt 2> /dev/null"
        echo "Done!"

        echo -n "Cloning commonspeak2 wordlists... "
        [ ! -d "${wordlists_dir}/commonspeak2-wordlists" ] && \
            su - "${user}" -c "git clone -q https://github.com/assetnote/commonspeak2-wordlists ${wordlists_dir}/commonspeak2-wordlists 2> /dev/null"
        echo "Done!"

        echo -n "Cloning subbrute wordlist... "
        [ ! -f "${wordlists_dir}/dns/subbrute-wl.txt" ] && \
            su - "${user}" -c "wget --quiet -c https://raw.githubusercontent.com/TheRook/subbrute/master/names.txt -O ${wordlists_dir}/dns/subbrute-wl.txt 2> /dev/null"
        echo "Done!"

        echo -n "Cloning dirbuster wordlists... "
        su - "${user}" -c "wget --quiet -c \"https://pt.osdn.net/frs/g_redir.php?m=kent&f=dirbuster%2FDirBuster+Lists%2FCurrent%2FDirBuster-Lists.tar.bz2\" -O /tmp/DirBuster-Lists.tar.bz2 2> /dev/null"
        su - "${user}" -c "tar xf /tmp/DirBuster-Lists.tar.bz2 -C ${wordlists_dir} 2> ${error_log_file} ; rm -rf /tmp/DirBuster-Lists.tar.bz2"
        echo "Done!"

        echo -n "Cloning some others wordlists... "
        [ ! -d "${wordlists_dir}/commonspeak2-wordlists" ] && \
            su - "${user}" -c "git clone -q https://github.com/assetnote/commonspeak2-wordlists.git ${wordlists_dir}/commonspeak2-wordlists 2> /dev/null"
        echo "Done!"

        echo -n "Cloning PWDB - New generation of Password Mass-Analysis... "
        [ ! -d "${wordlists_dir}/Pwdb-Public" ] && \
            su - "${user}" -c "git clone -q https://github.com/FlameOfIgnis/Pwdb-Public ${wordlists_dir}/Pwdb-Public 2> /dev/null"
        echo "Done!"

        echo -n "Cloning rockyou wordlist... "
        [ ! -f "rockyou.txt" ] && \
           su -c "${user}" -c "wget --quiet -c https://gitlab.com/kalilinux/packages/wordlists/-/raw/kali/master/rockyou.txt.gz -O ${wordlists_dir}/rockyou.txt.gz 2> /dev/null"
        [ -f "${wordlists_dir}/rockyou.txt.gz" ] && gunzip -f "${wordlists_dir}/rockyou.txt.gz" 2> /dev/null
        echo "Done!"

        echo -n "Cloning SecLists... "
        [ ! -d "${wordlists_dir}/SecLists" ] && \
            su - "${user}" -c "git clone -q https://github.com/danielmiessler/SecLists.git ${wordlists_dir}/SecLists 2> /dev/null"
        echo "Done!"

        #This file breaks massdns and needs to be cleaned
        echo -n "Removing bad chars from Jhaddix's wordlist head... "
        if [ ! -f "${wordlists_dir}/SecLists/Discovery/DNS/clean-jhaddix-dns.txt" ]; then
            su - "${user}" -c "cp ${wordlists_dir}/SecLists/Discovery/DNS/dns-Jhaddix.txt ${wordlists_dir}/SecLists/Discovery/DNS/clean-jhaddix-dns.txt 2> /dev/null"
            su - "${user}" -c "sed -i 1,14d ${wordlists_dir}/SecLists/Discovery/DNS/clean-jhaddix-dns.txt 2> /dev/null"
        fi
        echo "Done!"

    fi
}

if [[ "${profile}" == "web" ]]; then
    prepare_system
    go_bin
    # Modificado Amarelos # docker_system
    infra
    web_exploitation
    exploits
    payloads
    wordlists
    web_message
    final_message
elif [[ "${profile}" == "linux" ]]; then
    prepare_system
    go_bin
    # Modificado Amarelos # docker_system
    linux_exploitation
    exploits
    final_message    
elif [[ "${profile}" == "mobile" ]]; then
    prepare_system
    go_bin
    # Modificado Amarelos # docker_system
    mobile_android
    mobile_message
elif [[ "${profile}" == "osint" ]]; then
    prepare_system
    go_bin
    # Modificado Amarelos # docker_system
    osint_exploitation
    final_message
elif [[ "${profile}" == "windows" ]]; then
    prepare_system
    go_bin
    # Modificado Amarelos # docker_system
    windows_exploitation
    exploits
    final_message
elif [[ "${profile}" == "all" ]]; then
    prepare_system
    go_bin
    # Modificado Amarelos # docker_system
    infra
    web_exploitation
    linux_exploitation
    mobile_android
    osint_exploitation
    windows_exploitation
    exploits
    wordlists
    mobile_message
    payloads
    web_message
    final_message
else
    usage
fi

rm -rf "${error_log_file}"
