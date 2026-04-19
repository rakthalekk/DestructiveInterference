from typing import Callable


MIDI_PITCH_C4 = 60
MIDI_PITCH_A4 = 69 # nice
STEP_RATIO = 2 ** (1/12)


def get_one_or[T](l: list[T], otherwise: Callable) -> T:
    if len(l) != 1:
        otherwise()
    return l[0]


def raise_(ex: Exception):
    raise ex


def ratio_to_A4(midi_note_num: int) -> float:
    """
    Return the ratio a given pitch is above or below concert A4.

    Midi encodes an A4 as 69 (nice). Example usage of this function:

    - ratio_to_A4(81) = 2.0 # A5 = A4 x 2
    - ratio_to_A4(57) = 0.5 # A3 = A4 x 0.5
    - ratio_to_A4(72) = 1.18920455 # C5 = A4 x 1.189...

    Used ingame to pitch SFX based on the pitch of a note in the song.
    """
    pitch_diff = midi_note_num - MIDI_PITCH_A4
    freq_ratio = STEP_RATIO ** pitch_diff
    return freq_ratio

NOTE_NAMES = ["C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B"]

def display_name(midi_note_num:  int) -> str:
    pitch_octave = (midi_note_num // 12) - 1 # middle C4 = 60, so need to subtract 1 octave
    pitch_class = midi_note_num % 12 # middle C4 = 60, we'll treat C as pitch_class 0
    note_letter = NOTE_NAMES[pitch_class]
    return f"{note_letter}{pitch_octave}"

