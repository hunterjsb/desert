for file in *.gd *.tscn; do
  echo "# $file" >> combined.txt
  cat "$file" >> combined.txt
  echo "" >> combined.txt
done
