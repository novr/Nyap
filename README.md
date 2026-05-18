# Nyap

30分作業 + 5分休憩のリズムで、休憩時に猫オーバーレイを表示するmacOSアプリです。

## 開発ビルド

```bash
swift build
swift run
```

## 配布用ビルド

```bash
chmod +x scripts/build-distribution.sh
./scripts/build-distribution.sh
```

生成物:

- `dist/Nyap.app`
- `dist/Nyap-macOS.zip`

## 補足

- デフォルトでは未署名で出力します。
- 署名する場合は `SIGN_IDENTITY="Developer ID Application: ..."` を付けて実行してください。署名時は **ハードンドランタイム**（`--options runtime`）と **セキュアタイムスタンプ**が付きます（公証の前提条件）。
- 他の Mac で「開発元を確認できない」を避けるには、署名した ZIP を **公証（notarytool）** し、**ステープル**した配布物を渡します。

### 公証（任意・配布向け）

1. 一度だけ、App Store Connect API キーまたは Apple ID で notarytool 用プロファイルをキーチェーンに保存する。末尾の **`<profile-name>` が任意のプロファイル名**（`NOTARY_PROFILE` と同じ文字列にする）。

   **API キー（推奨）** の例:

   ```bash
   xcrun notarytool store-credentials \
     --key /path/to/AuthKey_XXXXXX.p8 \
     --key-id XXXXXX \
     --issuer <Issuer ID（UUID）> \
     MacDeveloper
   ```

   **Apple ID** の例:

   ```bash
   xcrun notarytool store-credentials \
     --apple-id "your@email.com" \
     --password "<アプリ用パスワード>" \
     --team-id <Team ID> \
     MacDeveloper
   ```
2. 署名付きビルドを作成する:

   ```bash
   SIGN_IDENTITY='Developer ID Application: …' ./scripts/build-distribution.sh
   ```

3. 公証して ZIP を差し替える:

   ```bash
   chmod +x scripts/notarize-distribution.sh
   NOTARY_PROFILE=<手順1のプロファイル名> ./scripts/notarize-distribution.sh
   ```

失敗時は `xcrun notarytool log --uuid <UUID> --keychain-profile <PROFILE>` でログを確認できます。
