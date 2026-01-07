//
//  AccountView.swift
//  ipjsua-swift
//
//  Created by Arman Pathan on 06/01/26.
//

import SwiftUI

struct AccountView: View {

    @EnvironmentObject var appSession: AppSession
    @EnvironmentObject var pjsipVars: PjsipVars

    var body: some View {
        VStack(spacing: 24) {

            Spacer()

            Text("Account")
                .font(.title)
                .fontWeight(.bold)

            Text("Logged in as SIP user")
                .foregroundColor(Color.gray)

            Button(action: logout) {
                Text("Logout")
                    .fontWeight(.semibold)
                    .foregroundColor(Color.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(10)
            }

            Spacer()
        }
        .padding()
    }

    // MARK: - Logout
    private func logout() {
        // Optional SIP cleanup
        // SIPManager.shared.logout()

        appSession.logout()
    }
}

