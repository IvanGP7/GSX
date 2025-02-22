#!/bin/bash

#!/bin/bash

# Check if the required parameters are provided
if [ $# -ne 2 ]; then
    echo "Error: Incorrect number of parameters."                       # Error message for missing or incorrect parameters
    echo "Usage: $0 <tar_file> <original_directory>"                    # Correct usage hint
    exit 1
fi

backup_file="$1"                                                        # The backup file to be extracted
original_dir="$2"                                                       # The original directory to compare against

# Extract the .tgz backup file into a temporary directory
temp_dir="temp_extracted"
mkdir -p "$temp_dir"  # Create the temporary directory if it doesn't exist
echo "Extracting the backup file: $backup_file"                         # Inform user about the extraction
tar -xzf "$backup_file" -C "$temp_dir"                                  # Extract the tar file to the temp directory

# Compare the attributes of the original and extracted files
echo "Comparing file attributes..."
for file in $(find "$original_dir" -type f); do                         # Loop through all files in the original directory
    rel_path=${file#$original_dir/}                                     # Get the relative path of the file from the original directory
    extracted_file="$temp_dir/$original_dir/$rel_path"                  # Corresponding path of the extracted file

    if [ -e "$extracted_file" ]; then                                   # Check if the file exists in the extracted backup
        echo "Comparing: $file"                                         
        echo "Original: $(stat --format="Permissions: %A, Owner: %U, Group: %G, Last access: %x, Last modification: %y, Status change: %z" "$file")"  # Show original file attributes
        echo "Extracted: $(stat --format="Permissions: %A, Owner: %U, Group: %G, Last access: %x, Last modification: %y, Status change: %z" "$extracted_file")"  # Show extracted file attributes
        echo "------------------------------------"  
    else
        echo "ERROR: Extracted file not found: $extracted_file"         # Error message for missing extracted file
    fi
done

# Clean up the temporary directory after comparison
echo "Cleaning up temporary directory..." 
rm -rf "$temp_dir"                                                      # Remove the temporary directory and its contents
