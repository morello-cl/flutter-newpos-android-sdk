/// Plugin Flutter para el terminal POS **Newpos 9830** (SDK `com.pos.device.*`).
///
/// Expone: impresión térmica, datos del equipo, scanner, lectura de banda
/// magnética (3 tracks) y tarjetas de contacto / PSAM.
///
/// Solo funciona en un terminal Newpos cuyo firmware provea `com.pos.device`.
///
/// En cualquier otro hardware el plugin es inocuo pero **falla en silencio**:
/// la init lazy no encuentra el SDK y cada llamada devuelve null / false /
/// lista vacia en lugar de lanzar. Un equipo sin impresion ni lector, con la
/// app funcionando normal, casi siempre es el APK de otro flavor instalado en
/// el terminal equivocado. Verificarlo con `Newpos.device.info()`: si devuelve
/// solo `brand` y el resto en null, el SDK no esta respondiendo.
library;

import 'src/newpos_device.dart';
import 'src/newpos_icc.dart';
import 'src/newpos_magcard.dart';
import 'src/newpos_printer.dart';
import 'src/newpos_scanner.dart';

export 'src/models.dart';
export 'src/newpos_l10n.dart';
export 'src/newpos_device.dart';
export 'src/newpos_icc.dart';
export 'src/newpos_magcard.dart';
export 'src/newpos_printer.dart';
export 'src/newpos_scanner.dart';

/// Punto de entrada único al plugin.
///
/// ```dart
/// final info = await Newpos.device.info();
/// await Newpos.printer.printImage(pngBytes);
/// ```
class Newpos {
  Newpos._();

  static const NewposPrinter printer = NewposPrinter();
  static const NewposDevice device = NewposDevice();
  static const NewposScanner scanner = NewposScanner();
  static const NewposMagcard magcard = NewposMagcard();
  static const NewposIcc icc = NewposIcc();
}
