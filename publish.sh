#! /bin/bash
# Based on @zporter's publish script.
# See https://zachporter.dev/posts/publishing-hugo-with-github-actions/

# abort on nonzero exitstatus
set -o errexit
# abort on unbound variable
set -o nounset

# Output directory
output_dir=gh-pages

# Usage: update_changed_on_message FILE
#    Function that updates the message at the bottom of a page with the time
#    stamp of the last change.
update_changed_on_message() {
  local file="${1}"
  local prompt="Laatste wijziging: "
  local timestamp
  timestamp=$(LC_TIME=nl_BE date)

  sed -i "s/^${prompt}/${prompt}${timestamp}/" "${file}"
}

# Exit if there are local changes
if [ "$(git status -s)" ]; then
  printf 'Changes detected in working directory. Commit them before proceeding.\n'
  exit 1
fi

printf 'Deleting old publication\n'
rm -rf "${output_dir}"
mkdir "${output_dir}"
git worktree prune
rm -rf ".git/worktrees/${output_dir}"

printf 'Fetch gh-pages branch\n'
git fetch origin gh-pages

printf 'Checking out gh-pages branch\n'
git worktree add -B gh-pages ${output_dir} origin/gh-pages

# Slide decks are expected to reside in a subdirectory starting with a date,
# or at least a year:
for dir in ./[0-9][0-9][0-9][0-9]*/; do
  pushd "${dir}"
  printf "Building site in ${dir}\n"
  make all
  popd
done

# Copy tables of content
cp toc.md  "${output_dir}"/README.md
update_changed_on_message "${output_dir}/README.md"

printf 'Updating gh-pages branch\n'
cd "${output_dir}" \
  && git add --all \
  && git commit -m "Publishing to gh-pages (${0}) at $(date --utc --iso-8601=seconds)"

printf 'Pushing to Github\n'
git push "${REPOSITORY:-origin}" gh-pages
