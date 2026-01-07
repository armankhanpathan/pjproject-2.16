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

    func logout() {
        isLoggedIn = false
    }

    func loginSuccess() {
        isLoggedIn = true
    }
}
