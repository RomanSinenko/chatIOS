import SwiftUI

struct NewMessageView: View {
    // MARK: - Input

    let currentUserID: Int
    let sessionToken: String

    // MARK: - Local Data

    private let contacts: [Contact] = []

    // MARK: - State

    @State private var searchText = ""
    @State private var globalSearchResults: [UserSearchResult] = []
    @State private var isSearchingGlobally = false
    @State private var searchErrorMessage: String?
    @State private var isOpeningChat = false
    @State private var openChatErrorMessage: String?
    @State private var selectedChat: ChatScreenContext?

    // MARK: - Dependencies

    private let apiClient = APIClient()

    // MARK: - Computed Properties

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

    // MARK: - Body

    var body: some View {
        List {
            searchFieldSection
            contactsSection
            globalSearchSection
            emptyResultsSection
        }
        .onChange(of: searchText) {
            resetSearchState()
            runGlobalSearch()
        }
        .navigationDestination(item: $selectedChat) { chatContext in
            ChatView(
                chatContext: chatContext,
                sessionToken: sessionToken
            )
        }
        .navigationTitle("Написать сообщение")
    }

    // MARK: - Sections

    private var searchFieldSection: some View {
        Section {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Поиск", text: $searchText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
        }
    }

    @ViewBuilder
    private var contactsSection: some View {
        if !isSearching || hasContactResults {
            Section("Контакты") {
                ForEach(visibleContacts) { contact in
                    Text(contact.name)
                }
            }
        }
    }

    @ViewBuilder
    private var globalSearchSection: some View {
        if isSearchingGlobally || searchErrorMessage != nil || openChatErrorMessage != nil || hasGlobalResults {
            Section("Глобальный поиск") {
                globalSearchContent
            }
        }
    }

    @ViewBuilder
    private var globalSearchContent: some View {
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
                globalUserButton(user)
            }
        }
    }

    @ViewBuilder
    private var emptyResultsSection: some View {
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

    private func globalUserButton(_ user: UserSearchResult) -> some View {
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

    // MARK: - Actions

    // Сбрасывает результаты и ошибки перед новым поиском.
    private func resetSearchState() {
        globalSearchResults = []
        searchErrorMessage = nil
        openChatErrorMessage = nil
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
                let users = try await apiClient.searchUsers(
                    query: query,
                    sessionToken: sessionToken
                )
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
                    peerUserID: user.id,
                    sessionToken: sessionToken
                )

                print("Opened private chat \(chat.id)")

                selectedChat = ChatScreenContext(
                    id: chat.id,
                    currentUserID: currentUserID,
                    peerUserID: chat.peerUserID,
                    displayName: user.displayName ?? user.username
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
        NewMessageView(
            currentUserID: 1,
            sessionToken: "preview-token"
        )
    }
}
