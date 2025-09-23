

import cv2
import numpy as np
import tkinter as tk
from PIL import Image, ImageTk
import threading
import serial
import time
import pygame  # 🔔 효과음 재생용

# -----------------------------
# 효과음 초기화
# -----------------------------
pygame.mixer.init()
sound_violation = pygame.mixer.Sound("violation.mp3")
sound_pedestrian = pygame.mixer.Sound("pedestrian.mp3")

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
# 남은 시간 표시 (FND)
# -----------------------------
time_frame = tk.Label(root, bg="black", width=30, height=10, bd=5, relief="ridge")
time_frame.place(x=2200, y=40)
time_labels = []
for i in range(2):
    lbl = tk.Label(time_frame, bg="black", bd=0)
    lbl.place(x=i*90, y=5)
    time_labels.append(lbl)

# 숫자 PNG 불러오기
digit_images = []
digit_red_images = []
for i in range(10):
    digit_images.append(Image.open(f"digits_{i}.png").convert("RGBA"))
    digit_red_images.append(Image.open(f"digits_red_{i}.jpg").convert("RGBA"))

def set_time_display(number, red=False):
    if number > 99:
        return
    s = str(number).rjust(2, " ")
    for i, ch in enumerate(s):
        if ch == " ":
            time_labels[i].configure(image="", text="")
            time_labels[i].image = None
        else:
            idx = int(ch)
            img = digit_red_images[idx] if red else digit_images[idx]
            box = Image.new("RGBA", (80, 140), "black")
            box.paste(img, (0, 0), img)
            tk_img = ImageTk.PhotoImage(box)
            time_labels[i].configure(image=tk_img)
            time_labels[i].image = tk_img

def update_time_position():
    if display_mode == "vehicle":
        time_frame.place(x=1830, y=35)
        time_labels[0].place(x=20, y=5)
        time_labels[1].place(x=110, y=5)
        traffic_state_image_label.place(x=2050, y=40)  # FND 옆
    else:
        time_frame.place(x=1400, y=1050)
        time_labels[0].place(x=20, y=5)
        time_labels[1].place(x=110, y=5)
        traffic_state_image_label.place(x=1690, y=1050)  # 보행자 모드 FND 옆

# -----------------------------
# 카메라 설정
# -----------------------------
cap = cv2.VideoCapture(0, cv2.CAP_DSHOW)
scale = 4
qvga_height, qvga_width = 240, 320
camera_width = qvga_width * scale
camera_height = qvga_height * scale
camera_x = 50
camera_y = (window_height - camera_height) // 2
camera_label = tk.Label(root, bg="#2b2b2b", bd=5, relief="ridge")
camera_label.place(x=camera_x, y=camera_y, width=camera_width, height=camera_height)

# -----------------------------
# 차량 신호등 이미지
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
# Light / Heavy Traffic 이미지
# -----------------------------
traffic_state_images = {
    0: ImageTk.PhotoImage(Image.open("light_traffic.png").resize((150, 150), Image.LANCZOS)),
    1: ImageTk.PhotoImage(Image.open("heavy_traffic.png").resize((150, 150), Image.LANCZOS))
}
traffic_state_image_label = tk.Label(root, bg="#2b2b2b")
traffic_state_image_label.place(x=2250, y=40)

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
traffic_state = 1
pedestrian_state = 0
vehicle_state = 0
violation_state = 0
last_red_time = time.time()
prev_traffic_state = traffic_state
x_min_val, x_max_val, y_min_val, y_max_val = 0, 0, 0, 0
red_left_time, green_left_time = 0, 0
pedestrian_texts = ["없음", "발생"]
vehicle_texts = ["적음", "많음"]
pedestrian_colors = ["#7CFC00", "red"]
vehicle_colors = ["#7CFC00", "red"]
violation_colors = ["#7CFC00", "red"]
display_mode = "vehicle"
ped_last_change = 0
ped_current_state = 0
prev_pedestrian_state = 0
prev_violation_state = 0

# -----------------------------
# UART Thread
# -----------------------------
def uart_thread():
    global x_min_val, x_max_val, y_min_val, y_max_val
    global traffic_state, pedestrian_state, violation_state, vehicle_state
    global prev_pedestrian_state, prev_violation_state
    global red_left_time, green_left_time

    ser = serial.Serial("COM19", 115200, timeout=0.01)
    buf = bytearray()
    while True:
        data = ser.read(ser.in_waiting or 1)
        if data:
            buf.extend(data)
            while len(buf) >= 12:
                packet = buf[:12]
                buf = buf[12:]
                print("RX Packet (hex):", " ".join(f"{b:02X}" for b in packet))
                # Header Check
                if packet[0] != 0xAB:
                    buf = packet[1:] + buf
                    continue
                red_left_time = packet[1]
                green_left_time = packet[2]
                x_min_val = (packet[3] << 8) | packet[4]
                x_max_val = (packet[5] << 8) | packet[6]
                y_min_val = (packet[7] << 8) | packet[8]
                y_max_val = (packet[9] << 8) | packet[10]
                code6 = packet[11]
                traffic_state    = (code6 >> 7) & 0x1
                pedestrian_state = (code6 >> 6) & 0x1
                violation_state  = (code6 >> 5) & 0x1
                vehicle_state    = (code6 >> 4) & 0x1
                if pedestrian_state == 1 and prev_pedestrian_state == 0:
                    sound_pedestrian.play()
                if violation_state == 1 and prev_violation_state == 0:
                    sound_violation.play()
                prev_pedestrian_state = pedestrian_state
                prev_violation_state = violation_state

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
ped_alert_start = 0
vio_alert_start = 0

