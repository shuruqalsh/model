import UIKit
import AVFoundation
import Vision
import CoreML
import simd

class ViewController: UIViewController {
    
    @IBOutlet weak var previewView: UIView!
    
    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var detectionRequests = [VNRequest]()
    private var poseCounter = ["THW NECK Right": 0, "THW NECK Left": 0]
    private var model: MLModel! // سيتم تحميل نموذجك هنا
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        loadModel()
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoDeviceInput: AVCaptureDeviceInput
        
        do {
            videoDeviceInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }
        
        if (captureSession?.canAddInput(videoDeviceInput) == true) {
            captureSession?.addInput(videoDeviceInput)
        } else {
            return
        }
        
        let videoDataOutput = AVCaptureVideoDataOutput()
        if (captureSession?.canAddOutput(videoDataOutput) == true) {
            captureSession?.addOutput(videoDataOutput)
            
            videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sample buffer delegate"))
        } else {
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        previewLayer.frame = previewView.bounds
        previewLayer.videoGravity = .resizeAspectFill
        previewView.layer.addSublayer(previewLayer)
        
        captureSession?.startRunning()
    }
    
    private func loadModel() {
        // تحميل نموذجك المدرب
        guard let mlModel = try? First(configuration: MLModelConfiguration()).model else {
            fatalError("Could not load model")
        }
        
        model = mlModel
    }
    
    private func comparePose(predictedCoordinates: [simd_float3]) {
        // مقارنة الإحداثيات المتوقعة مع إحداثيات النموذج المدرب
        let threshold: Float = 0.05 // تحديد العتبة للمقارنة
        
        // مثال للمقارنة باستخدام إحداثيات النموذج المدرب
        // لنفترض أن النموذج المدرب يتوقع إحداثيات معينة، وسنقوم بمقارنة هذه الإحداثيات:
        let expectedPoseRight: [simd_float3] = [
            simd_float3(0.5, 0.6, 0.0), // مثال للإحداثيات
            simd_float3(0.4, 0.7, 0.1)
        ]
        
        let expectedPoseLeft: [simd_float3] = [
            simd_float3(0.5, 0.7, 0.0),
            simd_float3(0.6, 0.6, 0.1)
        ]
        
        var rightCount = 0
        var leftCount = 0
        
        // مقارنة الإحداثيات للتأكد من الوضعية
        for (index, coordinate) in predictedCoordinates.enumerated() {
            if simd_distance(coordinate, expectedPoseRight[index]) < threshold {
                rightCount += 1
            }
            if simd_distance(coordinate, expectedPoseLeft[index]) < threshold {
                leftCount += 1
            }
        }
        
        // زيادة العداد بناءً على الوضعية التي تم تحديدها
        if rightCount > 0 {
            poseCounter["THW NECK Right"]! += 1
        } else if leftCount > 0 {
            poseCounter["THW NECK Left"]! += 1
        }
    }
    
    private func updateUI() {
        // عرض النتائج على الشاشة
        print("THW NECK Right: \(poseCounter["THW NECK Right"] ?? 0)")
        print("THW NECK Left: \(poseCounter["THW NECK Left"] ?? 0)")
    }
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // هنا، سنقوم باستخدام Vision أو MediaPipe لاستخراج إحداثيات الجسم.
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        
        // معالجة الصورة لاكتشاف النقاط
        do {
            try requestHandler.perform(detectionRequests)
            
            // في هذه الخطوة، يمكنك تمرير إحداثيات الجسم التي تم استخراجها إلى النموذج المدرب
            // على سبيل المثال، قم بتعبئة [simd_float3] بالإحداثيات المكتشفة.
            let detectedCoordinates: [simd_float3] = [
                simd_float3(0.5, 0.6, 0.0), // مثال للإحداثيات
                simd_float3(0.4, 0.7, 0.1)
            ]
            
            // مقارنة الإحداثيات المكتشفة مع الإحداثيات المتوقعة
            comparePose(predictedCoordinates: detectedCoordinates)
        } catch {
            print("Failed to perform classification: \(error.localizedDescription)")
        }
    }
}
