import UIKit
import Vision
import CoreML

class PoseDetector {
    private var model: MLModel?
    private var counter: [String: Int] = ["right": 0, "left": 0]
    private var currentPosition: String?
    
    init() {
        setupModel()
    }
    
    private func setupModel() {
        if let modelURL = Bundle.main.url(forResource: "First", withExtension: "mlmodel") {
            do {
                self.model = try MLModel(contentsOf: modelURL)
                print("تم تحميل النموذج بنجاح")
            } catch {
                print("خطأ في تحميل النموذج: \(error.localizedDescription)")
                setupDefaultBehavior()
            }
        } else {
            print("لم يتم العثور على ملف النموذج")
            setupDefaultBehavior()
        }
    }
    
    private func setupDefaultBehavior() {
        print("استخدام السلوك الافتراضي")
    }
    
    func calculateAngle(point1: CGPoint, point2: CGPoint, point3: CGPoint) -> Double {
        let v1 = CGPoint(x: point1.x - point2.x, y: point1.y - point2.y)
        let v2 = CGPoint(x: point3.x - point2.x, y: point3.y - point2.y)
        
        let angle = atan2(v2.y, v2.x) - atan2(v1.y, v1.x)
        let degrees = abs(angle * 180 / .pi)
        return degrees > 180 ? 360 - degrees : degrees
    }
    
    func detectPose(in image: UIImage, completion: @escaping (String?, [String: Int]) -> Void) {
        guard let cgImage = image.cgImage else { return }
        
        // إعداد طلب تحليل الوضعية
        let request = VNDetectHumanBodyPoseRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
            
            guard let observation = request.results?.first as? VNHumanBodyPoseObservation else {
                completion(nil, counter)
                return
            }
            
            // استخراج نقاط الجسم المطلوبة
            let points = try observation.recognizedPoints(.all)
            
            guard let rightShoulder = points[.rightShoulder]?.location,
                  let leftShoulder = points[.leftShoulder]?.location,
                  let nose = points[.nose]?.location else {
                completion(nil, counter)
                return
            }
            
            // تحويل النقاط إلى إحداثيات الشاشة
            let rightShoulderPoint = CGPoint(x: rightShoulder.x, y: 1 - rightShoulder.y)
            let leftShoulderPoint = CGPoint(x: leftShoulder.x, y: 1 - leftShoulder.y)
            let nosePoint = CGPoint(x: nose.x, y: 1 - nose.y)
            
            // حساب زاوية الرقبة
            let neckAngle = calculateAngle(point1: rightShoulderPoint, point2: nosePoint, point3: leftShoulderPoint)
            
            // تحليل الوضعية باستخدام النموذج
            let prediction = try makePrediction(angle: neckAngle)
            
            // تحديث العداد والوضعية الحالية
            if prediction.right > 0.5 {
                currentPosition = "right"
                counter["right"]? += 1
            } else if prediction.left > 0.5 {
                currentPosition = "left"
                counter["left"]? += 1
            }
            
            completion(currentPosition, counter)
            
        } catch {
            print("خطأ في تحليل الوضعية: \(error)")
            completion(nil, counter)
        }
    }
    
    private func makePrediction(angle: Double) throws -> (right: Double, left: Double) {
        guard let model = self.model else {
            // منطق بديل في حالة عدم وجود النموذج
            let right = angle < 90 ? 1.0 : 0.0
            let left = angle >= 90 ? 1.0 : 0.0
            return (right: right, left: left)
        }
        
        // إنشاء المدخلات للنموذج
        let input = try MLDictionaryFeatureProvider(dictionary: [
            "angle": MLFeatureValue(double: angle)
        ])
        
        // تنفيذ التنبؤ
        let output = try model.prediction(from: input)
        
        // استخراج النتائج - تعديل الأسماء حسب مخرجات النموذج المحول
        guard let rightProb = output.featureValue(for: "rightProbability")?.multiArrayValue?[0].doubleValue,
              let leftProb = output.featureValue(for: "leftProbability")?.multiArrayValue?[0].doubleValue else {
            throw NSError(domain: "PoseDetection", code: 1, userInfo: [NSLocalizedDescriptionKey: "فشل في استخراج النتائج"])
        }
        
        return (right: rightProb, left: leftProb)
    }
} 