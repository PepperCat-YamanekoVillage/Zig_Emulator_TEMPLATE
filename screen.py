import numpy as np
import cv2
import os
import time

filename = ".screen"
width, height = 64, 32
scale = 10  # 拡大倍率
row_stride = (width * 3 + 3) & ~3
frame_size = row_stride * height

while True:
    if not os.path.exists(filename):
        time.sleep(0.01)
        continue

    with open(filename, "rb") as f:
        data = f.read()
    
    if len(data) != frame_size:
        time.sleep(0.01)
        continue  # 不完全フレームはスキップ

    frame = np.frombuffer(data, dtype=np.uint8).reshape((height, row_stride))
    frame = frame[:, :width*3]  # パディング除去
    frame = frame.reshape((height, width, 3))

    frame_large = cv2.resize(frame, (width*scale, height*scale), interpolation=cv2.INTER_NEAREST)

    cv2.imshow("Screen", frame_large)
    if cv2.waitKey(1) & 0xFF == ord("q"):
        break

cv2.destroyAllWindows()
