import SwiftUI
import SwiftData

enum Destination {
    case VScrollFormSections
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
            }
            .navigationTitle("SwiftUI Examples")
            .navigationDestination(for: Destination.self) { destination in
                switch destination {
                case .VScrollFormSections: VScrollFormSections()
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
