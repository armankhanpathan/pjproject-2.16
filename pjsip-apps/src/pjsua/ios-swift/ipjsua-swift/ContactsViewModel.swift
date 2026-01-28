import Foundation
import Contacts

final class ContactsViewModel: ObservableObject {

    @Published var contacts: [ContactItem] = []
    @Published var permissionDenied = false

    private let store = CNContactStore()

    func requestAndFetchContacts() {
        store.requestAccess(for: .contacts) { granted, _ in
            DispatchQueue.main.async {
                if granted {
                    self.fetchContacts()
                } else {
                    self.permissionDenied = true
                }
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
            result.append(ContactItem(name: name, phone: phone))
        }

        contacts = result
    }
}
