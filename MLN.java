import java.util.Arrays;

public class YoteiTest {//Multi-Layer Perceptron
    private int inputSize;       // 入力サイズ
    private int outputSize;      // 出力サイズ
    private double[][] weights;  // 重み行列
    private double[] biases;     // バイアス

    public YoteiTest(int inputSize, int outputSize) {
        this.inputSize = inputSize;
        this.outputSize = outputSize;
        this.weights = new double[outputSize][inputSize];
        this.biases = new double[outputSize];
        initializeWeights();
        initializeBiases();
    }

    // 重みの初期化（He初期化）
    private void initializeWeights() {
        double scale = Math.sqrt(2.0 / inputSize);
        for (int i = 0; i < outputSize; i++) {                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
            for (int j = 0; j < inputSize; j++) {
                weights[i][j] = Math.random() * scale;
            }
        }
    }

    // バイアスの初期化
    private void initializeBiases() {
        for (int i = 0; i < outputSize; i++) {
            biases[i] = 0.0;
        }
    }

    // ReLU活性化関数
    private double relu(double x) {
        return Math.max(0.0, x);
    }

    // softmax活性化関数
    private double[] softmax(double[] inputs) {
        double[] outputs = new double[outputSize];
        double sumExp = 0.0;
        for (int i = 0; i < outputSize; i++) {
            outputs[i] = Math.exp(inputs[i]);
            sumExp += outputs[i];
        }
        for (int i = 0; i < outputSize; i++) {
            outputs[i] /= sumExp;
        }
        return outputs;
    }

    // 順伝播
    public double[] forward(double[] inputs) {
        double[] outputs = new double[outputSize];
        for (int i = 0; i < outputSize; i++) {
            double sum = 0.0;
            for (int j = 0; j < inputSize; j++) {
                sum += weights[i][j] * inputs[j];
            }
            outputs[i] = relu(sum + biases[i]);
        }
        return softmax(outputs);
    }

    // エントロピー誤差
    private double crossEntropyLoss(double[] predicted, double[] target) {
        double loss = 0.0;
        for (int i = 0; i < outputSize; i++) {
            loss += target[i] * Math.log(predicted[i]);
        }
        return -loss;
    }

    // 逆伝播
    public void backward(double[] inputs, double[] predicted, double[] target, double learningRate) {
        double[] gradients = new double[outputSize];
        for (int i = 0; i < outputSize; i++) {
            gradients[i] = predicted[i] - target[i];
        }

        for (int i = 0; i < outputSize; i++) {
            for (int j = 0; j < inputSize; j++) {
                weights[i][j] -= learningRate * gradients[i] * inputs[j];
            }
            biases[i] -= learningRate * gradients[i];
        }
    }

    public static void main(String[] args) {
    	
        // 入力と出力のサイズ
        int inputSize = 4;
        int outputSize = 3;

        // 全結合層のインスタンス化
        YoteiTest fcLayer = new YoteiTest(inputSize, outputSize);

        // 学習データの入力
        double[][] inputs = {
        	{247, 183, 247, 248},  // 001
        	{254, 253,254, 133}, 
        	{245, 246,254, 254},  
        	{253, 254,245, 246},
        	{246, 254,247, 254},
        	
        	{230, 230, 247, 157},//010
        	{247, 255, 247, 157},
        	{247, 247, 255, 157},
        	
        	{247, 255,247, 255},//100
        	{230, 230, 247, 255},
        	{236, 238, 247, 255}
        	
        };

        double[][] targets = {
            {0.0, 0.0, 1.0},  // 忙しい
            {0.0, 0.0, 1.0}, 
            {0.0, 0.0, 1.0},  
            {0.0, 0.0, 1.0},   
            {0.0, 0.0, 1.0},   
            
            {0.0, 1.0, 0.0},   //普通
            {0.0, 1.0, 0.0},   
            {0.0, 1.0, 0.0},   
            
            {1.0, 0.0, 0.0},   //暇
            {1.0, 0.0, 0.0},   
            {1.0, 0.0, 0.0}   
        };

        // 学習（複数回繰り返す）
        int numEpochs = 10000000;
        double learningRate = 0.000001;

        for (int epoch = 0; epoch < numEpochs; epoch++) {
            for (int i = 0; i < inputs.length; i++) {
                double[] predicted = fcLayer.forward(inputs[i]);
                double[] target = targets[i];
                double loss = fcLayer.crossEntropyLoss(predicted, target);
                fcLayer.backward(inputs[i], predicted, target, learningRate);
            }
            System.out.println("epoch:" + epoch);
        }
        System.out.println();
        
        double[][] poolingans = {{247, 255}, {247, 190}};
        int numRows = poolingans.length;
       	int numCols = poolingans.length;
       	double[] oneDArray = new double[numRows * numCols];

       	int index = 0;
       	for (int i = 0; i < numRows; i++) {
       	    for (int j = 0; j < numCols; j++) {
       	        oneDArray[index] = poolingans[i][j];
       	        index++;
       	        System.out.print(poolingans[i][j]);
       	     	System.out.print(" ");
       	    }
       	}
       	System.out.println();
       	System.out.println();

        // 予測
        double[] testInputs = oneDArray;
        double[] predicted = fcLayer.forward(testInputs);

        // 結果の出力
        System.out.println("Predicted: " + Arrays.toString(predicted));
    }
}
