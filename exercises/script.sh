# --- Configuration ---
# The directory to start searching from ('.' means the current directory)
START_DIR="."

# File renaming
OLD_FILE_NAME="solution.md"
NEW_FILE_NAME="activity.md"

# Directory renaming
OLD_DIR_NAME="solution"
NEW_DIR_NAME="exercise"
# --- End Configuration ---

echo "Starting renaming process from: $(pwd)/$START_DIR"
echo "---------------------------------------------------"

# --- Part 1: Rename Files (solution.md to activity.md) ---
echo "1. Renaming files from '$OLD_FILE_NAME' to '$NEW_FILE_NAME'..."

# Find all files named OLD_FILE_NAME in START_DIR and its subdirectories
# -type f: Only find files
# -name "$OLD_FILE_NAME": Match the specified filename
# -print0: Print results separated by a null character (safer for special characters/spaces in names)
# while IFS= read -r -d $'\0' filepath: Loop through null-separated paths safely
find "$START_DIR" -type f -name "$OLD_FILE_NAME" -print0 | while IFS= read -r -d $'\0' filepath; do
    # Get the directory part of the found file's path
    dir=$(dirname "$filepath")
    # Construct the new full path for the renamed file
    new_filepath="${dir}/${NEW_FILE_NAME}"

    echo "  Renaming file: \"$filepath\" -> \"$new_filepath\""
    mv "$filepath" "$new_filepath"
done
echo "   File renaming complete."
echo "---------------------------------------------------"

# --- Part 2: Rename Directories (solution to exercise) ---
echo "2. Renaming directories from '$OLD_DIR_NAME' to '$NEW_DIR_NAME'..."

# Find all directories named OLD_DIR_NAME in START_DIR and its subdirectories
# -type d: Only find directories
# -name "$OLD_DIR_NAME": Match the specified directory name
# -depth: Process contents of a directory before the directory itself. This is CRUCIAL
#         because we need to rename subdirectories *before* their parent directories
#         if a parent also matches the OLD_DIR_NAME pattern.
# -print0: Safe handling of special characters/spaces in names
find "$START_DIR" -type d -name "$OLD_DIR_NAME" -depth -print0 | while IFS= read -r -d $'\0' dirpath; do
    # Get the parent directory of the found 'solution' directory
    parent_dir=$(dirname "$dirpath")
    # Construct the new full path for the renamed directory
    new_dirpath="${parent_dir}/${NEW_DIR_NAME}"

    echo "  Renaming directory: \"$dirpath\" -> \"$new_dirpath\""
    mv "$dirpath" "$new_dirpath"
done
echo "   Directory renaming complete."
echo "---------------------------------------------------"
echo "All renaming operations finished."
