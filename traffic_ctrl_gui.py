
import cv2
import numpy as np
import tkinter as tk
from PIL import Image, ImageTk
import threading
import serial
import time

# -----------------------------
# GUI 설정
# -----------------------------
root = tk.Tk()
root.title("실시간 교통 관제 시스템")
window_width = 2560
window_height = 1440
root.geometry(f"{window_width}x{window_height}")
root.configure(bg="#2b2b2b")

# -----------------------------
# GUI 타이틀 상자
# -----------------------------
title_frame = tk.Frame(root, bg="#3a3a3a", bd=5, relief="ridge")
title_frame.place(x=50, y=40, width=1450, height=110)

main_title = tk.Label(title_frame, text="실시간 교통 관제 시스템",
                      font=("맑은 고딕", 55, "bold"),
                      fg="white", bg="#3a3a3a")
main_title.pack(expand=True, fill="both")

# -----------------------------
# 카메라 설정
# -----------------------------
cap = cv2.VideoCapture(1, cv2.CAP_DSHOW)
scale = 4
qvga_height, qvga_width = 240, 320

camera_width = qvga_width * scale
camera_height = qvga_height * scale
camera_x = 50
camera_y = (window_height - camera_height) // 2

camera_label = tk.Label(root, bg="#2b2b2b", bd=5, relief="ridge")
camera_label.place(x=camera_x, y=camera_y, width=camera_width, height=camera_height)

# -----------------------------
# 차량 신호등 (PNG)
# -----------------------------
signal_files = ["red.png", "yellow.png", "green.png"]
traffic_images = []

for file in signal_files:
    img = Image.open(file).convert("RGBA")
    bg_color = (43, 43, 43, 255)
    background = Image.new("RGBA", img.size, bg_color)
    img_composite = Image.alpha_composite(background, img)
    img_composite = img_composite.resize((1105, 360), Image.LANCZOS)
    traffic_images.append(ImageTk.PhotoImage(img_composite))

traffic_label = tk.Label(root, bg="#2b2b2b")
traffic_label.place(x=1400, y=camera_y-50)

# -----------------------------
# 문구 박스 (차량 모드)
# -----------------------------
pedestrian_label = tk.Label(root, text="무단횡단: 없음",
                            font=("맑은 고딕", 60, "bold"), fg="#7CFC00",
                            bg="#3a3a3a", width=20, height=2, bd=5, relief="ridge")
pedestrian_label.place(x=1500, y=camera_y + 400)

vehicle_label = tk.Label(root, text="유동차량: 적음",
                         font=("맑은 고딕", 60, "bold"), fg="#7CFC00",
                         bg="#3a3a3a", width=20, height=2, bd=5, relief="ridge")
vehicle_label.place(x=1500, y=camera_y + 700)

# -----------------------------
# 보행자 신호등 이미지
# -----------------------------
ped_signal_files = ["ped_red.png", "ped_green.png"]
ped_images = []
for file in ped_signal_files:
    img = Image.open(file).convert("RGBA")
    bg_color = (43, 43, 43, 255)
    background = Image.new("RGBA", img.size, bg_color)
    img_composite = Image.alpha_composite(background, img)
    img_composite = img_composite.resize((350, 727), Image.LANCZOS)
    ped_images.append(ImageTk.PhotoImage(img_composite))

ped_signal_label = tk.Label(root, bg="#2b2b2b", bd=0, relief="flat")
violation_label = tk.Label(root, text="위반: 없음",
                           font=("맑은 고딕", 60, "bold"),
                           fg="#7CFC00", bg="#3a3a3a",
                           width=20, height=2, bd=5, relief="ridge")
ped_vehicle_label = tk.Label(root, text="유동차량: 적음",
                             font=("맑은 고딕", 60, "bold"),
                             fg="#7CFC00", bg="#3a3a3a",
                             width=20, height=2, bd=5, relief="ridge")

# -----------------------------
# 상태 변수
# -----------------------------
traffic_state = 0  # 0=green, 1=red
pedestrian_state = 0
vehicle_state = 0
violation_state = 0
last_red_time = 0

x_min_val, x_max_val, y_min_val, y_max_val = 0, 0, 0, 0

pedestrian_texts = ["없음", "발생"]
vehicle_texts = ["적음", "보통", "많음"]

pedestrian_colors = ["#7CFC00", "red"]
vehicle_colors = ["#7CFC00", "yellow", "red"]
violation_colors = ["#7CFC00", "red"]

display_mode = "vehicle"  # 차량/보행자 모드
ped_last_change = 0
ped_current_state = 0  # 0=빨강, 1=초록

