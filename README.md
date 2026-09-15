# Dictado por voz (estilo macOS) para KDE Plasma / Wayland

Dictado por voz local, offline y system-wide para KDE Plasma en Wayland,
inspirado en la doble pulsación de `Fn` de macOS: pulsas un atajo,
hablas, vuelves a pulsarlo, y el texto se escribe en la posición del
cursor en cualquier aplicación.

Usa **whisper.cpp** (con aceleración CUDA) para la transcripción local
— sin nube, sin API keys — y **ydotool** para escribir el texto, porque
`wtype` **no funciona en KDE Plasma Wayland** (KWin no implementa el
protocolo `zwp_virtual_keyboard_v1` que necesita).

## Requisitos

- KDE Plasma sobre Wayland (probado en CachyOS)
- GPU NVIDIA (recomendado para velocidad; funciona sin GPU pero más lento)
- `fish` como shell del script (no hace falta que sea tu shell por defecto)
- PipeWire (viene por defecto en CachyOS)

## Instalación

```bash
git clone <tu-repo> dictado-voz-cachyos
cd dictado-voz-cachyos
./install.sh
```

El script instala dependencias, compila whisper.cpp con CUDA, descarga
el modelo `large-v3-turbo`, configura el servicio `ydotoold` y los
permisos de `/dev/uinput`, e instala el script de dictado. **No** puede
automatizar dos cosas porque dependen de tu hardware concreto — las
explico abajo.

## Configuración manual obligatoria

### 1. Averigua el ID de tu micrófono en PipeWire

Ejecuta:

```bash
wpctl status
```

Busca tu micrófono real en la sección `Audio` → `Filters` o `Sources`.
**No confíes en el "Default Source"** — en interfaces de audio externas
(Scarlett, GoXLR, etc.) PipeWire a veces configura por defecto un
*sink* de salida como si fuera *source* de entrada, lo cual produce
grabaciones completamente en silencio.

Verifica siempre grabando un audio de prueba antes de dar el ID por
bueno:

```bash
pw-record --target TU_ID --rate 16000 --channels 1 test.wav
aplay test.wav
```

Si al reproducirlo no se oye tu voz, prueba con otro ID de la lista
hasta encontrar el correcto.

> **Por qué importa esto tanto:** si grabas silencio, Whisper no
> devuelve un error ni un texto vacío — **alucina** texto inventado.
> El caso más conocido es que transcriba frases tipo *"gracias por ver
> el vídeo"* o *"thanks for watching"*, porque el modelo se entrenó
> con muchísimos subtítulos de vídeos de YouTube que terminan así. Si
> te sale siempre la misma frase random sin relación con lo que
> dijiste, el problema case seguro es el dispositivo de audio, no
> Whisper.

Edita `~/.config/dictado-voz/config.fish` y pon ese ID en
`AUDIO_TARGET`.

### 2. Confirma la arquitectura CUDA de tu GPU (si compilas con GPU)

`install.sh` usa `-DCMAKE_CUDA_ARCHITECTURES=native`, que debería
autodetectar tu GPU. Si la compilación falla o el binario no arranca,
especifica la arquitectura a mano en el comando `cmake` de
`install.sh`:

| GPU | Arquitectura |
|---|---|
| RTX 50xx (Blackwell) | `120` |
| RTX 40xx (Ada) | `89` |
| RTX 30xx (Ampere) | `86` |

### 3. Crea el atajo global en KDE

En Plasma 6 el módulo de atajos personalizados ya no es una sección
aparte — está integrado en **Atajos de teclado**:

1. *System Settings* → **Atajos de teclado**
2. Click en la flechita junto a **"+ Añadir nuevo"** → **"Comando o
   script"**
3. Rellena:
   - **Nombre:** `Dictado voz`
   - **Comando/URL:** `/usr/bin/fish /home/TU_USUARIO/.config/scripts/dictado.fish`

   (usa la ruta absoluta a `fish`, comprobable con `which fish` — los
   atajos globales a veces arrancan con un `$PATH` mínimo que no
   incluye tu shell)
4. Asigna la combinación de teclas.

**Para el estilo más parecido a macOS posible:** en Mac el dictado se
activa con una única tecla (`Fn` x2), no una combinación con
modificadores. Si tu teclado tiene alguna tecla poco usada y libre
(p. ej. **Menú contextual**, al lado de Ctrl derecho), asígnala sola,
sin modificadores — KDE lo permite mientras ninguna otra app la use.
Si no tienes ninguna libre, `Meta+Espacio` es una alternativa cómoda
de una sola mano.

## Personalización

Todo se controla desde `~/.config/dictado-voz/config.fish`:

- `WHISPER_BIN` / `WHISPER_MODEL` — rutas al binario y modelo
- `DICTADO_LANG` — idioma de transcripción (`es`, `en`, `ca`...)
- `AUDIO_TARGET` — ID del nodo de PipeWire (ver arriba)

Para más precisión (a costa de velocidad) prueba con el modelo
`large-v3` completo en vez de `large-v3-turbo`:

```bash
cd ~/whisper.cpp
bash ./models/download-ggml-model.sh large-v3
```

y cambia `WHISPER_MODEL` en el config.

## Solución de problemas

**`Compositor does not support the virtual keyboard protocol`**
Es `wtype`, que no funciona en KDE Wayland (KWin no implementa ese
protocolo). Este repo ya usa `ydotool` en su lugar — si ves este
error es que estás usando una versión antigua del script.

**Transcribe siempre la misma frase random ("gracias por ver el
vídeo", etc.) sin relación con lo que dices**
Estás grabando silencio — revisa el `AUDIO_TARGET` en la sección de
configuración manual arriba.

**`No se ha podido encontrar el programa «Dictado»`** al lanzar el
atajo de KDE
El campo Comando/URL del atajo se guardó vacío o mal — vuelve a
editarlo y asegúrate de escribir la ruta completa al binario de fish
(`/usr/bin/fish /ruta/al/script`), no solo el nombre.

**El atajo no hace nada al pulsarlo**
Prueba el comando exacto del atajo directamente en una terminal
primero, para descartar que sea un problema de PATH/entorno del
atajo global y no del script en sí.

## Ideas para ampliar

- Detección de silencio (VAD) para cortar la grabación sola en vez de
  tener que pulsar el atajo dos veces.
- Feedback sonoro (beep) al empezar/parar grabación.
- Indicador visual persistente en la bandeja mientras graba.

## Licencia

MIT
