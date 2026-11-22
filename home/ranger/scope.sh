#!/usr/bin/env bash
# Ranger scope exit codes: 2=plain text, 5=text preview, 6=cached image, 7=image.
set -o noglob -o nounset -o pipefail

# Bound slow metadata decoders and archives. Never execute the selected file.
if [[ "${RANGER_SCOPE_BOUNDED:-0}" != 1 ]]; then
    export RANGER_SCOPE_BOUNDED=1
    exec timeout --signal=TERM --kill-after=1s 5s bash "$0" "$@"
fi

FILE_PATH="${1:?file required}"
PV_WIDTH="${2:?width required}"
PV_HEIGHT="${3:?height required}"
IMAGE_CACHE_PATH="${4:?cache path required}"
PV_IMAGE_ENABLED="${5:-False}"
[[ -f "$FILE_PATH" && "$PV_WIDTH" =~ ^[1-9][0-9]*$ && "$PV_HEIGHT" =~ ^[1-9][0-9]*$ ]] || exit 1

FILE_EXTENSION_LOWER="${FILE_PATH##*.}"
FILE_EXTENSION_LOWER="${FILE_EXTENSION_LOWER,,}"
MIMETYPE="$(file --dereference --brief --mime-type -- "$FILE_PATH")" || exit 1

# Listing archives is useful without decompressing a cover image on every move.
case "$FILE_EXTENSION_LOWER" in
    7z|zip)
        7zz l -p -- "$FILE_PATH" </dev/null && exit 5
        exit 1 ;;
    rar)
        unrar lt -p- -- "$FILE_PATH" </dev/null && exit 5
        exit 1 ;;
    a|ace|alz|arc|arj|bz|bz2|cab|cpio|deb|gz|jar|lha|lz|lzh|lzma|lzo|rpm|rz|tar|tbz|tbz2|tgz|tlz|txz|tz|tzo|war|xpi|xz|z)
        atool --option=path_7z=7zz --list -- "$FILE_PATH" </dev/null && exit 5
        bsdtar --list --file "$FILE_PATH" </dev/null && exit 5
        exit 1 ;;
esac

if [[ "$PV_IMAGE_ENABLED" == True ]]; then
    case "$MIMETYPE" in
        image/*)
            # Ranger's Sixel implementation scales with ImageMagick itself.
            exit 7 ;;
        video/*)
            ffmpegthumbnailer -i "$FILE_PATH" -o "$IMAGE_CACHE_PATH" -s 1024 </dev/null && exit 6
            ;;
        application/pdf)
            pdftoppm -f 1 -l 1 -scale-to 1280 -singlefile -png \
                -- "$FILE_PATH" "$IMAGE_CACHE_PATH" </dev/null >/dev/null 2>&1 && {
                mv -- "${IMAGE_CACHE_PATH}.png" "$IMAGE_CACHE_PATH"
                exit 6
            }
            ;;
    esac
fi

case "$FILE_EXTENSION_LOWER" in
    pdf)
        pdftotext -l 10 -nopgbrk -q -- "$FILE_PATH" - | fmt -w "$PV_WIDTH" && exit 5
        exit 1 ;;
    odt|ods|odp|sxw)
        odt2txt "$FILE_PATH" && exit 5
        exit 1 ;;
    htm|html|xhtml)
        w3m -dump -T text/html -- "$FILE_PATH" && exit 5
        exit 1 ;;
esac

case "$MIMETYPE" in
    text/*|*/xml|application/json|application/javascript)
        # Only syntax-highlight small sources; Ranger bounds its plain-text read.
        if [[ "$(stat --printf='%s' -- "$FILE_PATH")" -le 262144 ]]; then
            highlight --out-format=ansi --force --style=pablo -- "$FILE_PATH" && exit 5
        fi
        exit 2 ;;
    image/vnd.djvu)
        djvutxt "$FILE_PATH" | fmt -w "$PV_WIDTH" && exit 5
        exit 1 ;;
    video/*|audio/*)
        mediainfo -- "$FILE_PATH" && exit 5
        exit 1 ;;
    image/*)
        exiftool -- "$FILE_PATH" && exit 5
        exit 1 ;;
esac

file --dereference --brief -- "$FILE_PATH" && exit 5
exit 1
