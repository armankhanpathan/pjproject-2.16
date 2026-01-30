//
//  RootView.swift
//  ipjsua-swift
//
//  Created by Arman Pathan on 06/01/26.
//

import SwiftUI

struct RootView: View {

    @EnvironmentObject var appSession: AppSession
    @EnvironmentObject var pjsipVars: PjsipVars

    var body: some View {
        ZStack {

            // Main app flow
            if appSession.isLoggedIn {
                MainTabView()
            } else {
                LoginView()
            }
        }
        // Incoming call screen
        .fullScreenCover(
            isPresented: $pjsipVars.hasIncomingCall
        ) {
            IncomingCallView()
                .environmentObject(pjsipVars)
        }
        // Ongoing call screen
        .fullScreenCover(
            isPresented: $pjsipVars.showOngoingCall
        ) {
            OngoingCallView()
                .environmentObject(pjsipVars)
        }
    }
}
