#!/bin/bash

# executing script directory
script_dir="$PWD"

# create the directory structure
create_directory() {
    domain="$1"

    # script directory
    static_dir="$(dirname "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")/assets/static"

    # Create directory if it doesn't exist
    mkdir -p "/var/www/$domain/public_html"

    # Copy HTML files to site directories
    cp -R "$static_dir"/* "/var/www/$domain/public_html/"

    # Specify output file
    output_file="/var/www/$domain/public_html/index.html"

    # Create a temporary script file with variable updates
    temp_script="/var/www/$domain/public_html/temp_script.sh"
    echo "#!/bin/bash" > "$temp_script"
    echo "sed -i 's/{{DOMAIN_NAME}}/$domain/g' $output_file" >> "$temp_script"
    chmod +x "$temp_script"

    # Execute the temporary script within the directory
    (cd "/var/www/$domain/public_html" && ./temp_script.sh)

    # Delete the temporary script file
    rm "$temp_script"
}

# create NGINX config file
create_nginx_config() {
    domain=$1
    server_dir="$(dirname "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")/assets/server"
    template_file="$server_dir/template.conf"
    config_file="/etc/nginx/sites-available/$domain.conf"

    # replace variables in the template file
    cp "$template_file" "$config_file"
    sed -i "s/{{DOMAIN_NAME}}/$domain/g" "$config_file"

    echo "Created NGINX configuration file: $config_file"
}

# Function to create a symbolic link in sites-enabled
create_nginx_symlink() {
    domain=$1
    config_file="/etc/nginx/sites-available/$domain.conf"
    symlink="/etc/nginx/sites-enabled/$domain.conf"

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

# obtain SSL certs with Certbot
run_certbot() {
    domain="$1"

    certbot --nginx -d "$domain" -d "www.$domain" --redirect --non-interactive

    echo "Obtained SSL certificates for domain: $domain"

    if [[ $? -ne 0 ]]; then
        echo "Error: failed to obtain SSL certificates."
        exit 1
    fi
}

# print usage
print_usage() {
    echo "Usage: $0 -d|--domain <domain_name> [--no-ssl] [-h|--help]"
}

# parse command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--domain)
            domain_name="$2"
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

echo "Domain: $domain_name"

# call the functions
create_directory "$domain_name"
create_nginx_config "$domain_name"
create_nginx_symlink "$domain_name"

# Run certbot if --ssl flag is passed
if [[ "$ssl" == true ]]; then
    echo "SSL: enabled"
    run_certbot "$domain_name"
else
    echo "SSL: none"
fi

echo "Setup complete for domain: $domain_name"
