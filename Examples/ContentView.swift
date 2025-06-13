import SwiftUI
import SwiftData

enum Destination {
    case VScrollFormSections
    case Shaders
    case GradientSubtractShaders
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
            }
            .navigationTitle("SwiftUI Examples")
            .navigationDestination(for: Destination.self) { destination in
                switch destination {
                case .VScrollFormSections: VScrollFormSectionsView()
                case .Shaders: ShadersView()
                case .GradientSubtractShaders: GradientSubtractView()
                }
            }
            .onAppear {
                // Auto open some example
                // navigationPath.append(Destination.VScrollFormSections)
            }
        }
    }
}

#Preview {
    ContentView()
        //.modelContainer(for: Item.self, inMemory: true)
}
