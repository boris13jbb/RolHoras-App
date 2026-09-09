#!/bin/bash

# Script de compilación APK para RolHoras-App
# Genera APK debug para pruebas en dispositivo real

set -e  # Detener en error

echo "==============================================="
echo "🔨 Compilando APK Debug - RolHoras-App"
echo "==============================================="
echo ""

# Paso 1: Limpiar build anterior
echo "📦 Paso 1: Limpiando build anterior..."
flutter clean

# Paso 2: Obtener dependencias
echo "📚 Paso 2: Obteniendo dependencias..."
flutter pub get

# Paso 3: Generar archivos (drift, etc.)
echo "⚙️  Paso 3: Generando archivos necesarios (build_runner)..."
flutter pub run build_runner build --delete-conflicting-outputs

# Paso 4: Análisis estático
echo "🔍 Paso 4: Análisis estático..."
flutter analyze

# Paso 5: Compilar APK debug
echo "🏗️  Paso 5: Compilando APK debug (esto puede tomar 2-5 minutos)..."
flutter build apk --debug

# Paso 6: Verificar que existe el APK
APK_PATH="build/app/outputs/flutter-apk/app-debug.apk"
if [ -f "$APK_PATH" ]; then
    APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
    echo ""
    echo "✅ ¡APK generada correctamente!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📍 Ruta: $APK_PATH"
    echo "📊 Tamaño: $APK_SIZE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "🔧 Próximos pasos:"
    echo "  1. Conectar dispositivo Android por USB"
    echo "  2. Ejecutar: adb install -r build/app/outputs/flutter-apk/app-debug.apk"
    echo "  3. O simplemente: flutter install"
    echo ""
    echo "📋 Para ver logs en tiempo real:"
    echo "  flutter logs"
    echo ""
else
    echo "❌ Error: No se encontró la APK generada"
    exit 1
fi
