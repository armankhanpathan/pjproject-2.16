//
//  CallView.swift
//  ipjsua-swift
//
//  Created by Arman Pathan on 31/12/25.
//

import SwiftUI

struct CallView: View {

    @EnvironmentObject var pjsipVars: PjsipVars
    @Environment(\.presentationMode) var presentationMode

    @State private var number = ""
//    @State private var navigate = false

    var body: some View {
        NavigationView {
            VStack {

                Spacer()

                // Dialed Number
                Text(number.isEmpty ? " " : formatted(number))
                    .font(.system(size: 40))
                    .foregroundColor(.primary)
                    .padding(.bottom, 24)

                // Keypad
                VStack(spacing: 18) {
                    keypadRow(["1","2","3"], ["","ABC","DEF"])
                    keypadRow(["4","5","6"], ["GHI","JKL","MNO"])
                    keypadRow(["7","8","9"], ["PQRS","TUV","WXYZ"])
                    keypadRow(["*","0","#"], ["","+",""])
                }

                HStack(spacing: 18) {

                    Color.clear
                        .frame(width: 78, height: 78)

                    Button {
                        startCall()
                    } label: {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                            .frame(width: 72, height: 72)
                            .background(Color.green)
                            .clipShape(Circle())
                    }
                    .disabled(number.isEmpty)
                    .opacity(number.isEmpty ? 0.4 : 1)

                    if !number.isEmpty {
                        Button(action: eraseLastDigit) {
                            Image(systemName: "delete.left")
                                .font(.system(size: 26))
                                .foregroundColor(.primary)
                                .frame(width: 72, height: 72)
                                .background(Color(UIColor.systemGray5))
                                .clipShape(Circle())
                        }
                    } else {
                    
                        Color.clear
                            .frame(width: 56, height: 56)
                    }
                }
                .padding(.top, 18)

                Spacer(minLength: 30)

//                NavigationLink(
//                    destination: OngoingCallView()
//                        .environmentObject(pjsipVars),
//                    isActive: $navigate
//                ) { EmptyView() }
            }
            .padding(.horizontal)
            .navigationBarTitle("", displayMode: .inline)
        }
    }

    // MARK: - Helpers

    private func keypadRow(_ numbers: [String], _ letters: [String]) -> some View {
        HStack(spacing: 18) {
            ForEach(0..<3, id: \.self) { index in
                DialKey(
                    number: numbers[index],
                    letters: letters[index]
                ) {
                    number.append(numbers[index])
                }
            }
        }
    }

    private func eraseLastDigit() {
        guard !number.isEmpty else { return }
        number.removeLast()
    }

    private func startCall() {

        //  Prepare destination
        pjsipVars.dest = "sip:\(number)@sip.linphone.org"

        //  SHOW ongoing call UI FIRST
        DispatchQueue.main.async {
            pjsipVars.showOngoingCall = true
            pjsipVars.calling = true
            pjsipVars.callAnswered = false
        }

        //  Trigger SIP call
        let userData =
            UnsafeMutableRawPointer(
                Unmanaged.passUnretained(pjsipVars).toOpaque()
            )

        pjsua_schedule_timer2_dbg(
            call_func,
            userData,
            0,
            "swift-add-call",
            0
        )

        //  THEN dismiss dialer
        presentationMode.wrappedValue.dismiss()
    }



    private func formatted(_ text: String) -> String {
        let chars = Array(text)
        return chars.enumerated().map { i, c in
            (i == 5 || i == 9) ? " \(c)" : String(c)
        }.joined()
    }
}

struct DialKey: View {

    let number: String
    let letters: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(number)
                    .font(.system(size: 32, weight: .regular))
                if !letters.isEmpty {
                    Text(letters)
                        .font(.system(size: 11))
                        .tracking(1)
                }
            }
            .foregroundColor(.primary)
            .frame(width: 78, height: 78)
            .background(Color(UIColor.systemGray5))
            .clipShape(Circle())
        }
    }
}

//#Preview {
//    CallView()
//}








//import SwiftUI
//
//struct CallView: View {
//
//    @EnvironmentObject var pjsipVars: PjsipVars
//
//    var body: some View {
//        VStack(spacing: 20) {
//
//            Text("SIP Account Registered")
//                .font(.headline)
//
//            Button(action: {
//                triggerCallOrHangup()
//            }) {
//                Text(pjsipVars.calling ? "Hangup Call" : "Call Test User")
//                    .foregroundColor(.white)
//                    .padding()
//                    .frame(maxWidth: .infinity)
//                    .background(pjsipVars.calling ? Color.red : Color.green)
//                    .cornerRadius(8)
//            }
//
//            if pjsipVars.calling {
//                Text("Call in progress…")
//                    .foregroundColor(.green)
//            }
//
//            Spacer()
//        }
//        .padding()
//    }
//
//    // MARK: - PJSIP call trigger
//    private func triggerCallOrHangup() {
//        let userData =
//            UnsafeMutableRawPointer(
//                Unmanaged.passUnretained(pjsipVars).toOpaque()
//            )
//
//        // PJSUA internal timer thread
//        pjsua_schedule_timer2_dbg(
//            call_func,
//            userData,
//            0,
//            "swift",
//            0
//        )
//    }
//}
//
//func call_func(user_data: UnsafeMutableRawPointer?) {
//   let pjsip_vars = Unmanaged<PjsipVars>.fromOpaque(user_data!).takeUnretainedValue()
//   if (!pjsip_vars.calling) {
//       var status: pj_status_t;
//       var opt = pjsua_call_setting();
//
//       pjsua_call_setting_default(&opt);
//       opt.aud_cnt = 1;
//       opt.vid_cnt = 1;
//
//       let dest_str = strdup(pjsip_vars.dest);
//       var dest:pj_str_t = pj_str(dest_str);
//       
//       status = pjsua_call_make_call(SIPManager.shared.accountId, &dest, &opt, nil, nil, &pjsip_vars.call_id);
//       DispatchQueue.main.sync {
//           pjsip_vars.calling = (status == PJ_SUCCESS.rawValue);
//       }
//       free(dest_str);
//   } else {
//       if (pjsip_vars.call_id != PJSUA_INVALID_ID.rawValue) {
//           DispatchQueue.main.sync {
//               pjsip_vars.calling = false;
//           }
//           pjsua_call_hangup(pjsip_vars.call_id, 200, nil, nil);
//           pjsip_vars.call_id = PJSUA_INVALID_ID.rawValue;
//       }
//   }
//
//}
