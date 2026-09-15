#!/usr/bin/env fish
#
# Dictado por voz estilo macOS para KDE Plasma (Wayland) + PipeWire + whisper.cpp
# Toggle: primera pulsación empieza a grabar, segunda para y transcribe/escribe.
#
# Configuración en ~/.config/dictado-voz/config.fish (ver config.fish.example)

set -l CONFIG_FILE $HOME/.config/dictado-voz/config.fish

if not test -f $CONFIG_FILE
    notify-send "Dictado" "Falta el archivo de configuración:\n$CONFIG_FILE\n\nCopia config.fish.example y edítalo." -u critical
    exit 1
end

source $CONFIG_FILE

# Valores por defecto si el config no los define
if not set -q DICTADO_LANG
    set -g DICTADO_LANG es
end

set PIDFILE /tmp/dictado.pid
set AUDIO /tmp/dictado.wav

if test -f $PIDFILE
    # --- Segunda pulsación: parar grabación y transcribir ---
    kill -INT (cat $PIDFILE)
    rm $PIDFILE
    sleep 0.3

    notify-send "Dictado" "Transcribiendo…" -t 1500

    set texto ($WHISPER_BIN -m $WHISPER_MODEL -f $AUDIO -l $DICTADO_LANG -nt 2>/dev/null | string trim)

    if test -n "$texto"
        ydotool type -- "$texto"
    else
        notify-send "Dictado" "No se ha entendido nada (¿silencio grabado?)" -u normal
    end

    rm -f $AUDIO
else
    # --- Primera pulsación: empezar a grabar ---
    notify-send "Dictado" "🎙️ Grabando…" -t 1200
    pw-record --target $AUDIO_TARGET --rate 16000 --channels 1 $AUDIO &
    echo $last_pid > $PIDFILE
end
