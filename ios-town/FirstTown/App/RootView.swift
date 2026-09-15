import SwiftUI

struct RootView: View {
    @State private var town = Town.launch()

    var body: some View {
        PlayView(town: town)
    }
}
