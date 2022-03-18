#!/bin/bash
# Based on https://github.com/cli/cli/issues/444
# & https://github.com/cli/cli/issues/3189
# Requires gh v1.7+
# Test Environment: fork-update-test @ GitHub.com

USER="$(head -2 ~/.config/gh/hosts.yml | tail +2)"

function update() {
	read -a PARENT <<< $(gh api repos/${USER#*: }/$1 --jq '.parent | [.owner.login, .default_branch] | @tsv')
	# PARENT[0]="parent_repo" PARENT[1]=default_branch""
	SHA=$(gh api repos/${PARENT[0]}/$1/git/refs/heads/${PARENT[1]} --jq '.object.sha')
	echo "Merging ${PARENT[0]}/${PARENT[1]} to ${USER#*: }/$1..."
	gh api -X PATCH repos/${USER#*: }/$1/git/refs/heads/${PARENT[1]} -f sha="$SHA" -F force=true --silent
}

if [[ $1 == *"all"* ]];
	then gh repo list --fork -L 1000 --no-archived | while read fork_repo _; do update "$fork_repo"; done
else
	for fork_repo in $@; do update "$fork_repo"; done
fi
