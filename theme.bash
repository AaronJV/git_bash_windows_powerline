# Git bash for windows powerline theme
#
# Licensed under MIT
# Based on https://github.com/Bash-it/bash-it and https://github.com/Bash-it/bash-it/tree/master/themes/powerline
# Some ideas from https://github.com/speedenator/agnoster-bash
# Git code based on https://github.com/joeytwiddle/git-aware-prompt/blob/master/prompt.sh
# More info about color codes in https://en.wikipedia.org/wiki/ANSI_escape_code


PROMPT_CHAR=${POWERLINE_PROMPT_CHAR:=""}
[ -z ${POWERLINE_RIGHT_PAD+x} ] && POWERLINE_RIGHT_PAD=" "
POWERLINE_SEP_CHAR=${POWERLINE_SEP_CHAR:=""}
POWERLINE_LEFT_SEPARATOR="$POWERLINE_SEP_CHAR$POWERLINE_LEFT_PAD"
POWERLINE_PROMPT=${POWERLINE_PROMPT:="last_status user_info cwd scm"}

USER_INFO_SSH_CHAR=" "
USER_INFO_PROMPT_COLOR="C B"

SCM_GIT_CHAR=" "
SCM_PROMPT_CLEAN=""
SCM_PROMPT_DIRTY="*"
SCM_PROMPT_AHEAD="↑"
SCM_PROMPT_BEHIND="↓"
SCM_PROMPT_CLEAN_COLOR="G Bl"
SCM_PROMPT_DIRTY_COLOR="R Bl"
SCM_PROMPT_AHEAD_COLOR=""
SCM_PROMPT_BEHIND_COLOR=""
SCM_PROMPT_STAGED_COLOR="Y Bl"
SCM_PROMPT_UNSTAGED_COLOR="R Bl"
SCM_PROMPT_COLOR=${SCM_PROMPT_CLEAN_COLOR}

CWD_PROMPT_COLOR="B C"

STATUS_PROMPT_COLOR="Bl R B"
STATUS_PROMPT_ERROR=${STATUS_PROMPT_ERROR:=" ✘"}
STATUS_PROMPT_ERROR_COLOR="Bl R B"
STATUS_PROMPT_ROOT="⚡"
STATUS_PROMPT_ROOT_COLOR="Bl Y B"
STATUS_PROMPT_JOBS="●"
STATUS_PROMPT_JOBS_COLOR="Bl Y B"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$DIR/powerline_functions.sh"

function __color {
  local bg
  local fg
  local mod
  case $1 in
     'Bl') bg=40;;
     'R') bg=41;;
     'G') bg=42;;
     'Y') bg=43;;
     'B') bg=44;;
     'M') bg=45;;
     'C') bg=46;;
     'W') bg=47;;
     *) bg=49;;
  esac

  case $2 in
     'Bl') fg=30;;
     'R') fg=31;;
     'G') fg=32;;
     'Y') fg=33;;
     'B') fg=34;;
     'M') fg=35;;
     'C') fg=36;;
     'W') fg=37;;
     *) fg=39;;
  esac

  case $3 in
     'B') mod=1;;
     'N') mod=7;;
     *) mod=0;;
  esac

  # Control codes enclosed in \[\] to not polute PS1
  # See http://unix.stackexchange.com/questions/71007/how-to-customize-ps1-properly
  echo "\[\e[${mod};${fg};${bg}m\]"
}

function __powerline_prompt_command {
  local last_status="$?" ## always the first
  local separator_char="${POWERLINE_PROMPT_CHAR}"

  LEFT_PROMPT=""
  SEGMENTS_AT_LEFT=0
  LAST_SEGMENT_COLOR=""
  WIDTH=$(tput cols)

  ## left prompt ##
  for segment in $POWERLINE_PROMPT; do
    if [[ $segment == \>* ]]; then
      segment="${segment:1}"
      if [[ $WIDTH -lt 100 ]]; then
        continue
      fi
    fi
    local info="$(__powerline_${segment}_prompt)"
    [[ -n "${info}" ]] && __powerline_left_segment "${info}"
  done

  [[ -n "${LEFT_PROMPT}" ]] && LEFT_PROMPT+="$(__color - ${LAST_SEGMENT_COLOR})${separator_char}$(__color)"
  PS1="${LEFT_PROMPT} "

  ## cleanup ##
  unset LAST_SEGMENT_COLOR \
        LEFT_PROMPT \
        SEGMENTS_AT_LEFT
}

function safe_append_prompt_command {
    local prompt_re

    # Set OS dependent exact match regular expression
    if [[ ${OSTYPE} == darwin* ]]; then
      # macOS
      prompt_re="[[:<:]]${1}[[:>:]]"
    else
      # Linux, FreeBSD, etc.
      prompt_re="\<${1}\>"
    fi

    if [[ ${PROMPT_COMMAND} =~ ${prompt_re} ]]; then
      return
    elif [[ -z ${PROMPT_COMMAND} ]]; then
      PROMPT_COMMAND="${1}"
    else
      PROMPT_COMMAND="${1};${PROMPT_COMMAND}"
    fi
}

safe_append_prompt_command __powerline_prompt_command

__color_matrix() {
  local buffer

  declare -A colors=([0]=black [1]=red [2]=green [3]=yellow [4]=blue [5]=purple [6]=cyan [7]=white)
  declare -A mods=([0]='' [1]=B [4]=U [5]=k [7]=N)

  # Print foreground color names
  echo -ne "       "
  for fgi in "${!colors[@]}"; do
    local fg=`printf "%10s" "${colors[$fgi]}"`
    #print color names
    echo -ne "\e[m$fg "
  done
  echo

  # Print modificators
  echo -ne "       "
  for fgi in "${!colors[@]}"; do
    for modi in "${!mods[@]}"; do
      local mod=`printf "%1s" "${mods[$modi]}"`
      buffer="${buffer}$mod "
    done
    # echo -ne "\e[m "
    buffer="${buffer} "
  done
  echo -e "$buffer\e[m"
  buffer=""

  # Print color matrix
  for bgi in "${!colors[@]}"; do
    local bgn=$((bgi + 40))
    local bg=`printf "%6s" "${colors[$bgi]}"`

    #print color names
    echo -ne "\e[m$bg "

    for fgi in "${!colors[@]}"; do
      local fgn=$((fgi + 30))
      local fg=`printf "%7s" "${colors[$fgi]}"`

      for modi in "${!mods[@]}"; do
        buffer="${buffer}\e[${modi};${bgn};${fgn}m "
      done
      # echo -ne "\e[m "
      buffer="${buffer}\e[m "
    done
    echo -e "$buffer\e[m"
    buffer=""
  done
}

__character_map () {
  echo "powerline: ±●➦★⚡★ ✗✘✓✓✔✕✖✗← ↑ → ↓"
  echo "other: ☺☻👨⚙⚒⚠⌛"
}
