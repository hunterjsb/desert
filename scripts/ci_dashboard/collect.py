#!/usr/bin/env python3
"""Build the static performance report from Actions evidence; stdlib only."""
import argparse
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone
import json
import math
import os
from pathlib import Path
import re
import shutil
import time
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

SCHEMA = 1
VERDICT = re.compile(r"^(?:again, by itself: )?(PASS|FAIL|ERROR|TIMEOUT)\s+(probes/[^\s]+\.gd) \((\d+)s\)$")
STAMP = re.compile(r"^\d{4}-\d\d-\d\dT[\d:.]+Z\s*")
ANSI = re.compile(r"\x1b\[[0-9;]*[a-zA-Z]")


def seconds(start, end):
    if not start or not end:
        return None
    return max(0, (datetime.fromisoformat(end.replace('Z', '+00:00')) -
                   datetime.fromisoformat(start.replace('Z', '+00:00'))).total_seconds())


def platform(name):
    if name.startswith('Windows ') or 'windows-x86_64' in name:
        return 'Windows'
    if name.startswith('macOS ') or 'macos-universal' in name:
        return 'macOS'
    return 'Linux'


def parse_log(log):
    """Keep every verdict attempt; only accept explicit numeric game measurements."""
    probes, metrics = {}, []
    for line in log.splitlines():
        line = STAMP.sub('', ANSI.sub('', line))
        match = VERDICT.fullmatch(line)
        if match and not match[2].startswith('probes/selftest/'):
            probes.setdefault(match[2], []).append({'result': match[1], 'seconds': int(match[3])})
        elif line.startswith('PROBE_METRIC '):
            try:
                m = json.loads(line.removeprefix('PROBE_METRIC '))
                if not re.fullmatch(r'probes/[\w/.-]+\.gd', m['probe']):
                    continue
                if not isinstance(m['name'], str) or not isinstance(m['unit'], str):
                    continue
                if not isinstance(m['value'], (int, float)) or not math.isfinite(m['value']):
                    continue
                clean = {k: m[k] for k in ('probe', 'name', 'value', 'unit')}
                clean['name'], clean['unit'] = clean['name'][:120], clean['unit'][:16]
                budget = m.get('budget')
                if isinstance(budget, (int, float)) and math.isfinite(budget) and budget >= 0:
                    clean['budget'] = budget
                clean['attempt'] = len(probes.get(m['probe'], []))
                metrics.append(clean)
            except (ValueError, KeyError, TypeError):
                continue
    rows = []
    for path, attempts in probes.items():
        rows.append({'path': path, 'attempts': attempts, 'result': attempts[-1]['result'],
                     'seconds': attempts[-1]['seconds'],
                     'retry_seconds': sum(a['seconds'] for a in attempts[:-1]),
                     'total_seconds': sum(a['seconds'] for a in attempts)})
    # A failed run's partial measurements must not masquerade as passing evidence.
    for m in metrics:
        attempts = probes.get(m['probe'], [])
        n = m['attempt']
        m['result'] = attempts[n - 1]['result'] if 0 < n <= len(attempts) else 'UNKNOWN'
    return rows, metrics


class GitHub:
    def __init__(self, repo, token):
        if not re.fullmatch(r'[\w.-]+/[\w.-]+', repo):
            raise ValueError('Expected owner/repository')
        self.repo, self.token = repo, token

    def get(self, path, raw=False):
        url = f'https://api.github.com/repos/{self.repo}/{path}'
        # urllib strips authorization on neither all redirects nor all hosts. Resolve
        # the API's signed log URL without forwarding our token to blob storage.
        import urllib.request
        class NoRedirect(urllib.request.HTTPRedirectHandler):
            def redirect_request(self, req, fp, code, msg, headers, newurl):
                return None
        for attempt in range(3):
            try:
                req = Request(url, headers={'Authorization': f'Bearer {self.token}',
                    'Accept': 'application/vnd.github+json', 'X-GitHub-Api-Version': '2022-11-28'})
                try:
                    with urllib.request.build_opener(NoRedirect).open(req, timeout=45) as response:
                        body = response.read()
                except HTTPError as error:
                    if error.code not in (301, 302, 307):
                        raise
                    location = error.headers['Location']
                    if not location.startswith('https://'):
                        raise ValueError('Non-HTTPS log redirect')
                    with urlopen(location, timeout=45) as response:
                        body = response.read()
                return body.decode('utf-8', errors='replace') if raw else json.loads(body)
            except (HTTPError, URLError, TimeoutError) as error:
                if isinstance(error, HTTPError) and error.code < 500:
                    raise
                if attempt == 2:
                    raise
                time.sleep(attempt + 1)

    def pages(self, path, key):
        rows, page = [], 1
        while True:
            separator = '&' if '?' in path else '?'
            batch = self.get(f'{path}{separator}per_page=100&page={page}')[key]
            rows.extend(batch)
            if len(batch) < 100:
                return rows
            page += 1


