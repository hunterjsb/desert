find . \
  \( -path "./godot-jolt" -o -path "./.git" \) -prune -o \
  \( -name "*.gd" -o -name "*.tscn" -o -name "*.gdshader" \) -print | while read -r file; do
  echo "# $file" >> combined.txt
  cat "$file" >> combined.txt
  echo "" >> combined.txt
done
