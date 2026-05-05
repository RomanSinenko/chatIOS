import SwiftUI

struct NewMessageView: View {
    // ID текущего пользователя
    let currentUserID: Int
    
    // Контакты приложения пока не подключены, поэтому список пустой.
    private let contacts: [Contact] = []
    
    // Текст, который пользователь вводит в поле поиска.
    @State private var searchText = ""
    // Результаты глобального поиска по точному username.
    @State private var globalSearchResults: [UserSearchResult] = []
    // true, пока ждём ответ backend по глобальному поиску.
    @State private var isSearchingGlobally = false
    // Текст ошибки глобального поиска.
    @State private var searchErrorMessage: String?
    // true, пока backend создает или возвращает private chat.
    @State private var isOpeningChat = false
    // Текст ошибки открытия private chat.
    @State private var openChatErrorMessage: String?
    // Контакт, для которого нужно открыть экран чата после успешного ответа backend.
    @State private var selectedContact: Contact?

    
    private let apiClient = APIClient()
    
    
    // Контакты, которые нужно показать с учетом текста поиска.
    private var visibleContacts: [Contact] {
        if searchText.isEmpty {
            return contacts
        }
        
        return contacts.filter { contact in
            contact.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    
    private var isSearching: Bool {
        !searchText.isEmpty
    }
    
    private var hasContactResults: Bool {
        !visibleContacts.isEmpty
    }
    
    private var hasGlobalResults: Bool {
        !globalSearchResults.isEmpty
    }
    
    private var hasAnyResults: Bool {
        hasContactResults || hasGlobalResults
    }
    
    
    var body: some View {
        List {
            Section {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    
                    TextField("Поиск", text: $searchText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            }
            
            if !isSearching || hasContactResults {
                Section("Контакты") {
                    // Каждая строка списка открывает чат с выбранным контактом.
                    ForEach(visibleContacts) { contact in
                        NavigationLink {
                            ChatView(contact: contact)
                        } label: {
                            Text(contact.name)
                        }
                    }
                }
            }
            
            if isSearchingGlobally || searchErrorMessage != nil || openChatErrorMessage != nil || hasGlobalResults {
                Section("Глобальный поиск") {
                    if isSearchingGlobally {
                        Text("Ищем пользователя")
                            .foregroundStyle(.secondary)
                    } else if let searchErrorMessage {
                        Text(searchErrorMessage)
                            .foregroundStyle(.red)
                    } else if let openChatErrorMessage {
                        Text(openChatErrorMessage)
                            .foregroundStyle(.red)
                    } else {
                        ForEach(globalSearchResults) { user in
                            Button {
                                openPrivateChat(with: user)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(user.displayName ?? user.username)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    
                                    Text("@\(user.username)")
                                        .font(.footnote)
                                        .foregroundStyle(.blue)
                                }
                            }
                            .buttonStyle(.plain)
                            .disabled(isOpeningChat)
                        }
                    }
                }
            }
            if isSearching && !isSearchingGlobally && searchErrorMessage == nil && !hasAnyResults {
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Нет результатов")
                        
                        Text("По запросу '\(searchText)' ничего не найдено")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .onChange(of: searchText) {
            globalSearchResults = []
            searchErrorMessage = nil
            openChatErrorMessage = nil
            runGlobalSearch()
        }
        .navigationDestination(item: $selectedContact) { contact in
            ChatView(contact: contact)
        }
        .navigationTitle("Написать сообщение")
    }
    
    // Запускает точный глобальный поиск пользователя по username.
    private func runGlobalSearch() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if query.isEmpty {
            globalSearchResults = []
            searchErrorMessage = nil
            return
        }
        
        Task {
            isSearchingGlobally = true
            searchErrorMessage = nil
            
            do {
                let users = try await apiClient.searchUsers(query: query)
                globalSearchResults = users.filter { user in
                    user.id != currentUserID
                }
            } catch {
                searchErrorMessage = "Не удалось выполнить запрос"
                print("Global search failed \(error)")
            }
            
            isSearchingGlobally = false
        }
    }
    
    // Создает или получает private chat с выбранным пользователем.
    private func openPrivateChat(with user: UserSearchResult) {
        print("Tapped global user \(user.id), current user \(currentUserID)")
        openChatErrorMessage = nil
        
        Task {
            isOpeningChat = true
            
            do {
                let chat = try await apiClient.getOrCreatePrivateChat(
                    currentUserID: currentUserID,
                    peerUserID: user.id
                )
                
                print("Opened private chat \(chat.id)")
                
                selectedContact = Contact(
                    id: user.id,
                    name: user.displayName ?? user.username
                )
            } catch {
                openChatErrorMessage = "Не удалось открыть чат"
                print("Open private chat failed \(error)")
            }
            
            isOpeningChat = false
        }
    }
}
#Preview {
    NavigationStack {
        NewMessageView(currentUserID: 1)
    }
}
