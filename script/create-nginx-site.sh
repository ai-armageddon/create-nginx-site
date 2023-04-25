#!/bin/bash

# create the directory structure
create_directory() {
    domain="$1"
    directory="/var/www/$domain/public_html"

    mkdir -p "$directory"

    # copy HTML files to site directories
    cp -R ./assets/static/. "$directory"

    # Specify output file
    output_file="index.html"

    # Create a temporary script file with variable updates
    temp_script="$directory/temp_script.sh"
    echo "#!/bin/bash" > "$temp_script"
    echo "sed -i 's/{NAME}/Jane/g' $output_file" >> "$temp_script"
    chmod +x "$temp_script"

    # Execute the temporary script within the directory
    (cd "$directory" && ./temp_script.sh)

    # Delete the temporary script file
    rm "$temp_script"
}

# create NGINX config file
create_nginx_config() {
    domain=$1
    port=$2
    template_file="./assets/server/template.conf"
    config_file="/etc/nginx/sites-available/$domain.conf"

    # Replace variables in the template file
    cp "$template_file" "$config_file"
    sed -i "s/{{DOMAIN_NAME}}/$domain/g" "$config_file"
    sed -i "s/{{APP_PORT}}/$port/g" "$config_file"

    echo "Created NGINX configuration file: $config_file"
}

# Function to create a symbolic link in sites-enabled
create_nginx_symlink() {
    domain=$1
    config_file="/etc/nginx/sites-available/$domain"
    symlink="/etc/nginx/sites-enabled/$domain"

    ln -s "$config_file" "$symlink"

    echo "Created symbolic link in sites-enabled: $symlink"

    # reload, restart NGINX
    systemctl reload nginx
    systemctl restart nginx

    # handle errors if NGINX fails to reload or restart
    if [[ $? -ne 0 ]]; then
        echo "Error: failed to reload or restart NGINX."
        exit 1
    fi
}

# run Certbot to obtain SSL certs
run_certbot() {
    domain="$1"
    port="$2"

    # Create a PM2 process to serve the static project on the specified port
    pm2 start "npx serve -s /var/www/$domain/public_html -l $port" --name "$domain"
    pm2 save
    echo "Started PM2 process for $domain on port $port"

    certbot certonly --nginx -d "$domain" -d "www.$domain"

    echo "Obtained SSL certificates for domain: $domain"

    if [[ $? -ne 0 ]]; then
        echo "Error: failed to obtain SSL certificates."
        exit 1
    fi
}

# print usage
print_usage() {
    echo "Usage: $0 -d|--domain <domain_name> [-p|--port <port>] [--no-ssl] [-h|--help]"
}

# main script
# parse command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--domain)
            domain_name="$2"
            shift 2
            ;;
        -p|--port)
            port="$2"
            shift 2
            ;;
        --ssl)
            ssl=true
            shift
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            echo "Invalid option: $1" >&2
            print_usage
            exit 1
            ;;
    esac
done

# set default values if not provided
if [[ -z "$domain_name" ]]; then
    echo "Error: you must provide a domain name as a parameter using the -d or --domain option."
    print_usage
    exit 1
fi

if [[ -z "$port" ]]; then
    port=3001
fi

echo "Domain: $domain_name"
echo "Port: $port"

# call the functions
create_directory "$domain_name"
create_nginx_config "$domain_name" "$port"
create_nginx_symlink "$domain_name"

# Run certbot if --ssl flag is passed
if [[ "$ssl" == true ]]; then
    echo "SSL: enabled"
    run_certbot "$domain_name"
else
    echo "SSL: none"
fi

echo "Setup complete for domain: $domain_name"
