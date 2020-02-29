#! /usr/bin/env bash

# for files intended to be source'd from a bash script
THIS_IS_AN_INCLUDE_FILE() {
    # this file is intended to be source'd from a bash script
    if [[ -z $BASH_SOURCE ]]; then
        echo -e "\033[38:5:9mThis is an include script intended to be source'd by other scripts.\033[0m"
        # don't exit; user typed "source ./include-script-output.sh on the command-line"
        # exiting will close their terminal

        return 1
    fi

    # if this script is being executed directly, exit
    if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
        echo -e "\033[38:5:9mThis is an include script intended to be source'd by other scripts.\033[0m"
        exit 1
    fi
}

if THIS_IS_AN_INCLUDE_FILE; then
    source $(dirname "$0")/include-script-output.sh || exit 1

    ABORT() {
        echo ""
        echo -e "${C_FG_RED}An error was detected! Abort!${C_RESET}"
        echo ""
        exit 1
    }

    INDENT()       { sed 's/^/  /'; }

    SECTION_BEGIN()  {
        # first time check if the platform has 'boxes' and/or 'colorize'
        if [[ -z $HAS_BOXES ]]; then
            if which boxes >/dev/null 2>&1; then
                HAS_BOXES=0
            else
                HAS_BOXES=1
            fi
        fi

        if [[ -z $HAS_COLORIZE ]]; then
            if which colorize >/dev/null 2>&1; then
                HAS_COLORIZE=0
            else
                HAS_COLORIZE=1
            fi
        fi

        if [[ $HAS_BOXES == 0 ]]; then
            MSG=$(echo "$1" | boxes -d stone)
        else
            LEN=$((${#1} + 4))

            BDR=$(eval $(echo printf '"X%0.s"' {1..$LEN}))

            MSG=$(echo -e "${BDR}\nX $1 X\n${BDR}")
        fi

        if [[ $HAS_COLORIZE == 0 ]]; then
            echo "$MSG" | colorize $C_SECTION
        else
            echo -e "\n${C_FG_CYAN}${MSG}${C_RESET}\n";
        fi
    }

    STEP_BEGIN()     { echo -n "$1"; }
    STEP_OK()        { echo -e "${C_FG_GREEN}OK${C_RESET}"; [[ -n $1 ]] && echo -e "${C_FG_BLUE}$1${C_RESET}" | INDENT; }
    STEP_FAIL()      { echo -e "${C_FG_RED}FAIL${C_RESET}"; [[ -n $1 ]] && echo -e "${C_FG_RED}$1${C_RESET}" | INDENT; }
    STEP_ABORT()     { STEP_FAIL "$1"; exit 1; }

    CONFIRM() {
        echo ""
        echo -e "${C_FG_YELLOW}${1}${C_RESET}"
        echo ""
        echo "Type the word 'yes' to continue, or any other input to abort."
        echo -n "  Confirm action? "
        read CONFIRM

        [[ $CONFIRM == "yes" ]];
    }

    CONFIRM_OR_ABORT() {
        if ! CONFIRM "$1"; then
            echo -e "${C_FG_RED}Confirmation denied. Abort!${C_RESET}"
            exit 1
        fi
    }

    UNAME=$(uname)

    IS_OSX()  { [[ $UNAME == "Darwin" ]]; }
    IS_LINUX() { [[ $UNAME == "Linux" ]]; }
fi