# publicPrograms
jarファイルはjavaでの全結合層の試作品です。そのままでは閲覧できないため、テキストファイル版もあります。

swiftファイルはpdfの内容に則ったアプリで実際に使用したプログラムです。動作確認用の動画もあります。

O＋＋.jarはjavaで自作した擬似プログラミング言語です。以下はO++のサンプルコードです

["step",
  ["set", "i", 10],
  ["set", "sum", 0],
  ["until", ["=", ["get", "i"], 0], [
    "step",
    ["set", "sum", ["+", ["get", "sum"], ["get", "i"]]],
    ["set", "i", ["+", ["get", "i"], -1]]
  ]],
  ["get", "sum"]
]
