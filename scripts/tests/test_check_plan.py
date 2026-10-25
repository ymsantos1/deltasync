import importlib.util
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location('delta_plan', ROOT / 'scripts/check_plan.py')
checker = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(checker)


class LocalReferenceTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix='delta-plan-references-')
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        # Match a public checkout: ignored local references are never copied.
        tracked = subprocess.check_output(['git', 'ls-files', '-z'], cwd=ROOT, text=True)
        for name in filter(None, tracked.split('\0')):
            source = ROOT / name
            target = self.root / name
            if source.is_file():
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(source, target)
        self.reference = self.root / 'referencia/Proposta TCC.pdf'
        self.assertFalse(self.reference.exists())

    def test_missing_reference_is_strict_by_default_and_optional_explicitly(self):
        errors, _, _ = checker.check(self.root)
        self.assertTrue(errors)
        self.assertTrue(all('Proposta TCC.pdf' in error for error in errors))
        errors, _, _ = checker.check(self.root, allow_missing_tcc_reference=True)
        self.assertEqual(errors, [])

    def test_other_missing_files_are_still_errors(self):
        with (self.root / 'README.md').open('a') as document:
            document.write('\n[Other reference](referencia/other.pdf)\n'
                           '[Missing guide](docs/missing.md)\n')
        errors, _, _ = checker.check(self.root, allow_missing_tcc_reference=True)
        self.assertEqual(len(errors), 2)
        self.assertTrue(any('referencia/other.pdf' in error for error in errors))
        self.assertTrue(any('docs/missing.md' in error for error in errors))

    def test_existing_reference_still_checks_anchors(self):
        self.reference.parent.mkdir()
        self.reference.write_text('# Present\n')
        with (self.root / 'README.md').open('a') as document:
            document.write('\n[Missing section](<referencia/Proposta TCC.pdf#missing>)\n')
        errors, _, _ = checker.check(self.root, allow_missing_tcc_reference=True)
        self.assertEqual(len(errors), 1)
        self.assertIn('anchor ausente', errors[0])


if __name__ == '__main__':
    unittest.main()
