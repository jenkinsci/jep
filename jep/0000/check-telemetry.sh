#!/usr/bin/env bash

# The arrays 'TESTS' and 'RESULTS' need to be kept in sync
TESTS=(
    'hudson[.]plugins[.]analysis[.]util[.]Files[.]copyFilesWithAnnotationsToBuildFolder'
    'hudson[.]plugins[.]cobertura[.]renderers[.]SourceCodePainter[.]paintSourceCode'
    'io[.]jenkins[.]plugins[.]coverage[.]source[.]DefaultSourceFileResolver[$]SourceFilePainter[.]paintSourceCode'
    'com[.]microfocus[.]application[.]automation[.]tools[.]octane[.]tests[.]junit[.]JUnitExtension[$]GetJUnitTestResults[.]invoke'
    'jenkins[.]plugins[.]itemstorage[.]local[.]LocalObjectPath[$]IsNotThereOrOlderVisitor[.]visit'
    'hudson[.]plugins[.]logparser[.]LogParserStatusComputer[.]computeStatusMatches'
    'hudson[.]maven[.]MavenBuildProxy2[$]Filter[.](start|end)'
    'hudson[.]maven[.]reporters[.]MavenSiteArchiver[.]postExecute'
    'jenkins[.]plugins[.]publish_over_ssh[.]BapSshKeyInfo[.]getEffectiveKey'
    'Script1[.]groovy:1' # Trying to filter only the pre-2.322 test submission
    'hudson[.]plugins[.]selenium[.]callables[.]SeleniumCallable[.]invoke'
    'hudson[.]plugins[.]violations[.]generate[.]ExecuteFilePath[.]execute'
    'io[.]jenkins[.]plugins[.]analysis[.]core[.]steps[.]IssuesScanner[$]ReportPostProcessor[.]copyAffectedFiles' # until 5.1.0 / before d597cbdb, superseded June 2019
    'org[.]jenkinsci[.]plugins[.]xunit[.]service[.]XUnitTransformer[.]invoke' # until 2.0.2, superseded June 2018
)
RESULTS=(
    'analysis-core'
    'cobertura'
    'code-coverage-api'
    'hp-application-automation-tools-plugin'
    'jobcacher'
    'log-parser'
    'maven-plugin$MavenBuildProxy2'
    'maven-plugin$MavenSiteArchiver'
    'publish-over-ssh'
    'ScriptConsole'
    'selenium'
    'violations'
    'warnings-ng-5.1.0'
    'xunit-2.0.2'
)

function print_error_and_exit {
    echo "ERROR: $@" >&2
    echo "Usage: $0 <telemetry.json file>"
    exit 1
}

function log {
    echo "$@" >&2
}

TOOLS=(
    jq
    sort # Possibly only the Mac OS version?
    wc
    uniq
    cut
)
for TOOL in "${TOOLS[@]}" ; do
    command -v "$TOOL" > /dev/null || print_error_and_exit "Required tool not found: $TOOL"
done

[[ $# -eq 1 ]] || print_error_and_exit "Expected 1 argument, got $#"

FILE_NAME="$1"

[[ -f "$FILE_NAME" ]] || print_error_and_exit "$FILE_NAME is not a file"

log "[REPORTING STATS]"

log "Instances reporting FilePath telemetry:"
jq --raw-output '.correlator' < "$FILE_NAME" | sort -u | wc -l

log "Instances reporting non-empty FilePath telemetry:"
jq --raw-output 'if ( .payload.traces | length == 0) then empty else .correlator end' < "$FILE_NAME" | sort -u | wc -l


IFS='|' TEST_REGEX="${TESTS[*]}"
OUTPUT="$( jq --raw-output '.payload.traces[] | if test("'"$TEST_REGEX"'") then empty else . end' < "$FILE_NAME" )"

if [[ -n "$OUTPUT" ]] ; then
    log "[NEW TRACES CHECK]"
    log "Previously unknown agent-to-controller FilePath accesses identified:"
    echo "$OUTPUT"
    log "Skipping detailed plugin popularity stats."
else
    log "[PLUGIN POPULARITY STATS]"
    log "Instances reporting each of the known kinds of agent-to-controller FilePath calls:"

    JQ_EXPRESSION=""
    for idx in "${!TESTS[@]}" ; do
        JQ_EXPRESSION="$JQ_EXPRESSION | if test("'"'"${TESTS[idx]}"'"'") then "'"'"${RESULTS[idx]}"'"'" else . end"
    done

    jq --raw-output 'if ( .payload.traces | length == 0) then empty else "\( .correlator ) \( .payload.traces[] '"$JQ_EXPRESSION"' )" end' < "$FILE_NAME" | sort | uniq | cut -c66- | sort | uniq -c | sort -nr
fi