def update_frame():
    global traffic_state, last_red_time, ped_last_change, ped_current_state
    global pedestrian_state, vehicle_state, violation_state
    global x_min_val, x_max_val, y_min_val, y_max_val
    global display_mode, red_left_time, green_left_time, prev_traffic_state
    global ped_alert_start, vio_alert_start

    ret, frame = cap.read()
    if ret:
        video_region = frame[0:qvga_height, 0:qvga_width]
        if video_region.max() <= 15:
            video_region = video_region << 4
        video_large = cv2.resize(video_region, (qvga_width*scale, qvga_height*scale),
                                 interpolation=cv2.INTER_NEAREST)
        if x_min_val != x_max_val and y_min_val != y_max_val:
            cv2.rectangle(video_large,
                          (x_min_val * scale, y_min_val * scale),
                          (x_max_val * scale, y_max_val * scale),
                          (0, 0, 255), 5)
        video_large = cv2.cvtColor(video_large, cv2.COLOR_BGR2RGB)
        img = Image.fromarray(video_large)
        imgtk = ImageTk.PhotoImage(image=img)
        camera_label.imgtk = imgtk
        camera_label.configure(image=imgtk)

    # -----------------------------
    # 남은 시간 표시
    # -----------------------------
    update_time_position()
    if display_mode == "vehicle":
        red_flag = traffic_state == 0
    else:
        red_flag = traffic_state == 1
    if traffic_state == 0 and time.time() - last_red_time < 2:
        set_time_display(0, red=red_flag)
    elif traffic_state == 0:
        set_time_display(red_left_time, red=red_flag)
    else:
        set_time_display(green_left_time, red=red_flag)
        last_red_time = time.time()

    # -----------------------------
    # GUI 모드 처리
    # -----------------------------
    now = time.time()
    if pedestrian_state:
        ped_alert_start = now
    if violation_state:
        vio_alert_start = now

    if display_mode == "vehicle":
        traffic_label.place(x=1400, y=camera_y-30)
        pedestrian_label.place(x=1500, y=camera_y + 400)
        vehicle_label.place(x=1500, y=camera_y + 700)
        ped_signal_label.place_forget()
        violation_label.place_forget()
        ped_vehicle_label.place_forget()

        # 차량 신호등
        if traffic_state == 0 and time.time() - last_red_time < 2:
            traffic_label.configure(image=traffic_images[1])
        elif traffic_state == 0:
            traffic_label.configure(image=traffic_images[0])
        else:
            traffic_label.configure(image=traffic_images[2])
            last_red_time = time.time()

        # 무단횡단
        if now - ped_alert_start < 3:
            pedestrian_label.config(text=f"무단횡단: 발생", fg="red")
        else:
            pedestrian_label.config(text=f"무단횡단: {pedestrian_texts[pedestrian_state]}",
                                    fg=pedestrian_colors[pedestrian_state])

        # 차량 흐름 텍스트
        vehicle_label.config(text=f"유동차량: {vehicle_texts[vehicle_state]}",
                             fg=vehicle_colors[vehicle_state])

        # 차량 흐름 이미지 (light / heavy)
        traffic_state_image_label.configure(image=traffic_state_images[vehicle_state])
        traffic_state_image_label.place(x=2100, y=40)   # 차량 모드 위치

    else:
        ped_signal_label.place(x=1400, y=camera_y + 30)
        violation_label.place(x=1800, y=camera_y+ 200, width = 700, height = 200)
        ped_vehicle_label.place(x=1800, y=camera_y+600, width = 700, height = 200)
        traffic_label.place_forget()
        pedestrian_label.place_forget()
        vehicle_label.place_forget()

        if traffic_state == 0:
            if ped_current_state == 0 and now - ped_last_change >= 2:
                ped_current_state = 1
                ped_last_change = now
        else:
            ped_current_state = 0
            ped_last_change = now

        ped_signal_label.configure(image=ped_images[ped_current_state])

        if now - vio_alert_start < 3:
            violation_label.config(text=f"신호 위반: O", fg="red")
        else:
            violation_label.config(text=f"신호 위반: {'O' if violation_state else 'X'}",
                                   fg=violation_colors[violation_state] if violation_state else "#7CFC00")

        ped_vehicle_label.config(text=f"유동차량: {vehicle_texts[vehicle_state]}",
                                 fg=vehicle_colors[vehicle_state])

        # 보행자 모드에서도 차량 흐름 이미지 업데이트
        traffic_state_image_label.configure(image=traffic_state_images[vehicle_state])
        traffic_state_image_label.place(x=1650, y=1050)   # 차량 모드 위치

    root.after(30, update_frame)

# -----------------------------
# 실행
# -----------------------------
update_frame()
root.mainloop()
cap.release()
