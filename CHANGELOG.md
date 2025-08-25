## 1.0.3

* **DLL bundling fix** - Fixed DLL files not being properly copied to build directories
* **CMakeLists.txt update** - Enhanced DLL bundling configuration with dual approach (standard bundling + custom commands)
* **Improved reliability** - More robust DLL handling for both debug and release builds

## 1.0.2

* **Bug fixes** - Improved native library loading stability
* ✅ **Enhanced DLL bundling** - More reliable asset extraction
* ✅ **Better error handling** - Clearer error messages for troubleshooting

## 1.0.1

* **Bug fixes** - Improved native library loading stability
* ✅ **Enhanced DLL bundling** - More reliable asset extraction
* ✅ **Better error handling** - Clearer error messages for troubleshooting

## 1.0.0

* **Initial release** - Real-time object measurement plugin with OpenCV
* ✅ **Self-contained** - Includes all required OpenCV DLLs (no external dependencies)
* ✅ **Cross-platform** - Windows, macOS, and Linux support
* ✅ **Real-time processing** - 30 FPS camera feed with live measurements
* ✅ **Multiple detection modes** - Auto, color-based detection (blue, red, yellow, brown, white)
* ✅ **Ultra-precise measurements** - Sub-pixel accuracy with HSV color analysis
* ✅ **Flutter integration** - Native widgets and reactive streams
* ✅ **Visual overlays** - Bounding boxes and measurement displays
* ✅ **BGR to RGBA conversion** - Automatic format conversion for Flutter
* ✅ **Comprehensive API** - Full documentation and examples
* 📦 **Package size** - ~8MB (includes OpenCV 4.11.0 libraries)
* 🎯 **Target platforms** - Desktop applications only