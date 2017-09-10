#!/usr/bin/env bash

#Licensed Materials - Property of IBM
#
#@ Copyright IBM Corp. 2016  All Rights Reserved
#
#US Government Users Restricted Rights - Use, duplication or disclosure restricted by GSA ADP Schedule Contract with IBM Corp.

THIS_DIR="$( cd "$( dirname "$0" )" && pwd )"

if [[ -n ${UCD_PWD} && -n ${UDEPLOY_SERVER} ]]; then

  # download udclient
  curl -sSk ${UDEPLOY_SERVER}/tools/udclient.zip -o /tmp/udclient.zip && unzip -qo /tmp/udclient.zip -d . && rm /tmp/udclient.zip
  UCD_CLIENT=./udclient/udclient
  # check that udclient is there
  if [[ ! -x ${UCD_CLIENT} ]]; then
    echo "UCD Client not found, see previous output for more information."
    exit 1
  fi

  ###DS_AUTH_TOKEN=${UCD_TOKEN}
  DS_WEB_URL=${UDEPLOY_SERVER}
  COMPONENT_ID_FILE=${THIS_DIR}/ucd.comp.id.txt

  CURR_DATE=`date +"%T.%3N"`
  echo "### ${CURR_DATE} checking for existance of build file."
  if [[ -f ${BUILD_FILE} ]]; then
    COMPONENT_ID=$(<${COMPONENT_ID_FILE})
    # export the variables needed by the uDeploy client
    ###export DS_AUTH_TOKEN
    export DS_WEB_URL
    # Create a new version and add files
    ${UCD_CLIENT} -username ${UCD_USR} -password ${UCD_PWD} createVersion -component "${COMPONENT_ID}" -name "Dev-ANT-${TRAVIS_BUILD_ID}"
    echo "### uDeploy createVersion completed. Issuing addVersionFiles."
    ${UCD_CLIENT} -username ${UCD_USR} -password ${UCD_PWD} addVersionFiles -component "${COMPONENT_ID}" -version "Dev-ANT-${TRAVIS_BUILD_ID}" -base "$(dirname ${BUILD_FILE})" -include "$(basename ${BUILD_FILE})" -include "*"
    echo "### issuing uDeploy addVersionLink"
    ${UCD_CLIENT} -username ${UCD_USR} -password ${UCD_PWD} addVersionLink -component "${COMPONENT_ID}" -version "Dev-ANT-${TRAVIS_BUILD_ID}" -linkName "Travis Build" -link "${BUILD_LINK}"
    echo "### uDeploy addVersionLink complete. Issuing requestApplicationProcess"
    
    ${UCD_CLIENT} -username ${UCD_USR} -password ${UCD_PWD} requestApplicationProcess "${THIS_DIR}/ucd.deploy.req.json"
    echo "### uDeploy requestApplicationProcess complete"
  else
    echo "Did not find file to upload and/or its version file"
  fi
else
  echo "Did not get expected environment variables"
fi
