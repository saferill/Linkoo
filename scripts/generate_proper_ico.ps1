Add-Type -AssemblyName System.Drawing

$code = @"
using System;
using System.IO;
using System.Drawing;
using System.Drawing.Imaging;
using System.Collections.Generic;

public class IcoEncoder {
    public static void CreateIco(string sourcePngPath, string outputIcoPath) {
        using (Bitmap src = new Bitmap(sourcePngPath)) {
            int[] sizes = new int[] { 16, 32, 48, 64, 128, 256 };
            List<byte[]> iconImages = new List<byte[]>();
            List<int> iconSizes = new List<int>();

            foreach (int size in sizes) {
                using (Bitmap resized = new Bitmap(size, size, PixelFormat.Format32bppArgb)) {
                    using (Graphics g = Graphics.FromImage(resized)) {
                        g.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.HighQualityBicubic;
                        g.SmoothingMode = System.Drawing.Drawing2D.SmoothingMode.HighQuality;
                        g.PixelOffsetMode = System.Drawing.Drawing2D.PixelOffsetMode.HighQuality;
                        g.CompositingQuality = System.Drawing.Drawing2D.CompositingQuality.HighQuality;
                        g.Clear(Color.Transparent);
                        g.DrawImage(src, 0, 0, size, size);
                    }

                    if (size == 256) {
                        // 256x256 stored as PNG
                        using (MemoryStream ms = new MemoryStream()) {
                            resized.Save(ms, ImageFormat.Png);
                            iconImages.Add(ms.ToArray());
                            iconSizes.Add(size);
                        }
                    } else {
                        // Sizes < 256 stored as DIB (BITMAPINFOHEADER + 32bpp BGRA + AND mask)
                        using (MemoryStream ms = new MemoryStream()) {
                            using (BinaryWriter bw = new BinaryWriter(ms)) {
                                int andRowPitch = ((size + 31) / 32) * 4;
                                int andMaskSize = andRowPitch * size;
                                int imageSize = 40 + (size * size * 4) + andMaskSize;

                                // BITMAPINFOHEADER (40 bytes)
                                bw.Write((uint)40);              // biSize
                                bw.Write((int)size);             // biWidth
                                bw.Write((int)(size * 2));       // biHeight (doubled for XOR + AND)
                                bw.Write((ushort)1);             // biPlanes
                                bw.Write((ushort)32);            // biBitCount
                                bw.Write((uint)0);               // biCompression (BI_RGB)
                                bw.Write((uint)(size * size * 4 + andMaskSize)); // biSizeImage
                                bw.Write((int)0);                // biXPelsPerMeter
                                bw.Write((int)0);                // biYPelsPerMeter
                                bw.Write((uint)0);               // biClrUsed
                                bw.Write((uint)0);               // biClrImportant

                                // XOR Data: Bottom-to-top 32-bit BGRA
                                for (int y = size - 1; y >= 0; y--) {
                                    for (int x = 0; x < size; x++) {
                                        Color c = resized.GetPixel(x, y);
                                        bw.Write((byte)c.B);
                                        bw.Write((byte)c.G);
                                        bw.Write((byte)c.R);
                                        bw.Write((byte)c.A);
                                    }
                                }

                                // AND Mask: All 0s (transparency handled by 32bpp alpha)
                                byte[] andMask = new byte[andMaskSize];
                                bw.Write(andMask);

                                iconImages.Add(ms.ToArray());
                                iconSizes.Add(size);
                            }
                        }
                    }
                }
            }

            using (FileStream fs = new FileStream(outputIcoPath, FileMode.Create, FileAccess.Write))
            using (BinaryWriter writer = new BinaryWriter(fs)) {
                // ICONDIR Header
                writer.Write((ushort)0); // Reserved
                writer.Write((ushort)1); // Resource type (1 for ICO)
                writer.Write((ushort)iconImages.Count); // Image count

                int offset = 6 + (16 * iconImages.Count);

                // ICONDIRENTRY entries
                for (int i = 0; i < iconImages.Count; i++) {
                    int sz = iconSizes[i];
                    byte bSz = (byte)(sz >= 256 ? 0 : sz);
                    writer.Write(bSz);                   // Width
                    writer.Write(bSz);                   // Height
                    writer.Write((byte)0);               // Color count
                    writer.Write((byte)0);               // Reserved
                    writer.Write((ushort)1);             // Color planes
                    writer.Write((ushort)32);            // Bits per pixel
                    writer.Write((uint)iconImages[i].Length); // Bytes in resource
                    writer.Write((uint)offset);          // Image offset

                    offset += iconImages[i].Length;
                }

                // Image Data
                for (int i = 0; i < iconImages.Count; i++) {
                    writer.Write(iconImages[i]);
                }
            }
        }
    }
}
"@

Add-Type -TypeDefinition $code -ReferencedAssemblies System.Drawing

$srcPng = (Resolve-Path "Logo\Logo Icon.png").Path
[IcoEncoder]::CreateIco($srcPng, "app\assets\packaging\logo.ico")
[IcoEncoder]::CreateIco($srcPng, "app\assets\img\logo.ico")
[IcoEncoder]::CreateIco($srcPng, "app\windows\runner\resources\app_icon.ico")

Write-Host "Multi-res ICO generated with native Windows DIB format!" -ForegroundColor Green
