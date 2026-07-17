# PaperBridge

e-Ink/e-Paper系デバイスアダプタのハードウェア処理をSystemVerilogで扱うRTLコレクション, テンプレート。
特定の完成品アプリや特定メーカーの実装依存を離れてSPIパネル制御、信号観測、フレームバッファ変換などを再利用可能な形に置き換えます。

## 方針

ソフトと RTL の役割を分離

- ソフト側: 画像読み込み、描画、リサイズ、回転、ディザリング、デバイスプロファイル、USB/BLE/network などの通信
- SystemVerilog 側: SPI ピン制御、ready/valid stream、信号キャプチャ、トリガ検出、パッキング、単純なコマンド列生成

- `rtl/`: 再利用可能な RTLモジュール
- `templates/`: 学習・bring-up・実験用テンプレート
- `examples/`: panel profile や sequence を追加するための出発点
- `sim/`: Icarus Verilog 向けの簡易テストベンチ
- `paperbridge.f`: 外部ツールや外部プロジェクト向けの RTL ファイルリスト

## テンプレート

### 01: SPI e-Paper Controller

path: `templates/01_spi_epaper_controller`

SPI 接続の e-PaperパネルやWaveshare系モジュール向けのテンプレート。
再利用 RTL: `rtl/epaper/epaper_spi_stream_controller.sv`

detail:

- `{dc, byte}` stream を SPI 信号へ変換
- `CS`, `SCLK`, `MOSI`, `DC`, `RST`, `BUSY` を扱う
- 固定 SPI mode 0
- MSB first
- reset low/high 時間をパラメータ指定

### 02: Protocol Capture Trigger

path: `templates/02_protocol_capture_trigger`

既存機器や既存アダプタ基板の低速信号を観測するためのテンプレート。
再利用 RTL: `rtl/capture/serial_pin_capture.sv`

target:

- SPI
- UART
- GPIO
- reset / busy / data-command などの制御線

detail:

- ピン変化の edge event 化
- rising edge / falling edge の個別 enable
- `arm_i` による capture enable
- level 条件の false -> true 遷移検出
- timestamp 付き event 出力
- 小規模 FIFO による複数 pending event の保持
- FIFO full 中に追加 event が来た場合の sticky `overflow`

PCIe、USB high-speed、MIPI DSI などの高速差動リンクを直接観測する用途ではありません。

### 03: Framebuffer Packer

path: `templates/03_framebuffer_packer`

1bpp のピクセル列を e-Paperパネルでよく使われるpacked byte形式へ変換するテンプレート。
再利用 RTL: `rtl/framebuffer/fb_1bpp_packer.sv`

detail:

- 8 pixel を 1 byte に pack
- default では最初の pixel を bit 7 に配置
- MSB first / LSB first の bit order 指定
- 入力 pixel の反転指定
- 8 pixel 未満で `pixel_last` が来た場合、未使用 bit は 0 埋め
- ready/valid backpressure 対応

### 04: Panel Command Builder

path: `templates/04_panel_command_builder`

controller型e-Paperパネルでよく見られる window / cursor 設定コマンド列を生成するテンプレート。
再利用 RTL: `rtl/epaper/epaper_window_sequence.sv`

detail:

- `0x44`: RAM X address start/end
- `0x45`: RAM Y address start/end
- `0x4E`: RAM X address counter
- `0x4F`: RAM Y address counter

これらはWaveshareの公開サンプルを参考, 全てのe-Paper controller の共通仕様ではありません。

### 05: Frame Fill Generator

path: `templates/05_frame_fill_generator`

bring-up や結線確認用に、一定 byte で frame RAM を埋めるテンプレートです。
再利用 RTL: `rtl/epaper/epaper_frame_fill.sv`

detail:

- command `0x24`
- 指定 byte の繰り返し送信
- 白消去、黒消去、SPI 波形確認用の deterministic traffic 生成

対象パネルで`0x24`が画像RAM 書き込みであるか、byteの白黒極性がどうなっているかは要確認。

### 06: Panel Profile Constants

path: `templates/06_panel_profile_constants`

