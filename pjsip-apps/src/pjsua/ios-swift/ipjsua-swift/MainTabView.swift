//
//  MainTabView.swift
//  ipjsua-swift
//
//  Created by Arman Pathan on 06/01/26.
//

import Foundation
import SwiftUI

struct MainTabView: View {

    var body: some View {
        TabView {

            CallView()
                .tabItem {
                    Image(systemName: "phone.fill")
                    Text("Call")
                }

            ContactsView()
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("Contacts")
                }

            AccountView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Account")
                }
        }
    }
}
