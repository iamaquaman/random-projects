#######################################
#
# common.sh
#
#######################################

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

#######################################
# Check if command exists.
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   0 if command exists
#######################################
commandExists() {
    command -v "$@" > /dev/null 2>&1
}


#######################################
# Gets curl or wget depending if cmd exits.
# Globals:
#   PROXY_ADDRESS
# Arguments:
#   None
# Returns:
#   URLGET_CMD
#######################################
URLGET_CMD=
getUrlCmd() {
    if commandExists "curl"; then
        URLGET_CMD="curl -sSL"
        if [ -n "$PROXY_ADDRESS" ]; then
            URLGET_CMD=$URLGET_CMD" -x $PROXY_ADDRESS"
        fi
    else
        URLGET_CMD="wget -qO-"
    fi
}

#######################################
#
# prompt.sh
#
#######################################

PROMPT_RESULT=

if [ -z "$READ_TIMEOUT" ]; then
    READ_TIMEOUT="-t 20"
fi


#######################################
# Prompts the user for input.
# Globals:
#   READ_TIMEOUT, FAST_TIMEOUTS
# Arguments:
#   None
# Returns:
#   PROMPT_RESULT
#######################################
promptTimeout() {
    set +e
    if [ -z "$FAST_TIMEOUTS" ]; then
        read ${1:-$READ_TIMEOUT} PROMPT_RESULT < /dev/tty
    else
        read ${READ_TIMEOUT} PROMPT_RESULT < /dev/tty
    fi
    set -e
}

#######################################
# Confirmation prompt default yes.
# Globals:
#   READ_TIMEOUT, FAST_TIMEOUTS
# Arguments:
#   None
# Returns:
#   None
#######################################
confirmY() {
    printf "(Y/n) "
    promptTimeout
    if [ "$PROMPT_RESULT" = "n" ] || [ "$PROMPT_RESULT" = "N" ]; then
        return 1
    fi
    return 0
}

#######################################
# Confirmation prompt default no.
# Globals:
#   READ_TIMEOUT, FAST_TIMEOUTS
# Arguments:
#   None
# Returns:
#   None
#######################################
confirmN() {
    printf "(y/N) "
    promptTimeout
    if [ "$PROMPT_RESULT" = "y" ] || [ "$PROMPT_RESULT" = "Y" ]; then
        return 0
    fi
    return 1
}


#######################################
# Prompts the user for input.
# Globals:
#   READ_TIMEOUT
# Arguments:
#   None
# Returns:
#   PROMPT_RESULT
#######################################
prompt() {
    set +e
    read PROMPT_RESULT < /dev/tty
    set -e
}

#######################################
#
# system.sh
#
#######################################

#######################################
# Requires a 64 bit platform or exits with an error.
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#######################################
require64Bit() {
    case "$(uname -m)" in
        *64)
            ;;
        *)
            echo >&2 'Error: you are not using a 64bit platform.'
            echo >&2 'This installer currently only supports 64bit platforms.'
            exit 1
            ;;
    esac
}

#######################################
# Requires that the script be run with the root user.
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   USER
#######################################
USER=
requireRootUser() {
    USER="$(id -un 2>/dev/null || true)"
    if [ "$USER" != "root" ]; then
        echo >&2 "Error: This script requires admin privileges. Please re-run it as root."
        exit 1
    fi
}

