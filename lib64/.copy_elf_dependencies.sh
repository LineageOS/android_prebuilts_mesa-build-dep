#!/bin/bash

# Script: copy_elf_dependencies.sh
# Description: Finds dynamic library dependencies of ELF executables using ldd,
#              deduplicates the list, and copies them to a specified directory.
# Usage: ./copy_elf_dependencies.sh <destination_directory> <executable1> [executable2 ...]

# --- Configuration ---
# Set -e to exit immediately if a command exits with a non-zero status.
set -e

# --- Argument Parsing ---

# Check if at least two arguments are provided (destination_directory + at least one executable)
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <destination_directory> <executable1> [executable2 ...]"
    echo "Example: $0 /path/to/libs_dir /usr/bin/ls /bin/cat"
    exit 1
fi

# The first argument is the destination directory
DEST_DIR="$1"
shift # Remove the first argument, leaving only executables

# All remaining arguments are the ELF executables
ELF_EXECUTABLES=("$@")

# --- Create Destination Directory ---

echo "Ensuring destination directory exists: ${DEST_DIR}"
mkdir -p "${DEST_DIR}" || { echo "Error: Could not create directory ${DEST_DIR}. Exiting."; exit 1; }

# --- Discover and Deduplicate Dependencies ---

echo "Discovering dependencies for executables: ${ELF_EXECUTABLES[*]}"

# Initialize an empty array to store all found library paths
declare -a ALL_DEPENDENCIES

# Loop through each executable provided
for EXE in "${ELF_EXECUTABLES[@]}"; do
    if [ ! -f "$EXE" ]; then
        echo "Warning: Executable not found: ${EXE}. Skipping."
        continue
    fi

    if [ ! -x "$EXE" ]; then
        echo "Warning: Executable is not executable: ${EXE}. Skipping."
        continue
    fi

    echo "Running ldd on: ${EXE}"
    # Use awk for robust parsing of ldd output, handling both '=>' and direct paths.
    # It also filters out 'linux-vdso.so.1' and 'not found' lines.
    mapfile -t CURRENT_EXE_DEPS < <(ldd "$EXE" 2>/dev/null | awk '
        # Filter out linux-vdso.so.1 and "not found" lines first
        !/linux-vdso.so.1/ && !/not found/ {
            if ($0 ~ /=>/) {
                # For lines like "libfoo.so => /path/to/libfoo.so (0x...)"
                # The path is typically the third field.
                # We use match() and substr() for more precise extraction
                # to handle cases where the path might contain spaces (though rare for libs)
                # or if the field splitting is not exact.
                match($0, /=>[[:space:]]*(.*)[[:space:]]*\(0x/, arr);
                if (arr[1]) {
                    path = arr[1];
                    # Remove any trailing whitespace from the extracted path
                    gsub(/[[:space:]]+$/, "", path);
                    print path;
                }
            } else if ($0 ~ /\.so\.[0-9]+/) {
                # For lines like "    /path/to/lib.so.2 (0x...)"
                # The path is the first significant string on the line after leading whitespace.
                line = $0;
                gsub(/^[[:space:]]+/, "", line); # Remove leading whitespace (spaces and tabs)
                split(line, a, /[[:space:]]+/); # Split by one or more whitespace characters
                path = a[1]; # The first word is the path
                # Remove any trailing whitespace from the extracted path
                gsub(/[[:space:]]+$/, "", path);
                print path;
            }
        }
    ')

    # Debugging: Print dependencies found for the current executable
    echo "  Dependencies captured for ${EXE}:"
    printf "    %s\n" "${CURRENT_EXE_DEPS[@]}"

    # Append the dependencies found for the current executable to the main ALL_DEPENDENCIES array
    ALL_DEPENDENCIES+=("${CURRENT_EXE_DEPS[@]}")
done

# Deduplicate the list of dependencies
echo "Deduplicating dependency list..."
# Use printf "%s\n" to print each array element on a new line, then sort and uniq.
UNIQUE_DEPENDENCIES=$(printf "%s\n" "${ALL_DEPENDENCIES[@]}" | sort -u)

if [ -z "$UNIQUE_DEPENDENCIES" ]; then
    echo "No unique dependencies found to copy."
    exit 0
fi

echo "Found unique dependencies:"
echo "${UNIQUE_DEPENDENCIES}"

# --- Copy Dependencies ---

echo "Copying dependencies to ${DEST_DIR}..."

# Read the unique dependencies line by line
while IFS= read -r LIB_PATH; do
    if [ -f "$LIB_PATH" ]; then
        echo "Copying: ${LIB_PATH}"
        # Use cp -L to copy the actual file that a symbolic link points to
        # Use cp -v for verbose output
        cp -Lv "$LIB_PATH" "${DEST_DIR}/" || { echo "Error: Failed to copy ${LIB_PATH}. Continuing."; }
    else
        echo "Warning: Library not found on disk: ${LIB_PATH}. Skipping."
    fi
done <<< "${UNIQUE_DEPENDENCIES}"

echo "Dependency copying complete."
echo "All required libraries are now in: ${DEST_DIR}"
