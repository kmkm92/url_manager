import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class UrlSummary extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
        body: Scrollbar(
      child: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            title: const Text('要約'),
            floating: true,
            expandedHeight: 30.0.h,
            actions: [
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.replay),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(3.w),
              child: Markdown(
                data: markdownText,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
              ),
            ),
          ),
        ],
      ),
    ));
  }
}

final String markdownText = '''
# ChatGPTのAPI料金詳細（GPT-4o対応版）！各プランのコスト比較・支払い方法・削減5ポイント！ - AI Market

最終更新日：2024-05-20

## 1. ChatGPT APIの料金プラン

OpenAIのAPIは、利用量に応じた従量課金制であり、初期コストを抑えつつ、ビジネスの成長に合わせて柔軟にAIの活用を拡大できます。APIを利用することで、自社のプロジェクトにOpenAIの先進的なAIモデルの能力を組み込むことが可能です。また、APIを使う場合、契約アカウント数や月額料金を気にする必要がありません。

### 1.1 APIを利用可能なOpenAIのモデル一覧

- **GPT-4o**: マルチモーダルに対応した高速な言語モデル
- **GPT-4/GPT-4 Turbo**: 言語理解と推論能力に優れ、長文脈にも対応
- **GPT-3.5 Turbo**: GPT-3.5の高速版で、コスト効率に優れる
- **DALL･E 3およびDALL･E 2**: テキストから画像生成・編集が可能
- **TTS**: テキストを音声に変換
- **Whisper**: 音声をテキストに変換
- **Embeddings**: テキストをベクトル形式に変換

### 1.2 API課金単位はトークン数

API利用料は、選択されたAIモデルと消費されたトークン数に基づいて従量課金されます。トークンはテキストデータの量を表す単位であり、英語での単語や記号などを指します。日本語や中国語は英語に比べて一文を表現するのにより多くのトークンを必要とします。

## 2. 料金プラン比較

| モデル名        | 100万トークン当たりの料金（入力） | 100万トークン当たりの料金（出力） | 150×150ピクセル画像の生成料金（試算） |
|-----------------|---------------------------------|-----------------------------------|---------------------------------------|
| GPT-3.5 Turbo   | 0.5ドル（約75円）               | 1.5ドル（約225円）               | 対応なし                              |
| GPT-4           | 30ドル（約4,500円）             | 60ドル（約9,000円）               | 対応なし                              |
| GPT-4 Turbo     | 10ドル（約1,500円）             | 30ドル（約4,500円）               | 0.00255ドル（約0.38円）               |
| GPT-4o          | 5ドル（約750円）                | 15ドル（約2,250円）               | 0.001275ドル（約0.19円）              |

「GPT-3.5 Turbo」はコストパフォーマンスに優れ、高度な分析や複雑な言語タスクを求める場合は「GPT-4」や「GPT-4 Turbo」、および「GPT-4o」の採用を検討する価値があります。

## 3. API料金の支払い方法

OpenAIでは、API料金の支払いにクレジットカードを使用することができます。

### 3.1 支払い方法の登録手順

1. ChatGPTの支払いページにアクセス
2. 「Payment Methods」を選択後、クレジットカード情報の登録画面へ進む
3. 必要な情報を入力し、手続きを完了させる

### 3.2 利用上限の設定

「Usage Limits」から、1ヶ月あたりの利用上限額を設定することができます。

## 4. ChatGPT API利用料金を節約する5つの方法

### 4.1 無料枠の利用

OpenAIは、新規ユーザーに対し約5ドル分（約750円）の無料枠を提供しています。

### 4.2 最適なAIモデルの選択

用途に応じてコストパフォーマンスの良いモデルを選択することが重要です。

### 4.3 最大トークン数（max_tokens）の適切な設定

応答に必要な情報量を考慮して、max_tokensの値を適切に設定します。

### 4.4 入力文字数の最適化

質問や指示はできるだけ簡潔にし、不要な背景情報や前置きは省略します。

### 4.5 英語入力の推奨

リクエストを英語で行うことで、より少ないトークンで同じ量の情報を伝えることができ、コストを抑えることができます。

## 5. ChatGPT APIの料金についてよくある質問まとめ

### GPTのAPIに無料枠はありますか？

はい、新規ユーザーに対して約5ドル分（約750円）の無料枠があります。

### GPT APIの支払い方法を変更するにはどうすればよいですか？

ChatGPTの支払いページから「Billing」を選択し、「Payment Methods」でクレジットカード情報を更新します。

## 6. まとめ

ChatGPT APIの利用では、料金プランを理解し、目的に合ったモデルを選択し、トークン数を効率的に管理することがコスト削減につながります。支払い方法の選択には、利便性とコストのバランスを考慮することが重要です。

---

AI MarketではChatGPTをはじめとするLLMのカスタマイズ実績豊富なAI開発会社の選定・紹介を行っています。貴社に最適な会社に手間なく数日で出会えます。
''';
