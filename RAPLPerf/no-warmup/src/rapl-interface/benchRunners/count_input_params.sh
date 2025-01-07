#!/bin/bash
count_params(){
    input=$1
    # Remove the brackets and spaces
    array_string=$(echo "$input" | tr -d '[] ')
    
    # Count the number of elements in the comma-separated values
    echo "$array_string" | awk -F',' '{print NF}'
}