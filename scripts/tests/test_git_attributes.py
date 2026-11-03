from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]


class EvidenceWhitespaceTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix='delta-evidence-whitespace-')
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        subprocess.run(['git', 'init', '-q', str(self.root)], check=True)
        shutil.copyfile(ROOT / '.gitattributes', self.root / '.gitattributes')

    def check_whitespace(self, name, content):
        path = self.root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(content)
        subprocess.run(['git', 'add', '--intent-to-add', '--', name],
                       cwd=self.root, check=True)
        return subprocess.run(
            ['git', '-c', 'core.whitespace=blank-at-eol,blank-at-eof,space-before-tab',
             'diff', '--check', '--', name],
            cwd=self.root, capture_output=True, text=True)

    def test_evidence_csv_crlf_is_accepted(self):
        for series in ('cp12', 'cp18'):
            with self.subTest(series=series):
                result = self.check_whitespace(
                    f'plan/evidence/{series}/results/valid.csv', b'N,value\r\n1,2\r\n')
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_real_whitespace_errors_in_evidence_csv_are_rejected(self):
        cases = {
            'trailing-space': b'N,value \r\n',
            'blank-at-eof': b'N,value\r\n\r\n',
            'space-before-tab': b' \tN,value\r\n',
        }
        for series in ('cp12', 'cp18'):
            for label, content in cases.items():
                with self.subTest(series=series, error=label):
                    result = self.check_whitespace(
                        f'plan/evidence/{series}/results/{label}.csv', content)
                    self.assertEqual(result.returncode, 2, result.stdout + result.stderr)

    def test_other_paths_keep_strict_whitespace_checks(self):
        for name, content in (
                ('other.csv', b'N,value\r\n'),
                ('plan/evidence/cp12/other.csv', b'N,value\r\n'),
                ('plan/evidence/cp18/results/guide.md', b'text\r\n'),
                ('guide.md', b'text \n')):
            with self.subTest(path=name):
                result = self.check_whitespace(name, content)
                self.assertEqual(result.returncode, 2, result.stdout + result.stderr)


if __name__ == '__main__':
    unittest.main()
