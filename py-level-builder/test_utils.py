import unittest

from utils import ratio_to_A4, display_name


class RatioToA4Test(unittest.TestCase):

    def test_ratio_to_A4_cases(self):

        # A4 * 1.0 = A4
        self.assertAlmostEqual(
            ratio_to_A4(69),
            1.0
        )

        # A4 * 2.0 = A5
        self.assertAlmostEqual(
            ratio_to_A4(81),
            2.0
        )

        # A4 x 0.5 = A3
        self.assertAlmostEqual(
            ratio_to_A4(57),
            0.5
        )

        # A4 x ... = C5
        self.assertAlmostEqual(
            ratio_to_A4(72),
            523.2511306011972 / 440.0
        )

        # A4 x ... = G9
        self.assertAlmostEqual(
            ratio_to_A4(127),
            12543.85 / 440.0,
            places=4 # more sig figs left of decimal, so it's fine
        )

        # A4 x ... = C1
        self.assertAlmostEqual(
            ratio_to_A4(24),
            32.7032 / 440.0,
        )


class DisplayNameTest(unittest.TestCase):
    def test_display_name_cases(self):
        self.assertEqual(
            display_name(60),
            "C4",
        )
        self.assertEqual(
            display_name(69),
            "A4",
        )
        self.assertEqual(
            display_name(37),
            "Db2",
        )



if __name__ == '__main__':
    unittest.main()