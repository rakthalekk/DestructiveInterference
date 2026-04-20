import click
import pathlib
from miditoolkit import MidiFile
import re
import json
from dataclasses import asdict
from dacite import from_dict, Config
import shutil
from copy import deepcopy

from utils import *
from models import *

MINIMUM_DURATION_FOR_HOLD_NOTE_DEFAULT = 0.2
PRETTY_JSON = True
OUTPUT_LEVELS_FOLDER = (pathlib.Path(__file__) / ".." / ".." / "destructive-interference" / "levels").resolve()


# TODO: copy instrument sample mp3 files into output folder
# TODO: allow audio to start before first midi note
# TODO: allow each instrument to set its reference pitch


def merge_tuning(level_dict: dict, tuning_dict: dict, force_update_note_props: list[str]) -> dict:
    # metadata should be mostly overwritten, just check instrument count matches first
    # metadata.instruments
    if len(level_dict["metadata"]["instruments"]) > len(tuning_dict["metadata"]["instruments"]):
        for idx, inst in enumerate(level_dict["metadata"]["instruments"]):
            if inst["name"] not in {i["name"] for i in tuning_dict["metadata"]["instruments"]}:
                print(f"INFO: copying instrument metadata for {inst["name"]}")
                tuning_dict["metadata"]["instruments"].insert(idx, inst)
    elif len(level_dict["metadata"]["instruments"]) < len(tuning_dict["metadata"]["instruments"]):
        raise ValueError("ERROR: Tuning file metadata has more instruments than actual midi files parsed. Problem, go fix it manually.")
    # notes_by_instrument
    if len(level_dict["notes_by_instrument"]) > len(tuning_dict["notes_by_instrument"]):
        for inst_name, inst_notes in level_dict["notes_by_instrument"].items():
            if inst_name not in tuning_dict["notes_by_instrument"]:
                print(f"INFO: copying notes_by_instrument for {inst_name}")
                tuning_dict["notes_by_instrument"][inst_name] = deepcopy(inst_notes)
    elif len(level_dict["notes_by_instrument"]) < len(tuning_dict["notes_by_instrument"]):
        raise ValueError("ERROR: Tuning file notes_by_instrument has more instruments than actual midi files parsed. Problem, go fix it manually.")
    # assert len(level_dict["metadata"]["instruments"]) == len(tuning_dict["metadata"]["instruments"]), f"expected tuning.json file to have same number of instruments in metadata as generated from midi files, but didn't match. {len(level_dict["metadata"]["instruments"])=}, {len(tuning_dict["metadata"]["instruments"])=}. consider using --ignore-checks=instruments to copy new instruments into the tuning.json file."
    # assert len(level_dict["notes_by_instrument"]) == len(tuning_dict["notes_by_instrument"]), f"expected tuning.json file to have same number of instruments in notes_by_instrument as generated from midi files, but didn't match. {len(level_dict["notes_by_instrument"])=}, {len(tuning_dict["notes_by_instrument"])=} consider using --ignore-checks=instruments to copy new instruments into the tuning.json file."
    if set(level_dict["notes_by_instrument"].keys()) != set(tuning_dict["notes_by_instrument"]):
        raise ValueError("ERROR: midi files and tuning file have different instrument names in notes_by_instrument. Problem, go fix it manually.")
    # if some fields are entirely missing from tuning_dict, add them in
    # print(f"{level_dict["metadata"]=}\n{tuning_dict["metadata"]=}")
    for key, value in level_dict["metadata"].items():
        if key not in tuning_dict["metadata"]:
            # print(f"copying {key} from level_dict to tuning_dict")
            tuning_dict["metadata"][key] = deepcopy(value)
    level_dict["metadata"] = deepcopy(tuning_dict["metadata"])
    # print(f"{level_dict["metadata"]=}")

    for inst_name in level_dict["notes_by_instrument"].keys():
        level_inst_notes = level_dict["notes_by_instrument"][inst_name]
        tuning_inst_notes = tuning_dict["notes_by_instrument"][inst_name]

        # expect to have same length
        merging_different_lengths = False
        if len(level_inst_notes) != len(tuning_inst_notes):
            print(f"INFO: I see the tuning file has a different number of notes than found in the MIDI files.\n"
                f"I'll try to re-use existing notes from the tuning file, but I'll bail out if I get confused <3")
            merging_different_lengths = True
        # assert len(level_inst_notes) == len(tuning_inst_notes), f"expected tuning.json file to have same number of notes as generated from midi files, but didn't match. {len(level_inst_notes)=}, {len(tuning_inst_notes)=}. consider using --ignore-checks=notes to copy new notes into the tuning.json file."
        level_idx = 0
        tuning_idx = 0
        while level_idx < len(level_inst_notes) or tuning_idx < len(tuning_inst_notes):
            # print(f"starting loop. {level_idx=}, {tuning_idx=}")
            level_note = safe_get(level_inst_notes, level_idx)
            tuning_note = safe_get(tuning_inst_notes, tuning_idx)

            # copy over any properties not yet in the tuning note
            if level_note and tuning_note:
                for key, value in level_note.items():
                    if tuning_note.get(key) is None:
                        tuning_note[key] = value

            # check if the notes are equal
            DEFAULT_EQ_KEYS = ["name", "start_tick", "pitch_str"]
            ALWAYS_COPIED_FROM_LEVEL_DICT = ["start", "start_beat", "end", "end_beat", "pitch"]
            eq_keys = list([n for n in DEFAULT_EQ_KEYS if n not in force_update_note_props])
            if level_note and tuning_note and eq_by_keys(level_note, tuning_note, eq_keys):
                # same note in tuning and level
                # force-update any props requested by the user
                for prop_name in force_update_note_props:
                    tuning_note[prop_name] = level_note[prop_name]
                # force-update props always taken from midi parse
                for prop_name in ALWAYS_COPIED_FROM_LEVEL_DICT:
                    tuning_note[prop_name] = level_note[prop_name]
                # copy over other properties
                for prop_name in [n for n in tuning_note.keys() if n not in DEFAULT_EQ_KEYS and n not in ALWAYS_COPIED_FROM_LEVEL_DICT]:
                    level_note[prop_name] = tuning_note[prop_name]

            elif merging_different_lengths:
                if level_note is not None and (tuning_note is None or (level_note["start_tick"], level_note["name"]) < (tuning_note["start_tick"], level_note["name"])):
                    # new note from parsed Midi files. add to tuning
                    print(f"INFO: copying new Note into tuning file (name={level_note["name"]}, start_tick={level_note["start_tick"]})")
                    tuning_inst_notes.insert(tuning_idx, level_note)
                elif tuning_note is not None and (level_note is None or (tuning_note["start_tick"], tuning_note["name"]) < (level_note["start_tick"], level_note["name"])):
                    # tuning file has an extra note that's no longer in the Midi sources. warn, and maybe drop it.
                    raise ValueError(f"TODO handle nicer. Tuning file has an extra note that the Midi source files don't have. "
                                    f"{tuning_idx=}, {level_idx=}\n{tuning_note=}\n {level_note=}\n"
                                    f"")
                else:
                    # it's just the pitch that's different?
                    # if i ever run into this, maybe do something different. for now, just throw assertion error
                    for prop_name in eq_keys:
                        assert level_note[prop_name] == tuning_note[prop_name], f"expected notes at idx {level_idx} to have same properties in both level and tuning json files, but instead {prop_name} was different. {level_note[prop_name]=}, {tuning_note[prop_name]=}" # pyright: ignore[reportOptionalSubscript]

            else:
                # keys are different, but the user didn't request ignore note length checks. throw an assertion error.
                for prop_name in eq_keys:
                    assert level_note[prop_name] == tuning_note[prop_name], f"expected note at idx {level_idx} to have same properties in both level and tuning json files, but instead {prop_name} was different. {level_note[prop_name]=}, {tuning_note[prop_name]=}" # pyright: ignore[reportOptionalSubscript]

            level_idx += 1
            tuning_idx += 1

    return level_dict


