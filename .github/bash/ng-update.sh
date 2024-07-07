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

function genPackageUpdateCommand () {
  args=("$@")
  title="${args[0]}"
  BaseBranch="${args[1]}"
  id="${args[2]}"
  package="${args[3]}"

  PRCMD=""
  PRCMD+="## Create Temporary Directory${newline}"
  PRCMD+="if [[ ! -d \".github/.tmp\" ]] ${newline}"
  PRCMD+="then ${newline}"
  PRCMD+="  mkdir .github/.tmp ${newline}"    
  PRCMD+="fi ${newline}"
  PRCMD+="touch .github/.tmp/log.txt${newline}${newline}"

  ## Attemp Angular Package Update
  PRCMD+="## $title${newline}"
  PRCMD+="git checkout ${BaseBranch} && \\${newline}"
  PRCMD+="git checkout -b ng-update/${id} && \\${newline}"
  PRCMD+="npx ng update -C true $package \\ ${newline}"

  echo "$PRCMD"
}

function genUpdateScript () {
  UpdateOut=("$@")

  declare -A UpdateCmds=()
  Updates=$( CliMessageToData "$UpdateOut" )
  cmdStr=$( GetCommands "$Updates" )
  
  UpdateArray=( $(echo "${Updates[@]}") )

  newline=$'\n'

  PRCMD="#! /bin/bash${newline}"

  PRCMD+="set NG_FORCE_TTY=false;${newline}"
  PRCMD+="Urls=();${newline}${newline}"

  UpdateArray=( $(echo "${Updates[@]}") )
  for i in $(seq 0 $(("${#UpdateArray[@]}"-1)))
  do
    id=$( GenUniqueId );
    row=( $( CSVUnpackRow "${UpdateArray[$i]}" ) );
    title=$( GetPullRequestTitle "${row[@]}" );
    
    PRCMD+="## NG Update #$(( ${i}+1 ))${newline}${newline}"
    ## Create Temporary Directory
    PRCMD+="## Create Temporary Directory${newline}"
    PRCMD+="if [[ ! -d \".github/.tmp\" ]] ${newline}"
    PRCMD+="then ${newline}"
    PRCMD+="  mkdir .github/.tmp ${newline}"    
    PRCMD+="fi ${newline}"
    PRCMD+="touch .github/.tmp/log.txt${newline}${newline}"

    ## Attemp Angular Package Update
    #PRCMD+="## $title${newline}"
    #PRCMD+="git checkout ${BaseBranch} && \\${newline}"
    #PRCMD+="git checkout -b ng-update/${id} && \\${newline}"
    #PRCMD+="npx ng update -C true ${row[0]}@${row[2]} | tee -a .github/.tmp/log.txt; \\ ${newline}"

    PRCMD+=$( genPackageUpdateCommand "$title" "$BaseBranch" "$id" "${row[0]}@${row[2]}" )

    PRCMD+="[ $? -eq '0' ] && echo \"Angular Update Successfully Commited\" || echo 'Angular Update Failed';${newline}${newline}"

    ## Push Branch to Origin and Create Pull Request
    PRCMD+="PR_TITLE=\"$title\";${newline}"
    PRCMD+="PR_BODY=\"NG Update #$(( ${i}+1 ))${newline}\";${newline}${newline}"

    PRCMD+="if [[ -n .github/.tmp/log.txt ]]${newline}"
    PRCMD+="then${newline}"
    PRCMD+="  PR_BODY+='npx ng update -C true ${row[0]}@${row[2]}';${newline}"
    PRCMD+="  PR_BODY+=\$( cat .github/.tmp/log.txt );${newline}"
    PRCMD+="else${newline}"
    PRCMD+="  PR_BODY+=\$( git log -n 1 )${newline}"
    PRCMD+="fi${newline}${newline}"

    ## Push Branch to Origin and Create Pull Request
    PRCMD+="git push origin ng-update/${id} && \\${newline}"
    PRCMD+="gh pr create --label 'ng update','automated update' --title \"\$PR_TITLE\" -B $BaseBranch --body \"\$PR_BODY\" && \\${newline}"
    PRCMD+="url=\`gh pr view --json url | jq '.url'\` && \\${newline}"
    ## Print Message if creating the pull request was successful.
    PRCMD+="[ $? -eq '0' ] && echo \"Successfully Created Pull Request \$url\" || echo 'Failed to Create Pull Request';${newline}"
    
    PRCMD+="Urls+=( \"\$url\" ) && \\${newline}${newline}"
    
    ## Restore to base branch for next update
    PRCMD+="git checkout ${BaseBranch} && \\${newline}"
    PRCMD+="rm -rdf node_modules && \\${newline}"
    PRCMD+="npm install --no-progress; \\${newline}${newline}"
    

    PRCMD+="${newline}${newline}"
    sleep 3;
  done;

  PRCMD+='echo "${urls[@]}"'
  echo "$PRCMD";
}

TmpDir='.github/.tmp'
UpdateOut=$( npx ng update 2>&1 | grep '@angular' )
UpdateAvail=$( NgUpdateAvail "$UpdateOut" )

if [[ "$UpdateAvail" -gt "0" ]];
then
  if [[ -d "$TmpDir" ]]
  then
    rm -rdf "$TmpDir"
  fi
  
  mkdir "$TmpDir"

  genUpdateScript "$UpdateOut" > "$TmpDir"/update.sh
fi
