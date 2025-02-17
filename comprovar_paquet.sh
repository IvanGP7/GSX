#!/bin/bash

#
# Check and install the programs
# @param: One o Some Package installed or not

#apt-get update
#apt-cache search 'archivo'

# Funtion to read the user choice if he wants to install the package or not.
# @param: Only 1 Package
read_answer(){
    local package="$1"                                                                  # Get the package that sould be wrote by param
    while true; do                                                                      # Loop until User write a valid
        read -p "Do you want to install the next package: $package? (s/n): " answer
        answer="${answer,,}"                                                            # Force the answer to lower case letter
    
        if [[ "$answer" == "s" || "$answer" == "n" ]]; then                             # Check the User choice
            echo "$answer"                                                              # Return the Answer
            break
        else
            echo "Your answer is not valid, try again."                                 # Repit the loop
        fi
    
    done
}

#Filter if the user didn't write some param.
if [ $# == 0 ]; then
    echo "You have to write some package/s to try to install them if they are not in your system."
    exit 1
fi

if [ ! -f "error.log" ]; then
    touch "error.log"
fi

# Loop to see all the param the user wrote
for param in "$@"; do
    dpkg -l | grep -q "ii  $param"                                  # Check if the package is installed
    if [ $? == 0 ]; then                                            # If result is 0 then exist
        echo "**Package already Exist: $param"
    else
        answer=$(read_answer $param)                                # Ask the user if he wants to install the packar he wrote
        if [ "$answer" == "s" ]; then                               # We install the package
            echo "Installing $param ..."
            sudo apt install -y $param >> error.log 2>&1             # Intall the package accepting all the conditions
            if [ $? == 100 ]; then                                  # Check if the package we are tring to install exist and is completed
                echo "**Package does Not Exist: $param"
            else
                echo "**SUCCESSFUL: Package Installed: $param"
            fi
        else                                                         # We do NOT install de package
            echo "**FAILED: Package NOT Installed: $param"
        fi
        echo ""
    fi
done
