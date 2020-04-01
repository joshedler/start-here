#! /usr/bin/env bash

source $(dirname "$0")/include-script-output.sh || exit 1
source $(dirname "$0")/include-env-checks.sh || exit 1

COPY_SKEL() {
    SRC=$1
    DST=$2

    if [[ -z $SRC || -z $DST ]]; then
        echo -e "\n${C_FG_RED}ERROR: COPY_SKEL invalid arguments!${C_RESET}"
        exit 1
    fi

    if [[ ! -f $DST ]]; then
        cp $SRC $DST || ABORT
    else
        echo -e "\n${C_FG_YELLOW}${DST} exists, not overwriting.${C_RESET}"
    fi
}

RET=0

echo ""
SECTION_BEGIN "Terminal color test..."

echo ""
echo "STANDARD COLORS"
echo "==============="
echo -e "${C_FG_GRAY}GRAY${C_RESET}"
echo -e "${C_FG_RED}RED${C_RESET}"
echo -e "${C_FG_GREEN}GREEN${C_RESET}"
echo -e "${C_FG_YELLOW}YELLOW${C_RESET}"
echo -e "${C_FG_BLUE}BLUE${C_RESET}"
echo -e "${C_FG_MAGENTA}MAGENTA${C_RESET}"
echo -e "${C_FG_CYAN}CYAN${C_RESET}"
echo -e "${C_FG_WHITE}WHITE${C_RESET}"

echo ""
echo "ADDITIONAL COLORS"
echo "================="
echo -e "${C_FG_DIM}DIM${C_RESET}"
echo -e "${C_FG_ORANGE}ORANGE${C_RESET}"

echo ""
echo "The colors above should look reasonable for your terminal."

echo ""

SECTION_BEGIN "Checking environment..."

STEP_BEGIN "Detecting OS..."

if IS_OSX; then
    STEP_OK "OSX detected."
elif IS_LINUX; then
    STEP_OK "Linux detected."
else
    STEP_ABORT "FATAL: Unsupported OS '$UNAME'."
fi

#######################################################
##### AT THIS POINT THE OS IS EITHER OSX OR LINUX #####
#######################################################

if IS_OSX; then
    STEP_BEGIN "Detecting dependency 'homebrew'..."

    if which brew >/dev/null 2>&1; then
        STEP_OK
    else
        STEP_FAIL
        CONFIRM_OR_ABORT "Automatically install 'homebrew'?"

        if curl -sN https://brew.sh | grep -q '/usr/bin/ruby -e &quot;$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)&quot;'; then
            echo -e "\n${C_FG_YELLOW}Installing 'homebrew' using ruby...${C_RESET}"
            /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

        elif curl -sN https://brew.sh | grep -q '/bin/bash -c &quot;$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)&quot;'; then
            echo -e "\n${C_FG_YELLOW}Installing 'homebrew' using bash...${C_RESET}"
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
            stty echo
        else
            echo -e "${C_FG_RED}Unable to automatically install 'homebrew'. Visit https://brew.sh/ to manually install, and then re-run this script.${C_RESET}"
            exit 1
        fi
    fi
fi

STEP_BEGIN "\nDetecting dependency 'boxes'..."
if which boxes 2>&1 >/dev/null; then
    STEP_OK
else
    STEP_FAIL

    CONFIRM_OR_ABORT "Automatically install 'boxes'?"

    if IS_OSX; then
        brew install boxes || ABORT
    else
        sudo apt install boxes || ABORT
    fi
fi

STEP_BEGIN "\nDetecting dependency 'colorize'..."
if which colorize 2>&1 >/dev/null; then
    STEP_OK
else
    STEP_FAIL

    CONFIRM_OR_ABORT "Automatically install 'colorize'?"

    if IS_OSX; then
        pushd $HOME >/dev/null

        mkdir dev && cd dev

        # http://cgit.refcnt.org/colorize.git/tree/README
        git clone git://refcnt.org/colorize.git || ABORT

        cd colorize || ABORT

        make || ABORT

        cp colorize /usr/local/bin || ABORT

        popd >/dev/null
    else
        sudo apt install colorize
    fi
fi

STEP_BEGIN "\nDetecting Yubikey SSH dependencies..."

if IS_OSX; then
    # $ brew install gnupg yubikey-personalization hopenpgp-tools ykman pinentry-mac

    PACKAGES="gnupg yubikey-personalization hopenpgp-tools ykman pinentry-mac"

    if brew ls --versions $PACKAGES >/dev/null; then
        STEP_OK
    else
        STEP_FAIL
        echo "At least one of the following packages is missing:" | INDENT | colorize $C_NOTE2
        echo "$PACKAGES" | INDENT | INDENT | colorize $C_NOTE
        CONFIRM_OR_ABORT "Automatically install missing packages using 'homebrew'?"
        brew install $PACKAGES
    fi
