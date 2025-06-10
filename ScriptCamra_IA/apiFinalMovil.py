import cv2
import numpy as np
import logging
import os
import time
import requests
from ultralytics import YOLO

# Configurar logging
logging.getLogger('ultralytics').setLevel(logging.ERROR)

# Cargar modelo YOLOv8s (small, más preciso que YOLOv8n)
model = YOLO('models/yolov8n.pt')

# Variables para la zona restringida
ZONE = {'x1': 100, 'y1': 300, 'x2': 550, 'y2': 350}  # Zona inicial por defecto

# Variables para la selección con mouse
drawing = False
temp_zone = None
ix, iy = -1, -1

# Función del mouse para seleccionar zona
def mouse_callback(event, x, y, flags, param):
    global ix, iy, drawing, temp_zone, ZONE
    
    if event == cv2.EVENT_LBUTTONDOWN:
        drawing = True
        ix, iy = x, y
        temp_zone = {'x1': x, 'y1': y, 'x2': x, 'y2': y}
    
    elif event == cv2.EVENT_MOUSEMOVE:
        if drawing:
            temp_zone['x2'] = x
            temp_zone['y2'] = y
    
    elif event == cv2.EVENT_LBUTTONUP:
        drawing = False
        # Asegurar que x1,y1 sea la esquina superior izquierda
        x1 = min(ix, x)
        y1 = min(iy, y)
        x2 = max(ix, x)
        y2 = max(iy, y)
        
        # Actualizar la zona solo si tiene un tamaño mínimo
        if abs(x2 - x1) > 20 and abs(y2 - y1) > 20:
            ZONE = {'x1': x1, 'y1': y1, 'x2': x2, 'y2': y2}
            print(f"Nueva zona establecida: {ZONE}")
        temp_zone = None

# Configurar captura de video desde la cámara de la PC
cap = cv2.VideoCapture(0)  # 0 para la cámara predeterminada
if not cap.isOpened():
    print("Error al abrir la cámara.")
    exit(1)

# Función para verificar si un punto está en la zona restringida
def punto_en_rect(x, y, z):
    return z['x1'] <= x <= z['x2'] and z['y1'] <= y <= z['y2']

# Configuración de la alerta visual
ALERT_W, ALERT_H = 400, 100
FONT = cv2.FONT_HERSHEY_SIMPLEX
FONT_SCALE = 1
FONT_THICKNESS = 2

# Variables para foto y POST
fotos_dir = 'fotos'
os.makedirs(fotos_dir, exist_ok=True)

# Configuración de la API
API_URL = 'http://192.168.43.11:8001/api/infractions/'

# Variables para el contador y temporizador
stable_count = None  # Valor estable del contador
stable_start = None  # Tiempo de inicio de la estabilidad
photo_taken = False  # Bandera para evitar múltiples POSTs

# Configurar callback del mouse para la ventana principal
cv2.namedWindow('Zona IP')
cv2.setMouseCallback('Zona IP', mouse_callback)

print("Detección de zona. Pulsa 'q' para salir.")
print("Haz clic y arrastra para seleccionar una nueva zona restringida.")
print("Presiona 'r' para resetear a la zona por defecto.")

