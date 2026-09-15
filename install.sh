#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "== Instalación de Dictado por Voz (CachyOS / KDE Plasma Wayland) =="
echo ""

# 1. Dependencias del sistema
echo "--> Instalando dependencias (pacman)..."
sudo pacman -S --needed cmake git ffmpeg pipewire-audio ydotool libnotify

# 2. Clonar y compilar whisper.cpp con soporte CUDA
if [ ! -d "$HOME/whisper.cpp" ]; then
    echo "--> Clonando whisper.cpp..."
    git clone https://github.com/ggml-org/whisper.cpp "$HOME/whisper.cpp"
fi

echo "--> Compilando whisper.cpp con soporte CUDA..."
echo "    (necesitas el paquete 'cuda' instalado: sudo pacman -S cuda)"
cd "$HOME/whisper.cpp"
cmake -B build -DGGML_CUDA=ON -DCMAKE_CUDA_ARCHITECTURES=native
cmake --build build -j --config Release

# 3. Descargar el modelo
if [ ! -f "$HOME/whisper.cpp/models/ggml-large-v3-turbo.bin" ]; then
    echo "--> Descargando modelo large-v3-turbo..."
    bash ./models/download-ggml-model.sh large-v3-turbo
fi

# 4. Configurar ydotoold como servicio de usuario
echo "--> Configurando ydotoold..."
mkdir -p "$HOME/.config/systemd/user"
cp "$SCRIPT_DIR/systemd/ydotool.service" "$HOME/.config/systemd/user/ydotool.service"
systemctl --user daemon-reload
systemctl --user enable --now ydotool.service

# 5. Permisos de /dev/uinput
echo "--> Configurando permisos de /dev/uinput..."
sudo cp "$SCRIPT_DIR/udev/80-uinput.rules" /etc/udev/rules.d/80-uinput.rules
sudo usermod -aG input "$USER"
sudo udevadm control --reload-rules
sudo udevadm trigger

# 6. Instalar el script y la configuración
echo "--> Instalando script de dictado..."
mkdir -p "$HOME/.config/scripts"
cp "$SCRIPT_DIR/dictado.fish" "$HOME/.config/scripts/dictado.fish"
chmod +x "$HOME/.config/scripts/dictado.fish"

mkdir -p "$HOME/.config/dictado-voz"
if [ ! -f "$HOME/.config/dictado-voz/config.fish" ]; then
    cp "$SCRIPT_DIR/config.fish.example" "$HOME/.config/dictado-voz/config.fish"
fi

echo ""
echo "======================================================================"
echo " Instalación completada. Pasos manuales pendientes:"
echo "======================================================================"
echo ""
echo " 1. Cierra sesión y vuelve a entrar (para que el grupo 'input' se aplique)."
echo ""
echo " 2. Averigua el ID de tu micrófono real:"
echo "      wpctl status"
echo "    Prueba antes de nada con:"
echo "      pw-record --target TU_ID --rate 16000 --channels 1 test.wav"
echo "      aplay test.wav"
echo ""
echo " 3. Edita ~/.config/dictado-voz/config.fish con ese ID (AUDIO_TARGET)"
echo "    y confirma las rutas de WHISPER_BIN / WHISPER_MODEL."
echo ""
echo " 4. Añade el atajo global en KDE:"
echo "    System Settings > Atajos de teclado > flecha junto a '+ Añadir nuevo'"
echo "    > Comando o script"
echo "      Nombre:      Dictado voz"
echo "      Comando/URL: /usr/bin/fish $HOME/.config/scripts/dictado.fish"
echo "    Asigna la combinación de teclas que prefieras."
echo ""
echo "======================================================================"
