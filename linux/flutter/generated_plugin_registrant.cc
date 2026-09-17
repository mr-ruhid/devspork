//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <ffmpeg_kit_flutter_new_audio/f_fmpeg_kit_flutter_plugin.h>
#include <file_saver/file_saver_plugin.h>
#include <file_selector_linux/file_selector_plugin.h>
#include <flutter_avif_linux/flutter_avif_linux_plugin.h>
#include <heic_native/heic_native_plugin.h>
#include <pdf_combiner/pdf_combiner_plugin.h>
#include <screen_retriever_linux/screen_retriever_linux_plugin.h>
#include <url_launcher_linux/url_launcher_plugin.h>
#include <window_manager/window_manager_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) ffmpeg_kit_flutter_new_audio_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "FFmpegKitFlutterPlugin");
  f_fmpeg_kit_flutter_plugin_register_with_registrar(ffmpeg_kit_flutter_new_audio_registrar);
  g_autoptr(FlPluginRegistrar) file_saver_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "FileSaverPlugin");
  file_saver_plugin_register_with_registrar(file_saver_registrar);
  g_autoptr(FlPluginRegistrar) file_selector_linux_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "FileSelectorPlugin");
  file_selector_plugin_register_with_registrar(file_selector_linux_registrar);
  g_autoptr(FlPluginRegistrar) flutter_avif_linux_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "FlutterAvifLinuxPlugin");
  flutter_avif_linux_plugin_register_with_registrar(flutter_avif_linux_registrar);
  g_autoptr(FlPluginRegistrar) heic_native_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "HeicNativePlugin");
  heic_native_plugin_register_with_registrar(heic_native_registrar);
  g_autoptr(FlPluginRegistrar) pdf_combiner_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "PdfCombinerPlugin");
  pdf_combiner_plugin_register_with_registrar(pdf_combiner_registrar);
  g_autoptr(FlPluginRegistrar) screen_retriever_linux_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "ScreenRetrieverLinuxPlugin");
  screen_retriever_linux_plugin_register_with_registrar(screen_retriever_linux_registrar);
  g_autoptr(FlPluginRegistrar) url_launcher_linux_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "UrlLauncherPlugin");
  url_launcher_plugin_register_with_registrar(url_launcher_linux_registrar);
  g_autoptr(FlPluginRegistrar) window_manager_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "WindowManagerPlugin");
  window_manager_plugin_register_with_registrar(window_manager_registrar);
}
