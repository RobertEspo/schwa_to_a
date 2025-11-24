import os
from pydub import AudioSegment
from praatio import textgrid
from pathlib import Path

# Set the root directory for recursion specifically
root_dir = Path(__file__).parent.parent.parent / "data" / "prodShadow" / "data"

# Path to the text file with labels
text_file = Path(__file__).parent.parent.parent / "data" / "prodShadow" / "labels.txt"

# Read the text file
with open(text_file, 'r', encoding='utf-8') as file:
    sentences = [line.strip() for line in file if line.strip()]

# Find all folders named "wavs" starting from this directory
wavs_dirs = [p for p in root_dir.rglob("wavs") if p.is_dir()]

def get_audio_duration(wav_path):
    """Return duration (in seconds) using pydub."""
    audio = AudioSegment.from_file(wav_path)
    return len(audio) / 1000.0  # convert ms → seconds

# Loop through all wavs directories
for wav_dir in wavs_dirs:
    wav_files = sorted([f for f in wav_dir.iterdir() if f.suffix.lower() == ".wav"])
    
    # Make sure the number of sentences matches number of wavs
    if len(sentences) != len(wav_files):
        print(f"Warning: number of sentences ({len(sentences)}) does not match number of wavs ({len(wav_files)}) in {wav_dir}")
        continue  # skip this folder
    
    for wav_file, sentence in zip(wav_files, sentences):
        # Create a new TextGrid
        tg = textgrid.Textgrid()
        tier_name = "word"

        wav_path = wav_file
        max_time = get_audio_duration(wav_path)

        # Add interval tier
        interval_tier = textgrid.IntervalTier(tier_name, [(0, max_time, sentence)], 0, max_time)
        tg.addTier(interval_tier)

        # Save the TextGrid in the same directory as the wav
        output_file = wav_dir / (wav_file.stem + ".TextGrid")
        tg.save(output_file, includeBlankSpaces=True, format="short_textgrid")

    print(f"TextGrids created successfully in {wav_dir}")