def collect_run(api, run):
    jobs = api.pages(f"actions/runs/{run['id']}/jobs?filter=latest", 'jobs')
    def collect_job(job):
        out = {k: job.get(k) for k in ('id', 'name', 'conclusion', 'started_at', 'completed_at', 'html_url')}
        out['platform'] = platform(job['name'])
        execution_start = min((s['started_at'] for s in job.get('steps', []) if s.get('started_at')), default=None)
        out['seconds'] = seconds(execution_start, job.get('completed_at'))
        out['start_offset_seconds'] = seconds(run['created_at'], execution_start)
        out['steps'] = [{'name': s['name'], 'result': s['conclusion'],
                         'seconds': seconds(s.get('started_at'), s.get('completed_at'))}
                        for s in job.get('steps', [])]
        out.update(probes=[], metrics=[], log_status='not_needed')
        if any(s['name'] == 'Probes' for s in job.get('steps', [])):
            try:
                out['probes'], out['metrics'] = parse_log(api.get(f"actions/jobs/{job['id']}/logs", raw=True))
                out['log_status'] = 'available' if out['probes'] else 'no_verdicts'
            except (HTTPError, URLError, TimeoutError) as error:
                out['log_status'] = f"unavailable ({getattr(error, 'code', 'network')})"
                if isinstance(error, HTTPError):
                    error.close()
        return out
    with ThreadPoolExecutor(max_workers=4) as pool:
        collected = list(pool.map(collect_job, jobs))
    # Master skips the Linux probes of a commit its verify run passed: that
    # run's Linux jobs are this commit's evidence.
    proved_by = None
    if run['head_branch'] == 'master' and any(j['platform'] == 'Linux' and j['conclusion'] == 'skipped' for j in collected):
        runs = api.get(f"actions/workflows/probes.yml/runs?head_sha={run['head_sha']}&status=success&per_page=50")
        proving = next((r for r in runs['workflow_runs'] if r['head_branch'].startswith('verify-')), None)
        if proving:
            proved_by = proving['id']
            linux = [j for j in collect_run(api, proving)['jobs'] if j['platform'] == 'Linux' and j['probes']]
            collected = [j for j in collected if not (j['platform'] == 'Linux' and j['conclusion'] == 'skipped')] + linux
    artifacts = api.pages(f"actions/runs/{run['id']}/artifacts", 'artifacts')
    end = max((j['completed_at'] for j in jobs if j.get('completed_at')), default=None)
    return {'id': run['id'], 'attempt': run['run_attempt'], 'workflow': run['name'],
            'branch': run['head_branch'], 'sha': run['head_sha'], 'url': run['html_url'],
            'created_at': run['created_at'], 'result': run['conclusion'],
            'elapsed_seconds': seconds(run['created_at'], end),
            'proved_by': proved_by,
            'jobs': collected,
            'artifacts': [{'name': a['name'], 'bytes': a['size_in_bytes'], 'expired': a['expired']}
                          for a in artifacts if a['name'].startswith('desert-')]}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--repo', required=True)
    parser.add_argument('--history', type=Path, default=Path('.dashboard/history.json'))
    parser.add_argument('--output', type=Path, default=Path('_site'))
    parser.add_argument('--limit', type=int, default=8)
    args = parser.parse_args()
    api = GitHub(args.repo, os.environ['GH_TOKEN'])
    history = {}
    if args.history.exists():
        old = json.loads(args.history.read_text())
        if old.get('schema') == SCHEMA and old.get('repository') == args.repo:
            history = {r['id']: r for r in old['runs']}
    for workflow, query in [('probes.yml', '&branch=master'), ('release.yml', '')]:
        runs = api.get(f'actions/workflows/{workflow}/runs?status=completed&per_page={args.limit}{query}')['workflow_runs']
        for run in runs:
            previous = history.get(run['id'])
            if (previous and previous['attempt'] == run['run_attempt']
                    and previous['result'] == run['conclusion']
                    and not any(j['log_status'].startswith('unavailable') for j in previous['jobs'])):
                continue
            print(f"Collecting {run['name']} #{run['id']} attempt {run['run_attempt']}", flush=True)
            history[run['id']] = collect_run(api, run)
    document = {'schema': SCHEMA, 'repository': args.repo,
                'generated_at': datetime.now(timezone.utc).isoformat(),
                'runs': sorted(history.values(), key=lambda r: r['created_at'], reverse=True)[:40]}
    args.history.parent.mkdir(parents=True, exist_ok=True)
    payload = json.dumps(document, separators=(',', ':'), allow_nan=False)
    args.history.write_text(payload)
    args.output.mkdir(parents=True, exist_ok=True)
    for name in ('index.html', 'style.css', 'app.js'):
        shutil.copyfile(Path(__file__).resolve().parents[2] / 'site' / name, args.output / name)
    (args.output / 'data.json').write_text(payload)
    print(f"Published data: {len(document['runs'])} runs, {len(payload):,} bytes")


if __name__ == '__main__':
    main()
