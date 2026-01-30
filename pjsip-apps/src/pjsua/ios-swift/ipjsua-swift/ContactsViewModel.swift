//
//  ContactsViewModel.swift
//  ipjsua-swift
//
//  Created by Arman Pathan on 13/01/26.
//

import Foundation
import Contacts

struct ContactItem: Identifiable {
    let id = UUID()
    let name: String
    let phone: String
}

final class ContactsViewModel: ObservableObject {

    @Published var contacts: [ContactItem] = []
    @Published var permissionDenied = false

    private let store = CNContactStore()

    func requestAndFetchContacts() {
        store.requestAccess(for: .contacts) { granted, _ in
            guard granted else {
                DispatchQueue.main.async {
                    self.permissionDenied = true
                }
                return
            }

            // Fetch contacts on background thread
            DispatchQueue.global(qos: .userInitiated).async {
                self.fetchContacts()
            }
        }
    }

    private func fetchContacts() {
        let keys: [CNKeyDescriptor] = [
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor
        ]

        let request = CNContactFetchRequest(keysToFetch: keys)
        var result: [ContactItem] = []

        try? store.enumerateContacts(with: request) { contact, _ in
            guard let phone = contact.phoneNumbers.first?.value.stringValue else { return }

            let name = "\(contact.givenName) \(contact.familyName)"
                .trimmingCharacters(in: .whitespaces)

            result.append(ContactItem(name: name, phone: phone))
        }

        let sorted = result.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }

        //  UI update on main thread
        DispatchQueue.main.async {
            self.contacts = sorted
        }
    }

}