def eq_by_keys(d1: dict, d2: dict, keys: list[str]) -> bool:
    for key in keys:
        if key not in d1 or key not in d2:
            return False
        if d1[key] != d2[key]:
            return False
    return True


def safe_get(l: list, i: int, default=None):
    if i < len(l) and i >= 0:
        return l[i]
    else:
        return default

def parse_level_dir(level_dir: pathlib.Path, min_hold_duration: float) -> Level:

    instruments: list[Instrument] = []
    notes_by_instrument: dict[str, list[Note]] = {}

    # list all instrument folders
    for inst_dir in [p for p in level_dir.iterdir() if p.is_dir()]:
        # get midi file
        midi_files = list(inst_dir.glob("*.mid"))
        midi_file = get_one_or(midi_files, lambda: raise_(click.BadParameter(f"expected 1 midi file in {inst_dir}, but instead got {len(midi_files)}")))

        instrument, notes = parse_instrument_dir(midi_file, min_hold_duration)
        instruments.append(instrument)
        notes_by_instrument[instrument.name] = notes

    return Level(
        LeveLMetadata(
            instruments
        ),
        notes_by_instrument=notes_by_instrument,
    )



def parse_instrument_dir(midi_file: pathlib.Path, min_hold_duration: float) -> tuple[Instrument, list[Note]]:

    # parse midi filename
    instrument = Instrument.from_midi_filename(midi_file.stem)

    # parse!
    midi_obj = MidiFile(midi_file)
    # print(midi_obj)
    # print(midi_obj.ticks_per_beat)
    time_for = midi_obj.get_tick_to_time_mapping()

    # check assumptions
    assert len(midi_obj.instruments) == 1, f"expected one instrument in midi file {midi_file}, but instead found {len(midi_obj.instruments)}"
    midi_instrument = midi_obj.instruments[0]
    assert len(midi_instrument.notes) > 0, f"no notes present in instrument {midi_instrument.name}"

    # parse notes one at a time
    notes: list[Note] = []
    for midi_note in midi_instrument.notes:
        start_time: float = time_for[midi_note.start]
        end_time: Optional[float] = time_for[midi_note.end]
        end_beat = (midi_note.end / midi_obj.ticks_per_beat) + 1
        if time_for[midi_note.end] - start_time < min_hold_duration:
            end_time = None
            end_beat = None
        notes.append(Note(
            name=instrument.name,
            start=start_time,
            start_beat=(midi_note.start / midi_obj.ticks_per_beat) + 1,
            start_tick=midi_note.start,
            end=end_time,
            end_beat=end_beat,
            end_tick=midi_note.end,
            pitch=ratio_to_A4(midi_note.pitch),
            pitch_str=display_name(midi_note.pitch),
            idx=len(notes),
        ))
        # print(midi_note.start)

    return instrument, notes





