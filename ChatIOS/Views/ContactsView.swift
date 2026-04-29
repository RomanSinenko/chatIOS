import SwiftUI

struct ContactsView: View {
    var body: some View {
        // Здесь позже появится поиск пользователей и выбор контакта.
        List {
            Section {
                Text("Поиск")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Написать сообщение")
    }
}

#Preview {
    NavigationStack {
        ContactsView()
    }
}
