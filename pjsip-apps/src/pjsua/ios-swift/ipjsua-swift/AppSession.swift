//
//  AppSession.swift
//  ipjsua-swift
//
//  Created by Arman Pathan on 06/01/26.
//

import Foundation
import SwiftUI

final class AppSession: ObservableObject {

    @Published var isLoggedIn: Bool = false

    // Logged-in SIP user info
    @Published var sipUsername: String = ""
    @Published var sipDomain: String = ""

    var sipURI: String {
        "sip:\(sipUsername)@\(sipDomain)"
    }

    func loginSuccess(username: String, domain: String) {
        self.sipUsername = username
        self.sipDomain = domain
        isLoggedIn = true
    }

    func logout() {
        isLoggedIn = false
        sipUsername = ""
        sipDomain = ""
    }
}
