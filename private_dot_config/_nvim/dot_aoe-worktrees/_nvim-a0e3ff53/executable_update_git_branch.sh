#!/bin/bash
jira_issue=$1
git_branch="$2"

issue_info=$(curl -u francisco.roa.prieto@synaos.com:"$JIRA_API_KEY" \
	-X GET \
	-H "Content-Type: application/json" \
	https://synaos.atlassian.net/rest/api/2/issue/"$jira_issue"?fields="summary" | jq -r '.fields.summary')

issue_info=$(sed "s/ /_/g" <<<"$issue_info")
issue_info=$(sed "s/-/_/g" <<<"$issue_info")
# test
git checkout -b feature/"$jira_issue"_"$issue_info" origin/"$2"
