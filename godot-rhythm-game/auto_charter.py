import json
import random
import argparse
import os
import numpy as np


# Example usage:
# python auto_charter.py "songs/novacane.mp3" "novacane_expert" --diff 1.5 --- HARD
# python auto_charter.py "songs/novacane.mp3" "novacane_easy" --diff 0.5 --- EASY
# python auto_charter.py "songs/novacane.mp3" "novacane_normal" --diff 1.0 --- NORMAL

try:
    import librosa
except ImportError:
    print("Error: librosa is not installed.")
    print("Please install it by running: pip install librosa soundfile numpy")
    exit(1)

def generate_chart(audio_path, output_name, difficulty=1.0):
    print(f"Loading audio file: {audio_path}...")
    
    # Load audio
    y, sr = librosa.load(audio_path)
    
    # Isolate percussive (drums) and harmonic (vocals/melody) components 
    # This heavily improves charting accuracy by mapping to the actual rhythm!
    print("Separating percussive components for better beat mapping...")
    y_harmonic, y_percussive = librosa.effects.hpss(y)
    
    # Get tempo (BPM)
    tempo, beat_frames = librosa.beat.beat_track(y=y_percussive, sr=sr)
    try:
        bpm = float(tempo[0])
    except (TypeError, IndexError):
        bpm = float(tempo)
    print(f"Detected BPM: {bpm:.2f}")
    
    # Detect rhythmic hits based only on drums / percussive noises
    onset_env = librosa.onset.onset_strength(y=y_percussive, sr=sr)
    peaks = librosa.util.peak_pick(onset_env, pre_max=3, post_max=3, pre_avg=3, post_avg=5, delta=0.3, wait=5)
    
    peak_times = librosa.frames_to_time(peaks, sr=sr)
    peak_energies = [onset_env[p] for p in peaks]
    
    if len(peak_energies) > 0:
        # Determine the cutoff for dropping quiet notes based on difficulty
        # Easy (diff=0.5) throws out ~70% of notes, Hard (diff=1.0) throws out ~40%, Expert(diff=2.0) keeps almost all
        percentile_to_keep = 100 - (min(difficulty, 2.0) * 40)
        threshold = np.percentile(peak_energies, max(1, percentile_to_keep))
        
        filtered_indices = [i for i, p in enumerate(peaks) if onset_env[p] >= threshold]
        filtered_times = [peak_times[i] for i in filtered_indices]
    else:
        filtered_times = peak_times
    
    print(f"Detected {len(filtered_times)} rhythmic peaks for charting at {difficulty}x density.")
    
    lanes = ["up", "left", "down", "right"]
    
    notes = []
    crotchet = 60.0 / bpm
    
    # How strictly to snap notes based on difficulty
    # Easy snaps to 1/2 beats. Normal to 1/4 beats. Hard/Expert to 1/8 beats.
    beat_snap_div = 2.0 if difficulty < 0.8 else 4.0
    if difficulty > 1.5:
        beat_snap_div = 8.0
        
    for i, t in enumerate(filtered_times):
        # Convert time to beat index, snap to nearest fraction
        beat = round((t / crotchet) * beat_snap_div) / beat_snap_div
        
        # 1. Loud hits (strong onset) tend to be kicks/snares -> Down and Up
        # 2. Quiet hits (weak onset) tend to be hi-hats -> Left and Right
        energy = peak_energies[filtered_indices[i]]
        is_loud = energy > np.percentile(peak_energies, 80)
        
        if is_loud:
            available_lanes = ["up", "down"]
        else:
            available_lanes = ["left", "right"]
            
        # Try to avoid the exact same lane repeatedly if possible
        if len(notes) >= 1 and notes[-1]["lane"] in available_lanes:
            if random.random() > 0.4 and len(available_lanes) > 1:
                available_lanes.remove(notes[-1]["lane"])
                
        lane = random.choice(available_lanes)
        
        # Pick top ("u") or bottom ("d") direction randomly to make them come from both sides
        dir_val = random.choice(["u", "d"])
        
        # Ensure we don't overlap exact same lane in exact same beat
        if len(notes) > 0 and notes[-1]["beat"] == beat and notes[-1]["lane"] == lane:
            continue
            
        notes.append({
            "beat": float(beat),
            "lane": lane,
            "dir": dir_val
        })

    # Sort notes by beat
    notes.sort(key=lambda x: x["beat"])

    # Create the JSON structure
    chart_data = {
        "song": os.path.splitext(output_name)[0],
        "bpm": round(bpm, 2),
        "scroll_speed": 400.0,
        "notes": notes
    }

    # Save to file
    out_path = f"charts/{output_name}.json"
    os.makedirs("charts", exist_ok=True)
    
    with open(out_path, 'w') as f:
        json.dump(chart_data, f, indent=2)
        
    print(f"Successfully generated new chart -> {out_path}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Auto-charter for rhythm games using audio analysis.")
    parser.add_argument("audio", help="Path to the audio file (.ogg, .wav, .mp3)")
    parser.add_argument("output", help="Name of the output chart (e.g. 'my_song')")
    parser.add_argument("--diff", type=float, default=1.0, help="Density of notes (0.5 for easy, 1.0 normal)")
    
    args = parser.parse_args()
    if not os.path.exists(args.audio):
        print(f"Cannot find audio file: {args.audio}")
    else:
        generate_chart(args.audio, args.output, args.diff)