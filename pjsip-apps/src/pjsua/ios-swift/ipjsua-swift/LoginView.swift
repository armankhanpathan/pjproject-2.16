//
//  LoginView.swift
//  ipjsua-swift
//
//  Created by Arman Pathan on 30/12/25.
//

import SwiftUI

struct LoginView: View {

    // MARK: - User Input
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var domain: String = "sip.linphone.org"

    // MARK: - UI State
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    // MARK: - Environment
    @EnvironmentObject var pjsipVars: PjsipVars
    @EnvironmentObject var appSession: AppSession

    var body: some View {
        VStack(spacing: 16) {

            Spacer()

            Text("SIP Login")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 24)

            TextField("SIP Username", text: $username)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .keyboardType(.asciiCapable)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            TextField("SIP Domain", text: $domain)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .keyboardType(.URL)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(Color.red)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
            }

            Button(action: login) {
                HStack {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("Login")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(DefaultButtonStyle())
            .padding(.top, 8)
            .disabled(isLoading)

            Spacer()
        }
        .padding()
    }

    // MARK: - Login Logic
    private func login() {
        errorMessage = nil
        isLoading = true

        SIPManager.shared.login(
            username: username,
            password: password,
            domain: domain
        ) { success, error in

            DispatchQueue.main.async {
                isLoading = false

                if success {
                    appSession.loginSuccess()
                } else {
                    errorMessage = error ?? "Login failed. Please try again."
                }
            }
        }
    }
}

