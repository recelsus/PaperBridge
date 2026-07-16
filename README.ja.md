# PaperBridge

e-Ink/e-Paper系デバイスアダプタのハードウェア処理をSystemVerilogで扱うRTLコレクション, テンプレート。
特定の完成品アプリや特定メーカーの実装依存を離れてSPIパネル制御、信号観測、フレームバッファ変換などを再利用可能な形に置き換えます。

## 方針

ソフトと RTL の役割を分離

- ソフト側: 画像読み込み、描画、リサイズ、回転、ディザリング、デバイスプロファイル、USB/BLE/network などの通信
- SystemVerilog 側: SPI ピン制御、ready/valid stream、信号キャプチャ、トリガ検出、パッキング、単純なコマンド列生成

- `rtl/`: 再利用可能な RTLモジュール
- `templates/`: 学習・bring-up・実験用テンプレート
- `sim/`: Icarus Verilog 向けの簡易テストベンチ

## テンプレート

### 01: SPI e-Paper Controller

path: `templates/01_spi_epaper_controller`

SPI 接続の e-PaperパネルやWaveshare系モジュール向けのテンプレート。

detail:

- `{dc, byte}` stream を SPI 信号へ変換
- `CS`, `SCLK`, `MOSI`, `DC`, `RST`, `BUSY` を扱う
- 固定 SPI mode 0
- MSB first
- reset low/high 時間をパラメータ指定

### 02: Protocol Capture Trigger

path: `templates/02_protocol_capture_trigger`

既存機器や既存アダプタ基板の低速信号を観測するためのテンプレート。

target:

- SPI
- UART
- GPIO
- reset / busy / data-command などの制御線

detail:

- ピン変化の edge event 化
- level 条件の false -> true 遷移検出
- timestamp 付き event 出力
- pending 中に追加 event が来た場合の sticky `overflow`

PCIe、USB high-speed、MIPI DSI などの高速差動リンクを直接観測する用途ではありません。

### 03: Framebuffer Packer

path: `templates/03_framebuffer_packer`

1bpp のピクセル列を e-Paperパネルでよく使われるpacked byte形式へ変換するテンプレート。

detail:

- 8 pixel を 1 byte に pack
- 最初の pixel を bit 7 に配置
- MSB first
- 8 pixel 未満で `pixel_last` が来た場合、未使用下位 bit は 0 埋め
- ready/valid backpressure 対応

### 04: Panel Command Builder

path: `templates/04_panel_command_builder`

controller型e-Paperパネルでよく見られる window / cursor 設定コマンド列を生成するテンプレート。

detail:

- `0x44`: RAM X address start/end
- `0x45`: RAM Y address start/end
- `0x4E`: RAM X address counter
- `0x4F`: RAM Y address counter

これらはWaveshareの公開サンプルを参考, 全てのe-Paper controller の共通仕様ではありません。

### 05: Frame Fill Generator

path: `templates/05_frame_fill_generator`

bring-up や結線確認用に、一定 byte で frame RAM を埋めるテンプレートです。

detail:

- command `0x24`
- 指定 byte の繰り返し送信
- 白消去、黒消去、SPI 波形確認用の deterministic traffic 生成

対象パネルで`0x24`が画像RAM 書き込みであるか、byteの白黒極性がどうなっているかは要確認。

## Common RTL

### ready/valid stream

多くのテンプレートは ready/valid 方式を使います。

```text
valid: producer が data を持っている
ready: consumer が data を受け取れる
data : payload
last : frame / command / packet の終端
```

転送は`valid && ready` のサイクルで成立。

### rv_skid_buffer

path: `rtl/common/rv_skid_buffer.sv`

ready/valid stream用の1 wordバッファ。

usecase:

- backpressureの吸収
- ready経路の分離
- 小規模なタイミング改善

## Test

Icarus Verilog を使います。

```sh
sudo apt install iverilog
sudo pacman -S iverilog
```
など


```sh
make test
```

個別テスト:

```sh
make test-packer
make test-capture
make test-epaper
make test-window
make test-fill
make test-skid
```

テスト対象:

- `fb_1bpp_packer`: 1bpp pixel の byte pack
- `serial_pin_capture`: edge event、level event、overflow
- `epaper_spi_stream_controller`: `{dc, byte}` の SPI 出力
- `epaper_window_sequence`: window / cursor コマンド列
- `epaper_frame_fill`: `0x24` と fill data の生成
- `rv_skid_buffer`: backpressure 中の 1 word 保持

## Caution

一部テンプレートはWaveshareの公開manualと公開サンプルコードを参考にしています。

- e-Paper controller のコマンドは完全な共通規格ではありません。
- `0x24`, `0x44`, `0x45`, `0x4E`, `0x4F` などは実用的な出発点ですが、対象パネルごとに確認が必要。
- ノーブランド機器や完成品端末では、内部controllerやcommand sequenceが異なる可能性があります。

- 特定製品の完全な初期化シーケンスは含みません。
- FPGAボード別の制約ファイルは含みません。
- USB/BLE/networkプロトコル解析はRTLの対象外。
- 高速差動信号の直接観測は対象外。
- 外部SDRAM framebufferは未対応。
- AXI4 / Wishbone / Avalon wrapperは未対応。
- 実機自動テストは一部未対応です。

## ライセンス

MIT License です。詳細は [LICENSE](LICENSE) を参照してください。
