#!/bin/bash

echo " *****"
projectName=$1

homePath="/home/$(whoami)/"
projectPath="$homePath$projectName"

deployPath="/var/www/$projectName"

sitesAvailable="/etc/nginx/sites-available/$projectName"
sitesEnabled="/etc/nginx/sites-enabled/$projectName"


################################################################################
# Ask to remove files and directories if exists
################################################################################

if [[ -d "$projectPath" ]] || [[ -d "$deployPath" ]] || [[ -f "$sitesAvailable" ]] || [[ -f "$sitesEnabled" ]]; then
    echo " * The project '$projectName' will be removed"
    read -r -p " * Are you sure [Y/n]?" response
    if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo " * Cleaning project"
        rm -rf $projectPath
        rm -rf $deployPath
        if [[ -f "$sitesAvailable" ]]; then
            sudo rm $sitesAvailable
        fi
        if [[ -f "$sitesEnabled" ]]; then
            sudo rm $sitesEnabled
        fi
        sudo service nginx restart
        echo " * Files and directories cleaned"
        echo " *****"
    else
        echo " * Stopping script"
        echo " * Ok! Bye"
        echo " *****"
        exit 1
    fi
else
    echo " * Not found project '$projectName'"
    echo " *****"
    exit 1
fi

