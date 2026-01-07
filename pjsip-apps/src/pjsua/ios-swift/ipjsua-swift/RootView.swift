//
//  RootView.swift
//  ipjsua-swift
//
//  Created by Arman Pathan on 06/01/26.
//

import SwiftUI

struct RootView: View {

    @EnvironmentObject var appSession: AppSession

    var body: some View {
        if appSession.isLoggedIn {
            MainTabView()
        } else {
            LoginView()
        }
    }
}
