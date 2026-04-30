import SwiftUI

struct ContactsView: View {
    
    // Временные контакты для проверки flow без backend.
    private let contacts = [
        Contact(id: 1, name: "Alena"),
        Contact(id: 2, name: "Stepa"),
        Contact(id: 3, name: "Roman"),
        Contact(id: 4, name: "Milo")
    ]
    
    var body: some View {
        List {
            Section {
                // Каждая строка списка открывает чат с выбранным контактом.
                ForEach(contacts) { contact in
                    NavigationLink {
                        ChatView(contact: contact)
                    } label: {
                        Text(contact.name)
                    }
                }
            }
            .navigationTitle("Написать сообщение")
        }
    }
}
#Preview {
    NavigationStack {
        ContactsView()
    }
}
