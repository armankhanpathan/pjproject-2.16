//
//  IncomingCallView.swift
//  ipjsua-swift
//
//  Created by Arman Pathan on 12/01/26.
//

import SwiftUI

struct IncomingCallView: View {

    @EnvironmentObject var pjsipVars: PjsipVars

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 32) {

                Spacer()

                Text("Incoming Call")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                Text(pjsipVars.dest)
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
