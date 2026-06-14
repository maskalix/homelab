#!/bin/bash

# Ensure lm-sensors is installed
if ! command -v sensors &> /dev/null
then
    echo "lm-sensors is not installed. Please install it using 'sudo apt install lm-sensors'."
    exit 1
fi

# Read and display all temperatures
echo "Listing all device temperatures:"
echo "---------------------------------"
sensors | grep -E 'Adapter|temp[0-9]+|Core|Tdie|Tctl|Package id'

# Another approach using sensors output parsing
# Uncomment below if needed
# sensors_output=$(sensors)
# echo "$sensors_output" | while IFS= read -r line
# do
#     if [[ $line =~ ^Adapter ]] || [[ $line =~ ^temp[0-9]+ ]] || [[ $line =~ ^Core ]] || [[ $line =~ ^Tdie ]] || [[ $line =~ ^Tctl ]] || [[ $line =~ ^Package\ id ]]
#     then
#         echo "$line"
#     fi
# done

echo "---------------------------------"
