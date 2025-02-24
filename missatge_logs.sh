#!/bin/bash

# 
# Using logger, send a message that register a personal sentence using a specific level: INFO, WARNING, ERROR
# Testing if the message had success or not 
# 




if [ $# != 2 ]; then                                                        # Filter only 2 input Param
    echo "Wrong number of param." 
    echo "Should be 2: $0 <level> <Message>"
    echo "levels: INFO, WARNING, ERROR"
    exit 1
fi

level="$1"                                                                  # Save level param
message="$2"                                                                # Save Mesage param

case "$level" in                                                            # Check the level param is correct
    INFO|WARNING|ERROR)                                                     # Compare with our content
        # Valid Level
        ;;
    *)                                                                      # If is not exacly with our content exit with error 2
        echo "ERROR: Level NOT Valid. Use INFO, WARNING or ERROR."
        exit 2
        ;;
esac

sudo logger -p "user.$level" "$message"                                     # Create the log with the param

sudo journalctl | grep "user.$level '$message'" | cut -d ';' -f 4                          # Get the message sended before
sudo journalctl | grep ": $message"

if [ $? == 0 ]; then                                                        # Check if the message has been sended correctly
    echo "SUCCESS: The Message has been registered CORRECTLY in the log"
else
    echo "ERROR: The Message has NOT been resgistered in the log"           # The message had an error
    exit 3                                                                  # These shoud NOT be possible to happen
fi