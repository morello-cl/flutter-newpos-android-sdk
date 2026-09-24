import 'channel.dart';
import 'models.dart';

/// Datos del terminal y detección de capacidades de hardware.
class NewposDevice {
  const NewposDevice();

  /// Constantes de módulo de `com.pos.device.config.DevConfig` (para [hasModule]).
  static const String modulePrinter = 'PRINTER';
  static const String moduleScanner = 'BAR_SCANNER';
  static const String moduleMagcard = 'MAGCARD_READER';
  static const String moduleIcc = 'ICC_READER';
  static const String modulePicc = 'PICC_READER';
  static const String moduleSam = 'SAM_SLOT';

  /// Tags de idioma (BCP-47) de los idiomas que maneja DTEx, para [setLocale].
  ///
  /// Verificados contra el firmware del NEW9830 (`getAllLocales`). El equipo
  /// también trae variantes regionales por si se prefieren: `es-US`, `en-GB`,
  /// `zh-HK` (también tradicional), `pt-PT`. La fuente de verdad en runtime
  /// sigue siendo [supportedLocales].
  static const String localeSpanish = 'es-ES';
  static const String localeEnglish = 'en-US';
  static const String localeChineseTraditional = 'zh-TW'; // tradicional (Taiwán)
  static const String localePortuguese = 'pt-BR'; // Brasil

  /// Ficha del equipo (serie, modelo, versiones, IMEI).
  ///
  /// Valores reales capturados en un Newpos 9830 (2026-09-24), porque no son
  /// los que uno esperaria y ya causaron confusion aguas arriba:
  ///
  /// - `model` (`DevConfig.getMachine()`) devuelve **`NEW9810`**, no `9830`.
  ///   El "9830" del nombre comercial no aparece por ningun lado en el SDK;
  ///   Android si usa NEW9830 en `ro.product.device` / `ro.product.name`,
  ///   pero su `ro.product.model` tambien dice NEW9810.
  /// - `serialNumber` (`DevConfig.getSN()`) devuelve la serie de transporte
  ///   (ej. `H3R000700052135`), que **no** es `ro.serialno` del sistema
  ///   (ej. `9810250930644607`). Son dos series distintas en el mismo equipo.
  ///
  /// Al comparar contra un registro externo, usar estos valores literales:
  /// no derivarlos del nombre comercial ni asumir que coinciden con las
  /// propiedades de Android.
  Future<DeviceInfo> info() async {
    final m = await newposChannel.invokeMethod<Map<dynamic, dynamic>>('device.info');
    return DeviceInfo.fromMap(m ?? const {});
  }

  /// N° de serie del terminal (atajo de [info]).
  Future<String?> serialNumber() async => (await info()).serialNumber;

  /// Nombres de los módulos de hardware presentes.
  Future<List<String>> modules() async {
    final list = await newposChannel.invokeMethod<List<dynamic>>('device.modules');
    return (list ?? const []).cast<String>();
  }

  /// true si el terminal declara el módulo (usar las constantes `module*`).
  Future<bool> hasModule(String name) async {
    return await newposChannel.invokeMethod<bool>('device.hasModule', {'name': name}) ?? false;
  }

  /// Idiomas que el firmware del terminal declara soportar (tags BCP-47).
  Future<List<String>> supportedLocales() async {
    final list = await newposChannel.invokeMethod<List<dynamic>>('device.supportedLocales');
    return (list ?? const []).cast<String>();
  }

  /// Cambia el idioma del sistema del terminal. [tag] BCP-47 (usar las
  /// constantes `locale*`). Devuelve true si el terminal lo aplicó (false si no
  /// soporta el tag).
  Future<bool> setLocale(String tag) async {
    return await newposChannel.invokeMethod<bool>('device.setLocale', {'tag': tag}) ?? false;
  }
}
