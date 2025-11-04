#!/usr/bin/env bash

# TODO pass project ID as a variable
# TODO pass query as a variable

gh api graphql --paginate --jq '.data.search.edges[]' -f query='
  query {
  search(first: 100, type: ISSUE, query: "user:timja is:issue repo:jenkins-gh-issues-poc state:open label:bug") {
    issueCount
    pageInfo {
      hasNextPage
      endCursor
    }
    edges {
      node {
        ... on Issue {
          id
        }
      }
    }
  }
}' | jq -s -r '.[].node.id' | xargs -P 10 -I '{}' -n 1 gh api graphql -f query='
mutation {
    addProjectNextItem(input: {projectId: "PN_kwHOAUNoHs4ACnA-" contentId: "{}"}) {
      projectNextItem {
        id
      }
    }
  }'