# -----------------------------
# UART Thread
# -----------------------------
def uart_thread():
    global x_min_val, x_max_val, y_min_val, y_max_val
    global traffic_state, pedestrian_state, violation_state, vehicle_state

    ser = serial.Serial("COM15", 9600, timeout=0.01)
    buf = bytearray()
    while True:
        data = ser.read(ser.in_waiting or 1)
        if data:
            buf.extend(data)
            while len(buf) >= 9:
                packet = buf[:9]
                buf = buf[9:]

                x_min_val = (packet[0] << 8) | packet[1]
                x_max_val = (packet[2] << 8) | packet[3]
                y_min_val = (packet[4] << 8) | packet[5]
                y_max_val = (packet[6] << 8) | packet[7]

                code6 = packet[8] & 0xF8
                traffic_state = (code6 >> 7) & 0x1
                pedestrian_state = (code6 >> 6) & 0x1
                violation_state = (code6 >> 5) & 0x1
                vehicle_state = (code6 >> 3) & 0x3

threading.Thread(target=uart_thread, daemon=True).start()

# -----------------------------
# 모드 변경 버튼
# -----------------------------
def toggle_mode():
    global display_mode
    if display_mode == "vehicle":
        display_mode = "pedestrian"
        mode_button.config(text="차량 모드로 전환")
    else:
        display_mode = "vehicle"
        mode_button.config(text="보행자 모드로 전환")

mode_button = tk.Button(root, text="보행자 모드로 전환", font=("맑은 고딕", 20, "bold"),
                        fg="white", bg="#555555", bd=5, relief="ridge",
                        command=toggle_mode)
mode_button.place(x=2200, y=camera_y + 1000, width=300, height=70)

# -----------------------------
# 업데이트 함수
# -----------------------------
def update_frame():
    global traffic_state, last_red_time, ped_last_change, ped_current_state
    global pedestrian_state, vehicle_state, violation_state
    global x_min_val, x_max_val, y_min_val, y_max_val
    global display_mode

    ret, frame = cap.read()
    if ret:
        video_region = frame[0:qvga_height, 0:qvga_width]
        if video_region.max() <= 15:
            video_region = video_region << 4
        video_large = cv2.resize(video_region, (qvga_width*scale, qvga_height*scale), interpolation=cv2.INTER_NEAREST)


        if x_min_val != x_max_val and y_min_val != y_max_val:
            cv2.rectangle(video_large,
                          (x_min_val * scale, y_min_val * scale),
                          (x_max_val * scale, y_max_val * scale),
                          (0, 0, 255), 2)

        video_large = cv2.cvtColor(video_large, cv2.COLOR_BGR2RGB)
        img = Image.fromarray(video_large)
        imgtk = ImageTk.PhotoImage(image=img)
        camera_label.imgtk = imgtk
        camera_label.configure(image=imgtk)

    # -----------------------------
    # 모드별 GUI 처리
    # -----------------------------
    if display_mode == "vehicle":
        traffic_label.place(x=1400, y=camera_y-50)
        pedestrian_label.place(x=1500, y=camera_y + 400)
        vehicle_label.place(x=1500, y=camera_y + 700)

        ped_signal_label.place_forget()
        violation_label.place_forget()
        ped_vehicle_label.place_forget()

        if traffic_state == 1 and time.time() - last_red_time < 2:
            traffic_label.configure(image=traffic_images[1])
        elif traffic_state == 1:
            traffic_label.configure(image=traffic_images[0])
        else:
            traffic_label.configure(image=traffic_images[2])
            last_red_time = time.time()

        pedestrian_label.config(text=f"무단횡단: {pedestrian_texts[pedestrian_state]}",
                                fg=pedestrian_colors[pedestrian_state])
        vehicle_label.config(text=f"유동차량: {vehicle_texts[vehicle_state]}",
                             fg=vehicle_colors[vehicle_state])
    else:
        # 보행자 모드
        ped_signal_label.place(x=1400, y=camera_y + 100)
        violation_label.place(x=1800, y=camera_y+ 200, width = 700, height = 200)
        ped_vehicle_label.place(x=1800, y=camera_y+600, width = 700, height = 200)
        traffic_label.place_forget()
        pedestrian_label.place_forget()
        vehicle_label.place_forget()

        # 보행자 신호등 상태
        now = time.time()
        if traffic_state == 1:  # 차량 빨간불 -> 보행자 초록 (2초 지연)
            if ped_current_state == 0 and now - ped_last_change >= 2:
                ped_current_state = 1
                ped_last_change = now
        else:  # 차량 초록 -> 보행자 빨강 (즉시)
            ped_current_state = 0
            ped_last_change = now

        ped_signal_label.configure(image=ped_images[ped_current_state])

        # 위반 표시
        violation_label.config(text=f"신호 위반: {'O' if violation_state else 'X'}",
                               fg=violation_colors[violation_state] if violation_state else "#7CFC00")
        # 유동량 표시
        ped_vehicle_label.config(text=f"유동차량: {vehicle_texts[vehicle_state]}",
                                 fg=vehicle_colors[vehicle_state])

    root.after(30, update_frame)

# -----------------------------
# 실행
# -----------------------------
update_frame()
root.mainloop()
cap.release()
