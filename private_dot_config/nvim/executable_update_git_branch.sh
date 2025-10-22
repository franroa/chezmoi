#!/bin/bash
jira_issue=$1

issue_info=$(curl -u froa@tecnosylva.com:"$JIRA_API_TOKEN" \
  -X GET \
  -H "Content-Type: application/json" \
  https://technosylva.atlassian.net/rest/api/2/issue/"$jira_issue"?fields="summary" | jq -r '.fields.summary')

issue_info=$(sed "s/ /_/g" <<<"$issue_info")
issue_info=$(sed "s/-/_/g" <<<"$issue_info")
# test
#
echo 'git checkout -b feature/"$jira_issue"_"$issue_info" "$2"'
git checkout -b feature/"$jira_issue"_"$issue_info" "$2"
