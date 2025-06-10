import cv2
import numpy as np
from ultralytics import YOLO
import os
import math

# Configuración del modelo - MODIFICA ESTA RUTA CON LA UBICACIÓN DE TU MODELO
MODEL_PATH = "models/yolov8n.pt"  # Ajusta según tu configuración

# Variables globales para almacenar los puntos de la línea de 20 metros
points = []
line_defined = False

def mouse_callback(event, x, y, flags, param):
    """Captura los clics del mouse para definir la línea de 20 metros."""
    global points, line_defined
    if event == cv2.EVENT_LBUTTONDOWN and not line_defined:
        if len(points) < 2:
            points.append((x, y))
            print(f"Punto {len(points)} seleccionado: ({x}, {y})")
        if len(points) == 2:
            line_defined = True
            print("Línea de 20 metros definida.")

class CarSpaceDetector:
    def __init__(self, model_path, street_length_meters=20, min_parking_space=4.0):
        print(f"Cargando modelo YOLOv8 desde: {model_path}")
        self.model = YOLO(model_path)
        self.street_length_meters = street_length_meters
        self.min_parking_space = min_parking_space  # Umbral mínimo para espacio útil (metros)
        self.vehicle_classes = [2]  # Solo autos (clase 2 en COCO)
        self.class_names = {2: 'car'}
        self.pixels_per_meter = None  # Se calculará con la línea definida por el usuario
    
    def set_pixels_per_meter(self, point1, point2):
        """Calcula la relación píxeles por metro basada en la línea de 20 metros."""
        distance_pixels = math.sqrt((point2[0] - point1[0])**2 + (point2[1] - point1[1])**2)
        self.pixels_per_meter = distance_pixels / 20  # 20 metros
    
    def detect_vehicles(self, frame):
        """Detecta autos en el frame usando YOLOv8."""
        results = self.model(frame)
        cars = []
        for result in results:
            boxes = result.boxes
            if boxes is not None:
                for box in boxes:
                    cls = int(box.cls[0])
                    conf = float(box.conf[0])
                    if cls in self.vehicle_classes and conf > 0.5:
                        x1, y1, x2, y2 = box.xyxy[0].cpu().numpy()
                        car_info = {
                            'class': cls,
                            'class_name': self.class_names[cls],
                            'confidence': conf,
                            'bbox': [int(x1), int(y1), int(x2), int(y2)],
                            'center_x': int((x1 + x2) / 2),
                            'center_y': int((y1 + y2) / 2),
                            'width': int(x2 - x1),
                            'height': int(y2 - y1)
                        }
                        cars.append(car_info)
        return cars
    
    def calculate_occupied_space(self, cars):
        """Calcula el espacio ocupado por los autos, considerando superposiciones."""
        if not cars or not self.pixels_per_meter:
            return 0
        cars_sorted = sorted(cars, key=lambda v: v['center_x'])
        merged_boxes = []
        current_box = cars_sorted[0]['bbox']
        for car in cars_sorted[1:]:
            x1, _, x2, _ = current_box
            next_x1, _, next_x2, _ = car['bbox']
            if next_x1 <= x2 + 10:  # Margen de 10 píxeles
                current_box[2] = max(x2, next_x2)
            else:
                merged_boxes.append(current_box)
                current_box = car['bbox']
        merged_boxes.append(current_box)
        occupied_pixels = sum(box[2] - box[0] for box in merged_boxes)
        occupied_meters = occupied_pixels / self.pixels_per_meter
        return min(occupied_meters, self.street_length_meters)
    
    def calculate_available_space(self, cars, frame_width):
        """Calcula el espacio disponible, considerando solo segmentos >= min_parking_space."""
        if not cars or not self.pixels_per_meter:
            return self.street_length_meters, [(0, frame_width, self.street_length_meters)]
        
        cars_sorted = sorted(cars, key=lambda v: v['center_x'])
        merged_boxes = []
        current_box = cars_sorted[0]['bbox']
        for car in cars_sorted[1:]:
            x1, _, x2, _ = current_box
            next_x1, _, next_x2, _ = car['bbox']
            if next_x1 <= x2 + 10:
                current_box[2] = max(x2, next_x2)
            else:
                merged_boxes.append(current_box)
                current_box = car['bbox']
        merged_boxes.append(current_box)
        
        available_segments = []
        start_x = 0
        for box in merged_boxes:
            x1, _, x2, _ = box
            gap_pixels = x1 - start_x
            gap_meters = gap_pixels / self.pixels_per_meter
            if gap_meters >= self.min_parking_space:
                available_segments.append((start_x, x1, gap_meters))
            start_x = x2
        
        # Espacio al final de la calle
        gap_pixels = frame_width - start_x
        gap_meters = gap_pixels / self.pixels_per_meter
        if gap_meters >= self.min_parking_space:
            available_segments.append((start_x, frame_width, gap_meters))
        
        total_available = sum(segment[2] for segment in available_segments)
        return total_available, available_segments
    
    def draw_reference_line(self, frame):
        """Dibuja la línea de 20 metros definida por el usuario."""
        if len(points) == 2:
            cv2.line(frame, points[0], points[1], (0, 0, 0), 5)
            mid_x = (points[0][0] + points[1][0]) // 2
            mid_y = (points[0][1] + points[1][1]) // 2
            cv2.putText(frame, "20 metros", (mid_x, mid_y - 15), 
                        cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 0, 0), 2)
    
    def draw_detections(self, frame, cars):
        """Dibuja las cajas delimitadoras de los autos detectados."""
        for car in cars:
            x1, y1, x2, y2 = car['bbox']
            color = (0, 255, 0)
            cv2.rectangle(frame, (x1, y1), (x2, y2), color, 2)
            label = f"Auto: {car['confidence']:.2f} | Pos: ({car['center_x']}, {car['center_y']})"
            cv2.putText(frame, label, (x1, y1-10), cv2.FONT_HERSHEY_SIMPLEX, 
                        0.5, color, 2)
        return frame
    
    def draw_available_segments(self, frame, available_segments):
        """Dibuja los segmentos de espacio disponible válidos."""
        for start_x, end_x, length in available_segments:
            y_pos = frame.shape[0] - 20
            cv2.line(frame, (int(start_x), y_pos), (int(end_x), y_pos), (255, 0, 0), 3)
            cv2.putText(frame, f"{length:.2f}m", (int((start_x + end_x)/2), y_pos - 10), 
                        cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 0, 0), 2)
    
    def process_frame(self, frame):
        """Procesa un frame, dibujando detecciones, línea de referencia y estadísticas."""
        global line_defined
        frame_copy = frame.copy()
        
        # Si la línea no está definida, mostrar mensaje y devolver frame sin procesar
        if not line_defined:
            cv2.putText(frame_copy, "Haz clic en 2 puntos para definir la linea de 20m", 
                        (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)
            return frame_copy, 0, 0
        
        # Calcular píxeles por metro si no está definido
        if len(points) == 2 and self.pixels_per_meter is None:
            self.set_pixels_per_meter(points[0], points[1])
        
        # Detectar autos
        cars = self.detect_vehicles(frame_copy)
        frame_width = frame_copy.shape[1]
        
        # Dibujar detecciones y línea de referencia
        frame_with_detections = self.draw_detections(frame_copy, cars)
        self.draw_reference_line(frame_with_detections)
        
        # Calcular espacio disponible y ocupado
        available_space, available_segments = self.calculate_available_space(cars, frame_width)
        occupied_space = self.street_length_meters - available_space
        
        # Dibujar segmentos disponibles
        self.draw_available_segments(frame_with_detections, available_segments)
        
        # Mostrar estadísticas en pantalla
        info_text = [
            f"Autos detectados: {len(cars)}",
            f"Espacio ocupado: {occupied_space:.2f}m",
            f"Espacio disponible: {available_space:.2f}m",
            f"Espacios validos: {len(available_segments)}",
            f"Longitud total: {self.street_length_meters}m",
            f"Pixeles por metro: {self.pixels_per_meter:.2f}"
        ]
        
        y_offset = 20
        for i, text in enumerate(info_text):
            # Dibujar texto con fondo blanco para mejor legibilidad
            cv2.putText(frame_with_detections, text, (10, y_offset + i*25), 
                        cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 255, 255), 4)
            cv2.putText(frame_with_detections, text, (10, y_offset + i*25), 
                        cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 0), 2)
        
        return frame_with_detections, available_space, len(cars)

