# Changelog

Todos los cambios relevantes de este proyecto se registran aquí.

El formato sigue [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/)
y el versionado sigue [SemVer](https://semver.org/lang/es/).

> **Dependencia propietaria.** Compilar este plugin requiere el `sdk.jar` del
> fabricante (paquetes `com.pos.device.*` y `com.secure.api.*`), que **no** se
> distribuye en este repositorio y exige licencia y autorización propias. Ver
> [«SDK del fabricante»](README.md#sdk-del-fabricante-requerido-para-compilar)
> y [`android/libs/README.md`](android/libs/README.md).

## [1.1.0]

Primera versión validada **contra un terminal físico**. Todo lo que aquí se
corrige estaba escrito contra la documentación del SDK y se rompía en el
equipo real; nada de esto era visible por compilación ni por tests.

### Corregido

- **`magcard.readTracks()` nunca alcanzaba a leer.**
  `MagCardReader.startSearchCard(int, callback)` recibe el timeout en
  **milisegundos**, no en segundos. El plugin le pasaba el valor en segundos
  tal cual, así que un `readTracks(timeout: 30s)` dejaba el lector escuchando
  30 ms y devolvía `TIMEOUT_ERROR` antes de que nadie pudiera deslizar la
  tarjeta. El síntoma era «sin lectura» instantáneo, indistinguible de un
  lector averiado o de un equipo sin banda magnética.

- **`device.hasModule()` devolvía `false` para todos los módulos.** Dos causas:
  las constantes `module*` eran nombres inventados (`BAR_SCANNER`,
  `MAGCARD_READER`, `ICC_READER`…) que no existen en el equipo — el firmware
  los reporta en minúscula (`barscanner`, `msr`, `ic`, `sam`, `nfc`,
  `printer`) — y la implementación resolvía con `DevConfig.getModuleByName()`,
  que exige el casing exacto del enum y devuelve `null` ante cualquier
  diferencia. Ahora se resuelve contra `modules()` comparando sin distinguir
  mayúsculas, así que deja de depender del casing de cada firmware.

  Impacto aguas abajo: cualquier consumidor que condicionara una función a
  `hasModule(...)` tomaba la rama de «no disponible» en un equipo que sí trae
  el hardware. En DTEx esto dejaba el lector de códigos inutilizable en todo
  Newpos 9830, mostrando «este equipo no tiene lector» con el lector puesto.

### Cambiado

- **Valores de las constantes `NewposDevice.module*`.** Pasan a los nombres
  reales que reporta el equipo. Quien use las constantes no necesita hacer
  nada; quien hubiera escrito los literales a mano debe actualizarlos.

### Documentado

Todo verificado en un Newpos 9830 real, no deducido:

- **El firmware reporta el modelo `NEW9810`, no `9830`.** El número comercial
  no aparece en ningún campo del SDK. Se anotan los literales en el dartdoc de
  `device.info()` para que ninguna conciliación contra un registro externo se
  escriba por igualdad ni por similitud de cadenas.
- **El equipo expone dos números de serie distintos.** `DevConfig.getSN()`
  (el que entrega el plugin) y `ro.serialno` de Android no coinciden.
- **`hasModule()` devuelve `false` por dos motivos distintos** — el equipo no
  trae el módulo, o el SDK no respondió — y eso ya causó un mensaje falso al
  operador. Se documenta cómo separar ambos casos con `modules()`, que
  devuelve lista vacía exactamente cuando el SDK no responde, sin API nueva.
- **En hardware no-Newpos el plugin falla en silencio.** La init lazy no
  encuentra el SDK y cada llamada devuelve `null` / `false` / lista vacía en
  vez de lanzar. Un equipo sin impresión ni lector con la app aparentemente
  sana suele ser el APK de otro flavor instalado en el terminal equivocado.
- **El timeout de `Scanner.startScan` no se comporta como se pide.** Medido
  con `scanOnce(30)`: devuelve a los 9 s, ni los 30 ms que daría leerlo como
  milisegundos ni los 30 s solicitados. **No se toca**: no falla en la
  práctica y no hay evidencia de hacia dónde corregirlo.

### Añadido

- **Ejemplo: botón «Banda cruda (tarjeta de prueba)»**, que muestra los tres
  tracks completos en pantalla para certificar la conversión a tarjeta lógica
  de la pasarela. Muestra el PAN **en claro**: es solo para tarjetas de prueba,
  no registra ni persiste nada, y vive únicamente en la app de ejemplo — nunca
  en el plugin ni en una app de producción.

### Verificado en terminal físico

Impresión (ticket legible), datos de equipo, módulos, `hasModule()` y lectura
de banda magnética. El scanner responde pero no se probó con un código real.
La conexión a PSAM falla con `SDKException: errno=62`, pendiente de confirmar
si el slot tiene una tarjeta SAM instalada.

## [1.0.0]

Primera versión estable. Consolida todo el trabajo posterior al release inicial
y **supersede el tag de pre-lanzamiento `v0.0.2`** (mismo contenido,
re-versionado como 1.0.0).

### Corregido

- **Impresora — códigos de estado invertidos.** `PrinterStatus.fromCode`
  mapeaba valores positivos, pero los `Printer.PRINTER_STATUS_*` del SDK son
  **negativos** (`-1..-9`); toda condición de falla (papel agotado,
  sobrecalentamiento, sin batería) caía en `unknown`.
- **Inicialización del SDK sin recuperación.** Un fallo o timeout de
  `SDKManager.init` dejaba el gate trabado y el plugin inutilizable para el
  resto del proceso; ahora se permite reintento.
- **Despacho en un solo hilo.** Una operación larga (`scanner.scan` /
  `magcard.readTracks`, hasta 30 s) bloqueaba la cola y `scanner.stop()` /
  `disconnect` nunca podían interrumpirla. Se pasa a un pool de hilos.
- **Impresora — doble impresión / bitmap liberado en uso.** Ante un timeout la
  impresión seguía en curso; el reintento podía imprimir dos veces y liberar el
  bitmap mientras el SDK aún lo leía. Ahora se cancela la tarea colgada antes de
  reintentar.

### Agregado

- **i18n — textos de estado legibles.** `PrinterStatus.describe(Locale)` entrega
  el estado en español, inglés, chino tradicional y portugués (cae a inglés si
  el idioma no está). El `enum` sigue siendo la fuente de verdad; es una
  cortesía para apps sin l10n propio.
- **i18n — idioma del terminal.** `Newpos.device.setLocale(tag)` cambia el idioma
  del sistema del terminal y `Newpos.device.supportedLocales()` lista los que el
  firmware declara. Constantes `NewposDevice.locale*` para los 4 idiomas de DTEx.
- **example — selector de idioma.** El demo agrega botones de idioma que llaman
  `setLocale` y muestra el estado del printer traducido con `describe(locale)`.
- **docs — README bilingüe.** `README.md` en inglés (primario, convención de
  pub.dev) + `README.es.md` en español, con selector de idioma cruzado. Ambos
  documentan la API i18n.

### Cambiado

- **BREAKING — rename del paquete y el repo.** Paquete Dart `newpos_9830` →
  `flutter_newpos_android_sdk`; repo `flutter-newpos-9830` →
  `flutter-newpos-android-sdk` (para separar la línea Android de los terminales
  Linux de Newpos). Los consumidores actualizan el import a
  `package:flutter_newpos_android_sdk/flutter_newpos_android_sdk.dart` y la clave
  de dependencia. El package Kotlin (`cl.mufin.newpos_9830`), el channel y la API
  (`Newpos.*`) **no** cambian.
- **build — el jar se toma de una ubicación local.** El gradle resuelve el
  `sdk.jar` desde `libs/` (dev por `path:`) o `<app>/android/newpos-sdk/` (consumo
  por git). El jar lo **entrega Newpos** y se solicita al fabricante; no se
  versiona ni se distribuye por este repositorio. Disclaimer legal reforzado (uso
  sujeto a contratos y autorización del fabricante; prohibido sin permisos).

## [0.0.1]

### Agregado

- Release inicial. Wrapper del SDK Newpos `com.pos.device.*` (Android):
  - Impresión térmica por bitmap (`Newpos.printer`).
  - Datos del equipo y detección de módulos (`Newpos.device`).
  - Scanner single-shot (`Newpos.scanner`).
  - Lectura de banda magnética, 3 tracks (`Newpos.magcard`).
  - Tarjeta de contacto / PSAM con selección de slot (`Newpos.icc`).

[1.0.0]: https://github.com/morello-cl/flutter-newpos-android-sdk/compare/v0.0.1...v1.0.0
[0.0.1]: https://github.com/morello-cl/flutter-newpos-android-sdk/releases/tag/v0.0.1