#######################################
# Detects the linux distribution.
# Upon failure exits with an error.
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   LSB_DIST
#   DIST_VERSION - should be MAJOR.MINOR e.g. 16.04 or 7.4
#   DIST_VERSION_MAJOR
#######################################
LSB_DIST=
DIST_VERSION=
DIST_VERSION_MAJOR=
detectLsbDist() {
    _dist=
    _error_msg="We have checked /etc/os-release and /etc/centos-release files."
    if [ -f /etc/centos-release ] && [ -r /etc/centos-release ]; then
        # CentOS 6 example: CentOS release 6.9 (Final)
        # CentOS 7 example: CentOS Linux release 7.5.1804 (Core)
        _dist="$(cat /etc/centos-release | cut -d" " -f1)"
        _version="$(cat /etc/centos-release | sed 's/Linux //' | cut -d" " -f3 | cut -d "." -f1-2)"
    elif [ -f /etc/os-release ] && [ -r /etc/os-release ]; then
        _dist="$(. /etc/os-release && echo "$ID")"
        _version="$(. /etc/os-release && echo "$VERSION_ID")"
    elif [ -f /etc/redhat-release ] && [ -r /etc/redhat-release ]; then
        # this is for RHEL6
        _dist="rhel"
        _major_version=$(cat /etc/redhat-release | cut -d" " -f7 | cut -d "." -f1)
        _minor_version=$(cat /etc/redhat-release | cut -d" " -f7 | cut -d "." -f2)
        _version=$_major_version
    elif [ -f /etc/system-release ] && [ -r /etc/system-release ]; then
        if grep --quiet "Amazon Linux" /etc/system-release; then
            # Special case for Amazon 2014.03
            _dist="amzn"
            _version=`awk '/Amazon Linux/{print $NF}' /etc/system-release`
        fi
    else
        _error_msg="$_error_msg\nDistribution cannot be determined because neither of these files exist."
    fi

    if [ -n "$_dist" ]; then
        _error_msg="$_error_msg\nDetected distribution is ${_dist}."
        _dist="$(echo "$_dist" | tr '[:upper:]' '[:lower:]')"
        case "$_dist" in
            ubuntu)
                _error_msg="$_error_msg\nHowever detected version $_version is less than 12."
                oIFS="$IFS"; IFS=.; set -- $_version; IFS="$oIFS";
                [ $1 -ge 12 ] && LSB_DIST=$_dist && DIST_VERSION=$_version && DIST_VERSION_MAJOR=$1
                ;;
            debian)
                _error_msg="$_error_msg\nHowever detected version $_version is less than 7."
                oIFS="$IFS"; IFS=.; set -- $_version; IFS="$oIFS";
                [ $1 -ge 7 ] && LSB_DIST=$_dist && DIST_VERSION=$_version && DIST_VERSION_MAJOR=$1
                ;;
            fedora)
                _error_msg="$_error_msg\nHowever detected version $_version is less than 21."
                oIFS="$IFS"; IFS=.; set -- $_version; IFS="$oIFS";
                [ $1 -ge 21 ] && LSB_DIST=$_dist && DIST_VERSION=$_version && DIST_VERSION_MAJOR=$1
                ;;
            rhel)
                _error_msg="$_error_msg\nHowever detected version $_version is less than 7."
                oIFS="$IFS"; IFS=.; set -- $_version; IFS="$oIFS";
                [ $1 -ge 6 ] && LSB_DIST=$_dist && DIST_VERSION=$_version && DIST_VERSION_MAJOR=$1
                ;;
            centos)
                _error_msg="$_error_msg\nHowever detected version $_version is less than 6."
                oIFS="$IFS"; IFS=.; set -- $_version; IFS="$oIFS";
                [ $1 -ge 6 ] && LSB_DIST=$_dist && DIST_VERSION=$_version && DIST_VERSION_MAJOR=$1
                ;;
            amzn)
                _error_msg="$_error_msg\nHowever detected version $_version is not one of\n    2, 2.0, 2018.03, 2017.09, 2017.03, 2016.09, 2016.03, 2015.09, 2015.03, 2014.09, 2014.03."
                [ "$_version" = "2" ] || [ "$_version" = "2.0" ] || \
                [ "$_version" = "2018.03" ] || \
                [ "$_version" = "2017.03" ] || [ "$_version" = "2017.09" ] || \
                [ "$_version" = "2016.03" ] || [ "$_version" = "2016.09" ] || \
                [ "$_version" = "2015.03" ] || [ "$_version" = "2015.09" ] || \
                [ "$_version" = "2014.03" ] || [ "$_version" = "2014.09" ] && \
                LSB_DIST=$_dist && DIST_VERSION=$_version && DIST_VERSION_MAJOR=$_version
                ;;
            sles)
                _error_msg="$_error_msg\nHowever detected version $_version is less than 12."
                oIFS="$IFS"; IFS=.; set -- $_version; IFS="$oIFS";
                [ $1 -ge 12 ] && LSB_DIST=$_dist && DIST_VERSION=$_version && DIST_VERSION_MAJOR=$1
                ;;
            ol)
                _error_msg="$_error_msg\nHowever detected version $_version is less than 6."
                oIFS="$IFS"; IFS=.; set -- $_version; IFS="$oIFS";
                [ $1 -ge 6 ] && LSB_DIST=$_dist && DIST_VERSION=$_version && DIST_VERSION_MAJOR=$1
                ;;
            *)
                _error_msg="$_error_msg\nThat is an unsupported distribution."
                ;;
        esac
    fi

    if [ -z "$LSB_DIST" ]; then
        echo >&2 "$(echo | sed "i$_error_msg")"
        echo >&2 ""
        echo >&2 ""
        exit 1
    fi
}

