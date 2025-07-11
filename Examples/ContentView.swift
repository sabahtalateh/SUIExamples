import SwiftUI
import SwiftData

enum Destination {
    case VScrollFormSections
    case Shaders
    case GradientSubtractShaders
    case CubeMetal
    case SphereMetal
    case Blending
}

struct ContentView: View {
    
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        
        NavigationStack(path: $navigationPath) {
            List {
                NavigationLink(
                    "Vertical Scroll of Form Sections (Not Working)",
                    value: Destination.VScrollFormSections
                )
                NavigationLink(
                    "Shaders",
                    value: Destination.Shaders
                )
                NavigationLink(
                    "Gradient Subtract Shaders",
                    value: Destination.GradientSubtractShaders
                )
                NavigationLink(
                    "Cube. Metal",
                    value: Destination.CubeMetal
                )
                NavigationLink(
                    "Sphere. Metal",
                    value: Destination.SphereMetal
                )
            }
            .navigationTitle("SwiftUI Examples")
            .navigationDestination(for: Destination.self) { destination in
                switch destination {
                case .VScrollFormSections: VScrollFormSectionsView()
                case .Shaders:
                    ShadersView()
                case .GradientSubtractShaders: GradientSubtractView()
                case .CubeMetal:
                    MetalKitCubeView()
                case .SphereMetal: MetalKitSphereView()
                case .Blending:
                    BlendingView()
                }
            }
            .onAppear {
                // Auto open some example
//                navigationPath.append(Destination.SphereMetal)
            }
        }
    }
}

#Preview {
    ContentView()
    //.modelContainer(for: Item.self, inMemory: true)
}
