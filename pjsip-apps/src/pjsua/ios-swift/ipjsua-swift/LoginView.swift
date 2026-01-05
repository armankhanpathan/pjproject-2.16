//
//  LoginView.swift
//  ipjsua-swift
//
//  Created by Arman Pathan on 30/12/25.
//

import SwiftUI

struct LoginView: View {

    @State private var username = ""
    @State private var password = ""
    @State private var domain = "sip.linphone.org"

    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isLoggedIn = false

    @EnvironmentObject var pjsipVars: PjsipVars

    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                VStack(spacing: 16) {
                    
                    Text("SIP Login")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom, 24)
                    
                    TextField("SIP Username", text: $username)
                        .autocapitalization(.none)
                        .keyboardType(.asciiCapable)
                        .textFieldStyle(.roundedBorder)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("SIP Domain", text: $domain)
                        .autocapitalization(.none)
                        .keyboardType(.URL)
                        .textFieldStyle(.roundedBorder)
                    
                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.footnote)
                    }
                    
                    Button {
                        login()
                    } label: {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Login")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isLoading)
                    
                    Spacer()
                }
                .padding()
                .navigationDestination(isPresented: $isLoggedIn) {
                    CallView()
                        .environmentObject(pjsipVars)
                }
            }
        } else {
            // Fallback on earlier versions
        }
    }

    private func login() {
        errorMessage = nil
        isLoading = true

        SIPManager.shared.login(
            username: username,
            password: password,
            domain: domain
        ) { success, error in
            isLoading = false
            if success {
                isLoggedIn = true
            } else {
                errorMessage = error
            }
        }
    }
}

#Preview {
    LoginView()
}