while True:
    ret, frame = cap.read()
    if not ret:
        print("Error al leer el frame de la cámara.")
        break

    # Crear una copia del frame para dibujar
    display_frame = frame.copy()

    # Realizar detección con YOLO en el frame original
    results = model(frame, verbose=False, conf=0.5)[0]  # Umbral de confianza 0.5

    infraccion = False
    car_count = 0  # Contador de autos en la zona restringida

    for box, cls in zip(results.boxes, results.boxes.cls):
        if int(cls) != 2:  # Solo detectar "car"
            continue

        x1, y1, x2, y2 = map(int, box.xyxy[0])
        cx, cy = (x1 + x2) // 2, (y1 + y2) // 2

        if punto_en_rect(cx, cy, ZONE):
            infraccion = True
            car_count += 1
            color = (0, 0, 255)
        else:
            color = (0, 255, 0)

        cv2.rectangle(display_frame, (x1, y1), (x2, y2), color, 2)
        cv2.circle(display_frame, (cx, cy), 5, color, -1)

    # Dibujar la zona restringida actual
    cv2.rectangle(display_frame,
                  (ZONE['x1'], ZONE['y1']),
                  (ZONE['x2'], ZONE['y2']),
                  (255, 0, 0), 2)

    # Dibujar zona temporal mientras se está seleccionando
    if temp_zone is not None:
        cv2.rectangle(display_frame,
                      (temp_zone['x1'], temp_zone['y1']),
                      (temp_zone['x2'], temp_zone['y2']),
                      (0, 255, 255), 2)  # Amarillo para zona temporal

    # Mostrar el contador en la ventana principal
    count_text = f"Autos: {car_count}"
    cv2.putText(display_frame, count_text, (ZONE['x1'], ZONE['y1'] - 10),
                FONT, FONT_SCALE, (255, 255, 255), FONT_THICKNESS, cv2.LINE_AA)

    # Agregar instrucciones en pantalla
    instructions = [
        "Click y arrastra: Nueva zona",
        "R: Reset zona",
        "Q: Salir"
    ]
    for i, instruction in enumerate(instructions):
        cv2.putText(display_frame, instruction, (10, 30 + i * 25),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 255, 255), 1, cv2.LINE_AA)

    # Lógica para POST: cambio de contador y 3 segundos de estabilidad
    if stable_count is None or car_count != stable_count:
        # Reiniciar temporizador y bandera si el contador cambia
        stable_start = time.time()
        stable_count = car_count
        photo_taken = False
    elif not photo_taken and stable_start is not None and time.time() - stable_start >= 3:
        # Guardar foto
        timestamp = time.strftime("%Y%m%d_%H%M%S")
        filename = os.path.join(fotos_dir, f"infraccion_{timestamp}.jpg")
        cv2.imwrite(filename, frame)  # Guardar frame original sin anotaciones
        print(f"[Foto guardada] {filename}")

        # Enviar POST con mensaje e imagen
        payload = {'mensaje': f'{car_count} auto{"s" if car_count > 1 else ""} {"infractores" if car_count > 0 else "en la plaza"}'}
        try:
            with open(filename, 'rb') as img_file:
                files = {'image': (os.path.basename(filename), img_file, 'image/jpeg')}
                resp = requests.post(API_URL, data=payload, files=files, timeout=5)
                print(f"[API] {resp.status_code}: {resp.text}")
        except FileNotFoundError:
            print(f"[ERROR] No se encontró la imagen: {filename}")
        except Exception as e:
            print(f"[ERROR] al enviar POST: {e}")

        photo_taken = True

    # Mostrar ventana de alerta
    alert_bg = np.zeros((ALERT_H, ALERT_W, 3), dtype=np.uint8)
    if car_count > 0:
        alert_bg[:] = (0, 0, 255)
        text = f"Vehiculo en zona ({car_count} autos)"
    else:
        alert_bg[:] = (0, 255, 0)
        text = "Zona libre"
    (tw, th), _ = cv2.getTextSize(text, FONT, FONT_SCALE, FONT_THICKNESS)
    tx = (ALERT_W - tw) // 2
    ty = (ALERT_H + th) // 2
    cv2.putText(alert_bg, text, (tx, ty), FONT, FONT_SCALE, (255, 255, 255), FONT_THICKNESS, cv2.LINE_AA)
    cv2.imshow('Alerta', alert_bg)

    # Mostrar frame de la cámara
    cv2.imshow('Zona IP', display_frame)
    
    # Manejar teclas
    key = cv2.waitKey(1) & 0xFF
    if key == ord('q'):
        break
    elif key == ord('r'):
        # Resetear a zona por defecto
        ZONE = {'x1': 100, 'y1': 300, 'x2': 550, 'y2': 350}
        print(f"Zona reseteada a valores por defecto: {ZONE}")

# Liberar recursos
cap.release()
cv2.destroyAllWindows()