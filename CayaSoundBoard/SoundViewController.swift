import UIKit
import AVFoundation

class SoundViewController: UIViewController {

    @IBOutlet weak var grabarButton: UIButton!
    @IBOutlet weak var reproducirButton: UIButton!
    @IBOutlet weak var nombreTextField: UITextField!
    @IBOutlet weak var agregarButton: UIButton!
    
    @IBOutlet weak var recordingTimeLabel: UILabel!
    var grabarAudio: AVAudioRecorder?
    var reproducirAudio:AVAudioPlayer?
    var audioURL:URL?
    var timer: Timer?
    var recordingTime: Int = 0
    
    @IBOutlet weak var volumeSlider: UISlider!
    
    @IBAction func volumeChanged(_ sender: UISlider) {
        reproducirAudio?.volume = sender.value
    }
    @IBAction func grabarTapped(_ sender: Any) {
        guard let grabarAudio = grabarAudio else {
            print("Error: grabarAudio no está inicializado")
            return
        }
        
        if grabarAudio.isRecording {
            grabarAudio.stop()
            timer?.invalidate() // Detener el temporizador
            grabarButton.setTitle("GRABAR", for: .normal)
            reproducirButton.isEnabled = true
            agregarButton.isEnabled = true
        } else {
            grabarAudio.record()
            recordingTime = 0 // Reiniciar el tiempo
            recordingTimeLabel.text = "0s" // Reiniciar el label
            grabarButton.setTitle("DETENER", for: .normal)
            reproducirButton.isEnabled = true
            
            // Iniciar el temporizador
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                self?.recordingTime += 1
                self?.recordingTimeLabel.text = "\(self?.recordingTime ?? 0)s"
            }
        }
    }

    @IBAction func reproducirTapped(_ sender: Any) {
        do{
           try reproducirAudio = AVAudioPlayer(contentsOf: audioURL!)
            reproducirAudio!.play()
            print("REproduciendo")
        }catch{}
    }
    
    @IBAction func agregarTapped(_ sender: Any) {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let grabacion = Grabacion(context: context)
        grabacion.nombre = nombreTextField.text
        grabacion.audio = NSData(contentsOf: audioURL!)! as Data
        grabacion.tiempo = Int32(recordingTime) // Guardar el tiempo
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
        navigationController!.popViewController(animated: true)
    }

    func configurarGrabacion() {
        do {
            // Creando sesión de audio
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [])
            try session.overrideOutputAudioPort(.speaker)
            try session.setActive(true)

            // Creando dirección para el archivo de audio
            let basePath: String = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
            print("Base Path: \(basePath)") // Imprime la basePath

            let pathComponents = [basePath, "audio.m4a"]
            print("Path Components: \(pathComponents)") // Imprime los componentes de la ruta
            audioURL = NSURL.fileURL(withPathComponents: pathComponents)!

            // Impresión de ruta donde se guardan los archivos
            print("************************")
            print(audioURL!) // Asegúrate de que esto se imprima
            print("************************")

            // Crear opciones para el grabador de audio
            var settings: [String: AnyObject] = [:]
            settings[AVFormatIDKey] = Int(kAudioFormatMPEG4AAC) as AnyObject?
            settings[AVSampleRateKey] = 44100.0 as AnyObject?
            settings[AVNumberOfChannelsKey] = 2 as AnyObject?

            // Crear el objeto de grabación de audio
            grabarAudio = try AVAudioRecorder(url: audioURL!, settings: settings)
            grabarAudio?.prepareToRecord()
        } catch let error as NSError {
            print("Error al configurar la grabación: \(error.localizedDescription)")
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        configurarGrabacion()
        reproducirButton.isEnabled = false
        agregarButton.isEnabled = false
    }
}

