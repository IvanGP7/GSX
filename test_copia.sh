#!/bin/bash

# Test script for copia_seguretat.sh
# This script creates test files and directories, runs the backup script, and verifies its behavior.

# Define test directories and files
test_dir="test_backup"
backup_dir="Backups"
backup_file="$backup_dir/backup_$(date +"%Y-%m-%d_%Hh-%Mm-%Ss").tgz"

# Function to create the test environment
create_enviroment() {
    echo "Creating test environment..."
    mkdir -p "$test_dir/subdir1" "$test_dir/subdir2"
    touch "$test_dir/archivo1.txt"
    touch "$test_dir/subdir1/archivo2.txt"
    touch "$test_dir/subdir2/archivo3.txt"
    touch "$test_dir/.archivo_oculto"
    touch "$test_dir/archivo_antiguo.txt"

    # Simulate an old file
    touch -d "2020-01-01 12:00:00" "$test_dir/archivo_antiguo.txt"

    # Create a read-only file
    touch "$test_dir/archivo_solo_lectura.txt"
    chmod 444 "$test_dir/archivo_solo_lectura.txt"

    # Create an executable script
    echo "echo 'Test script'" > "$test_dir/script.sh"
    chmod +x "$test_dir/script.sh"

    # Create a symbolic link
    ln -s "$test_dir/archivo1.txt" "$test_dir/enlace_simbolico"
}

# Clean up before running tests
echo "Cleaning up previous test data..."
rm -rf "$test_dir" "$backup_dir"
echo ""

# Run negative test cases
echo "**************************************"
echo "*    TEST_Backup 0: Invalid Cases    *"
echo "**************************************"

# Case 1: Backup a non-existing directory
echo "** Testing non-existing directory... **"
./copia_seguretat.sh "Example_not_existent"
echo ""

# Case 2: Run without arguments
echo "** Testing script without arguments... **"
./copia_seguretat.sh
echo ""

# Create test environment
echo "******************************************"
echo "*    TEST_Backup 1: Enviroment_Buckup    *"
echo "******************************************"

create_enviroment

tree "$test_dir"
echo ""

# Run backup script
echo "** Running backup script... **"
./copia_seguretat.sh "$test_dir"
echo ""

# Check if backup file exists
echo "Verifying backup..."
if [ -f "$backup_file" ]; then
    echo "Backup created successfully: $backup_file"
    echo ""
else
    echo "ERROR: Backup file not found!"
    rm -rf "$test_dir"
    exit 1
fi

# Compare attributes after extracting the backup using comprova_copia.sh
echo "** Verifying backup integrity with comprova_copia.sh... **"
echo ""
./comprovar_copia.sh "$backup_file" "$test_dir"
echo ""

# Clean up test environment
echo "Cleaning up test environment..."
rm -rf "$test_dir"
echo ""

echo "All tests completed."