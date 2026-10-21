import unittest
from collect import parse_log, seconds, platform, collect_run


class EvidenceTests(unittest.TestCase):
    def test_retry_preserves_failed_cost_without_changing_final_verdict(self):
        rows, _ = parse_log('''2026-10-21T18:00:00.123Z TIMEOUT  probes/world/3_long_walk.gd (300s)
2026-10-21T18:00:01Z again, by itself: PASS     probes/world/3_long_walk.gd (119s)
2026-10-21T18:00:02Z FAIL     probes/selftest/fail.gd (1s)
''')
        self.assertEqual(len(rows), 1)
        self.assertEqual((rows[0]['result'], rows[0]['seconds'], rows[0]['retry_seconds'], rows[0]['total_seconds']), ('PASS', 119, 300, 419))

    def test_metrics_keep_their_attempt_and_failure_context(self):
        rows, metrics = parse_log('''FAIL probes/rope/10_cheap_enough.gd (20s)
PROBE_METRIC {"probe":"probes/rope/10_cheap_enough.gd","name":"Rope p99 tick","value":9.1,"unit":"ms","budget":8.3}
again, by itself: PASS probes/rope/10_cheap_enough.gd (21s)
PROBE_METRIC {"probe":"probes/rope/10_cheap_enough.gd","name":"Rope p99 tick","value":4.2,"unit":"ms","budget":8.3}
''')
        self.assertEqual([(m['result'], m['attempt'], m['value']) for m in metrics], [('FAIL', 1, 9.1), ('PASS', 2, 4.2)])
        self.assertEqual(metrics[1]['budget'], 8.3)

    def test_malformed_or_nonfinite_measurements_are_not_published(self):
        _, metrics = parse_log('''PROBE_METRIC not-json
PROBE_METRIC {"probe":"../../secret","name":"x","value":1,"unit":"ms"}
PROBE_METRIC {"probe":"probes/world/a.gd","name":"x","value":NaN,"unit":"ms"}
PROBE_METRIC {"probe":"probes/world/a.gd","name":"x","value":"1","unit":"ms"}
''')
        self.assertEqual(metrics, [])

    def test_absent_timestamps_are_not_zero_measurements(self):
        self.assertIsNone(seconds(None, None))
        self.assertEqual(seconds('2026-10-21T18:00:00Z','2026-10-21T18:01:30Z'),90)
        self.assertEqual(platform('macOS the rest'), 'macOS')
        self.assertEqual(platform('builds / smoke (windows-x86_64)'), 'Windows')

    def test_unavailable_logs_preserve_job_evidence_and_label_gap(self):
        from urllib.error import HTTPError
        class API:
            def pages(self, path, key):
                if key == 'artifacts': return []
                return [{'id':1,'name':'the rest','conclusion':'failure','started_at':'2026-10-21T18:00:10Z',
                         'completed_at':'2026-10-21T18:01:00Z','html_url':'https://github.com/example',
                         'steps':[{'name':'Probes','conclusion':'failure','started_at':'2026-10-21T18:00:10Z','completed_at':None}]}]
            def get(self, *args, **kwargs):
                raise HTTPError('https://example.com',410,'gone',{},__import__('io').BytesIO())
        run={'id':1,'run_attempt':2,'name':'Probes','head_branch':'master','head_sha':'abc',
             'html_url':'https://github.com/example','created_at':'2026-10-21T18:00:00Z',
             'run_started_at':'2026-10-21T18:00:40Z','conclusion':'failure'}
        result=collect_run(API(),run)
        self.assertEqual(result['jobs'][0]['log_status'],'unavailable (410)')
        self.assertEqual(result['jobs'][0]['seconds'],50)
        self.assertEqual(result['jobs'][0]['start_offset_seconds'],10)
        self.assertEqual(result['jobs'][0]['probes'],[])
        self.assertEqual(result['elapsed_seconds'],60)


if __name__ == '__main__':
    unittest.main()
