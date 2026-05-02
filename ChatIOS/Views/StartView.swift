import SwiftUI

struct StartView: View {
    // Телефон, который пользователь вводит для временного dev-login.
    @State private var phone = ""
    
    // StartView отдаёт наружу телефон.
    // Сам экран не решает, что делать дальше.
    let onContinue: (String) -> Void
    
    // true, пока идёт запрос входа/регистрации.
    let isLoading: Bool
    
    // Текст ошибки, который нужно показать под полями ввода.
    let errorMessage: String?
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 12){
                Text("PiChat")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Введите телефон, чтобы открыть чат")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            TextField("Введите телефон", text: $phone)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.phonePad)
            
            // Показываем ошибку только если ContentView передал текст.
            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
            
            Button(isLoading ? "Загрузка..." : "Продолжить") {
                // Убираем пробелы по краям, чтобы не принимать пустой ввод из пробелов.
                let trimmedPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
                
                onContinue(trimmedPhone)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoading ||
                      phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            )
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    StartView(
        onContinue: { phone in
            print("Preview continue with phone: \(phone)")
        },
        isLoading: false,
        errorMessage: nil
    )
}

