#!/bin/bash

BaseBranch='pkg-updates'
MasterBranch='main'

# Row 0 - Angular Package Name
# Row 1 - Current Package Verions
# Row 2 - Suggested Package Version
function CSVUnpackRow() {
  args=("$@")
  row="${args[0]}"

  unpackedRow=( $( echo "$row" | sed -E 's/"//g' | sed -E 's/,/ /g' ) )
  echo "${unpackedRow[@]}"
}

function NgUpdateAvail () {
  args=("$@")
  msg="${args[0]}"

   echo "$msg" | wc -l
}

function CliMessageToData () {
  args=("$@")
  msg="${args[0]}"

  UpdateStructText=$( echo "$msg" | sed -E 's/ng .*$/"/g' | sed -E 's/-> //g' | sed -E 's/ +/,/g' )
  UpdateStructText=$( echo "$UpdateStructText" | sed -E 's/^/"/g'  )
  UpdateStructText=$( echo "$UpdateStructText" | sed -E 's/,"/"/g' | sed -E 's/",/"/g')

  echo "$UpdateStructText"
}

function GetCommands () {
  args=("$@")
  NgUpdateArray=( $( echo "${args[0]}" ) )

  # Assign ng-cli and ng-core to the update stratergy first
  indecies=( $( echo "${!NgUpdateArray[*]}" ) )
  for u in "${indecies[@]}";
  do
    row=( $( CSVUnpackRow "${NgUpdateArray[$u]}" ) )
    if [[ "${row[0]}" == '@angular/cli' ]] 
    then
      UpdateCmds[0]="${row[0]}@${row[2]}";
      unset 'NgUpdateArray[u]';
    elif [[ "${row[0]}" == '@angular/core' ]]
    then
      UpdateCmds[1]="${row[0]}@${row[2]}";
      unset 'NgUpdateArray[u]';
    fi
  done;

  # Assign the rest of the packages to update stratergy
  indecies=( $( echo "${!NgUpdateArray[*]}" ) )
  for u in "${indecies[@]}";
  do
    idx=$(("${#UpdateCmds[@]}"))
    row=( $( CSVUnpackRow "${NgUpdateArray[$u]}" ) )
    UpdateCmds[$idx]="${row[0]}@${row[2]}";
  done;

  cmdString=""
  for i in $(seq 0 $(("${#UpdateCmds[@]}"-1)))
  do
    cmdString+="${UpdateCmds[$i]} "
  done;

  cmdString=$( echo $cmdString | sed -E 's/ $//g' )
  echo "npx ng update -C true $cmdString"
}

function GetPullRequestTitle () {
  args=("$@")
  row=( $( echo "${args[@]}" ) )

  # Example Title
  # chore(ng-deps): bump angular from 18.0.1 to 18.0.2
  title='chore(ng-deps): bump '

  if [[ "${row[0]}" == '@angular/core' ]]
  then
    title+="angular from ${row[1]} to ${row[2]}"
  else
    title+="${row[0]} from ${row[1]} to ${row[2]}"
  fi

  echo "$title"
}

function GenUniqueId () {
  echo $( date +%s | md5sum | awk '{print $1}' )
}

UpdateOut=$( npx ng update 2>&1 | grep '@angular' )
UpdateAvail=$( NgUpdateAvail "$UpdateOut" )

if [[ "$UpdateAvail" -gt "0" ]];
then
  declare -A UpdateCmds=( )
  Updates=$( CliMessageToData "$UpdateOut" )
  cmdStr=$( GetCommands "$Updates" )

  #echo "${Updates[@]}"
  #echo "${cmdStr}"

  # Need to program two options.
  #   - 1.  The angular update in a single command, commit, and pull request.
  #   - 2.  The angular update with a pull request, commit, and command per package.

  UpdateArray=( $(echo "${Updates[@]}") )
  for i in $(seq 0 $(("${#UpdateArray[@]}"-1)))
  do
    id=$( GenUniqueId );
    row=( $( CSVUnpackRow "${UpdateArray[$i]}" ) );
    title=$( GetPullRequestTitle "${row[@]}" );
    # echo "$title";
    PRCMD=" \
      git checkout -b ng-update/${id} && \
      npx ng update -C true ${row[0]}@${row[2]} && \
      git push origin ng-update/${id} && \
      gh pr create --title \"$title\" -B $BaseBranch --body \"\`git log -n 1\`\" && \
      git checkout ${MasterBranch}; \
      [ $? -eq '0' ] && echo 'Successfully Created Pull Request $id' || echo 'Failed to Create Pull Request'
    "
    echo "$PRCMD";
    sleep 3;
  done;
fi
