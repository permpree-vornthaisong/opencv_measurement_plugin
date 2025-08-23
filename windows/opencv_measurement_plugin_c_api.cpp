#include "include/opencv_measurement_plugin/opencv_measurement_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "opencv_measurement_plugin.h"

void OpencvMeasurementPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  opencv_measurement_plugin::OpencvMeasurementPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
