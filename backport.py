#!/usr/bin/env python2
import argparse
import logging
import re
import requests

logging.basicConfig(level=logging.DEBUG)
log = logging.getLogger("backport.py")

GITHUB_PR_URL_RE = re.compile("github\.com\/DataDog\/(\S+)\/pull\/(\d+)")
GITHUB_PATH_URL = "https://patch-diff.githubusercontent.com/raw/DataDog/%s/pull/%s.diff"

def _pre(pattern):
    """
    Precompiles a diff header regexp after adding it the common
    prefix that matches "--- a/" and "+++ b/"
    """
    return re.compile("(?:\-{3}|\+{3}) \w\/" + pattern)

"""
Conversion mapping for each repository.
Key is a regexp pattern, value is a expansion template.
Result path is relative to /opt/datadog-agent
"""
CONVERSIONS = {
    "dd-agent": {
        _pre("(.+\.py)$"): "agent/\\1",
    },
    "integrations-core": {
        _pre("(\S+)\/check\.py$"): "agent/checks.d/\\1.py",

    }
}

"""
Ignores regexp for each directory. Path that match
one of these rules will be ignored even if matching a
conversion rule
"""
IGNORES = {
    "dd-agent": {
        _pre("tests/"),
    },
    "integrations-core": { }
}

def convert_header(line, repo, silent=False):
    """
    Convert the file path to allow hotpatching,
    returns True if the patch needs to be patched,
    False if the file is to be ignored (tests / metadata)
    """
    for regexp in IGNORES[repo]:
        if regexp.match(line):
            if not silent:
                log.info("Skipping %s (ignored)" % line)
            return True
    for regexp, template in CONVERSIONS[repo].iteritems():
        match = regexp.match(line)
        if match:
            newline = line[0:4] + match.expand(template)
            if not silent:
                log.debug("Converting %s to %s" % (line, newline))
            print newline
            return False

    if not silent:
        log.info("Skipping %s (unknown)" % line)
    return True


def convert_diff(url):
    """
    Fetch a patch from a PR url and output its content
    to stdout, translating the file paths to allow
    hotpatching
    """
    conv_diffs = 0
    log.debug("Processing %s" % url.strip())
    match = GITHUB_PR_URL_RE.search(url)
    if match is None or match.lastindex != 2:
        raise ValueError("Can't extract PR from URL %s" % url)
    repo, prID = match.groups()
    if repo not in CONVERSIONS.keys():
        raise ValueError("Repository %s unsupported" % repo)

    patch = requests.get(GITHUB_PATH_URL % (repo, prID))
    patch.raise_for_status()

    skip = True
    for line in patch.iter_lines():
        if line.startswith("--- "):
            skip = convert_header(line, repo)
            if skip is False:
                conv_diffs += 1
        elif line.startswith("+++ "):
            skip = convert_header(line, repo, silent=True)
        elif line.startswith("diff --git "):
            skip = True
        elif skip is False:
            print line
        else:
            pass  # Ignore intro / ignored file contents

    return conv_diffs

def main(patch_urls):
    conv_urls = 0
    conv_diffs = 0
    log.debug("Starting automated diff conversion...")
    with open(patch_urls) as f:
        for line in f:
            if not line.startswith("#"):
                conv_urls += 1
                conv_diffs += convert_diff(line)

    if conv_diffs:
        log.info("Converted %s diffs from %s PRs" % (conv_diffs, conv_urls))
    else:
        log.error("Converted %s diffs from %s PRs" % (conv_diffs, conv_urls))    
        exit(1)    



if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Convert github PRs to a diff ready to '
                                                 'be piped into patch -u -p0. This allows to '
                                                 'hotpatch an agent to backport fixes.')
    parser.add_argument('patches', type=str, help='file to read PR urls from')

    try:
        args = parser.parse_args()
        main(args.patches)
    except Exception as e:
        log.exception(e)
