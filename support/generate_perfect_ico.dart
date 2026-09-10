import 'dart:io';
import 'dart:typed_data';

void main() {
  final logoFile = File(r'C:\Users\mochs\Downloads\Logo Linko\Linko.png');
  if (!logoFile.existsSync()) {
    print('Logo file not found!');
    return;
  }
  final originalBytes = logoFile.readAsBytesSync();

  // We will create multi-resolution PNGs and wrap them in standard ICO format
  // Using PowerShell / System.Drawing to resize PNGs with high-quality bicubic interpolation
  final sizes = [256, 128, 64, 48, 32, 16];
  final tempDir = Directory.systemTemp.createTempSync('linko_ico_');

  final pngEntries = <int, Uint8List>{};

  for (final size in sizes) {
    final outPng = File('${tempDir.path}\\icon_$size.png');
    final script = '''
Add-Type -AssemblyName System.Drawing
\$src = [System.Drawing.Image]::FromFile(r'${logoFile.path}')
\$bmp = New-Object System.Drawing.Bitmap($size, $size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
\$g = [System.Drawing.Graphics]::FromImage(\$bmp)
\$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
\$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
\$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
\$g.Clear([System.Drawing.Color]::Transparent)
\$g.DrawImage(\$src, 0, 0, $size, $size)
\$bmp.Save(r'${outPng.path}', [System.Drawing.Imaging.ImageFormat]::Png)
\$g.Dispose()
\$bmp.Dispose()
\$src.Dispose()
''';
    Process.runSync('powershell', ['-NoProfile', '-Command', script]);
    if (outPng.existsSync()) {
      pngEntries[size] = outPng.readAsBytesSync();
    }
  }

  // Build ICO header and directory
  final count = pngEntries.length;
  final headerSize = 6 + (count * 16);
  var currentOffset = headerSize;

  final bb = BytesBuilder();
  // ICONDIR: Reserved(2), Type=1(2), Count(2)
  bb.add([0x00, 0x00, 0x01, 0x00, count & 0xFF, (count >> 8) & 0xFF]);

  final imageBuffers = <Uint8List>[];

  for (final entry in pngEntries.entries) {
    final size = entry.key;
    final bytes = entry.value;
    imageBuffers.add(bytes);

    final w = size == 256 ? 0 : size;
    final h = size == 256 ? 0 : size;

    // ICONDIRENTRY
    bb.add([
      w, // Width
      h, // Height
      0, // ColorCount
      0, // Reserved
      1, 0, // Planes
      32, 0, // BitCount (32-bit RGBA)
      bytes.length & 0xFF,
      (bytes.length >> 8) & 0xFF,
      (bytes.length >> 16) & 0xFF,
      (bytes.length >> 24) & 0xFF,
      currentOffset & 0xFF,
      (currentOffset >> 8) & 0xFF,
      (currentOffset >> 16) & 0xFF,
      (currentOffset >> 24) & 0xFF,
    ]);
    currentOffset += bytes.length;
  }

  for (final buf in imageBuffers) {
    bb.add(buf);
  }

  final icoBytes = bb.toBytes();

  // Save to all target locations
  final root = Directory.current.path;
  final targetPaths = [
    '$root/app/windows/runner/resources/app_icon.ico',
    '$root/app/assets/img/logo.ico',
    '$root/build_output/windows/Linko-Windows-x64/data/flutter_assets/assets/img/logo.ico',
  ];

  for (final targetPath in targetPaths) {
    final f = File(targetPath);
    f.parent.createSync(recursive: true);
    f.writeAsBytesSync(icoBytes);
    print('Wrote ICO to $targetPath (${icoBytes.length} bytes)');
  }

  // Also save resized PNGs for tray and assets
  if (pngEntries.containsKey(32)) {
    File('$root/app/assets/img/logo-32.png').writeAsBytesSync(pngEntries[32]!);
    File('$root/app/assets/img/logo-32-white.png').writeAsBytesSync(pngEntries[32]!);
    File('$root/app/assets/img/logo-32-black.png').writeAsBytesSync(pngEntries[32]!);
    File('$root/build_output/windows/Linko-Windows-x64/data/flutter_assets/assets/img/logo-32.png').writeAsBytesSync(pngEntries[32]!);
    File('$root/build_output/windows/Linko-Windows-x64/data/flutter_assets/assets/img/logo-32-white.png').writeAsBytesSync(pngEntries[32]!);
  }
  if (pngEntries.containsKey(128)) {
    File('$root/app/assets/img/logo-128.png').writeAsBytesSync(pngEntries[128]!);
    File('$root/build_output/windows/Linko-Windows-x64/data/flutter_assets/assets/img/logo-128.png').writeAsBytesSync(pngEntries[128]!);
  }
  if (pngEntries.containsKey(256)) {
    File('$root/app/assets/img/logo-256.png').writeAsBytesSync(pngEntries[256]!);
    File('$root/build_output/windows/Linko-Windows-x64/data/flutter_assets/assets/img/logo-256.png').writeAsBytesSync(pngEntries[256]!);
  }

  print('All icons generated successfully with 32-bit TrueColor Alpha!');
}
