import SwiftUI

struct StartView: View {
    // MARK: - State

    @State private var phone = ""

    // MARK: - Input

    let onContinue: (String) -> Void
    let isLoading: Bool
    let errorMessage: String?

    // MARK: - Body

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            titleBlock
            phoneField
            errorText
            continueButton
            Spacer()
        }
        .padding()
    }

    // MARK: - Content

    private var titleBlock: some View {
        VStack(spacing: 12) {
            Text("PiChat")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Введите телефон, чтобы открыть чат")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var phoneField: some View {
        TextField("Введите телефон", text: $phone)
            .textFieldStyle(.roundedBorder)
            .keyboardType(.phonePad)
    }

    @ViewBuilder
    private var errorText: some View {
        if let errorMessage {
            Text(errorMessage)
                .font(.footnote)
                .foregroundStyle(.red)
        }
    }

    private var continueButton: some View {
        Button(isLoading ? "Загрузка..." : "Продолжить") {
            onContinue(trimmedPhone)
        }
        .buttonStyle(.borderedProminent)
        .disabled(isLoading || trimmedPhone.isEmpty)
    }

    // MARK: - Computed Properties

    private var trimmedPhone: String {
        phone.trimmingCharacters(in: .whitespacesAndNewlines)
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
