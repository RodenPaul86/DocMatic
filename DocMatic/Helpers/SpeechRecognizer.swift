//
//  SpeechRecognizer.swift
//  DocMatic
//
//  Created by Paul  on 6/12/25.
//

import Foundation
import Speech
import AVFoundation

class SpeechRecognizer: NSObject, ObservableObject, SFSpeechRecognizerDelegate {
    @Published var isListening: Bool = false
    private let recognizer = SFSpeechRecognizer()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    private var onResult: ((String) -> Void)?

    func requestPermission() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            switch authStatus {
            case .authorized:
                print("Speech recognition authorized")
            default:
                print("Speech recognition not authorized")
            }
        }
        
        AVAudioApplication.requestRecordPermission { granted in
            print(granted ? "Mic access granted" : "Mic access denied")
        }
    }

    func startTranscribing(onResult: @escaping (String) -> Void) {
        stopTranscribing() // Reset any active session
        self.onResult = onResult
        isListening = true

        let node = audioEngine.inputNode
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        guard let recognitionRequest = recognitionRequest else { return }

        recognitionRequest.shouldReportPartialResults = true

        let recordingFormat = node.outputFormat(forBus: 0)
        node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        try? AVAudioSession.sharedInstance().setCategory(.record, mode: .measurement, options: .duckOthers)
        try? AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)

        audioEngine.prepare()
        try? audioEngine.start()

        recognitionTask = recognizer?.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                self.onResult?(result.bestTranscription.formattedString)

                if result.isFinal {
                    self.stopTranscribing() /// <-- Auto stop when user finishes speaking
                }
            }

            if error != nil {
                self.stopTranscribing()
            }
        }
    }

    func stopTranscribing() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        isListening = false
    }
}