else
    # $ sudo apt install -y wget gnupg2 gnupg-agent dirmngr cryptsetup scdaemon pcscd secure-delete hopenpgp-tools yubikey-personalization

    PACKAGES="wget gnupg2 gnupg-agent dirmngr cryptsetup scdaemon pcscd secure-delete hopenpgp-tools yubikey-personalization"

    EXPECTED=$(echo "$PACKAGES" | wc -w)
    ACTUAL=$(sudo apt -qq list $PACKAGES 2>/dev/null | grep '\[installed\]' | wc -l)

    if [[ $EXPECTED == $ACTUAL ]]; then
        STEP_OK
    else
        STEP_FAIL

        echo "At least one of the following packages is missing:" | INDENT | colorize $C_NOTE2
        echo "$PACKAGES" | INDENT | INDENT | colorize $C_NOTE
        CONFIRM_OR_ABORT "Automatically install missing packages using 'apt'?"
        sudo apt install $PACKAGES
    fi
fi

WORKDIR=$(dirname "$0")

FOLDER=~/.gnupg

STEP_BEGIN "\nDetecting $FOLDER..."

if [[ -d $FOLDER && -f $FOLDER/gpg.conf && -f $FOLDER/gpg-agent.conf ]]; then
    STEP_OK
else
    STEP_FAIL "$FOLDER is missing or missing some files!"

    if CONFIRM "Create skeleton $FOLDER?"; then
        [[ ! -d $FOLDER ]] && { mkdir $FOLDER || ABORT; }
        chmod 700 $FOLDER || ABORT

        COPY_SKEL $WORKDIR/gpg.conf $FOLDER/gpg.conf
        COPY_SKEL $WORKDIR/gpg-agent.conf $FOLDER/gpg-agent.conf

        echo ""
        ls -laFhd $FOLDER
        echo ""
        ls -laFh $FOLDER/
    else
        echo -e "\n${C_FG_RED}${FOLDER} not created.${C_RESET}"
        echo -e "\n${C_FG_YELLOW}Why did you run this script?${C_RESET}"
        exit 1
    fi
fi

FOLDER=~/.ssh

STEP_BEGIN "\nDetecting $FOLDER..."

if [[ -d $FOLDER && -f $FOLDER/my_rsa.pub && -f $FOLDER/config ]]; then
    STEP_OK
else
    STEP_FAIL "$FOLDER is missing or missing some files!"

    if CONFIRM "Create skeleton $FOLDER?"; then
        [[ ! -d $FOLDER ]] && { mkdir $FOLDER || ABORT; }
        chmod 700 $FOLDER || ABORT

        COPY_SKEL $WORKDIR/my_rsa.pub $FOLDER/my_rsa.pub
        COPY_SKEL $WORKDIR/config $FOLDER/config

        echo ""
        ls -laFhd $FOLDER
        echo ""
        ls -laFh $FOLDER/
    else
        echo -e "\n${C_FG_RED}${FOLDER} not created.${C_RESET}"
        echo -e "\n${C_FG_YELLOW}Why did you run this script?${C_RESET}"
        exit 1
    fi
fi

if ! grep -q my_rsa.pub $FOLDER/config; then
    echo -e "\n${C_FG_YELLOW}WARNING: $FOLDER/config is not using my_rsa.pub${C_RESET}"
    echo -e "Manually edit the file to fix this issue. Re-run this script when complete."
    RET=1
fi

if ls $FOLDER/id_rsa_*.pub >/dev/null 2>&1; then
    echo -e "\n${C_FG_YELLOW}WARNING: $(ls $FOLDER/id_rsa_*.pub) exists.${C_RESET}"
    echo -e "Manually clean-up $FOLDER/ to fix this issue. Re-run this script when complete"
    RET=1
fi

if [[ $RET == 0 ]]; then

    if ! gpg -k 0xA9DB11547CAE3081; then
        gpg --import $WORKDIR/my-public-key.txt
    fi

    echo -e "\n${C_FG_YELLOW}In order to use the hardware security key for SSH access, you must set the following environment variables first:${C_RESET}"
    echo '$ export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)'
    echo '$ export GPG_TTY=$(tty)'

    echo -e "\n${C_FG_YELLOW}You can test your configuraiton by inserting the hardware security key and issuing the following commands:${C_RESET}"
    echo '$ gpg --card-status'
    echo '$ ssh -T git@github.com'

    echo -e "\n${C_FG_GREEN}You are ready for the next step in the process!${C_RESET}\n"
else
    echo -e "\n${C_FG_CYAN}You can re-run $0 to check that everything is properly fixed.${C_RESET}\n"
fi

exit $RET