import SwiftUI

struct MenuView: View {
    var body: some View {
        List {
            Section("Day of") {
                Label("Vendors", systemImage: "person.3")
                Label("Photo book", systemImage: "book.closed")
                Label("Tasks & checklists", systemImage: "checklist")
            }
            Section("Coming soon") {
                Text("Vendors and photo book move here in Phase 2.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Menu")
    }
}