@click.group()
def cli():
    pass


@cli.command()
@click.argument(
    'level_dir',
    type=click.Path(
        exists=True,
        dir_okay=True,
        file_okay=False,
        path_type=pathlib.Path,
    ),
)
@click.option(
    '-h',
    '--min-hold-duration',
    type=float,
    default=MINIMUM_DURATION_FOR_HOLD_NOTE_DEFAULT,
    help="minimum duration for a note to be mapped as a held note in the beatmap",
)
@click.option(
    "-f",
    "--force-update-note-props",
    "force_update_note_props_raw",
    help="comma-separated list of Note properties to force-update in the tuning file, even if they differ"
)
@click.option(
    "-d",
    "--display/--no-display",
    "display",
    default=True,
    help="Whether to display the beatmap in stdout"
)
def build(
    level_dir: pathlib.Path,
    min_hold_duration: float,
    force_update_note_props_raw: str,
    display: bool,
):
    """
    Process raw level data in LEVEL_DIR into a JSON beatmap ready for Godot.

    LEVEL_DIR is the path to the level directory
    with all midi and mp3 files necessary to make a level file.
    """

    force_update_note_props = [s for s in force_update_note_props_raw.split(',') if s] if force_update_note_props_raw else [] # strip empty

    # start making model
    level_name = level_dir.stem

    # parse raw level data
    level = parse_level_dir(level_dir, min_hold_duration)
    level_dict = asdict(level)
    # print(level_dict)
    # remove sort_index from notes
    for inst_note_list in level_dict["notes_by_instrument"].values():
        for note_dict in inst_note_list:
            del note_dict["sort_index"]
    print(f"Raw MIDI files parsed. "
          f"Total instruments: {len(level_dict["metadata"]["instruments"])} "
          f"Total notes: {sum((len(notes) for notes in level_dict["notes_by_instrument"].values()))}")

    # check for existing level-tuning.json file
    level_tuning_file = level_dir / "tuning.json"
    if level_tuning_file.exists():
        # load it and overwrite level data
        with open(level_tuning_file, 'r') as f:
            tuning_dict = json.load(f)
        # round-trip the tuning dict to fill in empty fields and restore ordering
        tuning_dict = asdict(
            from_dict(
                data_class=Level,
                data=tuning_dict,
                config=Config(
                    type_hooks={Waveform: Waveform})))
        # if any instrument has default_band set, fill in any missing notes.band values
        for inst in tuning_dict["metadata"]["instruments"]:
            if inst["default_band"] != None:
                for note in tuning_dict["notes_by_instrument"][inst["name"]]:
                    if note["band"] is None:
                        note["band"] = inst["default_band"]
        merge_tuning(level_dict, tuning_dict, force_update_note_props)
        # write back any modifications made
        write_tuning_file(tuning_dict, level_tuning_file)
    else:
        # create a dummy version for the user to edit
        write_tuning_file(level_dict, level_tuning_file)
    print("Tuning file updated!")

    # prepare the output level_dict
    # zip all notes together
    all_notes: list[dict] = []
    for inst_note_list in level_dict["notes_by_instrument"].values():
        for note_dict in inst_note_list:
            all_notes.append(note_dict)
    all_notes = sorted(all_notes, key=lambda note_dict: (note_dict["start_tick"], note_dict["name"]))
    level_dict["notes"] = all_notes
    # convert "beat" units to seconds
    if level_dict["metadata"]["song_end"] is None:
        bpm = level_dict["metadata"]["bpm"]
        song_end_beat: float = level_dict["metadata"]["song_end_beat"]
        if song_end_beat != None and bpm != None:
            song_end_beat_0_indexed = song_end_beat - 1
            song_end_min = song_end_beat_0_indexed / bpm
            song_end_sec = song_end_min * 60
            level_dict["metadata"]["song_end"] = song_end_sec
        else:
            print("WARN: metadata song_end is empty. I can fill it in from song_end_beat and bpm, but at least one of those is misisng. Please fill them in!")
    if level_dict["metadata"]["view_range"] is None:
        bpm = level_dict["metadata"]["bpm"]
        view_range_beats = level_dict["metadata"]["view_range_beats"]
        if view_range_beats != None and bpm != None:
            view_range_min = view_range_beats / bpm
            view_range_sec = view_range_min * 60
            level_dict["metadata"]["view_range"] = view_range_sec # 1.84615385
        else:
            print("WARN: metadata view_range is empty. I can fill it in from view_range_beats and bpm, but at least one of those is misisng. Please fill them in!")
    # drop useless fields
    for inst in level_dict["metadata"]["instruments"]:
        del inst["default_band"]
    for note in level_dict["notes"]:
        del note["idx"]
        del note["sort_index"]
    # annotate any compound fields
    import itertools
    notes_at_same_time = [g for g in [list(group) for start_tick, group in itertools.groupby(level_dict["notes"], lambda d: (d["start_tick"]))] if len(g) > 1]
    # print(notes_at_same_time[0])
    for maybe_compound in notes_at_same_time:
        # notes occur all at same time, but need to check for overlapping bands..
        # check for compounds one band at a time
        for band in range(0, 5):
            notes_in_this_band: list[dict] = []
            for note in maybe_compound:
                if note["band"] is None:
                    # print(f"WARN: Note {note=} doesn't have a band!")
                    continue
                if isinstance(note["band"], int):
                    if note["band"] == band:
                        notes_in_this_band.append(note)
                else:
                    if note["band"]["start"] <= band or note["band"]["end"] >= band:
                        notes_in_this_band.append(note)
            if len(notes_in_this_band) > 1:
                # we have a compound!!
                instruments_list = [n["name"] for n in notes_in_this_band]
                # print(f"compound at start_tick={notes_in_this_band[0]["start_tick"]}, size={len(notes_in_this_band)}, instruments={instruments_list}")
                for note in notes_in_this_band:
                    if note.get("compounds") is None:
                        note["compounds"] = {}
                    note["compounds"][band] = instruments_list




    # make level_dir in output_levels if not yet
    output_dir = OUTPUT_LEVELS_FOLDER / level_name
    output_dir.mkdir(exist_ok=True)

    # write to output
    output_beatmap = output_dir / f"{level_name}.json"
    with open(output_beatmap, 'w') as f:
        f.write(json.dumps(level_dict, indent='  ' if PRETTY_JSON else None))
    print(f"Wrote output level JSON file\n    to {output_beatmap.resolve()}")

    # copy level_dir/*.mp3 if it exists
    raw_mp3_files = list(level_dir.glob("*.mp3"))
    if len(raw_mp3_files) > 1:
        print(f"WARN: Multiple mp3 files seen in {level_dir}: {raw_mp3_files}. Please include only one top-level mp3 file; this will be used as the master recording played during the level.")
    elif len(raw_mp3_files) == 1:
        master_audio_from_raw = raw_mp3_files[0]
        master_audio_output = output_dir / f"{master_audio_from_raw.stem}.mp3"
        shutil.copy2(master_audio_from_raw, master_audio_output)
        print(f"Copied master MP3 file\n    from {master_audio_from_raw}\n    to {master_audio_output}")


    # pretty display the beat map
    if display:
        try:
            display_level(level_dict)
        except MissingTuningDataError as e:
            print("WARN: Can't display beat map due to missing fields in tuning file.\n" + str(e))

