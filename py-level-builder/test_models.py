import unittest

from models import Instrument, Waveform


class TestWaveformEnum(unittest.TestCase):

    def test_construct_by_name(self):
        self.assertEqual(
            Waveform.saw,
            Waveform['saw']
        )


class TestParseMidiFilename(unittest.TestCase):

    def test_short(self):
        self.assertEqual(
            Instrument("testname"),
            Instrument.from_midi_filename("testname")
        )

    def test_long(self):
        self.assertEqual(
            Instrument(
                name="testname",
                type=Waveform.saw,
                color="#FF8800",
                goal=75,
            ),
            Instrument.from_midi_filename("testname_saw_FF8800_75")
        )


if __name__ == '__main__':
    unittest.main()