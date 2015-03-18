#!/bin/bash

echo " *****"
projectName=$1

homePath="/home/$(whoami)/"
projectPath="$homePath$projectName"

deployPath="/var/www/$projectName"
contentPath="$deployPath/html"

sitesAvailable="/etc/nginx/sites-available/$projectName"
sitesEnabled="/etc/nginx/sites-enabled/$projectName"


################################################################################
# Ask to remove files and directories if exists
################################################################################

if [[ "$#" == "0" ]]; then
    echo " ** You need tu supply a project name! Ex: mydomain.com"
    echo " *****"
    exit 1
fi

if [[ -d "$projectPath" ]] || [[ -d "$deployPath" ]] || [[ -f "$sitesAvailable" ]] || [[ -f "$sitesEnabled" ]]; then
    echo " * The project '$projectName' already exists"
    echo " * Check on the following paths to se the configuration"
    echo " *"
    echo " * - $projectPath"
    echo " * - $deployPath"
    echo " * - $sitesAvailable"
    echo " * - $sitesEnabled"
    echo " *"
    read -r -p " * Do you want to overwrite? [Y/n] " response
    if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]
    then
        echo " * Cleaning project files if exists"
        rm -rf $projectPath
        rm -rf $deployPath
        if [[ -f "$sitesAvailable" ]]; then
            sudo rm $sitesAvailable
        fi
        if [[ -f "$sitesEnabled" ]]; then
            sudo rm $sitesEnabled
        fi
        echo " * Files and directories cleaned"
    else
        echo " * Stopping script"
        echo " * Ok! Bye"
        echo " *****"
        exit 1
    fi
fi


################################################################################
# Setup base project
################################################################################

# Create project directory
mkdir -p $projectPath
echo " * Created directory $projectPath"


################################################################################
# Add git bare repo and post-receive hook
################################################################################

# Initialize a git repo inside just created directory
echo " * Creating a git bare repo"
git --git-dir=$projectPath init

# Make post-receive file inside repo/hooks
cat << EOF > "$projectPath/hooks/post-receive"
#!/bin/bash

# Unset index for path with relation to working directory
unset GIT_INDEX_FILE

# Git post-receive hook
while read olrev newrev ref
do
    if [[ \$ref =~ .*/master$ ]];
    then
        echo "Changes accepted on \$ref. Deploying your new feature"
        git --work-tree=$contentPath --git-dir=$projectPath checkout -f
    else
        echo "Ref \$ref successfully received you push"
    fi
done

EOF

# Make post-receive executable
chmod +x "$projectPath/hooks/post-receive"
echo  " * Created post-receive hook at $projectPath/hooks/post-receive"


################################################################################
# Setup Production Project
################################################################################

# Create production directories
mkdir -p $contentPath


################################################################################
# Setup Nginx server block
################################################################################

# Create Nginx server block for the project
sudo tee $sitesAvailable > /dev/null << EOF
#!/bin/bash

## Answer to http://www.$projectName
server {
    listen 80;
    server_name www.$projectName;

    # Redirect permantly
    # Scheme is the protocol
    # Request ur is the path to location
    return 301 \$scheme://$projectName\$request_uri;
}

# Answer to http://$projectName
server {
    listen 80;
    server_name $projectName;

    access_log /var/log/nginx/$projectName.access.log;
    error_log /var/log/nginx/$projectName.error.log;

    root /var/www/$projectName/html;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ /index.html?q=\$uri&\$args /index.php?q=\$uri&\$args;
    }

    error_page 404 /404.html;
    error_page 500 502 503 504 /50x.html;
    location = /50x.html {
        root /var/www/$projectName/html;
    }

    location ~ \\.php$ {
        try_files \$uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/var/run/php5-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
}

EOF


################################################################################
# Add symbolic link to sites enabled
################################################################################

# Create symbolic link to project
sudo ln -s $sitesAvailable $sitesEnabled
echo " * Created symbolik link to project $projectName"


################################################################################
# Reload Nginx service
################################################################################

# Reload Nginx server
sudo nginx -t && sudo service nginx reload
echo " * Reloaded Nginx service"
echo " *****"


################################################################################
# Give you a production repo
################################################################################

echo
echo " *****"
echo " ** Every thing all right"
echo " ** Just add the follow remote to you local repo"
echo " ** 'git remote add production ssh://$(whoami)@$(hostname):${SSH_CLIENT##* }$projectPath'"
echo " ** and good work"
echo " *****"
