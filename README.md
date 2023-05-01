# create-nginx-site
**create-nginx-site** is an easy-to-use globally installed NPM package for a quick setup of new NGINX websites.

Developed and tested only on Ubuntu 18.04. It can create virtual host configuration files and public static file folders with the option of adding SSL via Certbot.

You may also customize the default HTML template located in the /assets/static folder where the package is installed.

# Installation
The create-nginx-site package is installed globally via NPM:

`npm install -g create-nginx-site`

# Usage
To create a new virtual host, use the following command:

`create-nginx-site -d example.com [--ssl]`

The -d or --domain option specifies the domain name for the new virtual host. The --ssl option can be used to obtain an SSL certificate for the domain using Certbot. Use -h or --help for a list of all available options.

# Dependencies
- NGINX (tested on 2.4.x)
- Certbot (optional for SSL)

# Contributing
If you encounter any issues or have suggestions for improvements, please submit an issue or pull request on the GitHub repository.

# License
This package is licensed under the MIT License. See the LICENSE file for details.