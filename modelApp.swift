import SwiftUI
import SwiftData

@main
struct modelApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            PoseDetectionView()
        }
        .modelContainer(sharedModelContainer)
    }
}

struct PoseDetectionView: View {
    @StateObject private var poseDetector = PoseDetectorViewModel()
    
    var body: some View {
        VStack {
            CameraPreviewView(poseDetector: poseDetector)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            VStack {
                Text("الوضعية: \(poseDetector.currentPosition ?? "غير محددة")")
                    .font(.title)
                    .foregroundColor(.green)
                
                HStack {
                    Text("يمين: \(poseDetector.counter["right"] ?? 0)")
                        .padding()
                    Text("يسار: \(poseDetector.counter["left"] ?? 0)")
                        .padding()
                }
                .font(.title2)
                .foregroundColor(.green)
            }
            .padding()
        }
    }
}

struct CameraPreviewView: UIViewRepresentable {
    let poseDetector: PoseDetectorViewModel
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
    }
}

class PoseDetectorViewModel: ObservableObject {
    @Published var currentPosition: String?
    @Published var counter: [String: Int] = ["right": 0, "left": 0]
    private let detector = PoseDetector()
    
    func processFrame(_ image: UIImage) {
        detector.detectPose(in: image) { [weak self] position, counter in
            DispatchQueue.main.async {
                self?.currentPosition = position
                self?.counter = counter
            }
        }
    }
} 