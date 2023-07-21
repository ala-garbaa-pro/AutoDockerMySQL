#!/bin/bash
# AutoDockerMySQL
# Timestamp: 9:25 PM, July 21, 2023 (GMT+1)
# A Bash Shell Script for Docker automation, handling MySQL DB operations: create, export, import, delete, print URI, check connection.
# Created By Ala GARBAA - Visit https://www.AlaGARBAA.com


# Load environment variables from .denv file

if [ -f "./db_dev_mysql/.denv" ]; then
    source "./db_dev_mysql/.denv"
else
    echo "Error: .denv file not found"
    exit 1
fi

# Check if all required environment variables are defined
required_env_vars=("CONTAINER_NAME" "DB_VOLUME_NAME" "IP_ADDRESS_DB" "PORT_NUMBER_DB" "MYSQL_DATABASE" "MYSQL_USER" "MYSQL_ROOT_PASSWORD" "MYSQL_PASSWORD" "BACKUP_DIR")

missing_env_vars=()

for var_name in "${required_env_vars[@]}"; do
    if [ -z "${!var_name}" ]; then
        missing_env_vars+=("$var_name")
    fi
done

if [ "${#missing_env_vars[@]}" -ne 0 ]; then
    echo -e "Error: the following environment variables are not defined: \e[31m${missing_env_vars[*]}\e[0m"
    exit 1
fi

DATABASE_URL="mysql://root:$MYSQL_ROOT_PASSWORD@$IP_ADDRESS_DB:$PORT_NUMBER_DB/$MYSQL_DATABASE"


# Create the database
function create_database() {
    # Check if the Docker daemon is running
    if ! docker info > /dev/null 2>&1; then
        echo "Error: Docker daemon is not running"
        exit 1
        return
    fi
    
    docker rm -f "$CONTAINER_NAME"
    docker volume rm --force "$DB_VOLUME_NAME"
    docker volume create "$DB_VOLUME_NAME"
    
    docker run --name "$CONTAINER_NAME" \
    -v $DB_VOLUME_NAME:/var/lib/mysql \
    -p $IP_ADDRESS_DB:$PORT_NUMBER_DB:3306 \
    -e MYSQL_DATABASE="$MYSQL_DATABASE" \
    -e MYSQL_USER="$MYSQL_USER" \
    -e MYSQL_ROOT_PASSWORD="$MYSQL_ROOT_PASSWORD" \
    -e MYSQL_PASSWORD="$MYSQL_PASSWORD" \
    --restart always \
    -d mysql
    
    # Print to the console the container ID using $CONTAINER_NAME variable
    echo "Database container '$CONTAINER_NAME', created: $(docker ps -aqf name=$CONTAINER_NAME)"
}




# Export the database
function export_database() {
    # Check if the docker daemon is running
    if ! docker info > /dev/null 2>&1; then
        echo "Error: Docker daemon is not running"
        exit 1
    fi
    
    # Verify the correctness of the MySQL root password
    if [ -z "$MYSQL_ROOT_PASSWORD" ]; then
        echo "Error: MySQL root password is not set"
        exit 1
    fi
    
    # Check if the MySQL container is running
    if ! docker ps --format '{{.Names}}' | grep -q "$CONTAINER_NAME"; then
        echo "Error: MySQL container '$CONTAINER_NAME' is not running"
        exit 1
    fi
    
    # Attempt to connect to MySQL server using the root password
    if ! docker exec -it "$CONTAINER_NAME" mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "SELECT 1" > /dev/null 2>&1; then
        echo "Error: Failed to connect to MySQL server using the root password"
        exit 1
    fi
    
    CURRENT_DATE=$(date +%Y-%m-%d_%H-%M-%S)
    FILE_NAME="backup_${CURRENT_DATE}.sql"
    
    # Export the database using mysqldump with --defaults-file option
    docker exec -t "$CONTAINER_NAME" bash -c "echo '[mysqldump]' > /tmp/my.cnf && echo 'password=\"$MYSQL_ROOT_PASSWORD\"' >> /tmp/my.cnf && mysqldump --defaults-file=/tmp/my.cnf -u root $MYSQL_DATABASE" > "$BACKUP_DIR/$FILE_NAME" 2>/dev/null
    
    # Check the exit status of the mysqldump command
    if [ $? -eq 0 ]; then
        echo "Database exported to '$BACKUP_DIR/$FILE_NAME'"
    else
        echo "Error: Failed to export the database"
        exit 1
    fi
}




