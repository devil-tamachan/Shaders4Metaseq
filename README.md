# Shaders4Metaseq
Metasequoia4向けシェーダー

注意：
 - DirectX 11で表示している場合のみ表示されます（DirectX9, OpenGLだとHLSLシェーダーが動作しないっぽい）
 - このシェーダーは公式サポート対象外になります。必ず自己責任で使用してください。
 - Metasequoia 4.5.7で動作確認しています。
 - それ以外のバージョンでは動かない可能性があります

[最新版ダウンロード](https://github.com/devil-tamachan/Shaders4Metaseq/archive/master.zip)

入っているシェーダー：
 - UVAnimeシェーダー

インストール方法：
 - 表示をDirectX11にしないと表示されません。
 - Windows 32ビット版 + Metasequoia 32ビット版:
 - Windows 64ビット版 + Metasequoia 64ビット版:
  * C:\Program Files \tetraface\Metasequoia4\Data\Shader へ、.xmlと.hlslファイルをコピーしてください
 - Windows 64ビット版 + Metasequoia 32ビット版:
  * C:\Program Files (x86)\tetraface\Metasequoia4\Data\Shader へ、.xmlと.hlslファイルをコピーしてください

使い方：
 - １番目のライトの向きによってアニメーションします。
 - 詳しくはサンプル見てください (example1.mqo, example2.mqo)
 - タイルは上下に増やしてください
 - WidthScale, HeightScaleでタイルを増やした時にUVを調整できます (例：example2.mqo)
 - LightYのチェックがオンの場合、ライトの左右でアニメーションします。オフの場合、ライト上下でアニメーションします。
  
UVAnimeのテクスチャ：
 - <img src="https://raw.githubusercontent.com/devil-tamachan/Shaders4Metaseq/master/example2-mouse.png" />
 <br/>
 縦にタイルが積み重なってるテクスチャ

Link:
 - [map.hlsl, map.xml(in Metasequoia 4.4.2) (public domain)](http://metaseq.net/bbs/metaseq/bbs.php?lang=jp&res=5528)