# Synchro Add-on Icons

## Available Icons

- **icon.svg** - Vector format (scalable, recommended)

## Converting SVG to PNG

### Method 1: Online Converter (Easiest)

1. Go to: https://cloudconvert.com/svg-to-png
2. Upload `icon.svg`
3. Set dimensions to 128x128
4. Download the PNG
5. Save as `icon.png` in this directory

### Method 2: Using ImageMagick (Command Line)

```bash
# Install ImageMagick if not installed
sudo apt-get install imagemagick

# Convert to PNG
convert -background none icon.svg -resize 128x128 icon.png

# Create different sizes
convert -background none icon.svg -resize 64x64 icon-64.png
convert -background none icon.svg -resize 256x256 icon-256.png
```

### Method 3: Using Inkscape

```bash
# Install Inkscape
sudo apt-get install inkscape

# Convert to PNG
inkscape icon.svg --export-filename=icon.png --export-width=128 --export-height=128
```

### Method 4: Using Browser

1. Open `icon.svg` in a modern web browser
2. Take a screenshot or use browser dev tools
3. Or use this HTML converter:

```html
<!DOCTYPE html>
<html>
<head><title>SVG to PNG Converter</title></head>
<body>
<canvas id="canvas" width="128" height="128"></canvas>
<script>
const canvas = document.getElementById('canvas');
const ctx = canvas.getContext('2d');
const img = new Image();
img.onload = function() {
  ctx.drawImage(img, 0, 0, 128, 128);
  const link = document.createElement('a');
  link.download = 'icon.png';
  link.href = canvas.toDataURL('image/png');
  link.click();
};
img.src = 'icon.svg';
</script>
</body>
</html>
```

Save this as `convert.html` in this directory, open in browser.

## Icon Design

The icon represents:
- Two servers/nodes (white boxes with blue details)
- Bidirectional sync arrows (white arrows between servers)
- Circular sync indicator in the center
- Blue background (#2563eb)
- Green status lights on servers

## Recommended Sizes

- **64x64** - Small displays
- **128x128** - Standard (default)
- **256x256** - High resolution
- **512x512** - Retina/HD displays

## Using the Icon

The manifest.jps references:
```
https://raw.githubusercontent.com/shaundma/synchro-addon/master/images/icon.png
```

If you only have the SVG, you can reference it:
```
https://raw.githubusercontent.com/shaundma/synchro-addon/master/images/icon.svg
```

Note: Some Jelastic platforms may require PNG format.
