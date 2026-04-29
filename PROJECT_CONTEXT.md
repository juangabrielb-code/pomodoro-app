# Pomodoro App — Contexto del Proyecto

## Resumen

App de timer Pomodoro con dos implementaciones paralelas en el mismo repositorio:

- **SwiftUI nativa** (`/`) → Mac App Store
- **Flutter** (`/flutter/`) → Android + macOS

Repositorio: `https://github.com/juangabrielb-code/pomodoro-app`

---

## Diseño y estética

**Principio:** Minimalista. Iconos simples, formas limpias, sin ruido visual.

| Token       | HEX       | Uso                                      |
|-------------|-----------|------------------------------------------|
| `greige`    | `#C4B9A8` | Fondo de todas las pantallas             |
| `wineDark`  | `#722F37` | Acento principal: ring, textos, botones  |
| `wineMid`   | `#947080` | Textos secundarios (wordmark "pomodoro") |

**Tipografía:** System fonts. Monospaced para el timer. Tracking amplio en labels.

**Ventana macOS (SwiftUI):** Fija en 380×480 px, no redimensionable.

---

## Lógica de negocio (común a ambas apps)

### Ciclos

```
Trabajo → Descanso Corto → Trabajo → ... → (cada N sesiones) → Descanso Largo → Trabajo
```

- `N` = `sessionsUntilLongBreak` (configurable, default 4, rango 2–8)
- Al completar un ciclo de trabajo se incrementa `completedSessions`
- `completedSessions % sessionsUntilLongBreak == 0 && completedSessions > 0` → Descanso Largo

### Valores por defecto

| Ciclo           | Default | Rango   |
|-----------------|---------|---------|
| Trabajo         | 25 min  | 1–90    |
| Descanso Corto  | 5 min   | 1–30    |
| Descanso Largo  | 15 min  | 1–60    |

### Timer

- **Precisión:** basado en timestamp (`Date.now()` / `DateTime.now()`), no en conteo de ticks. Evita drift.
- **Frecuencia de tick:** 500 ms (suficiente para MM:SS, sin CPU overhead).
- **Alarma:** `NSSound("Glass")` en SwiftUI / notificación del sistema en Flutter.
- **Auto-inicio:** toggle opcional. Si activo, el siguiente ciclo arranca automáticamente.

### Persistencia

Todas las settings se guardan en `UserDefaults` (SwiftUI) / `SharedPreferences` (Flutter):

| Clave                    | Tipo  |
|--------------------------|-------|
| `workMinutes`            | Int   |
| `shortBreakMinutes`      | Int   |
| `longBreakMinutes`       | Int   |
| `sessionsUntilLongBreak` | Int   |
| `autoStart`              | Bool  |

---

## App 1: SwiftUI nativa (macOS)

### Stack

- SwiftUI + AppKit
- Swift 5.9, mínimo macOS 13.0
- Proyecto generado con **xcodegen** (`project.yml`)
- App Sandbox habilitado (requerido para Mac App Store)

### Estructura de archivos

```
/
├── project.yml                  ← config xcodegen (regenerar con: xcodegen generate)
├── generate_icon.swift          ← script Swift para generar PNGs del ícono
├── Pomodoro.xcodeproj/
├── Sources/
│   ├── PomodoroApp.swift        ← @main entry point + AppDelegate + Settings scene
│   ├── PomodoroTimer.swift      ← @MainActor ObservableObject (toda la lógica)
│   ├── ContentView.swift        ← UI principal + extensión Color (tema)
│   ├── SettingsView.swift       ← Sheet de configuración
│   ├── Info.plist               ← generado por xcodegen
│   └── Pomodoro.entitlements    ← App Sandbox + file access
└── Resources/
    └── Assets.xcassets/
        └── AppIcon.appiconset/  ← PNGs 16px → 1024px
```

### Componentes de UI

| Componente        | Archivo            | Descripción                              |
|-------------------|--------------------|------------------------------------------|
| `ContentView`     | ContentView.swift  | Layout raíz, topbar, sheet de settings   |
| `TimerRingView`   | ContentView.swift  | Anillo circular con `Circle().trim()`    |
| `SessionDotsView` | ContentView.swift  | Dots de progreso de sesiones             |
| `ControlsView`    | ContentView.swift  | Botones reset / play-pause / skip        |
| `SettingsView`    | SettingsView.swift | Sliders + toggle auto-inicio             |
| `DurationRow`     | SettingsView.swift | Fila reutilizable de slider + label      |

### Atajos de teclado

| Atajo    | Acción    |
|----------|-----------|
| `Space`  | Play/Pause|
| `⌘R`     | Reset     |
| `⌘→`     | Skip      |

### Notificaciones

- Framework: `UserNotifications`
- Implementado en `AppDelegate` (via `@NSApplicationDelegateAdaptor`)
- Banners se muestran también en foreground (delegate retorna `.banner`)
- El audio lo maneja `NSSound` para evitar doble sonido
- Texto: "¡A trabajar!" / "¡Tiempo!" + nombre del ciclo en español