class MissingTuningDataError(ValueError): ...

def display_level(level_dict: dict) -> None:
    lines: list[str] = []
    active: dict[str, float] = {}
    required_props = ("bpm", "subdivisions_per_beat", "beats_per_measure")
    missing_required_props = [p for p in required_props if level_dict["metadata"][p] == None]
    if len(missing_required_props) > 0:
        raise MissingTuningDataError(f"Missing these properties required to display beatmap: {missing_required_props}")

    time_per_line: float = (60.0 / level_dict["metadata"]["bpm"]) / level_dict["metadata"]["subdivisions_per_beat"]
    instruments = [inst["name"] for inst in level_dict["metadata"]["instruments"]]
    base_line = "║ " + ' │ '.join(' '*len(instruments) for _ in range(5)) + " ║"
    cur_line = base_line + f" b1    m1"
    unassigned_notes: list[str] = []
    # print(f"setup for display. {time_per_line=}")
    def put_chr_at_idx(s: str, c: str, i: int):
        return s[:i] + c + s[i+1:]
    def get_idx(band: int, inst_name: str):
        return 2 + (len(instruments) + 3) * band + instruments.index(inst_name)
    for note in level_dict["notes"]:
        # print(f"processing note with start={note['start']}, name={note['name']}, diff={note["start"] - ((len(lines) + 1) * time_per_line)}")
        # TODO: update to use start_tick instead
        while (note["start"] - ((len(lines) + 1) * time_per_line)) > -0.01:
            # print(f"    starting new line, crossed threshold of {(len(lines) + 1) * time_per_line}")

            # add dots for sustained notes
            done_insts = []
            for inst_key, end_time in active.items():
                inst_name = inst_key[:-1]
                inst_band = int(inst_key[-1])
                idx = get_idx(inst_band, inst_name)
                if cur_line[idx] == ' ':
                    cur_line = put_chr_at_idx(cur_line, ".", idx)
                if (end_time - ((len(lines) + 1) * time_per_line)) < 0.01:
                    done_insts.append(inst_key)
            for inst_key in done_insts:
                del active[inst_key]

            # add a "unassigned" suffix for unassigned notes
            if len(unassigned_notes) > 0:
                cur_line = cur_line + f" unassigned: {unassigned_notes}"
            unassigned_notes = []

            lines.append(cur_line)
            cur_line = base_line
            if len(lines) % level_dict["metadata"]["subdivisions_per_beat"] == 0:
                beat_num = int(len(lines) / level_dict["metadata"]["subdivisions_per_beat"])
                cur_line = cur_line + f" b{(beat_num % level_dict["metadata"]["beats_per_measure"])+1:<4}"
                if beat_num % level_dict["metadata"]["beats_per_measure"] == 0:
                    measure_num = int(beat_num / level_dict["metadata"]["beats_per_measure"])
                    cur_line = cur_line + f" m{measure_num+1:<4}"
            # print(f"    line added. new diff={note["start"] - ((len(lines) + 1) * time_per_line)}")
        # print(f"  adding note(start={note["start"]}) to current line(start={(len(lines)) * time_per_line}, end={(len(lines)+1) * time_per_line})")
        if note["band"] == None:
            unassigned_notes.append(note["name"])
        elif isinstance(note["band"], int):
            str_idx = get_idx(note["band"], note["name"])
            cur_line = put_chr_at_idx(cur_line, note["name"][0], str_idx)
            if note["end"] is not None:
                active[f"{note["name"]}{note["band"]}"] = note["end"]
        else:
            for band in range(note["band"]["start"], note["band"]["end"]+1):
                str_idx = get_idx(band, note["name"])
                cur_line = put_chr_at_idx(cur_line, note["name"][0], str_idx)



    lines.append(cur_line)
    for line in reversed(lines):
        print(line)


def write_tuning_file(tuning_dict: dict, tuning_filepath: pathlib.Path) -> None:
    # delete unwanted fields
    del tuning_dict["notes"]
    del tuning_dict["metadata"]["view_range"]
    del tuning_dict["metadata"]["song_end"]
    for inst_name, inst_notes in tuning_dict["notes_by_instrument"].items():
        for note in inst_notes:
            for key in ["sort_index", "pitch", "compound"]:
                if key in note:
                    del note[key]
    with open(tuning_filepath, 'w') as f:
        json.dump(tuning_dict, fp=f, indent='  ')


if __name__ == '__main__':
    cli()