# Tienda Talavera Dolores · Archivos por ronda

Este zip contiene los archivos del manual "Talavera Dolores: tienda móvil completa",
organizados por ronda. NO incluye las carpetas android/, ios/, web/ ni windows/,
porque las genera `flutter create`.

## Ronda 1 · Preparar el proyecto

Desde la carpeta src del repositorio (Unidad_III\src):

    flutter create tienda_talavera
    cd tienda_talavera
    flutter pub add model_viewer_plus shared_preferences flutter_secure_storage crypto

Después:

1. Copia el pubspec.yaml de este zip sobre el que generó Flutter.
2. Borra test\widget_test.dart (es el contador de ejemplo y fallará).
3. Permisos Android (manual, Paso 1.2): en android\app\src\main\AndroidManifest.xml agrega
   <uses-permission android:name="android.permission.INTERNET"/> dentro de <manifest>.
   Solo para pruebas con servidor local, agrega android:usesCleartextTraffic="true" dentro de <application>.
4. Ejecuta:

    flutter pub get
    flutter test

Si "flutter test" no encuentra pruebas, es normal en esta ronda. Pasa a la Ronda 2.

## Rondas siguientes

Las rondas 2 a 12 se agregan una por una. Cada ronda trae sus archivos en lib\ y test\
con la misma ruta que indica el manual.
