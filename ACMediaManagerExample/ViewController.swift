//
//  ViewController.swift
//  ACMediaManagerExample
//
//  Created by Hussein AlMawla on 7/15/20.
//  Copyright © 2020 Arts'n'Code. All rights reserved.
//

import UIKit
import ACMediaManager

class ViewController: UIViewController {
    var blobs: [Blob] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func login(){
        let url = URL(string: baseUrl + "login")!
        
        var request = URLRequest(url: url)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        let parameters: [String: Any] = [
            "username": "hmawla",
            "password": "secretpass"
        ]
        request.httpBody = parameters.percentEncoded()
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let responseData = self.catchResponseData(data: data, response: response, error: error)
                else {return}
            
            do {
                //create json object from data
                if let json = try JSONSerialization.jsonObject(with: responseData, options: .mutableContainers) as? [String: Any] {
                    print(json["access_token"]!)
                    self.getTestData(accessToken: json["access_token"]! as! String)
                }
            } catch let error {
                print(error.localizedDescription)
            }
        }
        
        task.resume()
    }
    
    func getTestData(accessToken:String){
        blobs.removeAll()
        let url = URL(string: baseUrl + "post/findByUser?username=mikebrown&offset=0&max=20")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer " + accessToken, forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let responseData = self.catchResponseData(data: data, response: response, error: error)
                else {return}
            
            do {
                //create json object from data
                if let json = try JSONSerialization.jsonObject(with: responseData, options: .mutableContainers) as? [String: Any] {
                    let elements : [[String: Any]] = json["elements"]! as! [[String : Any]]
                    for post: [String: Any] in elements {
                        let blobMap = post["blob"] as! [String: Any]
                        
                        let json = try JSONSerialization.data(withJSONObject: blobMap, options: .prettyPrinted)
                        let reqJSONStr = String(data: json, encoding: .utf8)
                        let data = reqJSONStr?.data(using: .utf8)
                        
                        print("decoding: " + (blobMap["id"]! as! String))
                        let blob = try JSONDecoder().decode(OnlineBlob.self, from: data!)
                        self.blobs.append(blob.toNormalBlob())
                    }
                    self.preheatAllBlobs()
                }
            } catch let error {
                print(error)
            }
        }
        
        task.resume()
    }
    
    func preheatAllBlobs(){
        PreheatingManager.shared.preheat(blobs: blobs)
    }
    
    func catchResponseData(data:Data?, response:NSObject?, error:Error?) -> Data? {
        guard let data = data,
            let response = response as? HTTPURLResponse,
            error == nil else {                                              // check for fundamental networking error
                print("error", error ?? "Unknown error")
                return nil
        }
        
        guard (200 ... 299) ~= response.statusCode else {                    // check for http errors
            print("statusCode should be 2xx, but is \(response.statusCode)")
            print("response = \(response)")
            return nil
        }
        
        //            let responseString = String(data: data, encoding: .utf8)!
        let responseData = data
        return responseData
    }
    
    @IBAction func didTapGetData(_ sender: Any) {
        login()
    }
    
    @IBAction func didTapClearCache(_ sender: Any) {
        PreheatingManager.shared.clearCache()
    }
    
    
}


class Credentials : Codable{
    var accessToken: String?
    var refreshToken: String?
}


