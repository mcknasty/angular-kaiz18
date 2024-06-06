#!/bin/bash

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

UpdateOut=$( npx ng update 2>&1 | grep '@angular' )
UpdateAvail=$( NgUpdateAvail "$UpdateOut" )

if [[ "$UpdateAvail" -gt "0" ]];
then
  declare -A UpdateCmds=( )
  Updates=$( CliMessageToData "$UpdateOut" )
  cmdStr=$( GetCommands "$Updates" )

  echo "${Updates[@]}"
  echo "${cmdStr}"
fi
