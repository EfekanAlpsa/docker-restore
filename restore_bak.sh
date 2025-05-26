#!/bin/bash

# -----------------------------
# Restore .BAK File to SQL Server Docker Container
# Author: Efekan Alipasha
# -----------------------------

# ✅ Banner
print_banner() {
    echo -e "\033[1;35m"  # Purple and Bold text
    echo "___  ___  ___  ___  ___  ___  ___  ___  ___  ___  ___  ___  ___  ___  ___  ___  ___  ___"  

    echo -e "\033[1;36m" # Cyan and Bold text
cat << "EOF"
      ___           ___         ___           ___           ___           ___     
     /  /\         /  /\       /  /\         /__/|         /  /\         /__/\    
    /  /:/_       /  /:/_     /  /:/_       |  |:|        /  /::\        \  \:\   
   /  /:/ /\     /  /:/ /\   /  /:/ /\      |  |:|       /  /:/\:\        \  \:\  
  /  /:/ /:/_   /  /:/ /:/  /  /:/ /:/_   __|  |:|      /  /:/~/::\   _____\__\:\ 
 /__/:/ /:/ /\ /__/:/ /:/  /__/:/ /:/ /\ /__/\_|:|____ /__/:/ /:/\:\ /__/::::::::\
 \  \:\/:/ /:/ \  \:\/:/   \  \:\/:/ /:/ \  \:\/:::::/ \  \:\/:/__\/ \  \:\~~\~~\/
  \  \::/ /:/   \  \::/     \  \::/ /:/   \  \::/~~~~   \  \::/       \  \:\  ~~~ 
   \  \:\/:/     \  \:\      \  \:\/:/     \  \:\        \  \:\        \  \:\     
    \  \::/       \  \:\      \  \::/       \  \:\        \  \:\        \  \:\    
     \__\/         \__\/       \__\/         \__\/         \__\/         \__\/    
EOF

    echo -e "\033[1;35m"  # Purple and Bold text
    echo "___  ___  ___  ___  ___  ___  ___  ___  ___  ___  ___  ___  ___  ___  ___  ___  ___  ___"  

    echo -e "\033[0m" #Reset text color
}
slow_echo() {
    msg=$1
    for ((i=0; i<${#msg}; i++)); do
        printf "${msg:$i:1}"
        sleep 0.03
    done
    echo ""
}

# ✅ Is necessary tools installed?
check_dependencies() {
    echo ""
    slow_echo "🚧 Checking Dependencies..."
    echo ""
    sleep 3

    if ! command -v docker &> /dev/null; then
        echo "❌ Docker is not installed. Please install it and try again."
        exit 1
    fi

    if ! command -v sqlcmd &> /dev/null; then
        echo "❌ sqlcmd is not installed. To install:"
        echo "    brew tap microsoft/mssql-release && brew install --no-sandbox msodbcsql mssql-tools"
        exit 1
    fi

    slow_echo "Necessary tools are installed."
    echo ""
    slow_echo "Docker ✅"
    sleep 0.5
    slow_echo "sqlcmd ✅"
    echo "" 
    sleep 1.5
}

# ✅ Inputs Control
parse_arguments() {
    if [ "$#" -ne 3 ]; then
        echo "" 
        echo "❗️Incorrect Usage!"
        echo ""
        echo "USE:"
        slow_echo "  ./restore_bak.sh <BAK_FILE_PATH> <CONTAINER_ID> <SQL_PASSWORD>"
        echo ""
        echo "EXAMPLE:"
        slow_echo "  ./restore_bak.sh ~/Desktop/EDATA1.BAK 6e54c1234abc 'CodeWithEfekan'"  
        exit 1
    fi

    BAK_FILE="$1"
    CONTAINER_ID="$2"
    SA_PASSWORD="$3"

    # Check if file exists
    if [ ! -f "$BAK_FILE" ]; then
        echo "❌ BAK file not found: $BAK_FILE"
        exit 1
    fi

    slow_echo "📦 BAK File Path: $BAK_FILE"
    echo "🐳 Docker Container ID: $CONTAINER_ID"
    MASKED_PASSWORD=$(printf '%*s' ${#SA_PASSWORD} '' | tr ' ' '*')
    echo "🔐 Password: $MASKED_PASSWORD"
    echo ""
    sleep 1.5
}

copy_bak_to_container() {
    slow_echo "📁 Creating folder in Docker Container (Skipped if exists)..."
    docker exec -i "$CONTAINER_ID" mkdir -p /var/opt/mssql/backup

    slow_echo "📤 Copying .BAK file to Docker Container "
    docker cp "$BAK_FILE" "$CONTAINER_ID":/var/opt/mssql/backup/

    if [ $? -ne 0 ]; then
        echo "❌ BAK file could not be copied. Please check the container ID and file path."
        exit 1
    fi

    sleep 1.5
    echo "✅ The file has been copied successfully."
    echo ""
}

restore_database() {
    slow_echo "🧠 Reading logical names from .BAK file..." 
    sleep 1.5
    echo -e "\033[1;35m"  # Purple and Bold text
    echo "___  ___  ___  ___  ___  ___  ___  ___  ___  ___  ___  ___  ___  ___  ___  ___  ___  ___"  
    echo -e "\033[0m" #Reset text color

    # Command to run in Docker 
    RESTORE_FILELIST_CMD="
RESTORE FILELISTONLY 
FROM DISK = '/var/opt/mssql/backup/$(basename "$BAK_FILE")';
GO
"

    # Writing the command to a temporary SQL file
    echo "$RESTORE_FILELIST_CMD" > temp_restore.sql

    # Get sqlcmd output (we will parse this output to get logical names)
    SQLCMD_OUTPUT=$(sqlcmd -S localhost -U sa -P "$SA_PASSWORD" -i temp_restore.sql 2>/dev/null)

    if [[ $? -ne 0 || -z "$SQLCMD_OUTPUT" ]]; then
        echo "❌ Could not get logical names with SQLCMD. There may be a password or connection error."
        rm -f temp_restore.sql
        exit 1
    fi

    # Parse logical names (1st column, skip headers)
    LOGICAL_NAMES=($(echo "$SQLCMD_OUTPUT" | awk 'NR>2 {print $1}' | head -n 2))
    DATA_LOGICAL_NAME="${LOGICAL_NAMES[0]}"
    LOG_LOGICAL_NAME="${LOGICAL_NAMES[1]}"

    if [ -z "$DATA_LOGICAL_NAME" ] || [ -z "$LOG_LOGICAL_NAME" ]; then
        echo "❌ Logical names could not be parsed. .BAK file may be corrupt."
        rm -f temp_restore.sql
        exit 1
    fi

    # Extract database name from the BAK file name
    DB_NAME=$(basename "$BAK_FILE" .BAK)

    echo "🛠 DATABASE NAME: $DB_NAME"
    echo "📄 DATA LogicalName: $DATA_LOGICAL_NAME"
    echo "📄 LOG LogicalName:  $LOG_LOGICAL_NAME"

    # Create the SQL command to restore the database
    RESTORE_SQL="
ALTER DATABASE [$DB_NAME] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
RESTORE DATABASE [$DB_NAME]
FROM DISK = '/var/opt/mssql/backup/$(basename "$BAK_FILE")'
WITH MOVE '$DATA_LOGICAL_NAME' TO '/var/opt/mssql/data/$DB_NAME.mdf',
MOVE '$LOG_LOGICAL_NAME' TO '/var/opt/mssql/data/${DB_NAME}_log.ldf',
REPLACE;
ALTER DATABASE [$DB_NAME] SET MULTI_USER;
GO
"


    echo "$RESTORE_SQL" > temp_restore.sql
    echo ""
    slow_echo "⏳ Starting RESTORE..."
    sleep 1.5
    sqlcmd -S localhost -U sa -P "$SA_PASSWORD" -i temp_restore.sql

    if [ $? -eq 0 ]; then
        echo -e "\n✅ \033[1;32mDatabase Restored Successfully: $DB_NAME\033[0m 🎉"
    else
        echo -e "\n❌ \033[1;31mRESTORE failed. Please check sqlcmd output!\033[0m"
    fi

    # Clean up temporary files
    rm -f temp_restore.sql
}


# ✅ Main Function
main() {
    print_banner
    check_dependencies
    parse_arguments "$@"
    slow_echo "🔄 Restoring BAK file to SQL Server Docker container..."
    echo ""
    sleep 1.5
    copy_bak_to_container
    echo "🔄 Executing SQLCMD to restore the database..."
    restore_database
    echo "🔚 Restore process completed."
}

main "$@"