#######################################
# Detects the init system.
# Upon failure exits with an error.
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   INIT_SYSTEM
#######################################
INIT_SYSTEM=
detectInitSystem() {
    if [[ "$(/sbin/init --version 2>/dev/null)" =~ upstart ]]; then
        INIT_SYSTEM=upstart
    elif [[ "$(systemctl 2>/dev/null)" =~ -\.mount ]]; then
        INIT_SYSTEM=systemd
    elif [ -f /etc/init.d/cron ] && [ ! -h /etc/init.d/cron ]; then
        INIT_SYSTEM=sysvinit
    else
        echo >&2 "Error: failed to detect init system or unsupported."
        exit 1
    fi
}

#######################################
# Prompts the user for a private address.
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   PRIVATE_ADDRESS
#######################################
promptForPrivateIp() {
    _count=0
    _regex="^[[:digit:]]+: ([^[:space:]]+)[[:space:]]+[[:alnum:]]+ ([[:digit:].]+)"
    while read -r _line; do
        [[ $_line =~ $_regex ]]
        if [ "${BASH_REMATCH[1]}" != "lo" ]; then
            _iface_names[$((_count))]=${BASH_REMATCH[1]}
            _iface_addrs[$((_count))]=${BASH_REMATCH[2]}
            let "_count += 1"
        fi
    done <<< "$(ip -4 -o addr)"
    if [ "$_count" -eq "0" ]; then
        echo >&2 "Error: The installer couldn't discover any valid network interfaces on this machine."
        echo >&2 "Check your network configuration and re-run this script again."
        echo >&2 "If you want to skip this discovery process, pass the 'local-address' arg to this script, e.g. 'sudo ./install.sh local-address=1.2.3.4'"
        exit 1
    elif [ "$_count" -eq "1" ]; then
        PRIVATE_ADDRESS=${_iface_addrs[0]}
        printf "The installer will use network interface '%s' (with IP address '%s')\n" "${_iface_names[0]}" "${_iface_addrs[0]}"
        return
    fi
    printf "The installer was unable to automatically detect the private IP address of this machine.\n"
    printf "Please choose one of the following network interfaces:\n"
    for i in $(seq 0 $((_count-1))); do
        printf "[%d] %-5s\t%s\n" "$i" "${_iface_names[$i]}" "${_iface_addrs[$i]}"
    done
    while true; do
        printf "Enter desired number (0-%d): " "$((_count-1))"
        prompt
        if [ -z "$PROMPT_RESULT" ]; then
            continue
        fi
        if [ "$PROMPT_RESULT" -ge "0" ] && [ "$PROMPT_RESULT" -lt "$_count" ]; then
            PRIVATE_ADDRESS=${_iface_addrs[$PROMPT_RESULT]}
            printf "The installer will use network interface '%s' (with IP address '%s').\n" "${_iface_names[$PROMPT_RESULT]}" "$PRIVATE_ADDRESS"
            return
        fi
    done
}

