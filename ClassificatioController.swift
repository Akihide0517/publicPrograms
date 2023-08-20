//
//  ClassificatioController.swift
//  MyCNNApp
//
//  Created by 吉田成秀 on 2023/08/14.
//

import Foundation
import UIKit
import Photos
import Accelerate

// 画像のリサイズとピクセルデータ取得を行う拡張
extension UIImage {
    func resize(targetSize: CGSize) -> UIImage? {
        let size = self.size
        
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        
        let newSize: CGSize
        if widthRatio > heightRatio {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }
        
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    func convertToGrayScale() -> UIImage? {
        let context = CIContext(options: nil)
        if let currentFilter = CIFilter(name: "CIPhotoEffectMono") {
            currentFilter.setValue(CIImage(image: self), forKey: kCIInputImageKey)
            if let output = currentFilter.outputImage, let cgImage = context.createCGImage(output, from: output.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        return nil
    }
}

class ClassificatioController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var becouseText: UITextView!
    @IBOutlet weak var ClassificationText: UITextView!
    @IBOutlet weak var ClaImage: UIImageView!
    
    var outputSize = 3
    var inputSize = 60000
    let imagePicker = UIImagePickerController()
    let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
    }
    
    @IBAction func action(_ sender: Any) {
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
    
    // プーリングを行う関数
    func performPooling(matrix: [[UInt8]], poolSize: Int) -> [[UInt8]] {
        var result: [[UInt8]] = []
        let numRows = matrix.count
        let numCols = matrix[0].count
        for row in stride(from: 0, to: numRows, by: poolSize) {
            var rowResult: [UInt8] = []
            for col in stride(from: 0, to: numCols, by: poolSize) {
                var sum: UInt32 = 0
                for i in 0..<poolSize {
                    for j in 0..<poolSize {
                        let rowIndex = row + i
                        let colIndex = col + j
                        if rowIndex < numRows && colIndex < numCols {
                            sum += UInt32(matrix[rowIndex][colIndex])
                        }
                    }
                }
                let average = UInt8(sum / UInt32(poolSize * poolSize))
                rowResult.append(average)
            }
            result.append(rowResult)
        }
        return result
    }
    
    // 4x4のベクトルに畳み込みを行う関数
    func performConvolution(pixelData: [UInt8]) -> [[UInt8]] {
        var result: [[UInt8]] = []
        let blockSize = 4
        for row in 0..<blockSize {
            var rowResult: [UInt8] = []
            for col in 0..<blockSize {
                let blockStartIndex = row * blockSize + col
                let pixelValue = pixelData[blockStartIndex]
                rowResult.append(pixelValue)
            }
            result.append(rowResult)
        }
        return result
    }
    
    // 配列内の平均値を計算する関数
    func calculateAverage(of array: [UInt8]) -> UInt8 {
        var sum: UInt32 = 0
        for value in array {
            sum += UInt32(value)
        }
        return UInt8(sum / UInt32(array.count))
    }
    
    func findNearestToOneIndex(_ array: [Double]) -> Int? {
        var nearestIndex: Int?
        var minDistance: Double = Double.infinity

        for (index, value) in array.enumerated() {
            let distanceTo1 = abs(value - 1.0)
            if distanceTo1 < minDistance {
                minDistance = distanceTo1
                nearestIndex = index
            }
        }

        return nearestIndex
    }
    
    // pooledDataを正規化する関数
    func normalizePooledData(_ pooledData: [[UInt8]]) -> [[Float]] {
        var normalizedData: [[Float]] = []
        
        // 最小値と最大値を求める
        var minValue: Float = Float(UInt8.max)
        var maxValue: Float = 0.0
        
        for row in pooledData {
            for value in row {
                if Float(value) < minValue {
                    minValue = Float(value)
                }
                if Float(value) > maxValue {
                    maxValue = Float(value)
                }
            }
        }
        
        // 正規化を行う
        for row in pooledData {
            var normalizedRow: [Float] = []
            for value in row {
                let normalizedValue = (Float(value) - minValue) / (maxValue - minValue)
                normalizedRow.append(normalizedValue)
            }
            normalizedData.append(normalizedRow)
        }
        
        return normalizedData
    }
    
    func convertFloatArrayToUInt8Array(floatArray: [[Float]]) -> [UInt8] {
        var uint8Array: [UInt8] = []
        
        for row in floatArray {
            for value in row {
                // 浮動小数点数を0〜255の範囲にスケーリングして符号なし整数に変換
                let scaledValue = UInt8(max(0, min(255, value * 255)))
                uint8Array.append(scaledValue)
            }
        }
        
        return uint8Array
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[.originalImage] as? UIImage {
            let resizedImage = resizeImage(image: selectedImage, targetSize: CGSize(width: 1600, height: 600))
            ClaImage.image = selectedImage
            
            // 画像のピクセル値を配列として取得
            if let pixelData = resizedImage.pixelData() {
                // グレースケール画像に変換
                if let grayscaleData = convertToGrayscale(pixelData: pixelData) {
                    // 4次元4行の配列に変換
                    let reshapedGrayscaleData = reshapeGrayscaleData(grayscaleData: grayscaleData, width: 1600, height: 600)
                    
                    // 最大値プーリングを実行
                    if let pooledData = performMaxPooling(reshapedGrayscaleData: reshapedGrayscaleData, poolSize: 4) {
                        
                        let normalizedPooledData = normalizePooledData(pooledData)
                        
                        // 一次元配列に変換
                        var pooledFlatData = normalizedPooledData.compactMap { $0 }
                        
                        // 正規化
                        let pooledFlatData2 = convertFloatArrayToUInt8Array(floatArray: normalizedPooledData)
                        pooledFlatData = pooledFlatData2.map { UInt8($0) }.map { [Float($0) / 255.0] }
                        //print("正規化", pooledFlatData)

                        // 一次元配列をUIImageに変換
                        if let pooledImage = createImageFromFlatData(flatData: pooledFlatData2, width: 400) {
                            //ClaImage.image = pooledImage
                        }
                        
                        // 予測などの処理を続ける
                        var poolingans = pooledFlatData
                        let numRows = poolingans.count
                        let numCols = poolingans[0].count
                        var oneDArray = [Double](repeating: 0.0, count: numRows * numCols)
                        if let savedData = UserDefaults.standard.array(forKey: "dataArrayKey") as? [String] {
                            self.outputSize = savedData.count
                        }

                        var index = 0
                        for i in 0..<numRows {
                            for j in 0..<numCols {
                                oneDArray[index] = Double(poolingans[i][j])
                                index += 1
                                //print(poolingans[i][j], terminator: " ")
                            }
                        }
                        
                        var testInputs = oneDArray
                        for i in 0..<testInputs.count {
                            if testInputs[i].isNaN {
                                print("NaN testInputs")
                                testInputs[i] = 0
                            }
                        }
                        
                        let predicted = self.forward(inputs: testInputs)

                        // 結果
                        print("Predicted:", predicted)
                        UserDefaults.standard.set("\(predicted)", forKey: "lastmessage")
                        if let predictedIndex = self.findNearestToOneIndex(predicted) {
                            print("Nearest to 1.0: Index \(predictedIndex), Value \(predicted[predictedIndex])")
                            
                            if let savedData = UserDefaults.standard.array(forKey: "dataArrayKey") as? [String] {
                                if predictedIndex < savedData.count {
                                    let nearestData = savedData[predictedIndex]
                                    ClassificationText.text = "分類名: ”\(nearestData)”"
                                    //print(pooledFlatData)
                                    if let savedData = UserDefaults.standard.string(forKey: "\(nearestData)becausetext") {
                                        becouseText.text = savedData
                                        //print(savedData)
                                        //print("\(nearestData)becausetext.")
                                    }
                                }
                            }
                        } else {
                            print("No value near 1.0 found.")
                        }
                    }
                }
            }
        }
        picker.dismiss(animated: true, completion: nil)
        //print("\(weights[0]):\(biases[0])")
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
    
    // グレースケール値の配列を4次元4行の配列に畳み込んで再出力
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
        
        return ( applyConvolution(image: reshapedData, kernel: edgeDetectionKernel))
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
    
    func predictUsingSavedWeightsAndBiases(inputs: [Double]) -> [Double] {
        let savedWeights = UserDefaults.standard.array(forKey: "SavedWeights") as? [[Double]] ?? []
        let savedBiases = UserDefaults.standard.array(forKey: "SavedBiases") as? [Double] ?? []
        if let savedData = UserDefaults.standard.array(forKey: "dataArrayKey") as? [String] {
            outputSize = savedData.count
        }
        
        // Check if the saved weights and biases have the expected sizes
        guard savedWeights.count == outputSize && savedBiases.count == outputSize else {
            fatalError("Saved weights or biases do not have the expected sizes.")
        }
        
        var outputs = [Double](repeating: 0.0, count: outputSize)
        for i in 0..<outputSize {
            var sum = 0.0
            for j in 0..<inputSize {
                sum += savedWeights[i][j] * inputs[j]
            }
            outputs[i] = relu(sum + savedBiases[i])
        }
        return softmax(outputs)
    }

    private var weights: [[Double]] = UserDefaults.standard.array(forKey: "SavedWeights") as? [[Double]] ?? []  // 重み行列
    private var biases: [Double] = UserDefaults.standard.array(forKey: "SavedBiases") as? [Double] ?? []     // バイアス
    
    // 重みの初期化（He初期化）
    private func initializeWeights() {
        let scale = sqrt(2.0 / Double(inputSize))
        for _ in 0..<outputSize {
            let row = (0..<inputSize).map { _ in Double.random(in: 0..<scale) }
            weights.append(row)
        }
    }
    // バイアスの初期化
    private func initializeBiases() {
        biases = Array(repeating: 0.0, count: outputSize)
    }

    private func relu(_ x: Double) -> Double {
        return max(0.0, x)
    }

    // softmax活性化関数
    private func softmax(_ inputs: [Double]) -> [Double] {
        var outputs = [Double](repeating: 0.0, count: outputSize)
        var sumExp = 0.0
        for i in 0..<outputSize {
            outputs[i] = exp(inputs[i])
            sumExp += outputs[i]
        }
        for i in 0..<outputSize {
            outputs[i] /= sumExp
        }
        return outputs
    }
    
    func forward(inputs: [Double]) -> [Double] {
        print("重み：　\(weights[0])ここまで")
        var outputs = [Double](repeating: 0.0, count: outputSize)
        for i in 0..<outputSize {
            var sum = 0.0
            for j in 0..<inputSize {
                sum += weights[i][j] * inputs[j]
            }
            outputs[i] = relu(sum + biases[i])
        }
        return softmax(outputs)
    }

    // エントロピー誤差
    private func crossEntropyLoss(predicted: [Double], target: [Double]) -> Double {
        var loss = 0.0
        for i in 0..<outputSize {
            loss += target[i] * log(predicted[i])
        }
        return -loss
    }

    // 逆伝播
    func backward(inputs: [Double], predicted: [Double], target: [Double], learningRate: Double) {
        var gradients = [Double](repeating: 0.0, count: outputSize)
        for i in 0..<outputSize {
            gradients[i] = predicted[i] - target[i]
        }

        for i in 0..<inputSize {
            for j in 0..<inputs.count {
                weights[i][j] -= learningRate * gradients[i] * inputs[j]
            }
            biases[i] -= learningRate * gradients[i]
        }
    }

}
