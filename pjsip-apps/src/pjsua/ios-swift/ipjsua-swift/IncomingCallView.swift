//
//  IncomingCallView.swift
//  ipjsua-swift
//
//  Created by Arman Pathan on 12/01/26.
//

import SwiftUI

struct IncomingCallView: View {

    @EnvironmentObject var pjsipVars: PjsipVars

    // MARK: - Helper to extract username
    private var displayName: String {
        // Input: "sip:38006@sip.linphone.org" OR "<sip:38006@sip.linphone.org>"
        // Output: "38006"
        
        var clean = pjsipVars.dest
            .replacingOccurrences(of: "<", with: "")
            .replacingOccurrences(of: ">", with: "")
            .replacingOccurrences(of: "sip:", with: "")
        
        if let atIndex = clean.firstIndex(of: "@") {
            clean = String(clean[..<atIndex])
        }
        
        return clean
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 32) {

                Spacer()

                Text("Incoming Call")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                // CHANGED: Use displayName instead of pjsipVars.dest
                Text(displayName)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .padding(.horizontal)

                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 120, height: 120)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.white)
                    )

                Spacer()

                HStack(spacing: 80) {

                    // Reject Call
                    Button {
                        rejectCall()
                    } label: {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "phone.down.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                            )
                    }

                    // Accept Call
                    Button {
                        acceptCall()
                    } label: {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "phone.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                            )
                    }
                }

                Spacer(minLength: 40)
            }
        }
    }

    // MARK: - Call Actions

    private func acceptCall() {
        let userData =
            UnsafeMutableRawPointer(
                Unmanaged.passUnretained(pjsipVars).toOpaque()
            )

        // Answer call
        pjsua_schedule_timer2_dbg(
            answer_call,
            userData,
            0,
            "swift-answer",
            0
        )
        
    }

    private func rejectCall() {
        let userData =
            UnsafeMutableRawPointer(
                Unmanaged.passUnretained(pjsipVars).toOpaque()
            )

        // Reject call
        pjsua_schedule_timer2_dbg(
            reject_call,
            userData,
            0,
            "swift-reject",
            0
        )
       
    }
}
