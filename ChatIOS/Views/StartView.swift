import SwiftUI

struct StartView: View {
    // Локальный текст, который пользователь вводит в TextField.
    @State private var userName = ""
    
    // Действие, которое StartView вызывает при нажатии "Продолжить".
    // Сам экран не решает, куда идти дальше; он только отдаёт имя наружу.
    let onContinue: (String) -> Void
    
    // true, пока идёт запрос создания пользователя.
    let isLoading: Bool
    
    // Текст ошибки, который нужно показать под полем ввода.
    let errorMessage: String?
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 12){
                Text("PiChat")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Войдите по имени пользователя, что бы открыть чат")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            TextField("Имя пользователя", text: $userName)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            
            // Показываем ошибку только если ContentView передал текст.
            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
            
            Button(isLoading ? "Загрузка..." : "Продолжить") {
                // Убираем пробелы по краям, чтобы не принимать пустой ввод из пробелов.
                let trimmedUserName = userName.trimmingCharacters(in: .whitespacesAndNewlines)
                onContinue(trimmedUserName)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoading || userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    StartView(
        onContinue: { userName in
            print("Preview continue with user name: \(userName)")
        },
        isLoading: false,
        errorMessage: nil
    )
}

