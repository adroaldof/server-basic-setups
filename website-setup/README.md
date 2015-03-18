# Website Setup

This script will help you to configure an initial setups for a website project. It were tested on [Digital Ocean](https://www.digitalocean.com/).

## Prerequisite

- A virtual machine configured as you primary domain
- Set your primary domain name as hostname on that virtual machine
- [Nginx](http://nginx.com/) installed
- Root access to create and modify files and directories

## Scripts

### Create Project Script

To execute script you need to do

    ./createProject.sh your-domain.here

1. Will ask to remove a existing project with same name, if it exists
1. Setup a base project directory at `/home/<your-user>/your-domain.here`
1. Initialize a git bare repo
1. Create a post-receive hook on that repo
1. Setup a deploy directory at `/var/www/your-domain.here/html`
1. Configure a new server block at `/etc/nginx/sites-available/your-domain.here`
1. Create a symbolic link on sites available at `/etc/nginx/sites-enabled/your-domain.here`
1. Reload Nginx server
1. Give you a production remote address to add on your local repo


### Remove Project Script

To execute script you need to do

    ./removeProject your-domain.here

This will remove the following directories

1. `/home/<your-user>/your-domain.here`
1. `/var/www/your-domain.here`

Remove the following files

1. `/etc/nginx/sites-available/your-domain.here`
1. `/etc/nginx/sites-enabled/your-domain.here`

And reload Nginx server
