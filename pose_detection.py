import cv2
import mediapipe as mp
import numpy as np
from tensorflow.keras.models import load_model
import math
import UIKit
import Vision
import CoreML
import CreateML  # قد تحتاج إلى هذه المكتبة أيضاً

class PoseDetector:
    def __init__(self):
        self.mp_pose = mp.solutions.pose
        self.pose = self.mp_pose.Pose()
        self.mp_draw = mp.solutions.drawing_utils
        self.model = load_model('First.h5')  # تحميل النموذج المدرب
        self.counter = {'right': 0, 'left': 0}  # عداد لكل وضعية
        self.position = None
        
    def calculate_angle(self, point1, point2, point3):
        # حساب الزاوية بين ثلاث نقاط
        a = np.array([point1.x, point1.y])
        b = np.array([point2.x, point2.y])
        c = np.array([point3.x, point3.y])
        
        radians = np.arctan2(c[1] - b[1], c[0] - b[0]) - np.arctan2(a[1] - b[1], a[0] - b[0])
        angle = np.abs(radians * 180.0 / np.pi)
        if angle > 180:
            angle = 360 - angle
        return angle

    def detect_pose(self, frame):
        # تحويل الصورة إلى RGB
        image = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        results = self.pose.process(image)
        
        if results.pose_landmarks:
            # رسم نقاط الجسم
            self.mp_draw.draw_landmarks(frame, results.pose_landmarks, self.mp_pose.POSE_CONNECTIONS)
            
            # حساب زوايا الرقبة
            right_shoulder = results.pose_landmarks.landmark[self.mp_pose.PoseLandmark.RIGHT_SHOULDER]
            left_shoulder = results.pose_landmarks.landmark[self.mp_pose.PoseLandmark.LEFT_SHOULDER]
            nose = results.pose_landmarks.landmark[self.mp_pose.PoseLandmark.NOSE]
            
            # حساب الزوايا
            neck_angle = self.calculate_angle(right_shoulder, nose, left_shoulder)
            
            # تحليل الوضعية باستخدام النموذج
            pose_data = np.array([[neck_angle]])  # تجهيز البيانات للنموذج
            prediction = self.model.predict(pose_data)
            
            # تحديد الوضعية
            if prediction[0][0] > 0.5:  # يمين
                self.position = 'right'
                self.counter['right'] += 1
            elif prediction[0][1] > 0.5:  # يسار
                self.position = 'left'
                self.counter['left'] += 1
            
            # كتابة النتائج على الإطار
            cv2.putText(frame, f"Position: {self.position}", (10, 30), 
                       cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)
            cv2.putText(frame, f"Right Count: {self.counter['right']}", (10, 70), 
                       cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)
            cv2.putText(frame, f"Left Count: {self.counter['left']}", (10, 110), 
                       cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)
            
        return frame

def main():
    cap = cv2.VideoCapture(0)
    detector = PoseDetector()
    
    while True:
        ret, frame = cap.read()
        if not ret:
            break
            
        frame = detector.detect_pose(frame)
        cv2.imshow('Pose Detection', frame)
        
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break
    
    cap.release()
    cv2.destroyAllWindows()

if __name__ == "__main__":
    main() 