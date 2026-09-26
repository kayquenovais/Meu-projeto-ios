import SwiftUI

struct ActivationResponse: Decodable {
    let ok: Bool?
    let message: String?
    let expires_at: String?
}

struct ContentView: View {
    @State private var key = ""
    @State private var status = ""
    @State private var loading = false

    // TROQUE pelo endereço público do seu servidor.
    private let apiBaseURL = "https://SEU-SERVIDOR.example"

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 22) {
                Image(systemName: "key.fill")
                    .font(.system(size: 54))
                    .foregroundStyle(.white)

                Text("Proxy System")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)

                Text("Ative sua chave")
                    .foregroundStyle(.gray)

                TextField("PROXY-SYSTEM-7DIA-XXXXXXXX", text: $key)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .padding()
                    .background(Color.white.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.white)

                Button {
                    Task { await activate() }
                } label: {
                    HStack {
                        if loading {
                            ProgressView().tint(.black)
                        }
                        Text(loading ? "Ativando..." : "ATIVAR")
                            .bold()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .foregroundStyle(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(loading || key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                if !status.isEmpty {
                    Text(status)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                }

                Spacer()
            }
            .padding(24)
        }
    }

    @MainActor
    private func activate() async {
        loading = true
        status = ""

        guard let url = URL(string: apiBaseURL + "/api/activate") else {
            status = "Configure o endereço do servidor no código."
            loading = false
            return
        }

        let deviceID = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        let payload = ["key": key.trimmingCharacters(in: .whitespacesAndNewlines),
                       "device_id": deviceID]

        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)

            let (data, response) = try await URLSession.shared.data(for: request)

            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                status = "Servidor respondeu HTTP \(http.statusCode)."
                loading = false
                return
            }

            let decoded = try JSONDecoder().decode(ActivationResponse.self, from: data)
            if decoded.ok == true {
                status = "Chave ativada.\nValidade: \(decoded.expires_at ?? "não informada")"
            } else {
                status = decoded.message ?? "Chave inválida."
            }
        } catch {
            status = "Erro de conexão: \(error.localizedDescription)"
        }

        loading = false
    }
}
