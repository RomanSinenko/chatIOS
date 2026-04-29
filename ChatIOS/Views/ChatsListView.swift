import SwiftUI

struct ChatsListView: View {
    // Имя пользователя приходит снаружи из ContentView.
    let userName: String
    
    // Действие выхода приходит снаружи, потому что состояние входа хранит ContentView.
    let onLogout: () -> Void
    
    var body: some View {
        List {
            Section {
                Text("Пока чатов нету")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Чаты")
        .toolbar{
            ToolbarItem(placement: .topBarLeading) {
                Button("Выйти") {
                    onLogout()
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                // Карандаш открывает экран контактов перед созданием/открытием чата.
                NavigationLink {
                    ContactsView()
                } label: {
                    Image(systemName: "square.and.pencil")
                }
            }
        }
    }
}

#Preview {
    ChatsListView(userName: "Roman"){
        print("Preview logout")
    }
}
