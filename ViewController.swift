//
//  ViewController.swift
//  MyCNNApp
//
//  Created by 吉田成秀 on 2023/08/12.
//

import UIKit
import Accelerate

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, AddDataControllerDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    @IBAction func Addbutton(_ sender: Any) {
        let nextView = storyboard?.instantiateViewController(identifier: "Next") as! AddDataController
        nextView.delegate = self
        present(nextView, animated: true, completion: nil)
    }
    
    // グローバルな配列を定義
    var dataArray: [String] = ["Item 1", "Item 2", "Item 3", "Item 4", "Item 5"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        loadData()
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellIdentifier", for: indexPath)
        cell.weakLabel?.text = ""
        
        // セル内にラベルを生成してデータを表示（weak var で生成）
        let label = UILabel(frame: CGRect(x: 15, y: 0, width: cell.frame.width - 30, height: cell.frame.height))
        label.text = dataArray[indexPath.row]
        cell.contentView.addSubview(label)
        
        // weak var で生成したラベルをセルに関連付ける
        cell.weakLabel = label
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0 // セルの高さを指定
    }
    
    func saveData() {
        UserDefaults.standard.set(dataArray, forKey: "dataArrayKey")
    }
    
    func loadData() {
        if let savedData = UserDefaults.standard.array(forKey: "dataArrayKey") as? [String] {
            print(savedData)
            dataArray = savedData
        }
        tableView.reloadData() // ロード完了後にリロードを行う
        
        let count = dataArray.count
        var twoDimensionalArray = [[Int]]()
        print("配列の要素数は\(count)です。")
        
        for i in 0..<count {
            var arrayname = dataArray[i]
            
            var innerArray = [Int]()
            for j in 0..<count {
                if i == j {
                    innerArray.append(1)
                } else {
                    innerArray.append(0)
                }
            }
            
            if let dataArray = UserDefaults.standard.array(forKey: arrayname) as? [[Int]] {
                let count = dataArray.count
                //print("\(arrayname) Number of arrays in UserDefaults: \(count)")
                for _ in 1...count {
                    twoDimensionalArray.append(innerArray)
                }
            } else {
                print("No data found for the specified key.")
            }
            UserDefaults.standard.set(twoDimensionalArray, forKey: "AnswerArray")
        }
        
        //print(twoDimensionalArray)
    }
    
    @IBAction func cleardata(_ sender: Any) {
        UserDefaults.standard.set("", forKey: "dataArrayKey")
        tableView.reloadData()
        loadData()
        viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 画面が表示される直前にテーブルビューをリロード
        viewDidLoad()
    }
    
    // モーダルから戻ってきた際に呼ばれるメソッド
    func addDataControllerDidDismiss(_ controller: AddDataController) {
        // モーダルが閉じられた際に呼ばれるメソッドを利用してリロード
        viewDidLoad()
        print("モーダルから戻ったよ")
    }
    
    func standardizeArray(_ inputArray: [[Double]]) -> [[Double]] {
        var standardizedArray: [[Double]] = []
        
        for col in 0..<inputArray[0].count {
            var columnData: [Double] = []
            for row in 0..<inputArray.count {
                columnData.append(inputArray[row][col])
            }
            
            // Filter out NaN values from the column data
            let filteredColumnData = columnData.filter { !$0.isNaN }
            
            if filteredColumnData.isEmpty {
                // Handle the case where the entire column contains NaN values
                standardizedArray.append(columnData) // Keep NaN values as is
                continue
            }
            
            let sum = filteredColumnData.reduce(0, +)
            let mean = sum / Double(filteredColumnData.count)
            
            var squaredSum: Double = 0.0
            for value in filteredColumnData {
                let diff = value - mean
                squaredSum += diff * diff
            }
            let variance = squaredSum / Double(filteredColumnData.count)
            let standardDeviation = sqrt(variance)
            
            var standardizedColumn: [Double] = []
            for value in columnData {
                if value.isNaN {
                    standardizedColumn.append(value) // Keep NaN values as is
                } else {
                    let standardizedValue = (value - mean) / standardDeviation
                    standardizedColumn.append(standardizedValue)
                }
            }
            
            standardizedArray.append(standardizedColumn)
        }
        
        return standardizedArray
    }
    
    @IBAction func record(_ sender: Any) {
        var combinedArray: [[Int]] = []
        
        for element in dataArray {
            if let savedArray = UserDefaults.standard.array(forKey: element) as? [[Int]] {
                //print(savedArray)
                combinedArray += savedArray
            }
        }
        
        //print(combinedArray)
        UserDefaults.standard.set(combinedArray, forKey: "LearningArray")
        
        inputSize = 60000
        outputSize = dataArray.count
        self.weights = Array(repeating: Array(repeating: 0.0, count: inputSize), count: outputSize)
        self.biases = Array(repeating: 0.0, count: outputSize)
        print()
        initializeWeights()
        initializeBiases()
        
        // 学習
        var numEpochs = 100
        var learningRate = 0.01;
        
        if let savedData = UserDefaults.standard.object(forKey: "epoch") {
            if(savedData as! Int != 0){
                numEpochs = savedData as! Int
            }
        }
        
        var LearningArray: [[Double]] = []
        /*
        if let learningArray = UserDefaults.standard.array(forKey: "LearningArray") as? [[Int]] {
            var convertedArray: [[Double]] = learningArray.map { intArray in
                return intArray.map { Double($0) }
                // LearningArrayを標準化する
            }
            convertedArray = standardizeArray(convertedArray)
            print(convertedArray[0][0],"Learningcount:",convertedArray.count,convertedArray[0].count,learningArray[0].count)
            LearningArray += convertedArray
        }*/
        
        if let intArray = UserDefaults.standard.array(forKey: "LearningArray") as? [[Int]] {
            var doubleArray: [[Double]] = []
            
            for innerIntArray in intArray {
                var doubleInnerArray: [Double] = []
                for intValue in innerIntArray {
                    doubleInnerArray.append(Double(intValue))
                }
                doubleArray.append(doubleInnerArray)
            }
            
            // doubleArrayはUserDefaultsから取得した整数型2次元配列を倍精度浮動小数点数型2次元配列に変換して格納された配列です
            LearningArray = doubleArray
        } else {
            // UserDefaultsから取得できなかった場合の処理を記述することもできます
            // 例: LearningArrayをデフォルトの値で初期化する
            LearningArray = []
        }
        
        // 変換後の配列（標準化された配列）
        var standardizedArray: [[Double]] = []

        // 1. 平均を計算する
        var totalSum: Double = 0
        var totalCount: Int = 0

        for innerArray in LearningArray {
            for value in innerArray {
                totalSum += value
                totalCount += 1
            }
        }

        let mean = totalSum / Double(totalCount)

        // 2. 標準偏差を計算する
        var squaredDiffSum: Double = 0

        for innerArray in LearningArray {
            for value in innerArray {
                let diff = value - mean
                squaredDiffSum += diff * diff
            }
        }

        let variance = squaredDiffSum / Double(totalCount)
        let standardDeviation = sqrt(variance)

        // 3. 標準化された値を計算して新しい配列に追加する
        for innerArray in LearningArray {
            var standardizedInnerArray: [Double] = []
            for value in innerArray {
                let standardizedValue = (value - mean) / standardDeviation
                standardizedInnerArray.append(standardizedValue)
            }
            standardizedArray.append(standardizedInnerArray)
        }
        
        LearningArray = standardizedArray
        
        var AnswerArray: [[Double]] = []
        if let answerArray = UserDefaults.standard.array(forKey: "AnswerArray") as? [[Int]] {
            //print(answerArray)
            let convertedArray: [[Double]] = answerArray.map { intArray in
                return intArray.map { Double($0) }
            }
            AnswerArray += convertedArray
            AnsArray = AnswerArray.count
            print(AnswerArray.count,LearningArray[1].count)
        }
        
        for epoch in 0..<numEpochs {
            for i in 0..<AnswerArray.count {
                
                if LearningArray[i].isEmpty {
                    print("empty LearningArray")
                    continue // LearningArrayの要素が空の場合、次のループに進む
                }
                
                if LearningArray[i][0].isNaN {
                    for k in 0..<AnswerArray.count {
                        if LearningArray[i][k].isNaN {
                            print("NaN LearningArray")
                            LearningArray[i][k] = 0
                        }
                    }
                }
                
                var predicted = forward(inputs: LearningArray[i])
                let target = AnswerArray[i]
                let loss = crossEntropyLoss(predicted: predicted, target: target)
                backward(inputs: LearningArray[i], predicted: predicted, target: target, learningRate: learningRate)
                print("weights:", weights[0][i])
            }
            print("epoch:", epoch)
        }
        
        print("重み：　\(weights[0])ここまで","層:\(weights.count)")
        print("重み：　\(weights[1])ここまで")
        
        saveWeightsAndBiases(weights: self.weights, biases: self.biases)
    }
    
    private func saveWeightsAndBiases(weights: [[Double]], biases: [Double]) {
        UserDefaults.standard.set(weights, forKey: "SavedWeights")
        UserDefaults.standard.set(biases, forKey: "SavedBiases")
    }
    
    private var inputSize: Int = 0       // 入力サイズ
    private var outputSize: Int = 0      // 出力サイズdataArray.count
    private var AnsArray: Int = 0        // 回答要素数AnswerArray.count
    private var weights: [[Double]] = []  // 重み行列
    private var biases: [Double] = []     // バイアス
    
    private func initializeWeights() {
            let scale = sqrt(2.0 / Double(inputSize))
            for _ in 0..<outputSize {
                let row = (0..<inputSize).map { _ in Double.random(in: 0..<scale) }
                weights.append(row)
            }
        }

        private func initializeBiases() {
            biases = Array(repeating: 0.0, count: outputSize)
        }

        private func relu(_ x: Double) -> Double {
            return max(0.0, x)
        }

        private func softmax(inputs: [Double]) -> [Double] {
            let expValues = inputs.map { exp($0) }
            let sumExp = expValues.reduce(0.0, +)
            return expValues.map { $0 / sumExp }
        }

        func forward(inputs: [Double]) -> [Double] {
            var outputs = [Double](repeating: 0.0, count: outputSize)
            for i in 0..<outputSize {
                var sum = 0.0
                for j in 0..<inputSize {
                    sum += weights[i][j] * inputs[j]
                }
                outputs[i] = relu(sum + biases[i])
            }
            return softmax(inputs: outputs)
        }

        func crossEntropyLoss(predicted: [Double], target: [Double]) -> Double {
            var loss = 0.0
            for i in 0..<outputSize {
                loss += target[i] * log(predicted[i])
            }
            return -loss
        }

        func backward(inputs: [Double], predicted: [Double], target: [Double], learningRate: Double) {
            var gradients = [Double](repeating: 0.0, count: outputSize)
            for i in 0..<outputSize {
                gradients[i] = predicted[i] - target[i]
            }

            for i in 0..<outputSize {
                for j in 0..<inputSize {
                    weights[i][j] -= learningRate * gradients[i] * inputs[j]
                }
                biases[i] -= learningRate * gradients[i]
            }
        }
}

extension UITableViewCell {
    // weak var で生成されたラベルをセルと関連付けるプロパティ
    var weakLabel: UILabel? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.weakLabel) as? UILabel
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.weakLabel, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
    }
    
    private struct AssociatedKeys {
        static var weakLabel = "weakLabel"
    }
    
    @IBAction func LabelAddData(_ sender: Any) {
        labelname = weakLabel!.text!
        print("Selected name: \(labelname)")
        
        if let dataArray: [String] = UserDefaults.standard.array(forKey: "dataArrayKey") as? [String] {
            if let index = dataArray.firstIndex(of: labelname) {
                print("\(labelname)は配列の\(index + 1)番目に存在します。")
            } else {
                print("\(labelname)は配列内に存在しません。")
            }
        }
    }
}
