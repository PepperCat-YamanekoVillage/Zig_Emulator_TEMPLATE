import struct
import glob
import os
import time
import hashlib
import math
import numpy as np
import sounddevice as sd

# -------------------------
# Wave Type Enum
# -------------------------
class WaveType:
    SIGN = 0
    PULSE = 1
    TRIANGLE = 2
    NOISE = 3
    MEMORY = 4
    DPCM = 5


# -------------------------
# Wave Classes
# -------------------------
class Sign:
    def __init__(self, age, life, volume, envelope, freq):
        self.age = age
        self.life = life
        self.volume = volume
        self.envelope = envelope
        self.freq = freq


class Pulse:
    def __init__(self, age, life, volume, envelope, duty, sweep):
        self.age = age
        self.life = life
        self.volume = volume
        self.envelope = envelope
        self.duty = duty
        self.sweep = sweep


class Triangle:
    def __init__(self, age, life, volume, envelope, freq):
        self.age = age
        self.life = life
        self.volume = volume
        self.envelope = envelope
        self.freq = freq


class Noise:
    def __init__(self, age, life, volume, envelope, short_mode):
        self.age = age
        self.life = life
        self.volume = volume
        self.envelope = envelope
        self.short_mode = short_mode


class Memory:
    def __init__(self, age, life, volume, envelope, data):
        self.age = age
        self.life = life
        self.volume = volume
        self.envelope = envelope
        self.data = data


class Dpcm:
    def __init__(self, age, life, volume, envelope, data, freq):
        self.age = age
        self.life = life
        self.volume = volume
        self.envelope = envelope
        self.data = data
        self.freq = freq


# -------------------------
# Load a wave from raw bytes
# -------------------------
def load_wave_from_bytes(b: bytes):
    if len(b) < 1:
        raise ValueError("Byte data is empty")

    wtype = b[0]
    p = 1  # read pointer after wave type

    if wtype == WaveType.SIGN:
        age, life, volume, envelope, freq = struct.unpack_from("<IIBBf", b, p)
        return Sign(age, life, volume, envelope, freq)

    elif wtype == WaveType.PULSE:
        age, life, volume, envelope, duty, sweep = struct.unpack_from("<IIBBff", b, p)
        return Pulse(age, life, volume, envelope, duty, sweep)

    elif wtype == WaveType.TRIANGLE:
        age, life, volume, envelope, freq = struct.unpack_from("<IIBBf", b, p)
        return Triangle(age, life, volume, envelope, freq)

    elif wtype == WaveType.NOISE:
        age, life, volume, envelope, short_mode = struct.unpack_from("<IIBB?", b, p)
        return Noise(age, life, volume, envelope, short_mode)

    elif wtype == WaveType.MEMORY:
        age, life, volume, envelope, datalen = struct.unpack_from("<IIBBI", b, p)
        p += struct.calcsize("<IIBBI")
        data = b[p:p + datalen]
        return Memory(age, life, volume, envelope, data)

    elif wtype == WaveType.DPCM:
        age, life, volume, envelope, datalen, freq = struct.unpack_from("<IIBBIf", b, p)
        p += struct.calcsize("<IIBBIf")
        data = b[p:p + datalen]
        return Dpcm(age, life, volume, envelope, data, freq)

    else:
        raise ValueError(f"Unknown wave type: {wtype}")


# -------------------------
# Load all .channel/* files
# -------------------------
def load_all_channels(path=".channel"):
    waves = {}

    for filename in sorted(glob.glob(os.path.join(path, "*"))):
        with open(filename, "rb") as f:
            data = f.read()
            if not data:
                continue
            ch = int(os.path.basename(filename).split(".")[0])
            waves[ch] = load_wave_from_bytes(data)

    return waves

# -------------------------
# 音を鳴らす
# -------------------------

_current_streams = {}

def play_sign_wave(sign, channel=0, samplerate=44100):
    global _current_streams

    # 既に再生中なら止める
    if channel in _current_streams:
        _current_streams[channel].stop()
        _current_streams[channel].close()

    phase = 0.0
    freq = sign.freq
    volume = sign.volume / 255.0

    def callback(outdata, frames, time, status):
        nonlocal phase

        t = (np.arange(frames) + phase) / samplerate
        wave = np.sin(2 * np.pi * freq * t) * volume

        outdata[:] = wave.reshape(-1, 1)
        phase += frames

    stream = sd.OutputStream(
        samplerate=samplerate,
        channels=1,
        callback=callback,
    )
    stream.start()

    # ストリームを保存（後で止められる）
    _current_streams[channel] = stream

_last_hashes = {}

def compute_hash(data: bytes):
    return hashlib.md5(data).hexdigest()

def main_loop(interval=1.0):
    global _last_hashes, _current_streams

    while True:
        waves = load_all_channels()
        existing_channels = set(waves.keys())
        playing_channels = set(_current_streams.keys())

        # -----------------------------
        # 削除されたチャンネルのストリーム停止
        # -----------------------------
        removed = playing_channels - existing_channels
        for ch in removed:
            print(f"[Channel {ch}] removed → stop playback")
            stream = _current_streams.pop(ch, None)
            if stream:
                stream.stop()
                stream.close()
            _last_hashes.pop(ch, None)  # ハッシュ記録も消す

        # -----------------------------
        # (従来の処理) 更新されたチャンネルの再生
        # -----------------------------
        for ch, wave_obj in sorted(waves.items()):
            filename = f".channel/{ch}"
            with open(filename, "rb") as f:
                raw = f.read()

            h = compute_hash(raw)

            if _last_hashes.get(ch) == h:
                continue

            _last_hashes[ch] = h
            print(f"[Channel {ch}] updated → {type(wave_obj).__name__}")

            if isinstance(wave_obj, Sign):
                play_sign_wave(wave_obj, channel=ch)
            else:
                print("  -> Skipped (not a Sign wave)")

        time.sleep(interval)


if __name__ == "__main__":
    try:
        main_loop(interval=0.016)
    except KeyboardInterrupt:
        print("\nStopped.")

