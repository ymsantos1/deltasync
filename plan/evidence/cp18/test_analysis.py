import unittest
from analyze_comparison import describe, reduction


class ComparisonAnalysisTest(unittest.TestCase):
    def test_known_even_sample(self):
        self.assertEqual(describe([6, 1, 5, 2, 4, 3]),
                         dict(n=6, median=3.5, minimum=1, maximum=6))

    def test_reduction_direction_and_zero(self):
        self.assertEqual(reduction(100, 25), 75)
        self.assertEqual(reduction(100, 125), -25)
        self.assertIsNone(reduction(0, 0))

    def test_paired_reduction_is_not_ratio_of_medians(self):
        pairs=[(1, 1), (100, 50), (101, 100)]
        self.assertNotEqual(describe([reduction(a,b) for a,b in pairs])['median'],
                            reduction(describe([a for a,b in pairs])['median'],
                                      describe([b for a,b in pairs])['median']))


if __name__=='__main__':
    unittest.main()
