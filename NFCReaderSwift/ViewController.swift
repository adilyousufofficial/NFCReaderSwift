//
//  ViewController.swift
//  NFCReaderSwift
//
//  Created by Adil Yousuf on 13/12/2021.
//

import UIKit
import CoreNFC

struct BaseResponse<T: Codable>: Codable {
    let statusCode: Int
    let message: String!
    let data: T?
}

func printLog<T>(_ object: @autoclosure () -> T, _ file: String = #file, _ function: String = #function, _ line: Int = #line) {
    #if DEBUG
    let value = object()
    let fileURL = NSURL(string: file)?.lastPathComponent ?? "Unknown file"
    let queue = Thread.isMainThread ? "UI" : "BG"

    print("\n <\(queue)> \(fileURL) \(function)[\(line)]: " + String(reflecting: value))
    #endif
}

class ViewController: UIViewController, NFCTagReaderSessionDelegate {
    
    @IBOutlet weak var UIDLabel: UILabel!
    @IBOutlet weak var textView: UITextView!
    
    var session: NFCTagReaderSession?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func CaptureBtn(_ sender: Any) {
        self.session = NFCTagReaderSession(pollingOption: .iso14443, delegate: self)
        self.session?.alertMessage = "Hold Your Phone Near the NFC Tag"
        self.session?.begin()
        
//        let pdfFilePath = self.view.exportAsPdfFromView()
//        print(pdfFilePath)
    }
    
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        print("Session Begun!")
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        print("Error with Launching Session")
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        print("Connecting To Tag")
        if tags.count > 1 {
            session.alertMessage = "More Than One Tag Detected, Please try again"
            session.invalidate()
        }
        let tag = tags.first!
        session.connect(to: tag) { (error) in
            if nil != error{
                session.invalidate(errorMessage: error!.localizedDescription)
            }
            if case let .miFare(sTag) = tag{
                let UID = sTag.identifier.map{ String(format: "%.2hhx", $0)}.joined()
                print("UID:", UID)
                print(sTag.identifier)
                session.alertMessage = "UID Captured"
                session.invalidate()
                DispatchQueue.main.async {
                    self.UIDLabel.text = "\(UID)"
                    self.textView.text = "Loading"
                    var request: URLRequest? = nil
                    if let url = URL(string: "https://admin.jeptags.com/api/common/get-productTag-condition?tagId=\(UID)") {
                        request = URLRequest(
                            url: url,
                            cachePolicy: .useProtocolCachePolicy,
                            timeoutInterval: 30.0)
                    }
                    
                    request?.httpMethod = "GET"
                    request?.setValue("application/json", forHTTPHeaderField: "Accept")
                    //                    let error: Error? = nil
                    
                    let session = URLSession(configuration: URLSessionConfiguration.default)
                    
                    session.dataTask(with: request!) { [self] data, response, error in
                        
                        if let response = response {
                            print("RESPONSE: \(response)")
                        }
                        if let data = data {
                            print("DATA: \(data)")
                        }
                        var str: String? = nil
                        if let data = data {
                            str = String(data: data, encoding: .utf8)
                        }
                        print("\(str ?? "")")
                        
                        guard error == nil else { return }
                        
                        guard let data = data else { return }
                        
                        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                            do {
                                let strForData = String(data: data, encoding: .utf8)
                                debugPrint("API Request Response :  \(strForData ?? "")")
                                //                                let object = try JSONDecoder().decode(T.self, from: data)
                                
                                if let json = try JSONSerialization.jsonObject(with: data,
                                                                               options: [.mutableContainers]) as? [String: AnyObject] {
                                    if let apiResponse: [String : AnyObject] = json["data"] as? [String : AnyObject] {
                                        if let status = json["statusCode"] as? Int {
                                            switch status {
                                            case 200:
                                                print(strForData!)
                                            case 401:
                                                print("Not authorized")
                                                
                                            default:
                                                print(json["message"] as? String ?? "")
                                            }
                                        } else {
                                            // print(object)
                                            print(apiResponse["name"]! as! String)
                                            
                                            DispatchQueue.main.async(execute: { [self] in
                                                let longString = "Name: \(String(describing: apiResponse["name"]!)),\n Email: \(String(describing: apiResponse["email"]!)),\n Seller Id: \(String(describing: apiResponse["seller_id"]!))"
                                                self.textView.text = longString
                                            })
                                        }
                                    }
                                }
                            } catch let error {
                                printLog(error)
                                printLog(error.localizedDescription)
                                return
                            }
                        }
                    }.resume()
                }
            }
        }
    }
}

/**
 
 
//                        if response is HTTPURLResponse {
//                            var jsonError: Error?
//                            var apiResponse: [AnyHashable : Any]? = nil
////                            var apiResponse: Dictionary<String, Any>? = nil
//                            do {
//                                apiResponse = try (JSONSerialization.jsonObject(with: data, options: .allowFragments) as? Dictionary<String, Any>)!
//                            } catch let jsonError {
//                            }
//                            print("\(String(describing: apiResponse))")
////                            apiResponse = response as! [String: String]
//                            var statuss: String? = nil
//                            if let value = apiResponse!["status"] {
//                                statuss = "\(value)"
//                            }
//                            var correctCounter: String? = nil
//                            if let value = apiResponse!["counter"] {
//                                correctCounter = "\(value)"
//                            }
//                            if statuss == "1" {
//                                print(apiResponse as Any)
////                                let tagsData = apiResponse.value(forKey: "data")
////                                var correctProductID = ""
////                                var correcttagID = ""
////                                let correctType = ""
////                                let found = false
////
//////                                correcttagID = qrcode
////                                correctProductID = tagsData?.map("_id") ?? ""
////                                print(correctProductID)
////                                DispatchQueue.main.async(execute: { [self] in
//////                                    progressBar.value = 0
//////                                    qrString = "1"
////
//////                                    counter = correctCounter
//////                                    let counterId: String? = nil
//////                                    print("\(counterId ?? "")")
//////                                    print("\(counter)")
//////                                    let clod_count = counter.intValue
//////                                    var chip_count = 30
//////                                    if comingFromNFC {
//////                                        comingFromNFC = false
//////                                        chip_count = 20000000
//////                                    }
//////                                    if chip_count >= clod_count {
//////                                        SuccesFromAPI = "yes"
//////
//////                                        SuccesTAGID = qrcode
//////                                        SuccesPRODUCTID = correctProductID
//////
//////                                        callSuccus()
//////                                    } else {
//////                                        popAlertFail()
//////                                    }
////                                })
//                            } else {
//                                DispatchQueue.main.async(execute: { [self] in
////                                    progressBar.value = 0
////                                    qrString = "2"
////                                    callAlertFail()
//                                    print("failed")
//                                })
//                            }
//                        }
 */
