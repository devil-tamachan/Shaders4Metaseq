# Shaders4Metaseq
Metasequoia4向けシェーダー

注意：
 - このシェーダーは公式サポート対象外になります。必ず自己責任で使用してください。
 - Metasequoia 4.4.2で動作確認しています。
 - それ以外のバージョンでは動かない可能性があります

[最新版ダウンロード](https://github.com/devil-tamachan/Shaders4Metaseq/archive/master.zip)

入っているシェーダー：
 - Matcapシェーダー
 - LuxのPBR Metalnessシェーダー（環境マップ非対応）

インストール方法：
 - Windows 32ビット版 + Metasequoia 32ビット版:
 - Windows 64ビット版 + Metasequoia 64ビット版:
  * C:\Program Files \tetraface\Metasequoia4\Data\Shader へ、.xmlと.hlslファイルをコピーしてください
 - Windows 64ビット版 + Metasequoia 32ビット版:
  * C:\Program Files (x86)\tetraface\Metasequoia4\Data\Shader へ、.xmlと.hlslファイルをコピーしてください

使い方：
 - よくわからないパラメーターは1.0にしてください。0.5にするとテクスチャ値が*0.5されます。
 - マテリアル色もテクスチャを使う場合は白にしておいてください。

Link:
 - [Lux (MIT License)](https://github.com/larsbertram69/Lux)
  * Copyright (c) 2014 larsbertram69
 - [map.hlsl, map.xml(in Metasequoia 4.4.2) (public domain)](http://metaseq.net/bbs/metaseq/bbs.php?lang=jp&res=5528)