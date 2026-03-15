//
//  OngoingCallView.swift
//  ipjsua-swift
//
//  Created by Arman Pathan on 06/01/26.
//

import SwiftUI
import AVFAudio
import Combine

struct OngoingCallView: View {

    @EnvironmentObject var pjsipVars: PjsipVars
    @Environment(\.presentationMode) var presentationMode

    @State private var secondsElapsed = 0
    @State private var timer: Timer?

    @State private var isSpeakerOn = false
    @State private var isMicMuted = false

    @State private var showDialer = false
    @State private var isAddingCall = false

    @State private var showTransfer = false
    @State private var transferTarget = ""

    // MARK: - Helper to extract username
    private var displayName: String {
        var clean = pjsipVars.dest
            .replacingOccurrences(of: "<", with: "")
            .replacingOccurrences(of: ">", with: "")
            .replacingOccurrences(of: "sip:", with: "")
        
        if let atIndex = clean.firstIndex(of: "@") {
            clean = String(clean[..<atIndex])
        }
        
        return clean
    }

    // MARK: - UI

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                
                HStack {
                    Spacer()
                    recordButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)

                Spacer()

                // Calling OR Timer
                Text(pjsipVars.callAnswered ? formattedTime : "Calling")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.bottom, 8)

                // Display Name
                Text(displayName)
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)

                // Avatar
                Circle()
                    .fill(Color.gray.opacity(0.35))
                    .frame(width: 104, height: 104)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.white)
                    )

                Spacer()

                // MARK: - BOTTOM CONTROLS
                VStack(spacing: 28) {

                    // Row 1
                    HStack(spacing: 56) {
                        speakerButton
                        holdButton
                        muteButton
                    }

                    // Row 2
                    HStack(spacing: 56) {
                        transferButton
                        endCallButton
                        addCallButton
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            if pjsipVars.callAnswered {
                startTimer()
            }
        }
        .onDisappear {
            stopTimer()
        }
        .onReceive(pjsipVars.$callAnswered) { answered in
            if answered {
                startTimer()
            } else {
                stopTimer()
            }
        }
        .onReceive(pjsipVars.$callEnded) { ended in
            if ended {
                stopTimer()
                presentationMode.wrappedValue.dismiss()
            }
        }
        .onReceive(Just(showDialer)) { active in
            if !active {
                isAddingCall = false
            }
        }
        // Sheets
        .sheet(isPresented: $showDialer) {
            CallView()
                .environmentObject(self.pjsipVars)
        }
        .sheet(isPresented: $showTransfer) {
            transferSheet
        }
    }
    
    // MARK: - Transfer Sheet View
    private var transferSheet: some View {
        VStack(spacing: 20) {
            Text("Transfer Call").font(.headline)
            TextField("Enter SIP user or number", text: self.$transferTarget)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .keyboardType(.asciiCapable)

            Button("Transfer") {
                pjsipVars.dest = "sip:\(self.transferTarget)@sip.linphone.org"
                let userData = UnsafeMutableRawPointer(Unmanaged.passUnretained(pjsipVars).toOpaque())
                pjsua_schedule_timer2_dbg(transfer_call, userData, 0, "swift-transfer", 0)
                self.showTransfer = false
            }

            Button("Cancel") {
                self.showTransfer = false
            }.foregroundColor(.red)
        }
        .padding()
    }

    // MARK: - RECORD BUTTON
    private var recordButton: some View {
        Button(action: toggleRecording) {
            HStack(spacing: 8) {
                if pjsipVars.isRecording {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 10, height: 10)
                } else {
                    Image(systemName: "recordingtape")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }
                
                Text(pjsipVars.isRecording ? "REC" : "Record")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(Color(UIColor.systemGray6).opacity(0.2))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(pjsipVars.isRecording ? Color.red.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .disabled(!pjsipVars.callAnswered)
        .opacity(pjsipVars.callAnswered ? 1 : 0.5)
    }

    // MARK: - Standard Buttons

    private var addCallButton: some View {
        let canMerge = pjsipVars.activeCallIds.count == 2 && !pjsipVars.isConference
        return Button {
            if canMerge {
                mergeCalls()
            } else {
                isAddingCall = true
                toggleHold()
                showDialer = true
            }
        } label: {
            controlButton(
                icon: canMerge ? "arrow.triangle.merge" : "person.badge.plus",
                title: canMerge ? "Merge" : "Add Call"
            )
        }
        .disabled(!pjsipVars.callAnswered || pjsipVars.isConference)
    }

    private var endCallButton: some View {
        Button {
            let userData = UnsafeMutableRawPointer(Unmanaged.passUnretained(pjsipVars).toOpaque())
            pjsua_schedule_timer2_dbg(end_all_calls, userData, 0, "swift-end-all", 0)
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
    }

    private var speakerButton: some View {
        Button(action: toggleSpeaker) {
            controlButton(icon: "speaker.wave.2.fill", title: "Speaker", active: isSpeakerOn)
        }
    }

    private var muteButton: some View {
        Button(action: toggleMute) {
            controlButton(icon: isMicMuted ? "mic.slash.fill" : "mic.fill", title: "Mute", active: isMicMuted)
        }
        .disabled(!pjsipVars.callAnswered)
    }

    private var holdButton: some View {
        Button(action: toggleHold) {
            controlButton(icon: "pause.fill", title: pjsipVars.isOnHold ? "Resume" : "Hold", active: pjsipVars.isOnHold)
        }
        .disabled(!pjsipVars.callAnswered)
    }

    private var transferButton: some View {
        Button { showTransfer = true } label: {
            VStack(spacing: 6) {
                Image(systemName: "arrowshape.turn.up.right.fill")
                    .font(.system(size: 22))
                Text("Transfer").font(.caption)
            }
            .foregroundColor(.white)
        }
    }

    // MARK: - Helpers

    private func controlButton(icon: String, title: String, active: Bool = false) -> some View {
        VStack(spacing: 10) {
            Circle()
                .fill(active ? Color.white : Color.gray.opacity(0.25))
                .frame(width: 72, height: 72)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(active ? .black : .white)
                )
            Text(title).font(.caption).foregroundColor(.white)
        }
    }

    private var formattedTime: String {
        String(format: "%02d:%02d", secondsElapsed / 60, secondsElapsed % 60)
    }

    private func startTimer() {
        guard timer == nil else { return }
        secondsElapsed = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            DispatchQueue.main.async { self.secondsElapsed += 1 }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        secondsElapsed = 0
    }

    // MARK: - PJSIP Actions

    private func toggleSpeaker() {
        isSpeakerOn.toggle()
        let session = AVAudioSession.sharedInstance()
        try? session.overrideOutputAudioPort(isSpeakerOn ? .speaker : .none)
    }

    private func toggleMute() {
        guard pjsipVars.callAnswered else { return }
        isMicMuted.toggle()
        guard let callId = pjsipVars.activeCallIds.first else { return }
        var callInfo = pjsua_call_info()
        pjsua_call_get_info(callId, &callInfo)
        let callPort = callInfo.conf_slot
        if isMicMuted {
            pjsua_conf_disconnect(0, callPort)
        } else {
            pjsua_conf_connect(0, callPort)
        }
    }

    private func toggleHold() {
        let userData = UnsafeMutableRawPointer(Unmanaged.passUnretained(pjsipVars).toOpaque())
        pjsua_schedule_timer2_dbg(toggle_hold_call, userData, 0, "swift-hold", 0)
    }

    private func mergeCalls() {
        let userData = UnsafeMutableRawPointer(Unmanaged.passUnretained(pjsipVars).toOpaque())
        pjsua_schedule_timer2_dbg(merge_calls, userData, 0, "swift-merge", 0)
    }
    
    private func toggleRecording() {
        let userData = UnsafeMutableRawPointer(Unmanaged.passUnretained(pjsipVars).toOpaque())
       
        pjsua_schedule_timer2_dbg(toggle_call_recording, userData, 0, "swift-record", 0)
    }
}
