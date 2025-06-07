import SwiftUI

struct VScrollFormSections: View {
    
    @State private var currentPage = 0
    
    var body: some View {
        
//        Form {
            Section {
                TextField("Zhopa", text: .constant("Zhopa"))
            } header: {
                Text("Zhopa")
            }
            
//            ZStack {
            ScrollView(.vertical) {
                Section {
                    TextField("Name", text: .constant("Vasya"))
                } header: {
                    Text("Section 1")
                }
            }
//            }
            
            
//            TabView(selection: $currentPage) {
//                Section {
//                    
//                } header: {
//                    Text("Zhopa")
//                }
//            }
//            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
//            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
//        }
        
    }
    
}

struct Section1: View {
    var body: some View {
    }
}

#Preview {
    VScrollFormSections()
    //        .modelContainer(for: Item.self, inMemory: true)
}
