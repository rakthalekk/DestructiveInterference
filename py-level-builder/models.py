from dataclasses import dataclass, field
from enum import Enum, auto
from typing import Optional, Union
import re


class Waveform(str, Enum):
    sine = "sine"
    triangle = "triangle"
    saw = "saw"
    square = "square"


@dataclass
class Level:
    metadata: LeveLMetadata
    notes: Optional[list[Note]] = None
    notes_by_instrument: Optional[dict[str, list[Note]]] = None


@dataclass
class LeveLMetadata:
    instruments: list[Instrument]
    title: Optional[str] = None
    bpm: Optional[float] = None
    beats_per_measure: int = 4
    subdivisions_per_beat: int = 4
    view_range: Optional[float] = None # only present in output file, computed from view_range_beats and bpm
    view_range_beats: Optional[float] = None # only present in tuning file
    warmup_time: float = 3.0
    song_end: Optional[float] = None # base
    song_end_beat: Optional[float] = None


@dataclass
class Instrument:
    name: str
    type: Optional[Waveform] = None
    color: Optional[str] = None
    goal: Optional[int] = None
    default_band: Optional[int] = None # if present, auto-fills any "null" band to this value

    @staticmethod
    def from_midi_filename(filename: str) -> Instrument:
        MIDI_FILENAME_PATTERN = (
            r"(?P<name>[^_\\.]+)"
            r"(_(?P<waveform>[^_\\.]+))?"
            r"(_(?P<color>[^_\\.]+))?"
            r"(_(?P<goal>[^_\\.]+))?"
        )
        result = re.match(MIDI_FILENAME_PATTERN, filename)
        if result == None:
            raise ValueError(f"invalid midi filename: {filename}")
        return Instrument(
            name=result.groupdict()["name"],
            type=(Waveform[result.groupdict()["waveform"].lower()] if result.groupdict().get("waveform") else None),
            color=(f"#{result.groupdict()["color"]}" if result.groupdict().get("color") else None),
            goal=(int(result.groupdict()["goal"]) if result.groupdict().get("goal") else None),
        )


@dataclass(order=True)
class Note:
    sort_index: list = field(init=False, repr=False)
    idx: Optional[int] = None
    name: Optional[str] = None # instrument name
    start: Optional[float] = None # note start time
    start_beat: Optional[float] = None # start time expressed in beat count. mostly for making beatmaps easier
    start_tick: Optional[int] = None # midi tick. helps for detecting exactly-equal times
    end: Optional[float] = None
    end_beat: Optional[float] = None
    end_tick: Optional[float] = None
    pitch: Optional[float] = None
    pitch_str: Optional[str] = None
    band: Optional[Union[float, NoteBand]] = None
    jumpable: bool = False
    # slide: Optional[list[NoteSlide]] = None
    compounds: Optional[dict[int, list[str]]] = None

    def __post_init__(self):
        # sort by start time, then instrument name
        self.sort_index = [self.start, self.name]



@dataclass
class NoteBand:
    start: float
    end: float


@dataclass
class NoteSlide:
    time: float
    band: int