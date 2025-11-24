import os
import shutil
from glob import glob

# Source and destination
source_root = r"C:\Users\rober\Desktop\schwa_to_a\data\prodShadow\data"
dest_root = r"C:\Users\rober\Documents\MFA\pretrained_models"

# Loop through session folders
for session_num in range(7):  # session0 to session6
    session_name = f"session{session_num}"
    source_session = os.path.join(source_root, session_name)
    dest_session = os.path.join(dest_root, session_name)
    
    # Create session folder in destination if it doesn't exist
    os.makedirs(dest_session, exist_ok=True)
    
    # Get all wav and TextGrid files inside the 10 subfolders' 'wavs' directories
    wav_folders = glob(os.path.join(source_session, "*", "wavs"))
    
    for folder in wav_folders:
        for file_path in glob(os.path.join(folder, "*")):
            if file_path.lower().endswith((".wav", ".textgrid")):
                shutil.copy(file_path, dest_session)

print("Files copied successfully!")