def main():
    global line_defined, points
    if not os.path.exists(MODEL_PATH):
        print(f"Error: No se encontró el modelo en la ruta: {MODEL_PATH}")
        return
    
    print(f"Cargando modelo desde: {MODEL_PATH}")
    detector = CarSpaceDetector(model_path=MODEL_PATH, street_length_meters=20)
    
    print("Selecciona la fuente de video:")
    print("1. Cámara web (0)")
    print("2. Archivo de video")
    print("3. Imagen estática")
    choice = input("Ingresa tu opción (1-3): ")
    
    cv2.namedWindow("Detector de Autos - Espacio Disponible")
    cv2.setMouseCallback("Detector de Autos - Espacio Disponible", mouse_callback)
    
    if choice == '1':
        print("Intentando abrir cámara web...")
        cap = cv2.VideoCapture(0)
        if not cap.isOpened():
            print("Error: No se pudo abrir la cámara web")
            return
        print("Cámara web conectada exitosamente")
        process_video(detector, cap)
    
    elif choice == '2':
        video_path = input("Ingresa la ruta del archivo de video: ")
        print(f"Intentando abrir video: {video_path}")
        cap = cv2.VideoCapture(video_path)
        if not cap.isOpened():
            print("Error: No se pudo abrir el archivo de video")
            return
        print("Video cargado exitosamente")
        process_video(detector, cap)
    
    elif choice == '3':
        image_path = input("Ingresa la ruta de la imagen: ")
        print(f"Intentando cargar imagen: {image_path}")
        image = cv2.imread(image_path)
        if image is None:
            print("Error: No se pudo cargar la imagen")
            return
        print("Imagen cargada exitosamente")
        process_image(detector, image)
    
    else:
        print("Opción no válida")

