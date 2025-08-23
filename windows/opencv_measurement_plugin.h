#ifndef FLUTTER_PLUGIN_OPENCV_MEASUREMENT_PLUGIN_H_
#define FLUTTER_PLUGIN_OPENCV_MEASUREMENT_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace opencv_measurement_plugin {

class OpencvMeasurementPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  OpencvMeasurementPlugin();

  virtual ~OpencvMeasurementPlugin();

  // Disallow copy and assign.
  OpencvMeasurementPlugin(const OpencvMeasurementPlugin&) = delete;
  OpencvMeasurementPlugin& operator=(const OpencvMeasurementPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace opencv_measurement_plugin

#endif  // FLUTTER_PLUGIN_OPENCV_MEASUREMENT_PLUGIN_H_
