# PomodoroCat

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

- `dist/PomodoroCat.app`
- `dist/PomodoroCat-macOS.zip`

## 補足

- デフォルトでは未署名で出力します。
- 署名する場合は `SIGN_IDENTITY="Developer ID Application: ..."` を付けて実行してください。
- 他端末へ配布する場合、必要に応じて公証してください。
