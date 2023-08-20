//
//  AddLabelDataController.swift
//  MyCNNApp
//
//  Created by 吉田成秀 on 2023/08/13.
//

import Foundation
import UIKit
import Photos

class AddLabelDataController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextViewDelegate{
    @IBOutlet weak var becausetext: UITextView!
    @IBOutlet weak var LabelName: UILabel!
    
    @IBOutlet weak var imageView: UIImageView!
    let imagePicker = UIImagePickerController()
    var elementsToAdd = [1]
    var epochs = 1
    var mode = false

    override func viewDidLoad() {
        super.viewDidLoad()
        LabelName.text = labelname
        imagePicker.delegate = self
        loadData()
        
        // キーボードのアクセサリービューを設定
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "完了", style: .plain, target: self, action: #selector(doneButtonTapped))
        toolbar.setItems([doneButton], animated: false)
        becausetext.inputAccessoryView = toolbar
    }
    
    func squareImage(image: UIImage) -> UIImage? {
        let imageSize = image.size
        let sideLength = min(imageSize.width, imageSize.height)
        let squareSize = CGSize(width: sideLength, height: sideLength)

        UIGraphicsBeginImageContextWithOptions(squareSize, false, 0.0)
        let drawRect = CGRect(x: 0, y: 0, width: sideLength, height: sideLength)
        image.draw(in: drawRect)
        let squareImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return squareImage
    }
    
    // キーボードのアクセサリービューの「完了」ボタンがタップされたときの処理
    @objc func doneButtonTapped() {
        becausetext.resignFirstResponder() // キーボードを閉じる
    }
    
    @IBAction func A(_ sender: Any) {
        if ( (sender as AnyObject).isOn ) {
            if(epochs != 10){
                epochs = 5
            }
            mode = true
        } else {
            if(epochs != 10){
                epochs = 1
            }
            mode = false
        }
    }
    
    @IBAction func B(_ sender: Any) {
        if ( (sender as AnyObject).isOn ) {
            epochs = 10
        } else {
            if(mode != false){
                epochs = 5
            }else{
                epochs = 1
            }
        }
    }
    
    @IBAction func SuccesButton(_ sender: Any) {
        print(labelname)
        saveData()
    }

    func saveData() {
        UserDefaults.standard.set(becausetext.text, forKey: "\(LabelName.text!)becausetext")
    }

    func loadData() {
        if let savedData = UserDefaults.standard.string(forKey: "\(LabelName.text!)becausetext") {
            becausetext.text = savedData
            print("\(LabelName.text!)becausetext")
        }
    }

    // キーボードのReturnキーを押すとキーボードを閉じる
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func pickImage(_ sender: UIButton) {
        let status = PHPhotoLibrary.authorizationStatus()
        if status == .authorized {
            imagePicker.sourceType = .photoLibrary
            present(imagePicker, animated: true, completion: nil)
        } else if status == .notDetermined {
            PHPhotoLibrary.requestAuthorization { [weak self] status in
                if status == .authorized {
                    self?.imagePicker.sourceType = .photoLibrary
                    self?.present(self!.imagePicker, animated: true, completion: nil)
                } else {
                    // ユーザーが許可しなかった場合の処理
                    print("アルバムへのアクセスが拒否されました。")
                }
            }
        } else {
            // すでにアクセスが拒否されている場合の処理
            print("アルバムへのアクセスが拒否されています。")
        }
    }
    
    // 二次元配列をUserDefaultsから取得する関数
    func getTwoDimensionalArray() -> [[Int]] {
        if let savedArray = UserDefaults.standard.array(forKey: labelname) as? [[Int]] {
            return savedArray
        } else {
            return []
        }
    }

    // 二次元配列をUserDefaultsに保存する関数
    func saveTwoDimensionalArray(_ array: [[Int]]) {
        UserDefaults.standard.set(array, forKey: labelname)
    }

    // 配列を一つの要素として追加する関数
    func addArrayToTwoDimensionalArray(_ array: [Int]) {
        var currentArray = getTwoDimensionalArray()
        currentArray.append(array)
        saveTwoDimensionalArray(currentArray)
    }
    