def process_video(detector, cap):
    global line_defined, points
    if not cap.isOpened():
        print("Error: No se pudo abrir la fuente de video")
        return
    
    print("Presiona 'q' para salir, 'r' para reiniciar la selección de puntos")
    frame_count = 0
    
    while True:
        ret, frame = cap.read()
        if not ret or frame is None or frame.size == 0:
            print("Error: No se pudo leer el frame o fin del video")
            break
        
        frame_count += 1
        try:
            processed_frame, available_space, car_count = detector.process_frame(frame)
            if processed_frame is None or processed_frame.size == 0:
                print("Frame procesado vacío, usando frame original")
                processed_frame = frame
            
            cv2.imshow("Detector de Autos - Espacio Disponible", processed_frame)
            
            if frame_count % 20 == 0 and line_defined:
                print(f"Frame {frame_count} | Autos: {car_count} | Espacio disponible: {available_space:.2f}m")
        
        except Exception as e:
            print(f"Error procesando frame {frame_count}: {e}")
            continue
        
        key = cv2.waitKey(1) & 0xFF
        if key == ord('q'):
            break
        elif key == ord('r'):
            points = []
            line_defined = False
            detector.pixels_per_meter = None  # Resetear para nueva línea
            print("Selección de puntos reiniciada.")
    
    print(f"Total de frames procesados: {frame_count}")
    cap.release()
    cv2.destroyAllWindows()

def process_image(detector, image):
    global line_defined, points
    print("Haz clic en dos puntos para definir la línea de 20 metros. Presiona 'q' para salir, 'r' para reiniciar.")
    
    while True:
        processed_image, available_space, car_count = detector.process_frame(image)
        cv2.imshow("Resultado - Detector de Autos", processed_image)
        
        if line_defined:
            print(f"Análisis completado:")
            print(f"Autos detectados: {car_count}")
            print(f"Espacio disponible: {available_space:.2f} metros")
            print(f"Espacio ocupado: {detector.street_length_meters - available_space:.2f} metros")
            print("Presiona cualquier tecla para cerrar")
            cv2.waitKey(0)
            break
        
        key = cv2.waitKey(1) & 0xFF
        if key == ord('q'):
            break
        elif key == ord('r'):
            points = []
            line_defined = False
            detector.pixels_per_meter = None  # Resetear para nueva línea
            print("Selección de puntos reiniciada.")
    
    cv2.destroyAllWindows()

if __name__ == "__main__":
    main()