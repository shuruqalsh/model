//
//  modelApp.swift
//  model
//
//  Created by shuruq alshammari on 03/09/1446 AH.
//

import SwiftUI
import AVFoundation
import Vision
import CoreML
import simd

@main
struct modelApp: App {
    var body: some Scene {
        WindowGroup {
            // دمج ViewController داخل SwiftUI باستخدام UIViewControllerRepresentable
            ViewControllerWrapper()
        }
    }
}

// تحويل ViewController إلى SwiftUI باستخدام UIViewControllerRepresentable
struct ViewControllerWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> ViewController {
        return ViewController() // تحميل ViewController
    }
    
    func updateUIViewController(_ uiViewController: ViewController, context: Context) {
        // أي تحديثات إضافية لـ ViewController إذا كانت مطلوبة
    }
}
