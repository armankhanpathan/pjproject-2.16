//
//  ContactsView.swift
//  ipjsua-swift
//
//  Created by Arman Pathan on 13/01/26.
//

import SwiftUI

struct ContactsView: View {

    @StateObject private var vm = ContactsViewModel()

    var body: some View {
        NavigationView {
            Group {
                if vm.permissionDenied {
                    Text("Contacts permission denied.\nEnable it from Settings.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)
                        .padding()
                } else if vm.contacts.isEmpty {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Syncing contacts...")
                            .foregroundColor(.gray)
                    }
                } else {
                    List(vm.contacts) { contact in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(contact.name)
                                .font(.headline)
                            Text(contact.phone)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .navigationTitle("Contacts")
        }
        .onAppear {
            vm.requestAndFetchContacts()
        }
    }
}
