package io.flutter.plugins;

import io.flutter.plugin.common.PluginRegistry;
import com.shyandsy.cipher2.Cipher2Plugin;

/**
 * Generated file. Do not edit.
 */
public final class GeneratedPluginRegistrant {
  public static void registerWith(PluginRegistry registry) {
    if (alreadyRegisteredWith(registry)) {
      return;
    }
    Cipher2Plugin.registerWith(registry.registrarFor("com.shyandsy.cipher2.Cipher2Plugin"));
  }

  private static boolean alreadyRegisteredWith(PluginRegistry registry) {
    final String key = GeneratedPluginRegistrant.class.getCanonicalName();
    if (registry.hasPlugin(key)) {
      return true;
    }
    registry.registrarFor(key);
    return false;
  }
}
