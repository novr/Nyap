# Nyap Agent Guide

## プロジェクト概要
- `Nyap` は macOS 向けの Swift アプリです。
- 30分作業 + 5分休憩のリズムで、休憩時に猫オーバーレイを表示します。
- Swift Package Manager ベースで、エントリポイントは `Sources` 配下です。

## 前提環境
- macOS 14 以上
- Swift 6.2 以上（`Package.swift` 準拠）

## よく使うコマンド
- 開発ビルド: `swift build`
- 実行: `swift run`
- 配布ビルド: `chmod +x scripts/build-distribution.sh && ./scripts/build-distribution.sh`

## 生成物
- 配布ビルド後に `dist/Nyap.app` と `dist/Nyap-macOS.zip` が生成されます。
- デフォルトは未署名です。署名する場合は `SIGN_IDENTITY` を指定します。

## 変更時のガイドライン
- 既存の挙動を変える場合は、意図が分かるように差分を最小単位で実装します。
- UI/UX に関わる変更は、実行確認結果（期待挙動）を明示します。
- 配布スクリプトや署名フローを変更した場合は、README も合わせて更新します。