# Import the database
function import_database() {
    # Check if the docker daemon is running
    if ! docker info > /dev/null 2>&1; then
        echo "Error: docker daemon is not running"
        exit 1
        return
    fi
    
    files=("$BACKUP_DIR"/*) # Get all files in the backup directory
    file_count=${#files[@]} # Count the number of files
    
    if [ $file_count -eq 0 ]; then
        echo "Error: No backup files found in '$BACKUP_DIR'"
        exit 1
        return
    fi
    
    selected_file=0 # Initialize selected file index
    highlighted_file=0 # Initialize highlighted file index
    
    # Function to display the menu with highlighted file
    display_menu() {
        for ((i=0; i<$file_count; i++)); do
            if [ $i -eq $highlighted_file ]; then
                echo -e "\e[1;32m$i) ${files[$i]}\e[0m" # Highlighted file in green color
            else
                echo "$i) ${files[$i]}"
            fi
        done
    }
    
    printf "\033c"
    clear
    display_menu
    
    while true; do
        read -rsn1 input
        if [[ "$input" == $'\x1b' ]]; then
            read -rsn3 -t 0.1 input # Read additional escape sequence characters with a short timeout
            
            if [[ "$input" == "[A" ]]; then # Up arrow key pressed
                if [ $highlighted_file -gt 0 ]; then
                    highlighted_file=$((highlighted_file-1))
                fi
                elif [[ "$input" == "[B" ]]; then # Down arrow key pressed
                if [ $highlighted_file -lt $(($file_count-1)) ]; then
                    highlighted_file=$((highlighted_file+1))
                fi
                elif [[ "$input" == "[5~" ]]; then # Page up key pressed
                if [ $highlighted_file -ge 5 ]; then
                    highlighted_file=$((highlighted_file-5))
                else
                    highlighted_file=0
                fi
                elif [[ "$input" == "[6~" ]]; then # Page down key pressed
                if [ $(($highlighted_file+5)) -lt $file_count ]; then
                    highlighted_file=$((highlighted_file+5))
                else
                    highlighted_file=$(($file_count-1))
                fi
                elif [[ "$input" == "[H" ]]; then # Home key pressed
                highlighted_file=0
                elif [[ "$input" == "[F" ]]; then # End key pressed
                highlighted_file=$(($file_count-1))
            fi
            elif [ "$input" == "" ]; then # Enter key pressed
            selected_file=$highlighted_file
            break
        fi
        
        printf "\033c"
        clear
        display_menu
    done
    
    selected_file_path="${files[$selected_file]}"
    docker exec -i "$CONTAINER_NAME" mysql -u "root" -p"$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE" < "$selected_file_path"
    echo "Database imported from '$selected_file_path'"
}




# Print database URI
function print_database_uri() {
    echo "$DATABASE_URL"
}



# Delete the database
function delete_database() {
    
    # Check if the docker deamon is running
    if ! docker info > /dev/null 2>&1; then
        echo "Error: docker deamon is not running"
        exit 1
        return
    fi
    
    ID=$(docker ps -aqf name=$CONTAINER_NAME)
    if [ -z "$ID" ]; then
        echo "Database container '$CONTAINER_NAME' not found"
        return
        exit 1
    fi
    docker stop "$CONTAINER_NAME"
    docker rm "$CONTAINER_NAME"
    docker volume rm --force "$DB_VOLUME_NAME"
    echo "Database container deleted: $ID"
}

# Print database URI
function print_database_uri() {
    echo "$DATABASE_URL"
}

# Check the database connection
function check_database_connection() {
    if ! docker info > /dev/null 2>&1; then
        echo "Error: Docker daemon is not running"
        exit 1
    fi

    if ! docker ps --format '{{.Names}}' | grep -q "$CONTAINER_NAME"; then
        echo "Error: MySQL container '$CONTAINER_NAME' is not running"
        exit 1
    fi

    if ! docker exec -it "$CONTAINER_NAME" mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "SELECT 1" > /dev/null 2>&1; then
        echo "Error: Failed to connect to the MySQL server using the provided credentials"
        exit 1
    fi

    echo "Database connection is successful"
}



case "$1" in
    c | create )
    create_database ;;
    e | export )
    export_database ;;
    i | import )
    import_database "$2" ;;
    d | delete )
    delete_database ;;
    r | recreate )
    delete_database && create_database ;;
    p | print_uri )
    print_database_uri ;;
    ch | check )
    check_database_connection ;;
    *)
        echo "### Created By Ala GARBAA - https://www.AlaGARBAA.com ###"
        echo "---"
        echo "Invalid command: $1"
        echo -e "\n\e[1mUsage:\e[0m"
        echo -e "\e[32m./deploy.sh\e[0m"
        echo -e "\e[36m[ c | create ]\e[0m Create a new database"
        echo -e "\e[36m[ e | export ]\e[0m Export the database"
        echo -e "\e[36m[ i | import PATH ]\e[0m Import the database"
        echo -e "\e[36m[ d | delete ]\e[0m Delete an existing database"
        echo -e "\e[36m[ p | print_uri ]\e[0m Print database URI"
        echo -e "\e[36m[ ch | check ]\e[0m Check the database connection"
    exit 1 ;;
esac
