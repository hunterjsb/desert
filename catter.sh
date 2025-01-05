#!/bin/bash

# Generate a tree of relevant files and directories, excluding specified paths
tree_output=$(tree -I 'godot-jolt|.git' --prune)

# Write the tree output at the top of combined.txt
echo "$tree_output" > combined.txt
echo "" >> combined.txt

# Append the combined content of relevant files
find . \
  \( -path "./godot-jolt" -o -path "./.git" \) -prune -o \
  \( -name "*.gd" -o -name "*.tscn" -o -name "*.gdshader" \) -print | while read -r file; do
  echo "# $file" >> combined.txt
  cat "$file" >> combined.txt
  echo "" >> combined.txt
done
