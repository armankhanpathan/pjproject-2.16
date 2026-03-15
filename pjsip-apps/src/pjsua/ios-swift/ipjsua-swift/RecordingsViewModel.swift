//
//  RecordingsViewModel.swift
//  ipjsua-swift
//
//  Created by Arman Pathan on 04/02/26.
//

import Foundation
import AVFoundation
import UIKit

struct Recording: Identifiable {
    let id = UUID()
    let fileURL: URL
    let createdAt: Date
}

class RecordingsViewModel: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var recordings: [Recording] = []
    
    // MARK: - Playback State
    @Published var isPlaying: Bool = false
    @Published var currentRecordingID: UUID? = nil
    @Published var currentTime: TimeInterval = 0
    @Published var totalTime: TimeInterval = 0
    
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?

    func fetchRecordings() {
        let fileManager = FileManager.default
        // Access the app's Documents directory
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }

        do {
            // Get all files in the directory
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: [.creationDateKey])
            
            // Filter for .wav files and map them to Recording model
            self.recordings = fileURLs.filter { $0.pathExtension == "wav" }.map { url in
                let attributes = try? fileManager.attributesOfItem(atPath: url.path)
                let creationDate = attributes?[.creationDate] as? Date ?? Date()
                return Recording(fileURL: url, createdAt: creationDate)
            }.sorted(by: { $0.createdAt > $1.createdAt })
        } catch {
            print("Error fetching recordings: \(error)")
        }
    }

    func togglePlayback(for recording: Recording) {
        if currentRecordingID == recording.id {
            // If tapping the same recording, toggle play/pause
            if isPlaying {
                pauseAudio()
            } else {
                resumeAudio()
            }
        } else {
            // Start a new recording
            startPlaying(recording)
        }
    }
    
    private func startPlaying(_ recording: Recording) {
        // Stop any previous playback
        stopAudio()

        do {
            // Configure Audio Session for Loudspeaker
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            try session.setActive(true)

            // Setup Player
            audioPlayer = try AVAudioPlayer(contentsOf: recording.fileURL)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            
            // Update State
            currentRecordingID = recording.id
            totalTime = audioPlayer?.duration ?? 0
            isPlaying = true
            
            // Start Timer
            startTimer()
            
        } catch {
            print("Playback failed: \(error)")
        }
    }
    
    private func pauseAudio() {
        audioPlayer?.pause()
        isPlaying = false
        timer?.invalidate()
    }
    
    private func resumeAudio() {
        audioPlayer?.play()
        isPlaying = true
        startTimer()
    }
    
    func stopAudio() {
        audioPlayer?.stop()
        audioPlayer = nil
        timer?.invalidate()
        
        isPlaying = false
        currentRecordingID = nil
        currentTime = 0
        totalTime = 0
    }
    
    func seek(to time: TimeInterval) {
        guard let player = audioPlayer else { return }
        player.currentTime = time
        currentTime = time
    }

    // MARK: - Timer Logic
    private func startTimer() {
        timer?.invalidate() // invalid previous timer if any
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.audioPlayer else { return }
            self.currentTime = player.currentTime
        }
    }
    
    // MARK: - AVAudioPlayerDelegate
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.stopAudio()
        }
    }
}
