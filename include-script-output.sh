#! /usr/bin/env bash

# h/t: https://stackoverflow.com/questions/2683279/how-to-detect-if-a-script-is-being-sourced

# https://en.wikipedia.org/wiki/ANSI_escape_code#8-bit
C_ESC_256_PRE='\033[38;5;'
C_FG_DIM=${C_ESC_256_PRE}8m
C_FG_GRAY=${C_ESC_256_PRE}7m
C_FG_RED=${C_ESC_256_PRE}9m
C_FG_GREEN=${C_ESC_256_PRE}10m
C_FG_YELLOW=${C_ESC_256_PRE}11m
C_FG_BLUE=${C_ESC_256_PRE}12m
C_FG_MAGENTA=${C_ESC_256_PRE}13m
C_FG_CYAN=${C_ESC_256_PRE}14m
C_FG_WHITE=${C_ESC_256_PRE}15m

C_FG_ORANGE=${C_ESC_256_PRE}202m

C_BLACK_ON_GREEN='\033[0;30;42m'
C_BLACK_ON_CYAN='\033[0;30;46m'
C_WHITE_ON_RED='\033[0;37;41m'

C_RESET='\033[0m'

# some standard "colorize" colors
C_ERROR="Red"
C_WARNING="Yellow"
C_STATUS="Yellow"
C_SUCCESS="Green"
C_SECTION="Cyan"
C_NOTE="Blue"
C_NOTE2="Magenta"
C_DIM="Black"

# this file is intended to be source'd from a bash script
if [[ -z $BASH_SOURCE ]]; then
    echo -e "${C_FG_RED}This is an include script intended to be source'd by other scripts.${C_RESET}"
    # don't exit; user typed "source ./include-script-output.sh on the command-line"
    # exiting will close their terminal
fi

# if this script is being executed directly, exit
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo -e "${C_FG_RED}This is an include script intended to be source'd by other scripts.${C_RESET}"
    exit 1
fi
