//
//  AccountView.swift
//  ipjsua-swift
//
//  Created by Arman Pathan on 06/01/26.
//

import SwiftUI

struct AccountView: View {

    @EnvironmentObject var appSession: AppSession

    var body: some View {
        VStack(spacing: 16) {

            Spacer()

            Text("Account")
                .font(.title)
                .fontWeight(.bold)

            VStack(spacing: 6) {
                Text(appSession.sipUsername)
                    .font(.headline)

                Text(appSession.sipURI)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            Button(action: logout) {
                Text("Logout")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(10)
            }

            Spacer()
        }
        .padding()
    }

    private func logout() {
        appSession.logout()
    }
}
