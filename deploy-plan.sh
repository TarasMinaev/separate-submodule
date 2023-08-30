#!/bin/bash

# USAGE
# ./deploy-plan.sh - create commits updates from base repo to all repos in brands/ locally
# optionally only repos specified with -s parameter, e.g. ./deploy-plan.sh -s patterntheme-on

ALL_SITES=($(ls brands))
REMOTE_ORIGIN_NAME="source"
REMOTE_BRANCH="stage"
LOCAL_BRANCH="stage"
IGNORED=($(cat .deployignore))

updateSource() {

  git config -l | grep url
  git remote -v
  # Add source repository if not there
  if ! git config "remote.${REMOTE_ORIGIN_NAME}.url" >/dev/null;
  then
    git remote add $REMOTE_ORIGIN_NAME ../../
  fi

  git remote -v

  # Fetch source repo branches
  echo 'Fetch!!!!'
  git fetch $REMOTE_ORIGIN_NAME
  # Fetch local origin
  echo 'Fetch_origin!!!!'
  git fetch origin
  # Checkout to local origin
  echo 'Checkout!!!!'
  git config checkout.defaultRemote origin
  git checkout $LOCAL_BRANCH
  # Pull from latest origin
  echo 'pull!!!!!!!!!!'
  git pull origin $LOCAL_BRANCH
  # Checkout to a new temporary integration branch
  git checkout -b "${REMOTE_ORIGIN_NAME}_${REMOTE_BRANCH}"
  # Merge source branch onto local temporary integration branch but do not commit yet
  echo 'Merge!!!!'
  git merge -X theirs --no-ff --no-commit --allow-unrelated-histories "${REMOTE_ORIGIN_NAME}/${REMOTE_BRANCH}"
  # Save base theme version
  SETTINGS_FILE="config/settings_schema.json"
  THEME_VERSION=($(jq -r ".[0].theme_version" $SETTINGS_FILE))
  # Undo changes to files we don't want to change from source
  echo 'reset--------------'
  git reset $LOCAL_BRANCH -- ${IGNORED[@]}
  echo 'restore**************'
  git restore .
  echo 'clean.....!!!!!!!!!!!!!!!!!'
  # Remove any new files that were created by source that we don't want
  git clean -fd
  echo ',,,,,,,,,,,,,,,,,,'
  # Replace child theme version with base theme version
  echo "$(jq --arg v $THEME_VERSION '.[0].theme_version = $v' $SETTINGS_FILE)" > $SETTINGS_FILE
  git add $SETTINGS_FILE
  # Commit merging source
  echo 'commit____________1'
  git commit -m "Merge ${REMOTE_ORIGIN_NAME}/${REMOTE_BRANCH}"
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
    echo -e "Running plan for specified sites: ${sites[@]}\n"
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
      updateSource
      cd ../../
    else
      echo -e "${site} does not exist\n"
    fi
  done

  echo -e "\nDeploy Planned Successfully"
}

main "$@"