import UIKit
import Speech

class ViewController: UIViewController, SFSpeechRecognizerDelegate {
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var microphoneButton: UIButton!
    @IBOutlet weak var botResponse: UITextView!
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))!
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    let synthesizer = AVSpeechSynthesizer()
    var hasSpoken = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        microphoneButton.isEnabled = false
        
        speechRecognizer.delegate = self
        
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            
            var isButtonEnabled = false
            
            switch authStatus {
            case .authorized:
                isButtonEnabled = true
                
            case .denied:
                isButtonEnabled = false
                print("User denied access to speech recognition")
                
            case .restricted:
                isButtonEnabled = false
                print("Speech recognition restricted on this device")
                
            case .notDetermined:
                isButtonEnabled = false
                print("Speech recognition not yet authorized")
            }
            
            OperationQueue.main.addOperation() {
                self.microphoneButton.isEnabled = isButtonEnabled
            }
        }
    }
    
    func getRequest(words: String, completion: @escaping(_ response:String) -> Void ){
        let session = URLSession(configuration: .default)
        
        guard let url = URL(string: "http://127.0.0.1:5000/") else {
            print("not a valid url")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let params = "message=\(words)"
        request.httpBody = params.data(using: .utf8)
        
        let task = session.dataTask(with: request) { data, response, error in
            guard error == nil else {
                completion("error not equal to nil")
                return
            }
            
            guard data!.count > 0 else {                                                 // check for fundamental networking error
                completion("length of data is zero")
                return
            }
            
            do {
                guard let responseDictionary = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: AnyObject] else {
                    completion("can not get json from response")
                    return
                }
                
                guard let description = responseDictionary["bot_response"] as? String else {
                    return
                }
                
                completion(description)
                
            } catch {
                completion("Exception thrown parsing json")
            }
            
        }
        
        task.resume()
    }
    
    @IBAction func microphoneTapped(_ sender: AnyObject) {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            microphoneButton.isEnabled = false
            microphoneButton.setImage(UIImage(named: "icons8-record"), for: .normal)
            getRequest(words: self.textView.text, completion: { (response) in
                DispatchQueue.main.async {
                    print(response)
                    self.botResponse.text = response
                    let utterance = AVSpeechUtterance(string: response)
//                    utterance.voice = AVSpeechSynthesisVoice(language: "en-gb")
                    utterance.rate = 0.4
                    self.synthesizer.speak(utterance)
                }
            })
            
        } else {
            startRecording()
            microphoneButton.setImage(UIImage(named: "icons8-record-filled"), for: .normal)
        }
    }
    
    func startRecording() {
        
        if recognitionTask != nil {  //1
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()  //2
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()  //3
        
        let inputNode = audioEngine.inputNode
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        } //5
        
        recognitionRequest.shouldReportPartialResults = true  //6
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in  //7
            
            var isFinal = false  //8
            
            if result != nil {
                self.textView.text = result?.bestTranscription.formattedString  //9
                isFinal = (result?.isFinal)!
            }
            
            if error != nil || isFinal {  //10
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
                self.microphoneButton.isEnabled = true
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)  //11
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()  //12
        
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
        
        textView.text = "Say something, I'm listening!"
        
    }
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            microphoneButton.isEnabled = true
        } else {
            microphoneButton.isEnabled = false
        }
    }
}


