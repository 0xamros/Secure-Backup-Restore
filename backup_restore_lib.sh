#!/bin/bash

validate_backup_params(){

     # Check correct number of arguments
    if [ $# -ne 4 ]; then
        echo "usage: $0 <source_backup_dir> <backup_destination_dir> <ecryption_key> <days>"
        exit 1
    fi
    

    # check directories existance
    if [ ! -d "$1" ]; then
        echo "source backup not exist"
        exit 1
    fi

    if [ ! -d "$2" ]; then
        echo "destination backup directory not exist"
        exit 1
    fi

    # Check if encryption key is provided
    if [ -z "$3" ]; then
        echo "Encryption key must be provided"
        exit 1
    fi    
    # Validate days parameter
    regex='^[0-9]+$'
    if ! [[ $4 =~ $regex ]]; then
        echo "Days parameter must be a positive integer"
        exit 1
    fi
}

# Function to validate restore parameters
validate_restore_params() {
    if [ $# -ne 3 ]; then
        echo "usage: $0 <backup_dir> <restore_dir> <decryption_key>"
        exit 1
    fi


    # Check if backup and restore directories exist
    if [ ! -d "$1" ]; then
        echo "backup directory does not exist"
        exit 1
    fi

    if [ ! -d "$2" ]; then
        echo "restore directory does not exist"
        exit 1
    fi

    # Check if decryption key is provided
    if [ -z "$3" ]; then
        echo "decryption key must be provided"
        exit 1
    fi
}



backup() 
{
    local src_dir=$1
    local backup_dir=$2
    local encrypt_key=$3
    local days=$4

    if [[ "$src_dir" == */ ]]; then
        # Remove the trailing slash
        src_dir="${src_dir%/}"
    fi

    if [[ "$backup_dir" == */ ]]; then
        # Remove the trailing slash
        backup_dir="${backup_dir%/}"
    fi

    # Get current date and format it with underscores instead of spaces/colons
    local date=$(date +%Y_%m_%d_%H_%M_%S| sed 's/[[:space:]:]/_/g')
    
    # Construct full path for backup date directory
    local backup_date_dir="$backup_dir/$date"

    # Create the backup date directory
    mkdir -p "$backup_date_dir"


    ####################################
    ###   Dealing with directories   ###
    ####################################

    for d in "$src_dir"; do

            # check directories in specific modification time and compress to one file
            find "$d" -mindepth 1 -maxdepth 1 -type d  -mtime -$days -print | tar -czf "$backup_date_dir/${d##/}_$date.tar.gz" -T -

            # encrypt compressed file
            gpg --batch --yes --passphrase "$encrypt_key" -o "$backup_date_dir/${d##*/}_$date.tar.gz.gpg" -c "$backup_date_dir/${d##*/}_$date.tar.gz"


            # delete original compressed file
            rm "$backup_date_dir/${d##*/}_$date.tar.gz"

    done
    echo -e "\ndirectories successfully backed up\n"


    ##############################
    ###   Dealing with files   ###
    ##############################

    local loose_files_tar="$backup_date_dir/files_$date.tar"
    
    # getting first_file
    local first_file=$(find "$src_dir" -maxdepth 1 -type f -print -quit)

    # Create tar archive with first file
    tar -cf "$loose_files_tar" -C . "$first_file"

    for file in "$src_dir"/*; do
        # Ignore directories, only want files
        find "$src_dir" -maxdepth 1 -type f -print |tar -uf "$loose_files_tar" -T -
        
    done

    # Gzip compress the tar file
    gzip "$loose_files_tar"

    # Delete original tar file after compressing
    if [ -f $loose_files_tar ]; then
        rm "$loose_files_tar"
    fi

    # Encrypt the .tar.gz file
    gpg --batch --yes --passphrase "$encrypt_key" -o "$backup_date_dir/files_$date.tar.gz.gpg" -c "$backup_date_dir/files_$date.tar.gz"
    
    # Delete unencrypted .tar.gz
    rm "$backup_date_dir/files_$date.tar.gz"

    echo -e "files successfully backed up \n\n if you need to backup to remote server \n  please write it\n\n  or press (q) to Exit : "
    
    read remote_host

    # Check if user entered 'q' to Exit
    if [ "$remote_host" == "q" ]; then
        echo -e "\n\nok thank you"
        exit 0
    fi

    # Ping remote host to validate
    ping -c 1 "$remote_host" >/dev/null 2>&1
    
    # Check ping return code
    if [ $? -eq 0 ]; then
        echo "$remote_host is reachable."

    else
        echo "$remote_host is not reachable."
        exit 1
    fi

    echo -e "please write remote dir: "
    
    read remote_dir

    # Copy backup to remote host    
    scp -r "$backup_date_dir" "$remote_host:$remote_dir"
    if [ $? -eq 0 ]; then
        echo -e "\n\nall files and folders successfully backed up remotely :)"

    else
        echo "please try another dir you have permission."
    fi

}



restore() 
{
    local backup_dir=$1
    local restore_dir=$2
    local decrypt_key=$3

    local temp_dir="$restore_dir/temp"

    mkdir -p "$temp_dir"

    #Loop through encrypted backup files
    for f in $backup_dir/*.gpg; do
    # Decrypt each file into temp dir
        filename=$(basename "$f" .gpg)
    gpg --batch --yes --passphrase "$decrypt_key" -o "$temp_dir/$filename" -d "$f"
    done

    #Loop through temp dir
    for f in $temp_dir/*gz; do
    # Extract tar.gz files into restore dir
    tar -xzf "$f" -C "$restore_dir"
    done

    echo -e "\n\nall files and folders successfully restored :)\n"

    rm -r "$temp_dir"
}