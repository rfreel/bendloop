#!/usr/bin/env python3
"""Broker IO tests with a fake *trusted* native port; not Bend admission proofs.

The separate supervisor gate must integrate the compiled Bend port. The capability
probe below records the actual host result and tests fail-closed worker launch.
"""
import dataclasses,json,os,sys,tempfile,unittest,concurrent.futures
from pathlib import Path
from unittest.mock import patch
sys.path.insert(0,str(Path(__file__).resolve().parent))
from broker import Broker,Frozen,BoundaryError,canonical_tokens
from isolation import WorkerBoundary,IsolationUnavailable,Allocation

class BrokerTests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory();self.path=Path(self.temp.name)/'receiver';self.calls=[]
        self.b=Broker(self.path,self.port);self.b.issue(7,0,5,60,incumbent=b'[0]')
    def tearDown(self): self.b.close();self.temp.cleanup()
    def port(self,c,s):
        self.calls.append((c,s))
        if s is None:return {'kind':'failure','task':c['task'],'epoch':c['epoch'],'sequence':c['last_effect']+1}
        return {'kind':'publish','task':c['task'],'epoch':c['epoch'],'sequence':c['last_effect']+1,'artifact':json.loads(s.content)}
    def expired(self):
        c=self.b._json('context.json');c['deadline_ns']=0;self.b._write_json('context.json',c)
    def test_concurrent_submissions_preserve_exact_ingress_allowance(self):
        self.b.issue(7,1,32,60)
        def submit(i):
            try:return self.b.submit(b'[0]').serial
            except BoundaryError:return None
        with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:results=list(pool.map(submit,range(64)))
        self.assertEqual(sorted(x for x in results if x is not None),list(range(1,33)))
        self.assertEqual(self.b._json('context.json')['received'],32)
    def test_canonical_copy_and_publish(self):
        s=self.b.submit(b' [ 20, 0, 0 ] ');self.assertEqual(s.content,b'[20,0,0]')
        self.assertTrue(self.b.commit(s));self.assertEqual(self.b.read_delivered(),s.content)
    def test_forged_worker_effect_is_only_invalid_data(self):
        with self.assertRaises(BoundaryError):self.b.submit(b'{"kind":"publish","approved":true,"artifact":[0]}')
        self.assertFalse(self.calls);self.assertIsNone(self.b.read_delivered())
    def test_changed_snapshot_bytes_rejected(self):
        s=self.b.submit(b'[0]')
        with self.assertRaises(BoundaryError):self.b.commit(dataclasses.replace(s,content=b'[1]'))
        self.assertFalse(self.calls)
    def test_invented_serial_rejected(self):
        s=self.b.submit(b'[0]')
        with self.assertRaises(BoundaryError):self.b.commit(dataclasses.replace(s,serial=99))
    def test_contract_change_retires_delivery_and_stales_snapshot(self):
        s=self.b.submit(b'[0]');self.b.commit(s);self.b.issue(7,1,5,60)
        self.assertIsNone(self.b.read_delivered())
        with self.assertRaises(BoundaryError):self.b.commit(s)
    def test_cross_task_aba_generation_rejected(self):
        s=self.b.submit(b'[0]');self.b.issue(8,1,5,60)
        with self.assertRaises(BoundaryError):self.b.issue(7,0,5,60)
        self.b.issue(7,2,5,60);self.b.submit(b'[0]')
        with self.assertRaises(BoundaryError):self.b.commit(s)
    def test_native_artifact_mismatch(self):
        s=self.b.submit(b'[0]');self.b._native_port=lambda c,s:{**self.port(c,s),'artifact':[1]}
        with self.assertRaises(BoundaryError):self.b.commit(s)
        self.assertIsNone(self.b.read_delivered())
    def test_native_can_select_frozen_receiver_fallback(self):
        s=self.b.submit(b'[1]');self.b._native_port=lambda c,s:{**self.port(c,s),'artifact':[0]}
        self.assertTrue(self.b.commit(s));self.assertEqual(self.b.read_delivered(),b'[0]')
    def test_native_old_epoch(self):
        s=self.b.submit(b'[0]');self.b._native_port=lambda c,s:{**self.port(c,s),'epoch':99}
        with self.assertRaises(BoundaryError):self.b.commit(s)
    def test_effect_replay_sequence(self):
        s=self.b.submit(b'[0]');self.b._native_port=lambda c,s:{**self.port(c,s),'sequence':0}
        self.b.commit(s)
        with self.assertRaises(BoundaryError):self.b.commit(s)
    def test_protocol_boolean_integer_rejected(self):
        s=self.b.submit(b'[0]');self.b._native_port=lambda c,s:{**self.port(c,s),'task':True}
        with self.assertRaises(BoundaryError):self.b.commit(s)
    def test_native_no_effect_is_no_publication(self):
        s=self.b.submit(b'[0]');self.b._native_port=lambda c,s:{'kind':'none'}
        self.assertFalse(self.b.commit(s));self.assertIsNone(self.b.read_delivered())
    def test_expiry_during_native_check(self):
        s=self.b.submit(b'[0]')
        c=self.b._json('context.json');deadline=c['deadline_ns']
        with patch('broker.time.monotonic_ns',side_effect=[deadline-1,deadline]):
            with self.assertRaises(BoundaryError):self.b.commit(s)
        self.assertIsNone(self.b.read_delivered())
    def test_expired_worker_cannot_commit(self):
        s=self.b.submit(b'[0]');self.expired()
        with self.assertRaises(BoundaryError):self.b.commit(s)
    def test_rejected_ingress_spends_allowance(self):
        self.b.issue(7,1,1,60)
        with self.assertRaises(BoundaryError):self.b.submit(b'{"approved":true}')
        with self.assertRaises(BoundaryError):self.b.submit(b'[0]')
    def test_payload_types_bounds(self):
        for x in (b'[true]',b'[1.0]',b'[]',b'[21]',b'[0]'*22000,b'\xff',b'['*10000+b'0'+b']'*10000,bytearray(b'[0]')):
            with self.assertRaises(BoundaryError):canonical_tokens(x)
    def test_qualified_fallback_after_withholding(self):
        self.expired();self.assertTrue(self.b.finish());self.assertEqual(self.b.read_delivered(),b'[0]')
        self.assertEqual(self.calls[-1][0]['phase'],'expired')
        before=len(self.calls);self.assertTrue(self.b.finish());self.assertEqual(len(self.calls),before)
    def test_terminal_failure_without_incumbent(self):
        self.b.issue(7,1,0,60);self.expired();self.assertTrue(self.b.finish());self.assertIsNone(self.b.read_delivered())
        with self.assertRaises(BoundaryError):self.b.submit(b'[0]')
    def test_finish_before_deadline_rejected(self):
        with self.assertRaises(BoundaryError):self.b.finish()
    def test_symlink_root_rejected(self):
        link=Path(self.temp.name)/'link';link.symlink_to(self.path)
        with self.assertRaises(BoundaryError):Broker(link,self.port)
    def test_world_readable_root_rejected(self):
        root=Path(self.temp.name)/'public';root.mkdir(mode=0o755)
        with self.assertRaises(BoundaryError):Broker(root,self.port)
    def test_destination_symlink_is_replaced_not_followed(self):
        outside=Path(self.temp.name)/'outside';outside.write_bytes(b'untouched');(self.path/'result.bin').symlink_to(outside)
        self.b.commit(self.b.submit(b'[0]'));self.assertEqual(outside.read_bytes(),b'untouched');self.assertFalse((self.path/'result.bin').is_symlink())
    def test_crash_before_first_ack_does_not_publish(self):
        s=self.b.submit(b'[1]');write=self.b._write_json
        def crash(name,value):
            if name=='delivered.json':raise OSError('simulated crash before acknowledgement')
            return write(name,value)
        with patch.object(self.b,'_write_json',side_effect=crash):
            with self.assertRaises(OSError):self.b.commit(s)
        self.assertIsNone(self.b.read_delivered());self.b.recover();self.assertIsNone(self.b.read_delivered())
    def test_crash_during_replacement_restores_acknowledged_incumbent(self):
        self.b.commit(self.b.submit(b'[0]'));s=self.b.submit(b'[1]');write=self.b._write_json
        def crash(name,value):
            if name=='delivered.json':raise OSError('simulated crash before acknowledgement')
            return write(name,value)
        with patch.object(self.b,'_write_json',side_effect=crash):
            with self.assertRaises(OSError):self.b.commit(s)
        self.b.recover();self.assertEqual(self.b.read_delivered(),b'[0]')
    def test_crash_after_ack_restores_sequence(self):
        s=self.b.submit(b'[1]');write=self.b._write_json
        def crash(name,value):
            if name=='context.json':raise OSError('simulated crash after acknowledgement')
            return write(name,value)
        with patch.object(self.b,'_write_json',side_effect=crash):
            with self.assertRaises(OSError):self.b.commit(s)
        self.b.recover();self.assertEqual(self.b.read_delivered(),b'[1]');self.assertEqual(self.b._json('context.json')['last_effect'],0)
    def test_bad_contract_request_preserves_prior_delivery(self):
        self.b.commit(self.b.submit(b'[0]'))
        with self.assertRaises(BoundaryError):self.b.issue(7,1,5,60,incumbent=b'{"approved":true}')
        self.assertEqual(self.b.read_delivered(),b'[0]')
    def test_reboot_allocation_fails_closed(self):
        s=self.b.submit(b'[0]')
        with patch.object(self.b,'_boot',return_value='different-boot'):
            with self.assertRaises(BoundaryError):self.b.commit(s)
            with self.assertRaises(BoundaryError):self.b.finish()

    def test_reboot_recovery_expires_without_renewing_worker_credit(self):
        self.b.submit(b'[1]')
        with patch.object(self.b,'_boot',return_value='different-boot'):
            self.b.recover();c=self.b._json('context.json')
            self.assertEqual(c['received'],c['allowance']);self.assertEqual(c['deadline_ns'],0)
            with self.assertRaises(BoundaryError):self.b.submit(b'[1]')
            self.assertTrue(self.b.finish());self.assertEqual(self.b.read_delivered(),b'[0]')

class IsolationTests(unittest.TestCase):
    def test_non_cgroup_root_rejected(self):
        with self.assertRaises(IsolationUnavailable):WorkerBoundary(Path('/tmp'))
    def test_allocation_bounds(self):
        with self.assertRaises(ValueError):Allocation(pids=0).validate()
    def test_actual_host_capability_and_fail_closed(self):
        boundary=WorkerBoundary(Path(os.environ.get('BENDLOOP_DELEGATED_CGROUP','/sys/fs/cgroup')))
        result=boundary.probe()
        evidence=Path(os.environ.get('BENDLOOP_HOST_EVIDENCE',str(Path(__file__).resolve().parents[2]/'.artifacts'/'supervisor-host-capability.json')))
        evidence.parent.mkdir(parents=True,exist_ok=True);evidence.write_text(json.dumps(result,indent=2)+'\n')
        if not result['available']:
            with self.assertRaises(IsolationUnavailable):boundary.run(['/bin/true'],b'[0]')
        else:
            # This positive test is safe but requires real delegated host controls.
            outcome=boundary.run(['/bin/true'],b'[0]');self.assertEqual(outcome['returncode'],0)

if __name__=='__main__':unittest.main()
