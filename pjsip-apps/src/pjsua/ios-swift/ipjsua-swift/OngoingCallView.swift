//
//  OngoingCallView.swift
//  ipjsua-swift
//
//  Created by Arman Pathan on 06/01/26.
//

import SwiftUI
import AVFAudio

struct OngoingCallView: View {

    @EnvironmentObject var pjsipVars: PjsipVars
    @Environment(\.presentationMode) var presentationMode

    @State private var secondsElapsed = 0
    @State private var timer: Timer?
    @State private var isSpeakerOn = false
    @State private var isMicMuted = false


    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 28) {

                Spacer()

                // Calling OR Timer (strict logic)
                Text(pjsipVars.callAnswered ? formattedTime : "Calling")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                // SIP Username (single line, centered)
                Text(pjsipVars.dest)
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .padding(.horizontal, 24)

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

                // Controls (larger buttons)
                VStack(spacing: 28) {
                    HStack(spacing: 56) {
                        speakerButton
                        actionButton(icon: "video.fill", title: "FaceTime")
                        muteButton
                    }

                    HStack(spacing: 56) {
                        actionButton(icon: "person.badge.plus", title: "Add")
                        endCallButton
                        actionButton(icon: "circle.grid.3x3.fill", title: "Keypad")
                    }
                }

                Spacer(minLength: 28)
            }
        }
        .onAppear {
            triggerCallOrHangup()
        }
        .onChange(of: pjsipVars.callAnswered) { answered in
            answered ? startTimer() : stopTimer()
        }
        .onDisappear {
            stopTimer()
        }
        .onChange(of: pjsipVars.callEnded) { ended in
            if ended {
                presentationMode.wrappedValue.dismiss()
            }
        }

    }

    // MARK: - Speaker Control

    private func toggleSpeaker() {
        isSpeakerOn.toggle()

        let session = AVAudioSession.sharedInstance()
        do {
            if isSpeakerOn {
                try session.overrideOutputAudioPort(.speaker)
            } else {
                try session.overrideOutputAudioPort(.none)
            }
            try session.setActive(true)
        } catch {
            print("Speaker toggle error:", error)
        }
    }

    // MARK: - Buttons

    private func actionButton(icon: String, title: String) -> some View {
        VStack(spacing: 10) {
            Circle()
                .fill(Color.gray.opacity(0.25))
                .frame(width: 72, height: 72)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                )

            Text(title)
                .font(.caption)
                .foregroundColor(.white)
        }
    }

    private var endCallButton: some View {
        Button {
            triggerCallOrHangup()
            presentationMode.wrappedValue.dismiss()
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
        Button {
            toggleSpeaker()
        } label: {
            VStack(spacing: 10) {
                Circle()
                    .fill(isSpeakerOn ? Color.white : Color.gray.opacity(0.25))
                    .frame(width: 72, height: 72)
                    .overlay(
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 24))
                            .foregroundColor(isSpeakerOn ? .black : .white)
                    )

                Text("Speaker")
                    .font(.caption)
                    .foregroundColor(.white)
            }
        }
    }
    
    private var muteButton: some View {
        Button {
            toggleMute()
        } label: {
            VStack(spacing: 10) {
                Circle()
                    .fill(isMicMuted ? Color.white : Color.gray.opacity(0.25))
                    .frame(width: 72, height: 72)
                    .overlay(
                        Image(systemName: isMicMuted ? "mic.slash.fill" : "mic.fill")
                            .font(.system(size: 24))
                            .foregroundColor(isMicMuted ? .black : .white)
                    )

                Text("Mute")
                    .font(.caption)
                    .foregroundColor(.white)
            }
        }
        .disabled(!pjsipVars.callAnswered)
    }

    // MARK: - Mic Mute Control

    private func toggleMute() {
        guard pjsipVars.callAnswered else { return }

        var ci = pjsua_call_info()
        pjsua_call_get_info(pjsipVars.call_id, &ci)

        guard ci.conf_slot != PJSUA_INVALID_ID.rawValue else { return }

        if isMicMuted {
            // Unmute mic
            pjsua_conf_connect(0, ci.conf_slot)
        } else {
            // Mute mic
            pjsua_conf_disconnect(0, ci.conf_slot)
        }

        isMicMuted.toggle()
    }

    // MARK: - Timer (starts ONLY on answer)

    private var formattedTime: String {
        let m = secondsElapsed / 60
        let s = secondsElapsed % 60
        return String(format: "%02d:%02d", m, s)
    }

    private func startTimer() {
        secondsElapsed = 0
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            secondsElapsed += 1
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        secondsElapsed = 0
    }

    // MARK: - PJSIP

    private func triggerCallOrHangup() {
        let userData =
            UnsafeMutableRawPointer(
                Unmanaged.passUnretained(pjsipVars).toOpaque()
            )

        pjsua_schedule_timer2_dbg(
            call_func,
            userData,
            0,
            "swift",
            0
        )
    }
}
