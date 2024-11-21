//
//  ViewController.swift
//  CircomWitnesscalc
//
//  Created by Yaroslav Moria on 07/29/2024.
//  Copyright (c) 2024 Yaroslav Moria. All rights reserved.
//

import UIKit
import UniformTypeIdentifiers

import CircomWitnesscalc
import rapidsnark

class ViewController: UIViewController, UIDocumentPickerDelegate {
    var pickedFileType = FileType.inputs
    
    var inputs: Data?
    var graph: Data?
    var zkey: Data?
    var verificationKey: Data?
    
    var witness: Data?
    
    var proof: (proof: String, publicSignals: String)?
    
    @IBOutlet
    weak var inputsLabel: UILabel!;
    
    @IBOutlet
    weak var graphLabel: UILabel!;
    
    @IBOutlet
    weak var zkeyLabel: UILabel!;
    
    @IBOutlet
    weak var verificationKeyLabel: UILabel!;
    
    @IBOutlet
    weak var witnessLabel: UILabel!;
    
    @IBOutlet
    weak var proofLabel: UILabel!;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        inputs = FileManager.default.contents(atPath :inputsPath())!
        graph = FileManager.default.contents(atPath :witnessGraphPath())!
        zkey = FileManager.default.contents(atPath :zkeyPath())!
        verificationKey = FileManager.default.contents(atPath :verificatonKeyPath())!
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        NSLog("cancelled")
    }
    
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else {
            NSLog("File pick ulrs empty or cancelled")
            return
        }
        NSLog("Selected file URL: " + url.description)
        
        let label = switch pickedFileType {
        case .zkey: zkeyLabel
        case .inputs: inputsLabel
        case .graph: graphLabel
        case .verificationKey: verificationKeyLabel
        }
        
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            label?.text = "Error picking " + pickedFileType.name + ": " + error.localizedDescription
            NSLog(error.localizedDescription)
            return
        }
        
        label?.text = "Got " + pickedFileType.name + ". Name: " + url.lastPathComponent
        
        switch pickedFileType {
        case .zkey:
            zkey = data
        case .graph:
            graph = data
        case .inputs:
            inputs = data
        case .verificationKey:
            verificationKey = data
        }
    }
    
    private func filePicker(fileType: FileType) -> UIDocumentPickerViewController {
        let pickerViewController = if #available(iOS 14.0, *) {
            UIDocumentPickerViewController(
                forOpeningContentTypes: [fileType.uttype],
                asCopy: true
            )
        } else {
            UIDocumentPickerViewController(
                documentTypes: [fileType.documentType],
                in: UIDocumentPickerMode.open
            )
        }
        pickerViewController.delegate = self
        pickerViewController.allowsMultipleSelection = false
        if #available(iOS 13.0, *) {
            pickerViewController.shouldShowFileExtensions = true
        }
        return pickerViewController
    }
    
    @IBAction
    public func selectInputs() {
        pickedFileType = FileType.inputs
        
        let pickerViewController = filePicker(fileType: pickedFileType)
        self.present(pickerViewController, animated: true, completion: nil)
    }
    
    @IBAction
    public func selectGraphBinFile() {
        pickedFileType = FileType.graph
        
        let pickerViewController = filePicker(fileType: pickedFileType)
        self.present(pickerViewController, animated: true, completion: nil)
    }
    
    @IBAction
    public func selectZkeyFile() {
        pickedFileType = FileType.zkey
        
        let pickerViewController = filePicker(fileType: pickedFileType)
        self.present(pickerViewController, animated: true, completion: nil)
    }
    
    @IBAction
    public func generateWitness() {
        guard let presentInputs = inputs else {
            witnessLabel?.text = "No inputs present"
            return
        }
        
        guard let presentGraph = graph else {
            witnessLabel?.text = "No graph present"
            return
        }
        
        let start = Date()
        do {
            witness = try calculateWitness(
                inputs: presentInputs,
                graph: presentGraph
            )
            
            let diff = Date().timeIntervalSince(start)
            
            witnessLabel?.text = "Witness generated in " + String(format: "%.3f", diff) + "s"
        } catch {
            NSLog(error.localizedDescription)
        }
    }
    
    @IBAction
    public func saveWitnessFile() {
        guard let presentWitness = witness else {
            witnessLabel?.text = "No witness present"
            return
        }
        
        let temporaryFolder = FileManager.default.temporaryDirectory
        let fileName = "witness.wtns"
        let temporaryFileURL = temporaryFolder.appendingPathComponent(fileName)
        do {
            try presentWitness.write(to: temporaryFileURL)
            
            let activityController = UIActivityViewController(
                activityItems: [temporaryFileURL],
                applicationActivities: nil
            )
            self.present(activityController, animated: true, completion: nil)
        } catch {
            witnessLabel?.text = "Failed to save witness"
            print(error)
        }
    }
    
    @IBAction
    public func generateProof() {
        guard let presentZkey = zkey else {
            proofLabel?.text = "No zkey present"
            return
        }
        guard let presentWitness = witness else {
            proofLabel?.text = "No witness present"
            return
        }
        
        let start = Date()
        do {
            proof = try groth16Prove(
                zkey: presentZkey,
                witness: presentWitness
            )
            let diff = Date().timeIntervalSince(start)
            
            proofLabel?.text = "Proof generated in " + String(format: "%.3f", diff) +  " s\n" + (proof?.proof ?? "")
        } catch let error as RapidsnarkProverError {
            proofLabel?.text = "Error generating proof:" + "\n" + error.message
            NSLog(error.message)
        } catch {
            proofLabel?.text = "Error generating proof:" + "\n" + error.localizedDescription
            NSLog(error.localizedDescription)
        }
    }
    
    @IBAction
    func onCopyToClipboard() {
        let pasteBoard = UIPasteboard.general;
        pasteBoard.string = proof?.proof;
        
        // Create and present an alert controller
        let alertController = UIAlertController(
            title: "Copied",
            message: "Proof and inputs have been copied to clipboard.",
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alertController, animated: true)
    }
    
    @IBAction
    func onValidateProof() {
        if (proof == nil) {
            return
        }
        
        var valid = false
        do {
            valid = try groth16Verify(
                proof: proof!.proof.data(using: .utf8)!,
                inputs: proof!.publicSignals.data(using: .utf8)!,
                verificationKey: verificationKey!
            )
        } catch {
            proofLabel?.text = "Error validating proof:" + "\n" + error.localizedDescription
            return;
        }
        
        proofLabel?.text = "\n\nProof is " + (valid ? "valid" : "invalid")
    }
    
    @IBAction
    func onShare() {
        guard let presentProof = proof?.proof.data(using: .utf8) else {
            proofLabel?.text = "No proof present"
            return
        }
        
        let temporaryFolder = FileManager.default.temporaryDirectory
        let fileName = "proof.json"
        let temporaryFileURL = temporaryFolder.appendingPathComponent(fileName)
        do {
            try presentProof.write(to: temporaryFileURL)
            
            let activityController = UIActivityViewController(
                activityItems: [temporaryFileURL],
                applicationActivities: nil
            )
            self.present(activityController, animated: true, completion: nil)
        } catch {
            proofLabel?.text = "Failed to save proof"
            print(error)
        }
    }
    
    func inputsPath() -> String {
        return Bundle.main.path(forResource: "authV2_inputs", ofType: "json")!;
    }
    
    func zkeyPath() -> String {
        return Bundle.main.path(forResource: "authV2", ofType: "zkey")!;
    }
    
    func witnessGraphPath() -> String {
        return Bundle.main.path(forResource: "authV2", ofType: "wcd")!;
    }
    
    func verificatonKeyPath() -> String {
        return Bundle.main.path(forResource: "authV2_verification_key", ofType: "json")!;
    }
}

enum FileType {
    case zkey, graph, inputs, verificationKey;
    
    public var name : String {
        return switch self {
        case .zkey: "zkey"
        case .graph: "graph"
        case .inputs: "inputs"
        case .verificationKey: "verificationKey"
        }
    }
    
    @available(iOS 14.0, *)
    public var uttype: UTType {
        switch self {
        case .zkey:
            return UTType.data
        case .graph:
            return UTType.data
        case .inputs:
            return UTType.json
        case .verificationKey:
            return UTType.json
        }
    }
    
    public var documentType: String {
        switch self {
        case .zkey:
            return "application/octet-stream"
        case .graph:
            return "application/octet-stream"
        case .inputs:
            return "application/json"
        case .verificationKey:
            return "application/json"
        }
    }
}