#######################################
# Discovers public IP address from cloud provider metadata services.
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   PUBLIC_ADDRESS
#######################################
discoverPublicIp() {
    if [ -n "$PUBLIC_ADDRESS" ]; then
        printf "The installer will use service address '%s' (from parameter)\n" "$PUBLIC_ADDRESS"
        return
    fi

    # gce
    if commandExists "curl"; then
        set +e
        _out=$(curl --noproxy "*" --max-time 5 --connect-timeout 2 -qSfs -H 'Metadata-Flavor: Google' http://169.254.169.254/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip 2>/dev/null)
        _status=$?
        set -e
    else
        set +e
        _out=$(wget --no-proxy -t 1 --timeout=5 --connect-timeout=2 -qO- --header='Metadata-Flavor: Google' http://169.254.169.254/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip 2>/dev/null)
        _status=$?
        set -e
    fi
    if [ "$_status" -eq "0" ] && [ -n "$_out" ]; then
        PUBLIC_ADDRESS=$_out
        printf "The installer will use service address '%s' (discovered from GCE metadata service)\n" "$PUBLIC_ADDRESS"
        return
    fi

    # ec2
    if commandExists "curl"; then
        set +e
        _out=$(curl --noproxy "*" --max-time 5 --connect-timeout 2 -qSfs http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null)
        _status=$?
        set -e
    else
        set +e
        _out=$(wget --no-proxy -t 1 --timeout=5 --connect-timeout=2 -qO- http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null)
        _status=$?
        set -e
    fi
    if [ "$_status" -eq "0" ] && [ -n "$_out" ]; then
        PUBLIC_ADDRESS=$_out
        printf "The installer will use service address '%s' (discovered from EC2 metadata service)\n" "$PUBLIC_ADDRESS"
        return
    fi
}

#######################################
# Prompts the user for a public address.
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   PUBLIC_ADDRESS
#######################################
shouldUsePublicIp() {
    if [ -z "$PUBLIC_ADDRESS" ]; then
        return
    fi

    printf "The installer has automatically detected the service IP address of this machine as %s.\n" "$PUBLIC_ADDRESS"
    printf "Do you want to:\n"
    printf "[0] default: use %s\n" "$PUBLIC_ADDRESS"
    printf "[1] enter new address\n"
    printf "Enter desired number (0-1): "
    promptTimeout
    if [ "$PROMPT_RESULT" = "1" ]; then
        promptForPublicIp
    fi
}

#######################################
# Prompts the user for a public address.
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   PUBLIC_ADDRESS
#######################################
promptForPublicIp() {
    while true; do
        printf "Service IP address: "
        promptTimeout "-t 120"
        if [ -n "$PROMPT_RESULT" ]; then
            if isValidIpv4 "$PROMPT_RESULT"; then
                PUBLIC_ADDRESS=$PROMPT_RESULT
                break
            else
                printf "%s is not a valid ip address.\n" "$PROMPT_RESULT"
            fi
        else
            break
        fi
    done
}

#######################################
# Determines if the ip is valid.
# Globals:
#   None
# Arguments:
#   IP
# Returns:
#   None
#######################################
isValidIpv4() {
    if echo "$1" | grep -qs '^[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$'; then
        return 0
    else
        return 1
    fi
}

#######################################
# Returns the ip portion of an address.
# Globals:
#   None
# Arguments:
#   ADDRESS
# Returns:
#   PARSED_IPV4
#######################################
PARSED_IPV4=
parseIpv4FromAddress() {
    PARSED_IPV4=$(echo "$1" | grep --only-matching '[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*')
}

#######################################
# Prompts for proxy address.
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   PROXY_ADDRESS
#######################################
promptForProxy() {
    printf "Does this machine require a proxy to access the Internet? "
    if ! confirmN; then
        return
    fi

    printf "Enter desired HTTP proxy address: "
    prompt
    if [ -n "$PROMPT_RESULT" ]; then
        if [ "${PROMPT_RESULT:0:7}" != "http://" ] && [ "${PROMPT_RESULT:0:8}" != "https://" ]; then
            echo >&2 "Proxy address must have prefix \"http(s)://\""
            exit 1
        fi
        PROXY_ADDRESS="$PROMPT_RESULT"
        printf "The installer will use the proxy at '%s'\n" "$PROXY_ADDRESS"
    fi
}

#######################################
# Exports proxy configuration.
# Globals:
#   PROXY_ADDRESS
# Arguments:
#   None
# Returns:
#   None
#######################################
exportProxy() {
    if [ -z "$PROXY_ADDRESS" ]; then
        return
    fi
    if [ -z "$http_proxy" ]; then
       export http_proxy=$PROXY_ADDRESS
    fi
    if [ -z "$https_proxy" ]; then
       export https_proxy=$PROXY_ADDRESS
    fi
    if [ -z "$HTTP_PROXY" ]; then
       export HTTP_PROXY=$PROXY_ADDRESS
    fi
    if [ -z "$HTTPS_PROXY" ]; then
       export HTTPS_PROXY=$PROXY_ADDRESS
    fi
}

#######################################
# Check if SELinux is enabled
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   Non-zero exit status unless SELinux is enabled
#######################################
selinux_enabled() {
    if commandExists "selinuxenabled"; then
        selinuxenabled
        return
    elif commandExists "sestatus"; then
        ENABLED=$(sestatus | grep 'SELinux status' | awk '{ print $3 }')
        echo "$ENABLED" | grep --quiet --ignore-case enabled
        return
    fi

    return 1
}

#######################################
# Check if SELinux is enforced
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   Non-zero exit status unelss SELinux is enforced
#######################################
selinux_enforced() {
    if commandExists "getenforce"; then
        ENFORCED=$(getenforce)
        echo $(getenforce) | grep --quiet --ignore-case enforcing
        return
    elif commandExists "sestatus"; then
        ENFORCED=$(sestatus | grep 'SELinux mode' | awk '{ print $3 }')
        echo "$ENFORCED" | grep --quiet --ignore-case enforcing
        return
    fi

    return 1
}

#######################################
# Prints a warning if selinux is enabled and enforcing
# Globals:
#   None
# Arguments:
#   Mode - either permissive or enforcing
# Returns:
#   None
#######################################
warn_if_selinux() {
    if selinux_enabled ; then
        if selinux_enforced ; then
            printf "${YELLOW}SELinux is enforcing. The \"--selinux-enabled\" flag may cause issues some features to become unavailable.${NC}\n\n"
        else
            printf "${YELLOW}SELinux is enabled. The \"--selinux-enabled\" flag may cause issues or some features to become unavailable.${NC}\n\n"
        fi
    fi
}