### Cómo regenerar el proyecto Xcode

Si se edita `project.yml`, correr desde la raíz:
```bash
xcodegen generate
```
> Nota: xcodegen reescribe `Pomodoro.entitlements`. Los permisos están definidos en `project.yml` bajo `entitlements.properties`.

---

## App 2: Flutter (Android + macOS)

### Stack

- Flutter 3.41.8, Dart SDK ^3.11.5
- State management: **Provider** (`ChangeNotifier`)
- Notificaciones: **flutter_local_notifications 18.x**
- Persistencia: **shared_preferences 2.x**

### Estructura de archivos

```
flutter/
├── pubspec.yaml
├── lib/
│   ├── main.dart                        ← entry point, init, ChangeNotifierProvider
│   ├── theme.dart                       ← constantes de color (greige, wineDark, wineMid)
│   ├── models/
│   │   └── pomodoro_timer.dart          ← ChangeNotifier (lógica idéntica a SwiftUI)
│   ├── services/
│   │   └── notification_service.dart    ← wrapper de flutter_local_notifications
│   ├── screens/
│   │   ├── home_screen.dart             ← pantalla principal
│   │   └── settings_screen.dart        ← pantalla de configuración (StatefulWidget)
│   └── widgets/
│       ├── timer_ring.dart              ← CustomPainter del anillo circular
│       ├── session_dots.dart            ← dots de progreso
│       └── controls.dart               ← botones reset / play-pause / skip
├── android/
│   └── app/src/main/
│       └── AndroidManifest.xml         ← permisos: POST_NOTIFICATIONS, VIBRATE
└── macos/
    └── Runner/                         ← configuración estándar Flutter macOS
```

### Patrón de estado

```dart
// main.dart — callback wired antes de pasar al provider
timer.onCycleComplete = NotificationService.showCycleComplete;

runApp(ChangeNotifierProvider.value(value: timer, child: PomodoroApp()));
```

`PomodoroTimer` expone `onCycleComplete` como callback en vez de depender directamente de notificaciones. Esto mantiene el modelo desacoplado del servicio.

### Timer ring (Flutter)

Implementado con `CustomPainter`:
- Track: `wineDark.withAlpha(30)`, strokeWidth 5, círculo completo
- Progreso: `wineDark`, strokeWidth 5, `StrokeCap.round`, arco desde `-π/2`
- Texto centrado en `Stack` con fuente monospaced

### Notificaciones Android

Permisos en `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.VIBRATE"/>
```

Canal: `pomodoro_cycle`, importance HIGH.

### Comandos útiles

```bash
cd flutter

# Correr en macOS
flutter run -d macos

# Correr en Android (requiere Android Studio + SDK instalado)
flutter run -d android

# Verificar errores
flutter analyze

# Instalar dependencias
flutter pub get
```

**Para Android:** instalar Android Studio desde developer.android.com/studio, abrirlo una vez para configurar el SDK, luego `flutter doctor` debe mostrar el Android toolchain en verde.

---

## Estado actual del proyecto

### Implementado ✅

- Timer con precisión basada en timestamps
- 3 tipos de ciclo: Trabajo / Descanso Corto / Descanso Largo
- Alarma al final de cada ciclo
- Notificaciones del sistema (foreground y background)
- Configuración persistida de todos los parámetros
- Auto-inicio del siguiente ciclo (toggle)
- Ícono de la app generado programáticamente (greige + anillo vino)
- Atajos de teclado (SwiftUI)
- Session dots mostrando progreso al descanso largo
- App Sandbox habilitado (App Store ready)
- Monorepo con SwiftUI + Flutter en el mismo repo

### Pendiente / próximos pasos naturales

- Estadísticas de sesiones completadas (historial)
- Menu bar item en macOS (ver timer sin abrir ventana)
- Ícono Android personalizado (actualmente usa el default Flutter)
- Sonidos personalizables
- Apple Developer Account + provisioning para distribución
- Google Play Store setup

---

## Decisiones de diseño importantes

| Decisión | Razón |
|----------|-------|
| Timer basado en timestamp, no en conteo de ticks | Evita drift acumulado en sesiones largas |
| `NSSound` separado de notificación en SwiftUI | Evitar doble audio; el sonido es inmediato, la notificación es el banner visual |
| `onCycleComplete` como callback en Flutter | Mantiene `PomodoroTimer` desacoplado de `flutter_local_notifications` |
| Entitlements definidos en `project.yml` | xcodegen sobreescribe el archivo .entitlements en cada regeneración |
| Monorepo (SwiftUI en raíz, Flutter en `/flutter`) | Mismo repo, mismo historial git, ambas apps evolucionan juntas |
| `applySettings()` solo resetea si el timer no está corriendo | No interrumpir una sesión activa al guardar configuración |
