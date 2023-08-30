#!/bin/bash

# USAGE
# ./deploy-apply.sh - pushes planned updates from base repo to all repos in brands/
# optionally only repos specified with -s parameter, e.g. ./deploy-apply.sh -s patterntheme-on

ALL_SITES=($(ls brands))
REMOTE_ORIGIN_NAME="source"
REMOTE_BRANCH="main"
LOCAL_BRANCH="main"
IGNORED=($(cat .deployignore))

deploySource() {
  # Checkout to latest origin
  git checkout $LOCAL_BRANCH
  # Merge temporary integration branch
  git merge "${REMOTE_ORIGIN_NAME}_${REMOTE_BRANCH}"
  # Push updates to origin
  git push origin $LOCAL_BRANCH --force
  # Remove temporary integration branch
  git branch -D "${REMOTE_ORIGIN_NAME}_${REMOTE_BRANCH}"
}

# This makes sure we always point to latest version of submodules
# If there were any updates 
updateSubmodulesReferences() {
  git add brands
  git commit -m "Update submodules"
  git push origin $LOCAL_BRANCH
}


main() {
  local OPTIND
  while getopts s: option
  do 
    case "${option}" in
      s) sites+=(${OPTARG});;
    esac
  done

  if [ ${sites[@]} ]; then
    echo -e "Running apply for specified sites: ${sites[@]}\n"
    RUN_FOR_SITES=("${sites[@]}")
  else
    RUN_FOR_SITES=("${ALL_SITES[@]}")
  fi

  for site in ${RUN_FOR_SITES[@]};
  do
    if [ -d "brands/${site}" ];
    then
      echo -e "Running for ${site}:\n"
      cd brands/$site
      deploySource
      cd ../../
    else
      echo -e "${site} does not exist\n"
    fi
  done

  updateSubmodulesReferences

  echo -e "\nDeploy Applied Successfully"
}

main "$@"