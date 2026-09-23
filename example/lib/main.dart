import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_newpos_android_sdk/flutter_newpos_android_sdk.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Newpos 9830 demo',
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple, useMaterial3: true),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _log = 'Listo.';
  ui.Locale _locale = const ui.Locale('es');

  // Los 4 idiomas de DTEx: (etiqueta, tag para el terminal, Locale para describe()).
  static const _langs = <(String, String, ui.Locale)>[
    ('Español', NewposDevice.localeSpanish, ui.Locale('es')),
    ('English', NewposDevice.localeEnglish, ui.Locale('en')),
    ('中文(繁)', NewposDevice.localeChineseTraditional,
        ui.Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')),
    ('Português', NewposDevice.localePortuguese, ui.Locale('pt')),
  ];

  void _show(Object? msg) => setState(() => _log = '$msg');

  Future<void> _setLang(String label, String tag, ui.Locale locale) async {
    setState(() => _locale = locale);
    await _run('Idioma $label', () => Newpos.device.setLocale(tag));
  }

  Future<void> _run(String label, Future<Object?> Function() action) async {
    _show('$label…');
    try {
      _show('$label → ${await action()}');
    } catch (e) {
      _show('$label ✗ $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Newpos 9830')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(spacing: 8, children: [
              for (final (label, tag, locale) in _langs)
                FilledButton.tonal(
                  onPressed: () => _setLang(label, tag, locale),
                  child: Text(label),
                ),
              FilledButton.tonal(
                onPressed: () => _run('Idiomas', () => Newpos.device.supportedLocales()),
                child: const Text('Soportados'),
              ),
            ]),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              FilledButton(
                onPressed: () => _run('Info', () async => (await Newpos.device.info()).toString()),
                child: const Text('Datos equipo'),
              ),
              FilledButton(
                onPressed: () => _run('Módulos', () => Newpos.device.modules()),
                child: const Text('Módulos'),
              ),
              FilledButton(
                onPressed: () => _run('¿Scanner?', () => Newpos.device.hasModule(NewposDevice.moduleScanner)),
                child: const Text('¿Trae scanner?'),
              ),
              FilledButton(
                onPressed: () => _run('Imprimir', () async {
                  final png = await _demoTicket();
                  return Newpos.printer.printImage(png);
                }),
                child: const Text('Imprimir prueba'),
              ),
              FilledButton(
                onPressed: () => _run('Estado printer', () async {
                  final s = await Newpos.printer.status();
                  return '${s.name} — ${s.describe(_locale)}';
                }),
                child: const Text('Estado printer'),
              ),
              FilledButton(
                onPressed: () => _run('Escanear', () => Newpos.scanner.scan()),
                child: const Text('Escanear'),
              ),
              FilledButton(
                onPressed: () => _run('Banda', () async {
                  final t = await Newpos.magcard.readTracks();
                  return t == null
                      ? 'sin lectura'
                      : 'T1=${t.track1 != null} T2=${t.track2 != null} T3=${t.track3 != null}';
                }),
                child: const Text('Leer banda'),
              ),
              // ponytail: muestra el track EN CLARO (PAN incluido). Solo para
              // certificar la conversion a tarjeta logica con TARJETA DE PRUEBA.
              // No loguea ni persiste. Borrar este boton cuando cierre Socoepa.
              FilledButton(
                onPressed: () => _run('Banda cruda', () async {
                  final t = await Newpos.magcard.readTracks();
                  if (t == null) return 'sin lectura';
                  return 'T1=${t.track1}\nT2=${t.track2}\nT3=${t.track3}';
                }),
                child: const Text('Banda cruda (tarjeta de prueba)'),
              ),
              FilledButton(
                onPressed: () => _run('PSAM1', () async {
                  final ok = await Newpos.icc.connect(IccSlot.psam1);
                  if (!ok) return 'no conectó';
                  final r = await Newpos.icc
                      .transmit(IccSlot.psam1, Uint8List.fromList([0x00, 0x84, 0x00, 0x00, 0x08]));
                  await Newpos.icc.disconnect(IccSlot.psam1);
                  return 'resp ${r?.length ?? 0} bytes';
                }),
                child: const Text('APDU a PSAM1'),
              ),
            ]),
            const SizedBox(height: 24),
            Expanded(child: SingleChildScrollView(child: SelectableText(_log))),
          ],
        ),
      ),
    );
  }

  /// Genera un PNG de prueba (58mm = 384px de ancho) para imprimir.
  Future<Uint8List> _demoTicket() async {
    const width = 384.0;
    const height = 160.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(const Rect.fromLTWH(0, 0, width, height), Paint()..color = Colors.white);
    final tp = TextPainter(
      text: const TextSpan(
        text: 'NEWPOS 9830\nTicket de prueba\n----------------\nDTEx®',
        style: TextStyle(color: Colors.black, fontSize: 24, height: 1.3),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: width - 16);
    tp.paint(canvas, const Offset(8, 8));
    final img = await recorder.endRecording().toImage(width.toInt(), height.toInt());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }
}