よく使われる e-Paper command 値と小型パネルの geometry 値を再利用しやすい形で置くテンプレート。
再利用 RTL: `rtl/epaper/epaper_panel_profile_pkg.sv`

detail:

- `0x12`, `0x20`, `0x22`, `0x24`, `0x26`, `0x44`, `0x45`, `0x4E`, `0x4F` などのよくある command 値
- 2.13 inch、2.9 inch、4.2 inch class の代表的な寸法
- 完全な device database ではなく、実用的な初期値

### 07: Command Sequence Player

path: `templates/07_command_sequence_player`

command / data / delay / wait token を `{dc, byte}` stream に変換するテンプレート。
再利用 RTL: `rtl/epaper/epaper_command_sequence_player.sv`

detail:

- command byte / data byte の出力
- 固定 clock cycle delay
- busy解除待ち token
- end token 消費時の `done` pulse

### 08: Frame Pattern Generator

path: `templates/08_frame_pattern_generator`

host framebuffer なしで deterministic な `0x24` frame RAM 書き込みを生成するテンプレート。
再利用 RTL: `rtl/epaper/epaper_pattern_generator.sv`

detail:

- fill byte
- checker byte
- vertical stripes
- horizontal stripes
- walking one bit

### 09: e-Paper Bring-up Top

path: `templates/09_epaper_bringup_top`

reset、frame fill、SPI stream output を接続した小さな bring-up top テンプレート。
再利用 RTL: `rtl/epaper/epaper_bringup_fill_top.sv`

detail:

- reset timing の実行
- `0x24` fill transaction の送信
- SPI mode 0 panel pin の駆動
- full initialization や refresh policy はこのテンプレート外

### 10: SPI Capture Decoder

path: `templates/10_spi_capture_decoder`

`serial_pin_capture` が取得した低速 SPI 風 event を byte に戻すテンプレート。
再利用 RTL: `rtl/capture/spi_edge_decoder.sv`

detail:

- timestamp付き edge event の消費
- `CPHA=0` の MSB-first SPI byte 復元
- 復元 byte と一緒に data/command pin を sample
- chip select deassert 時の `frame_done` pulse

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

### sync_2ff

path: `rtl/common/sync_2ff.sv`

単一bitの非同期入力をローカルクロックへ取り込むための2段同期回路。

usecase:

- e-Paper `BUSY`
- 外部トリガピン
- 低速ステータス入力のクロックドメイン取り込み

### spi_tx

path: `rtl/spi/spi_tx.sv`

e-Paper stream controller から利用する 8bit MSB-first の SPI transmitter。

現在の範囲:

- 固定 SPI mode 0
- 1転送 1 byte
- ready/valid input
- デフォルトは byte単位の chip select
- `in_last` までの chip select hold を選択可能
- レジスタ化された `transfer_done`

### epaper_reset_controller

path: `rtl/epaper/epaper_reset_controller.sv`

e-Paper パネル向けの reset sequencer。

現在の範囲:

- パラメータ指定の reset low duration
- パラメータ指定の reset high wait duration
- reset sequence 完了後の `ready` 出力

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
make test-epaper-reset
make test-window
make test-fill
make test-skid
make test-sync
make test-bad-params
```

テスト対象:

- `fb_1bpp_packer`: 1bpp pixel の byte pack、bit order、反転
- `serial_pin_capture`: edge event、level event、FIFO保持、overflow
- `epaper_spi_stream_controller`: `{dc, byte}` の SPI 出力、reset timing、busy handling、command/data切替、SPI clock period、CS hold、busy timeout
- `epaper_reset_controller`: reset low、reset high wait、ready の挙動
- `epaper_window_sequence`: window / cursor コマンド列
- `epaper_frame_fill`: `0x24` と fill data の生成
- 今回追加した template RTL は file list 全体 elaboration で確認
- `rv_skid_buffer`: backpressure 中の 1 word 保持
- `sync_2ff`: 2段同期の挙動
- `spi_tx`: `epaper_spi_stream_controller` 経由で検証
- bad-parameter tests: 不正パラメータで期待通り `$fatal` すること

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
