##sudo pacman -S python-opencv

import cv2
import os
from pathlib import Path
import sys


video_path = sys.argv[1] if len(sys.argv) > 1 else 'input_video.mp4'

def open_video_capture(video_source):
    # Open the video source using OpenCV
    cap = cv2.VideoCapture(video_source)
    # ... (error handling)
    return cap

def get_last_frame(cap):
    # Iterate through frames and get the last one
    last_frame = None
    while True:
        ret, tmp_frame = cap.read()
        if not ret:
            break
        last_frame = tmp_frame
    return last_frame

def extract_last_frame_from_path(video_path):
    cap = open_video_capture(video_path)
    last_frame = get_last_frame(cap)
    in_path = Path(video_path)
    # Préserve un éventuel suffixe de résolution (ex: wave_reveal_2560x1440.mp4
    # -> wave_last_frame_2560x1440.png) pour que chaque écran garde sa propre frame.
    out_name = in_path.stem.replace("wave_reveal", "wave_last_frame") + ".png"
    out_path = in_path.parent / out_name
    cv2.imwrite(str(out_path), last_frame)  # Save the last frame as an image
    print(out_path)

extract_last_frame_from_path(video_path)
