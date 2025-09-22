#!/bin/bash

# Auto-setup .ruby-version files for Ruby projects
# Based on Gemfile ruby version requirements

set -euo pipefail

echo "🔍 Finding Ruby projects and setting .ruby-version files..."

# Find all directories with Gemfiles
while IFS= read -r -d '' gemfile; do
  project_dir=$(dirname "$gemfile")

  # Skip vim plugins and other non-project directories
  if [[ "$project_dir" == *"/plugged/"* ]] || [[ "$project_dir" == *"/.git/"* ]]; then
    continue
  fi

  echo "📁 Checking: $project_dir"

  # Extract ruby version requirement from Gemfile
  ruby_requirement=$(grep -E '^ruby\s+["\']~?\s*[0-9]+\.' "$gemfile" 2>/dev/null || echo "")

  if [[ -n "$ruby_requirement" ]]; then
    # Parse version (e.g., ruby "~> 3.2.6" -> 3.2.6)
    version=$(echo "$ruby_requirement" | sed -E 's/.*["\']~?\s*([0-9]+\.[0-9]+\.?[0-9]*).*/\1/')

    # Check if rbenv has this exact version or find closest match
    available_versions=$(rbenv versions --bare)
    exact_match=$(echo "$available_versions" | grep "^${version}$" || echo "")

    if [[ -n "$exact_match" ]]; then
      target_version="$version"
    else
      # Find closest patch version (e.g., 3.2.6 if asking for 3.2)
      major_minor=$(echo "$version" | cut -d. -f1-2)
      target_version=$(echo "$available_versions" | grep "^${major_minor}\." | tail -1 || echo "")
    fi

    if [[ -n "$target_version" ]]; then
      ruby_version_file="$project_dir/.ruby-version"
      current_version=""

      if [[ -f "$ruby_version_file" ]]; then
        current_version=$(cat "$ruby_version_file")
      fi

      if [[ "$current_version" != "$target_version" ]]; then
        echo "  ✅ Setting Ruby $target_version (was: ${current_version:-"none"})"
        echo "$target_version" > "$ruby_version_file"
      else
        echo "  ⏭️  Already using Ruby $target_version"
      fi
    else
      echo "  ⚠️  No matching Ruby version found for requirement: $ruby_requirement"
      echo "     Available versions: $(echo $available_versions | tr '\n' ' ')"
    fi
  else
    echo "  ℹ️  No ruby version specified in Gemfile"
  fi

done < <(find "$HOME/codebase" -name "Gemfile" -not -path "*/plugged/*" -not -path "*/.git/*" -print0)

echo "✨ Done! Ruby versions have been set for all projects."
echo ""
echo "💡 Tip: Your shell should automatically switch Ruby versions when you cd into these directories."
echo "   If not working, ensure rbenv is properly initialized in your shell profile."