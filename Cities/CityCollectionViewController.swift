//
//  CityCollectionViewController.swift
//  Cities
//
//  Created by Yasar on 29.01.2021.
//

import Photos
import PhotosUI
import UIKit
import TensorFlowLiteTaskVision
import SwiftUI

private let reuseIdentifier = "Cell"

class CityCollectionViewController: UICollectionViewController,PHPickerViewControllerDelegate {
    
    @IBAction func unwindToMain(segue: UIStoryboardSegue){
        
    }
    static func emptyImage(with size: CGSize) -> UIImage? {
            UIGraphicsBeginImageContext(size)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return image
        }
    private var cities : [City] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "FAvIDC Checker"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didTapAdd))


    }
    @objc private func didTapAdd() {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.selectionLimit = 1
        let vc = PHPickerViewController(configuration: config)
        vc.delegate = self
        present(vc, animated: true)
        
    }
    private var images = [UIImage]()
    private var labels = [(String,String)]()
    func picker(_ picker:PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true, completion: nil)
        let group = DispatchGroup()
        results.forEach{ result in
            group.enter()
            result.itemProvider.loadObject(ofClass: UIImage.self) {[weak self] reading, error in
                defer {
                    group.leave()
                }
                guard let image = reading as? UIImage, error==nil else{
                    return
                }
                self?.images.append(image)
            }
        }
        group.notify(queue: .main) {
            print(self.images.count)
            if(!self.images.isEmpty){
                let frame = self.buffer(from:self.images.last!)!
                let result = self.imageClassificationHelper?.classify(frame: frame)
                self.inferenceResult = result
                let strings = self.displayStringsForResults(atRow: 0, result:result!)
                self.labels.append(strings)
                self.cities.append(City(image: self.images.last!, name: strings.0))
                
                self.collectionView.reloadData()
                // Create a new alert
//                var dialogMessage = UIAlertController(title: "Results", message: String(self.cities.isEmpty), preferredStyle: .alert)
////
////                // Present alert to user
//                self.present(dialogMessage, animated: true, completion: nil)
//                self.myCollectionViewController.dataSource.insert(self.textToImage(drawText: strings.0, inImage: self.images.last!, atPoint: CGPointMake(100,200)), at: 0)
                
                
                                
            }

        }
    }
    private var imageClassificationHelper: ImageClassificationHelper? =
    ImageClassificationHelper(modelFileInfo: (name:"model-2",extension:"tflite"))
    var inferenceResult: ImageClassificationResult?=nil
    func buffer(from image: UIImage) -> CVPixelBuffer? {
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer : CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(image.size.width), Int(image.size.height), kCVPixelFormatType_32BGRA, attrs, &pixelBuffer)
        guard (status == kCVReturnSuccess) else {
            return nil
        }
      CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
      let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)

      let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
      let context = CGContext(data: pixelData, width: Int(224), height: Int(224), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)

      context?.translateBy(x: 0, y: image.size.height)
      context?.scaleBy(x: 1.0, y: -1.0)

      UIGraphicsPushContext(context!)
      image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
      UIGraphicsPopContext()
      CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))

      return pixelBuffer
    }
    func displayStringsForResults(atRow row: Int, result inferenceResult: ImageClassificationResult) -> (String, String) {
        var fieldName: String = ""
        var info: String = ""
        let tempResult = inferenceResult
        guard tempResult.classifications.categories.count > 0 else {
            
            if row == 0 {
                fieldName = "No Results"
                info = ""
            } else {
                fieldName = ""
                info = ""
            }
            
            return (fieldName, info)
        }
        
        if row < tempResult.classifications.categories.count {
            let category = tempResult.classifications.categories[row]
            if(category.index==0){
                fieldName = "FA"
            }else if(category.index == 1){
                fieldName = "IDC"
            }else {
                fieldName = String(category.index)
            }
            info = String(format: "%.2f", category.score * 100.0) + "%"
        } else {
            fieldName = ""
            info = ""
        }
        
        return (fieldName, info)
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return cities.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "dataCell", for: indexPath) as! CityCollectionViewCell
    
        // Configure the cell
        
        let city = self.cities[indexPath.row]
        cell.cityImageView.image = city.image
        cell.cityNameLabel.text = city.name
        
                
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        performSegue(withIdentifier: "showDetail", sender: nil)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPaths = collectionView.indexPathsForSelectedItems{
                let destinationController = segue.destination as! CityDetailViewController
                destinationController.city = cities[indexPaths[0].row]
                collectionView.deselectItem(at: indexPaths[0], animated: false)
            }
        }
    }
    
}
