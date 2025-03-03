import CoreML
import CreateML

func createTestModel() {
    let modelParameters = MLModelConfiguration()
    
    // إنشاء نموذج بسيط للاختبار
    let builder = MLModelBuilder(configuration: modelParameters)
    
    // إضافة المدخلات
    let inputDescription = MLModelDescription.Input(name: "angle", type: .double)
    builder.addInput(inputDescription)
    
    // إضافة المخرجات
    let outputDescription = MLModelDescription.Output(name: "prediction", type: .dictionary)
    builder.addOutput(outputDescription)
    
    // حفظ النموذج
    do {
        let modelURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("First.mlmodel")
        try builder.build().write(to: modelURL)
        print("تم إنشاء نموذج اختباري في: \(modelURL.path)")
    } catch {
        print("خطأ في إنشاء النموذج: \(error)")
    }
} 