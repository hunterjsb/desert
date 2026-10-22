"""Exercise CI routing and landing against a local remote, without hosted jobs."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

VERIFY = Path(__file__).with_name('verify.sh').resolve()


class VerificationRouting(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.repo = self.root / 'repo'
        self.repo.mkdir()
        self.env = dict(os.environ, GIT_CONFIG_NOSYSTEM='1',
                        GIT_CONFIG_GLOBAL='/dev/null', GIT_AUTHOR_NAME='Test',
                        GIT_AUTHOR_EMAIL='test@example.invalid',
                        GIT_COMMITTER_NAME='Test', GIT_COMMITTER_EMAIL='test@example.invalid')
        self.git('init', '-q', '-b', 'master')
        self.write('game/main.gd', 'game\n')
        self.git('add', '.')
        self.git('commit', '-qm', 'base')
        self.git('init', '-q', '--bare', str(self.root / 'remote'))
        self.git('remote', 'add', 'origin', str(self.root / 'remote'))
        self.git('push', '-q', '-u', 'origin', 'master')
        self.base = self.git('rev-parse', 'HEAD').strip()
        self.bin = self.root / 'bin'
        self.bin.mkdir()
        self.log = self.root / 'calls'
        self.env.update(PATH=str(self.bin) + os.pathsep + self.env['PATH'],
                        VERIFY_CALLS=str(self.log), VERIFY_STATE=str(self.root / 'dispatched'))
        self.tool('sleep', '#!/bin/sh\nexit 0\n')
        self.tool('gh', '''#!/usr/bin/env python3
import json, os, pathlib, sys
args=sys.argv[1:]
with open(os.environ['VERIFY_CALLS'],'a') as f: f.write(json.dumps(args)+'\\n')
state=pathlib.Path(os.environ['VERIFY_STATE'])
if args[:2]==['workflow','run']: state.touch()
elif args[:2]==['run','list']:
    if not os.environ.get('VERIFY_FALLBACK') or state.exists(): print('123')
elif args[:2]==['run','view']:
    field=args[args.index('--json')+1]
    if field=='status': print('completed')
    elif field=='conclusion': print(os.environ.get('VERIFY_RESULT','success'))
''')
        self.copy = self.root / 'verify.sh'
        shutil.copyfile(VERIFY, self.copy)

    def tool(self, name, source):
        p = self.bin / name
        p.write_text(source)
        p.chmod(0o755)

    def git(self, *args):
        return subprocess.check_output(['git', *args], cwd=self.repo, env=self.env,
                                       text=True, stderr=subprocess.DEVNULL)

    def write(self, name, text='changed\n'):
        p = self.repo / name
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(text)

    def commit(self):
        self.git('add', '-A')
        self.git('commit', '-qm', 'change')

    def verify(self, *args):
        return subprocess.run(['bash', str(self.copy), 'test', *args], cwd=self.repo,
                              env=self.env, text=True, capture_output=True)

    def calls(self):
        import json
        return [json.loads(line) for line in self.log.read_text().splitlines()] if self.log.exists() else []

    def test_dashboard_checks_can_land(self):
        for path in ['site/app.js', 'scripts/ci_dashboard/collect.py',
                     '.github/workflows/performance-pages.yml', 'docs/report.md']:
            self.write(path)
        self.commit()
        result = self.verify('--land')
        self.assertEqual(result.returncode, 0, result.stderr)
        calls = self.calls()
        self.assertTrue(any(c[:4] == ['run', 'list', '-w', 'performance-pages.yml'] for c in calls))
        self.assertFalse(any('probes.yml' in c for c in calls))
        self.assertEqual(self.git('rev-parse', 'HEAD'), self.git('rev-parse', 'origin/master'))

    def test_mixed_changes_keep_game_checks(self):
        self.write('site/app.js')
        self.write('game/main.gd')
        self.commit()
        self.assertEqual(self.verify().returncode, 0)
        self.assertTrue(any('probes.yml' in c for c in self.calls()))

    def test_shared_runner_keeps_game_checks(self):
        self.write('scripts/probe.sh')
        self.commit()
        self.assertEqual(self.verify().returncode, 0)
        self.assertTrue(any('probes.yml' in c for c in self.calls()))

    def test_moving_game_into_site_keeps_game_checks(self):
        (self.repo / 'site').mkdir()
        self.git('mv', 'game/main.gd', 'site/main.gd')
        self.commit()
        self.assertEqual(self.verify().returncode, 0)
        self.assertTrue(any('probes.yml' in c for c in self.calls()))

    def test_failed_dashboard_cannot_land(self):
        self.write('site/app.js')
        self.commit()
        self.env['VERIFY_RESULT'] = 'failure'
        self.assertNotEqual(self.verify('--land').returncode, 0)
        self.assertEqual(self.git('rev-parse', 'origin/master').strip(), self.base)

    def test_dashboard_fallback_dispatches_dashboard(self):
        self.write('site/app.js')
        self.commit()
        self.env['VERIFY_FALLBACK'] = '1'
        self.assertEqual(self.verify().returncode, 0)
        self.assertIn(['workflow', 'run', 'performance-pages.yml', '--ref', 'verify-test'], self.calls())

    def test_game_fallback_keeps_linux_dispatch(self):
        self.write('game/main.gd')
        self.commit()
        self.env['VERIFY_FALLBACK'] = '1'
        self.assertEqual(self.verify().returncode, 0)
        self.assertIn(['workflow', 'run', 'probes.yml', '--ref', 'verify-test', '-f', 'full_platforms=false'], self.calls())

    def test_docs_skip_ci(self):
        self.write('docs/report.md')
        self.commit()
        self.assertEqual(self.verify('--land').returncode, 0)
        self.assertEqual(self.calls(), [])


if __name__ == '__main__':
    unittest.main()
