//
//  RecordingsListView.swift
//  ipjsua-swift
//
//  Created by Arman Pathan on 04/02/26.
//

import SwiftUI

struct RecordingsListView: View {
    @StateObject private var viewModel = RecordingsViewModel()

    // MARK: - Date Formatter
    
    private let recordingDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        // 'h' = 12-hour format, 'a' = AM/PM marker
        formatter.dateFormat = "d MMMM yyyy hh:mm a"
        return formatter
    }()

    var body: some View {
        NavigationView {
            List(viewModel.recordings) { recording in
                VStack(spacing: 8) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(recording.fileURL.lastPathComponent)
                                .font(.headline)
                            
                            // Displays date with AM/PM time
                            Text(recording.createdAt, formatter: recordingDateFormatter)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        // Play / Pause Button
                        Button(action: {
                            viewModel.togglePlayback(for: recording)
                        }) {
                            Image(systemName: (viewModel.currentRecordingID == recording.id && viewModel.isPlaying)
                                  ? "pause.circle.fill"
                                  : "play.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    
                    // Progress Bar Section
                    if viewModel.currentRecordingID == recording.id {
                        VStack(spacing: 4) {
                            Slider(value: Binding(
                                get: { viewModel.currentTime },
                                set: { viewModel.seek(to: $0) }
                            ), in: 0...viewModel.totalTime)
                            
                            HStack {
                                Text(formatTime(viewModel.currentTime))
                                Spacer()
                                Text(formatTime(viewModel.totalTime))
                            }
                            .font(.caption)
                            .foregroundColor(.gray)
                        }
                        .padding(.top, 4)
                        .transition(.opacity)
                    }
                }
                .padding(.vertical, 8)
            }
            .navigationTitle("Call Recordings")
            .onAppear {
                viewModel.fetchRecordings()
            }
            .onDisappear {
                viewModel.stopAudio()
            }
        }
    }
    
    // Helper to format playback timer (MM:SS)
    func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

//#Preview {
//    RecordingsListView()
//}
