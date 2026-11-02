import unittest
from analyze import stats, delta, paired


class AnalysisTest(unittest.TestCase):
    def test_six_rounds_have_maximum_as_nearest_rank_p95(self):
        self.assertEqual(stats([6, 1, 4, 2, 5, 3]),
                         dict(n=6, minimum=1, median=3.5, maximum=6, p95=6))

    def test_known_hundred_values(self):
        self.assertEqual(stats(range(1, 101))['p95'], 95)

    def test_missing_values_are_not_zero(self):
        self.assertEqual(stats([None, None])['n'], 0)
        self.assertIsNone(stats([None])['median'])
        self.assertEqual(stats([None, 8])['median'], 8)
        self.assertIsNone(delta(None, 100))
        self.assertIsNone(delta(-1, 100))

    def test_counter_reset_is_rejected(self):
        with self.assertRaises(ValueError):
            delta(12, 10)

    def test_paired_changes_preserve_negative_direction(self):
        self.assertEqual(paired(75, 100), (-25, -25))
        self.assertEqual(paired(10, 0), (10, None))

    def test_median_of_differences_not_difference_of_medians(self):
        on, off = [1, 2, 100], [0, 99, 100]
        self.assertEqual(stats([paired(a, b)[0] for a, b in zip(on, off)])['median'], 0)
        self.assertNotEqual(0, stats(on)['median'] - stats(off)['median'])


if __name__ == '__main__':
    unittest.main()
