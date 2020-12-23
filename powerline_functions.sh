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

function __powerline_user_info_prompt {
  local user_info=""
  local color=${USER_INFO_PROMPT_COLOR}
  if [[ -n "${SSH_CLIENT}" ]]; then
    user_info="${USER_INFO_SSH_CHAR}\u@\h"
  else
    user_info="\u@\h"
  fi
  [[ -n "${user_info}" ]] && echo "${user_info}|${color}"
}

function __powerline_cwd_prompt {
  echo "\w|${CWD_PROMPT_COLOR}"
}

function __powerline_short_cwd_prompt() {
  base="${PWD#${HOME}}"
  if [ "${PWD}" != "${base}" ]; then
    base="~$base"
  fi

  parts=
  last_short=""
  IFS="/"
  for q in ${base}; do
    last_short=""
    if [[ ${#q} -gt 3 ]]; then
      short_cwd+="${q:0:2}./"
    else
      last_short=true
      short_cwd+="$q/"
    fi
  done
  short_cwd=${short_cwd%/}
  if [ -z $last_short ]; then
    short_cwd=${short_cwd%.}
    short_cwd+="${q:2}"
  fi
  IFS=' '
  echo "$short_cwd|${CWD_PROMPT_COLOR}"
}


function __powerline_scm_prompt {
  git_local_branch=""
  git_branch=""
  git_dirty=""
  git_dirty_count=""
  git_ahead_count=""
  git_ahead=""
  git_behind_count=""
  git_behind=""

  find_git_branch() {
    # Based on: http://stackoverflow.com/a/13003854/170413
    git_local_branch=$(git rev-parse --abbrev-ref HEAD 2> /dev/null)

    if [[ -n "$git_local_branch" ]]; then
      if [[ "$git_local_branch" == "HEAD" ]]; then
        # Branc detached Could show the hash here
        git_branch=$(git rev-parse --short HEAD 2>/dev/null)
      else
        git_branch=$git_local_branch
      fi
    else
      git_branch=""
      return 1
    fi
  }

  find_git_dirty() {
    # All dirty files (modified and untracked)
    local status_count=$(git status --porcelain 2> /dev/null | wc -l)

    if [[ "$status_count" != 0 ]]; then
      git_dirty=true
      git_dirty_count="$status_count"
    else
      git_dirty=''
      git_dirty_count=''
    fi
  }

  find_git_ahead_behind() {
    if [[ -n "$git_local_branch" ]] && [[ "$git_branch" != "HEAD" ]]; then
      local upstream_branch=$(git rev-parse --abbrev-ref "@{upstream}" 2> /dev/null)
      # If we get back what we put in, then that means the upstream branch was not found.  (This was observed on git 1.7.10.4 on Ubuntu)
      [[ "$upstream_branch" = "@{upstream}" ]] && upstream_branch=''
      # If the branch is not tracking a specific remote branch, then assume we are tracking origin/[this_branch_name]
      [[ -z "$upstream_branch" ]] && upstream_branch="origin/$git_local_branch"
      if [[ -n "$upstream_branch" ]]; then
        git_ahead_count=$(git rev-list --left-right ${git_local_branch}...${upstream_branch} 2> /dev/null | grep -c '^<')
        git_behind_count=$(git rev-list --left-right ${git_local_branch}...${upstream_branch} 2> /dev/null | grep -c '^>')
        if [[ "$git_ahead_count" = 0 ]]; then
          git_ahead_count=''
        else
          git_ahead=true
        fi
        if [[ "$git_behind_count" = 0 ]]; then
          git_behind_count=''
        else
          git_behind=true
        fi
      fi
    fi
  }


  local color
  local scm_info

  find_git_branch && find_git_dirty && find_git_ahead_behind

  #not in Git repo
  [[ -z "$git_branch" ]] && return

  scm_info="${SCM_GIT_CHAR}${git_branch}"
  [[ -n "$git_dirty" ]] && color=${SCM_PROMPT_DIRTY_COLOR} || color=${SCM_PROMPT_CLEAN_COLOR}
  [[ -n "$git_behind" ]] && scm_info+="${SCM_PROMPT_BEHIND}${git_behind_count}"
  [[ -n "$git_ahead" ]] && scm_info+="${SCM_PROMPT_AHEAD}${git_ahead_count}"

  [[ -n "${scm_info}" ]] && echo "${scm_info}|${color}"
}

function __powerline_left_segment {
  local OLD_IFS="${IFS}"; IFS="|"
  local params=( $1 )
  IFS="${OLD_IFS}"
  local separator_char="${POWERLINE_LEFT_SEPARATOR}"
  local separator=""
  local styles=( ${params[1]} )

  if [[ "${SEGMENTS_AT_LEFT}" -gt 0 ]]; then
    styles[1]=${LAST_SEGMENT_COLOR}
    styles[2]=""
    separator="$(__color ${styles[@]})${separator_char}"
  fi

  styles=( ${params[1]} )
  LEFT_PROMPT+="${separator}$(__color ${styles[@]})${params[0]}$POWERLINE_RIGHT_PAD"

  #Save last background for next segment
  LAST_SEGMENT_COLOR=${styles[0]}
  (( SEGMENTS_AT_LEFT += 1 ))
}

function __powerline_last_status_prompt {
  local symbols=()
  [[ $last_status -ne 0 ]] && symbols+="$(__color ${STATUS_PROMPT_ERROR_COLOR})${STATUS_PROMPT_ERROR}"
  [[ $UID -eq 0 ]] && symbols+="$(__color ${STATUS_PROMPT_ROOT_COLOR})${STATUS_PROMPT_ROOT}"
  [[ $(jobs -l | wc -l) -gt 0 ]] && symbols+="$(__color ${STATUS_PROMPT_JOBS_COLOR})${STATUS_PROMPT_JOBS}"

  [[ ! -n "$symbols" ]] && [[ ! -z "$STATUS_PROMPT_SUCCESS" ]]  && symbols+="$STATUS_PROMPT_SUCCESS"
  [[ -n "$symbols" ]] && echo "$symbols|${STATUS_PROMPT_COLOR}"

}

function __powerline_history_prompt() {
  echo "\!|C G"
}

function __powerline_weather_prompt() {
  file=~/.bash/weather
  if [ -f $file ]; then
    MIN=$((($(date +%s) - $(date -r $file +%s)) / 60))

    if [ $MIN -gt 15 ]; then
      status=$(curl -s wttr.in/$WEATHER_LOC?format="+%c+%t" | tr -d '[:space:]')
      echo $status >$file
    else
      status=$(cat $file)
    fi
  else
    status=$(curl -s wttr.in/$WEATHER_LOC?format="+%c+%t" | tr -d '[:space:]')
    echo $status >$file
  fi

  temp=$(echo $status | tr -dc '\-0-9')
  if [ $temp -lt 5 ]; then
    echo "$status|B Bl"
  elif [ $temp -lt 20 ]; then
    echo "$status|Y Bl"
  else
    echo "$status|R Y"
  fi
}

function __powerline_emoji-clock_prompt() {
  local color="M Bl"
  printf -v clock "%d" $(expr $(date +%H%M) % 1200)

  oclock=🕛

  [ ${clock} -ge 30 ] && oclock=🕧
  [ ${clock} -ge 100 ] && oclock=🕐
  [ ${clock} -ge 130 ] && oclock=🕜
  [ ${clock} -ge 200 ] && oclock=🕑
  [ ${clock} -ge 230 ] && oclock=🕝
  [ ${clock} -ge 300 ] && oclock=🕒
  [ ${clock} -ge 330 ] && oclock=🕞
  [ ${clock} -ge 400 ] && oclock=🕓
  [ ${clock} -ge 430 ] && oclock=🕟
  [ ${clock} -ge 500 ] && oclock=🕔
  [ ${clock} -ge 530 ] && oclock=🕠
  [ ${clock} -ge 600 ] && oclock=🕕
  [ ${clock} -ge 630 ] && oclock=🕡
  [ ${clock} -ge 700 ] && oclock=🕖
  [ ${clock} -ge 730 ] && oclock=🕢
  [ ${clock} -ge 800 ] && oclock=🕗
  [ ${clock} -ge 830 ] && oclock=🕣
  [ ${clock} -ge 900 ] && oclock=🕘
  [ ${clock} -ge 930 ] && oclock=🕤
  [ ${clock} -ge 1000 ] && oclock=🕙
  [ ${clock} -ge 1030 ] && oclock=🕥
  [ ${clock} -ge 1100 ] && oclock=🕚
  [ ${clock} -ge 1130 ] && oclock=🕦

  echo "${oclock}|$color"
}
