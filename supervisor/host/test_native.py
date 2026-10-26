#!/usr/bin/env python3
"""Actual compiled Bend -> broker integration. No fake approval port here."""
import argparse,dataclasses,hashlib,json,sys,tempfile,time,unittest
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
from broker import Broker,BoundaryError
from native import BendPort
p=argparse.ArgumentParser();p.add_argument('--binary',type=Path,required=True);p.add_argument('--sha256',required=True);p.add_argument('--output',type=Path)
a=p.parse_args();binary=a.binary.resolve()
contract={'evaluator':1,'permission':'publish','reference':[20,0,0],'allowed_ops':[17,18,19,20],'max_nodes':3,'fallback':[20,0,0],'budget':5}

class NativeTests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory();self.contracts={(7,0):dict(contract)}
        self.port=BendPort(binary,a.sha256,self.contracts)
        self.b=Broker(Path(self.temp.name)/'receiver',self.port);self.b.issue(7,0,5,60,incumbent=b'[20,0,0]')
    def tearDown(self):self.b.close();self.temp.cleanup()
    def expire(self):
        c=self.b._json('context.json');c['deadline_ns']=0;self.b._write_json('context.json',c)
    def test_correct_smaller_candidate_published(self):
        self.assertTrue(self.b.commit(self.b.submit(b'[1]')));self.assertEqual(self.b.read_delivered(),b'[1]')
    def test_inequivalent_candidate_cannot_replace_fallback(self):
        self.assertTrue(self.b.commit(self.b.submit(b'[2]')));self.assertEqual(self.b.read_delivered(),b'[20,0,0]')
    def test_no_worker_results_delivers_rechecked_fallback(self):
        self.expire();self.assertTrue(self.b.finish());self.assertEqual(self.b.read_delivered(),b'[20,0,0]')
    def test_malformed_ast_native_rejects(self):
        with self.assertRaises(BoundaryError):self.b.commit(self.b.submit(b'[20,0]'))
        self.assertIsNone(self.b.read_delivered())
    def test_denied_effect_is_terminal_failure(self):
        contracts={(7,0):{**contract,'permission':'deny'}};self.b._native_port=BendPort(binary,a.sha256,contracts)
        self.expire();self.assertTrue(self.b.finish());self.assertIsNone(self.b.read_delivered())
    def test_changed_executable_identity_rejected(self):
        self.b._native_port=BendPort(binary,'0'*64,self.contracts)
        with self.assertRaises(BoundaryError):self.b.commit(self.b.submit(b'[1]'))
    def test_worker_cannot_set_evaluator_or_permission(self):
        with self.assertRaises(BoundaryError):self.b.submit(b'{"artifact":[2],"permission":"publish","evaluator":1,"approved":true}')
        self.assertIsNone(self.b.read_delivered())
    def test_receiver_unknown_evaluator_fails_closed(self):
        self.b._native_port=BendPort(binary,a.sha256,{(7,0):{**contract,'evaluator':2}})
        self.expire();self.assertTrue(self.b.finish());self.assertIsNone(self.b.read_delivered())
    def test_contract_revision_invalidates_old_snapshot(self):
        old=self.b.submit(b'[1]');new={**contract,'reference':[19,0,16],'fallback':[19,0,16]}
        self.b._native_port=BendPort(binary,a.sha256,{(7,1):new});self.b.issue(7,1,5,60,incumbent=b'[19,0,16]')
        with self.assertRaises(BoundaryError):self.b.commit(old)
        self.assertTrue(self.b.commit(self.b.submit(b'[16]')));self.assertEqual(self.b.read_delivered(),b'[16]')
    def test_acknowledged_incumbent_is_preserved_when_later_candidate_wrong(self):
        self.b.commit(self.b.submit(b'[1]'));self.b.commit(self.b.submit(b'[2]'))
        self.assertEqual(self.b.read_delivered(),b'[1]')
    def test_qualified_worse_candidate_retains_better_incumbent(self):
        self.b.commit(self.b.submit(b'[1]'));self.b.commit(self.b.submit(b'[20,0,0]'))
        self.assertEqual(self.b.read_delivered(),b'[1]')
    def test_equal_cost_qualified_candidate_keeps_incumbent(self):
        self.b.commit(self.b.submit(b'[18,0,1]'));self.assertEqual(self.b.read_delivered(),b'[20,0,0]')
    def test_no_registered_fallback_produces_permitted_failure(self):
        self.b._native_port=BendPort(binary,a.sha256,{(7,1):dict(contract)})
        self.b.issue(7,1,5,60);self.expire();self.assertTrue(self.b.finish())
        self.assertIsNone(self.b.read_delivered());self.assertTrue(self.b._json('context.json')['terminal'])
    def test_valid_candidate_without_registered_fallback_can_succeed(self):
        self.b._native_port=BendPort(binary,a.sha256,{(7,1):dict(contract)})
        self.b.issue(7,1,5,60);self.assertTrue(self.b.commit(self.b.submit(b'[1]')))
        self.assertEqual(self.b.read_delivered(),b'[1]')
    def test_empty_native_allowance_still_cannot_admit_wrong_candidate(self):
        self.b._native_port=BendPort(binary,a.sha256,{(7,0):{**contract,'budget':0}})
        self.b.commit(self.b.submit(b'[2]'));self.assertNotEqual(self.b.read_delivered(),b'[2]')

started=time.monotonic();suite=unittest.defaultTestLoader.loadTestsFromTestCase(NativeTests)
r=unittest.TextTestRunner(verbosity=2).run(suite)
report={'status':'PASS' if r.wasSuccessful() else 'FAIL','scope':'actual pinned native Bend supervisor to fixed-file broker; not hostile process isolation',
        'tests':r.testsRun,'failures':len(r.failures),'errors':len(r.errors),'elapsed_seconds':time.monotonic()-started,
        'binary_sha256':hashlib.sha256(binary.read_bytes()).hexdigest(),'expected_sha256':a.sha256,
        'sources':{x.name:hashlib.sha256(x.read_bytes()).hexdigest() for x in Path(__file__).parent.glob('*.py')}}
output=a.output or Path(__file__).resolve().parents[2]/'.artifacts'/'supervisor-host-native.json';output.parent.mkdir(parents=True,exist_ok=True);output.write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps({'status':report['status'],'report':str(output)}));raise SystemExit(0 if r.wasSuccessful() else 1)
