#!/bin/bash

# Validate .env file for syntax errors

if [ ! -f ".env" ]; then
    echo "Error: .env file not found"
    exit 1
fi

echo "Checking .env file for syntax errors..."

# Check for lines with '=' at the beginning or other issues
line_num=0
errors=0

while IFS= read -r line || [ -n "$line" ]; do
    line_num=$((line_num + 1))
    
    # Skip empty lines and comments
    if [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]]; then
        continue
    fi
    
    # Check for lines starting with =
    if [[ "$line" =~ ^[[:space:]]*= ]]; then
        echo "Error on line $line_num: Line starts with '='"
        echo "  $line"
        errors=$((errors + 1))
    fi
    
    # Check for proper KEY=value format
    if [[ ! "$line" =~ ^[[:space:]]*[A-Za-z_][A-Za-z0-9_]*= ]]; then
        echo "Warning on line $line_num: Possible malformed line"
        echo "  $line"
    fi
    
done < .env

if [ $errors -gt 0 ]; then
    echo ""
    echo "Found $errors errors in .env file"
    echo "The error './.env: line 6: =: command not found' suggests line 6 has an issue"
    echo ""
    echo "Common causes:"
    echo "1. Multi-line value not properly quoted"
    echo "2. Line break in the middle of a value"
    echo "3. Missing quote at the end of a multi-line value"
else
    echo "No obvious syntax errors found"
fi

# Show line 6 specifically
echo ""
echo "Line 6 of .env:"
sed -n '6p' .env