    func TwoDimensionalArray() {
        addArrayToTwoDimensionalArray(elementsToAdd)
        let savedArray = getTwoDimensionalArray()
        
        for (index, row) in savedArray.enumerated() {
            //print("Row \(index + 1): \(row)")
        }
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[.originalImage] as? UIImage {
            let resizedImage = resizeImage(image: selectedImage, targetSize: CGSize(width: 1600, height: 600)) // 1200x600にリサイズ
            imageView.image = resizedImage
            
            // 画像のピクセル値を配列として取得
            if let pixelData = resizedImage.pixelData() {
                // グレースケール画像に変換
                if let grayscaleData = convertToGrayscale(pixelData: pixelData) {
                    let reshapedGrayscaleData = reshapeGrayscaleData(grayscaleData: grayscaleData, width: 1600, height: 600)
                    // 最大値プーリングを実行
                    if let pooledData = performMaxPooling(reshapedGrayscaleData: reshapedGrayscaleData, poolSize: 4) {
                        // 一次元配列に変換
                        var pooledFlatData = pooledData.flatMap { $0 }
                        
                        // 一次元配列をUIImageに変換
                        if let pooledImage = createImageFromFlatData(flatData: pooledFlatData, width: 400) { // 400はリサイズ後の幅
                            // imageViewに表示
                            print("Pooled Flat Data: \(pooledFlatData)")
                            let intArray: [Int] = pooledFlatData.map { Int($0) }
                            elementsToAdd = intArray
                            
                            for _ in 0..<epochs {
                                TwoDimensionalArray()
                                print("go")
                            }
                            
                            imageView.image = pooledImage
                            let count = pooledFlatData.count
                            print("配列の要素数: \(count)")
                        }
                    }
                }
            }
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    // 一次元配列からUIImageを生成
    func createImageFromFlatData(flatData: [UInt8], width: Int) -> UIImage? {
        let height = flatData.count / width
        let bitsPerComponent = 8
        let bytesPerPixel = 1
        let bytesPerRow = bytesPerPixel * width
        let colorSpace = CGColorSpaceCreateDeviceGray()
        
        var imageData = flatData
        
        let context = CGContext(data: &imageData,
                                width: width,
                                height: height,
                                bitsPerComponent: bitsPerComponent,
                                bytesPerRow: bytesPerRow,
                                space: colorSpace,
                                bitmapInfo: CGImageAlphaInfo.none.rawValue)
        
        if let cgImage = context?.makeImage() {
            return UIImage(cgImage: cgImage)
        }
        
        return nil
    }
    
    // 最大値プーリングを実行
    func performMaxPooling(reshapedGrayscaleData: [[[UInt8]]], poolSize: Int) -> [[UInt8]]? {
        let inputHeight = reshapedGrayscaleData.count
        let inputWidth = reshapedGrayscaleData[0].count
        
        let outputHeight = inputHeight / poolSize
        let outputWidth = inputWidth / poolSize
        
        var pooledData = [[UInt8]](repeating: [UInt8](repeating: 0, count: outputWidth), count: outputHeight)
        
        for y in 0..<outputHeight {
            for x in 0..<outputWidth {
                var maxPixelValue: UInt8 = 0
                
                for poolY in 0..<poolSize {
                    for poolX in 0..<poolSize {
                        let inputY = y * poolSize + poolY
                        let inputX = x * poolSize + poolX
                        
                        let pixelValue = reshapedGrayscaleData[inputY][inputX][0]
                        if pixelValue > maxPixelValue {
                            maxPixelValue = pixelValue
                        }
                    }
                }
                
                pooledData[y][x] = maxPixelValue
            }
        }
        
        return pooledData
    }

    // 二次元配列からUIImageを生成
    func createImageFromPooledData(pooledData: [[UInt8]]) -> UIImage? {
        let height = pooledData.count
        let width = pooledData[0].count
        let bitsPerComponent = 8
        let bytesPerPixel = 1
        let bytesPerRow = bytesPerPixel * width
        let colorSpace = CGColorSpaceCreateDeviceGray()
        
        var imageData = [UInt8]()
        for y in 0..<height {
            for x in 0..<width {
                imageData.append(pooledData[y][x])
            }
        }
        
        let context = CGContext(data: &imageData,
                                width: width,
                                height: height,
                                bitsPerComponent: bitsPerComponent,
                                bytesPerRow: bytesPerRow,
                                space: colorSpace,
                                bitmapInfo: CGImageAlphaInfo.none.rawValue)
        
        if let cgImage = context?.makeImage() {
            return UIImage(cgImage: cgImage)
        }
        
        return nil
    }

    // グレースケールデータからUIImageを生成
    func createImageFromGrayscaleData(reshapedGrayscaleData: [[[UInt8]]]) -> UIImage? {
        let width = reshapedGrayscaleData[0].count
        let height = reshapedGrayscaleData.count
        let bitsPerComponent = 8
        let bytesPerPixel = 1
        let bytesPerRow = bytesPerPixel * width
        let colorSpace = CGColorSpaceCreateDeviceGray()
        
        var imageData = [UInt8]()
        for y in 0..<height {
            for x in 0..<width {
                imageData.append(reshapedGrayscaleData[y][x][0])
            }
        }
        
        let context = CGContext(data: &imageData,
                                width: width,
                                height: height,
                                bitsPerComponent: bitsPerComponent,
                                bytesPerRow: bytesPerRow,
                                space: colorSpace,
                                bitmapInfo: CGImageAlphaInfo.none.rawValue)
        
        if let cgImage = context?.makeImage() {
            return UIImage(cgImage: cgImage)
        }
        
        return nil
    }

    // カラーチャンネルからグレースケール値を計算し、新しいピクセルデータを生成
    func convertToGrayscale(pixelData: [UInt8]) -> [UInt8]? {
        var grayscaleData = [UInt8]()
        
        for i in stride(from: 0, to: pixelData.count, by: 4) {
            let red = Double(pixelData[i])
            let green = Double(pixelData[i + 1])
            let blue = Double(pixelData[i + 2])
            
            // グレースケール値の計算
            let grayscaleValue = UInt8((red * 0.299) + (green * 0.587) + (blue * 0.114))
            
            grayscaleData.append(grayscaleValue)
        }
        
        return grayscaleData
    }
    
    // グレースケール値の配列を4次元4行の配列で再出力
    func reshapeGrayscaleData(grayscaleData: [UInt8], width: Int, height: Int) -> [[[UInt8]]] {
        var reshapedData = [[[UInt8]]](repeating: [[UInt8]](repeating: [UInt8](repeating: 0, count: 1), count: width), count: height)
        var dataIndex = 0
        
        for y in 0..<height {
            for x in 0..<width {
                reshapedData[y][x] = [grayscaleData[dataIndex]]
                dataIndex += 1
            }
        }
        
        // Example kernel for edge detection
        let edgeDetectionKernel: [[Int]] = [
            [-1, 0, 1],
            [-2, 0, 2],
            [-1, 0, 1]
        ]
        
        return (applyConvolution(image: reshapedData, kernel: edgeDetectionKernel))
    }
    
    func applyConvolution(image: [[[UInt8]]], kernel: [[Int]], padding: Int = 0) -> [[[UInt8]]] {
        let height = image.count
        let width = image[0].count
        let kernelSize = kernel.count
        let paddedWidth = width + 2 * padding
        let paddedHeight = height + 2 * padding
        
        var convolvedImage = [[[UInt8]]](repeating: [[UInt8]](repeating: [UInt8](repeating: 0, count: 1), count: width), count: height)
        
        for y in 0..<height {
            for x in 0..<width {
                var sum: Int = 0
                
                for ky in 0..<kernelSize {
                    for kx in 0..<kernelSize {
                        let imgX = x + kx - kernelSize / 2
                        let imgY = y + ky - kernelSize / 2
                        
                        if imgX >= 0 && imgX < width && imgY >= 0 && imgY < height {
                            sum += Int(image[imgY][imgX][0]) * kernel[ky][kx]
                        }
                    }
                }
                
                sum = max(0, min(255, sum))
                convolvedImage[y][x][0] = UInt8(sum)
            }
        }
        
        return convolvedImage
    }
    
    func invertGrayscaleImage(data: [[[UInt8]]]) -> [[[UInt8]]] {
        var invertedData: [[[UInt8]]] = []
        
        for row in data {
            var invertedRow: [[UInt8]] = []
            for pixel in row {
                var invertedPixel: [UInt8] = []
                for channel in pixel {
                    invertedPixel.append(255 - channel) // 白黒を反転させる
                }
                invertedRow.append(invertedPixel)
            }
            invertedData.append(invertedRow)
        }
        
        return invertedData
    }
    
    // 画像のピクセルデータを指定した幅と高さの4次元4行配列に変換
    func reshapePixelData(pixelData: [UInt8], width: Int, height: Int) -> [[[UInt8]]] {
        var reshapedData = [[[UInt8]]](repeating: [[UInt8]](repeating: [UInt8](repeating: 0, count: 4), count: width), count: height)
        var dataIndex = 0
        
        for y in 0..<height {
            for x in 0..<width {
                reshapedData[y][x] = [pixelData[dataIndex], pixelData[dataIndex + 1], pixelData[dataIndex + 2], pixelData[dataIndex + 3]]
                dataIndex += 4
            }
        }
        
        return reshapedData
    }

    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        
        let newSize: CGSize
        if widthRatio > heightRatio {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        
        return resizedImage
    }
}

extension UIImage {
    func pixelData() -> [UInt8]? {
        let cgImage = self.cgImage
        let width = cgImage?.width
        let height = cgImage?.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width!
        let bitsPerComponent = 8
        var pixelData = [UInt8](repeating: 0, count: width! * height! * bytesPerPixel)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: &pixelData,
                                width: width!,
                                height: height!,
                                bitsPerComponent: bitsPerComponent,
                                bytesPerRow: bytesPerRow,
                                space: colorSpace,
                                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
        
        context?.draw(cgImage!, in: CGRect(x: 0, y: 0, width: width!, height: height!))
        
        return pixelData
    }
}
