import SwiftUI

struct ChatView: View {
    // Контакт приходит с экрана контактов.
    let contact: Contact
    
    // Текст, который пользователь вводит в нижнем поле.
    @State private var messageText = ""
    
    // Временные сообщения для проверки внешнего вида чата без backend.
    private let messages = [
        ChatMessage(id: 1, text: "Hello!", isMine: false),
        ChatMessage(id: 2, text: "Hello, how ara you!", isMine: true),
        ChatMessage(id: 3, text: "I'am fine! and you?!", isMine: false)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            List {
                ForEach(messages) { message in
                    HStack {
                        // Spacer перед текстом прижимает моё сообщение вправо.
                        if message.isMine {
                            Spacer()
                        }
                        
                        Text(message.text)
                            .padding(10)
                            .background(message.isMine ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundStyle(message.isMine ? .white : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        // Spacer после текста оставляет сообщение собеседника слева.
                        if !message.isMine {
                            Spacer()
                        }
                    }
                    .listRowSeparator(.hidden)
                }
            }
            
            // Нижняя панель ввода: поле сообщения + кнопка отправки.
            HStack {
                TextField("Сообщение", text: $messageText)
                    .textFieldStyle(.roundedBorder)
                
                Button {
                    print("Send message: \(messageText)")
                    messageText = ""
                } label: {
                    Image(systemName: "paperplane.fill")
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
        }
        .navigationTitle(contact.name)
    }
}

#Preview {
    NavigationStack {
        ChatView(contact: Contact(id: 1, name: "Alena"))
    }
}
