# zxSnake Demo - stan aktualny

## Cel

Samodzielne demo `zxSnake` w katalogu `demo/`, budowane niezależnym `Makefile` do formatów `.tap` i `.tzx`.

## Build

```sh
make -C demo clean && make -C demo
```

Wyniki:

- `demo/build/zxsnake_demo.tap`
- `demo/build/zxsnake_demo.tzx`

## Sekwencja demo

1. Loader pokazuje splashscreen z `zxSnake_loading_256x192.png`.
2. Program po starcie ponownie kopiuje splashscreen, przykrywając komunikat `Bytes: zxsndemo`.
3. Splashscreen przewija się pionowo.
4. Atrybuty kolorów cyklują w stylu ZX Spectrum.
5. Pojawia się efekt `flash_bars`.
6. Pojawia się efekt `phase_distort`, czyli poziome zakłócenie/fazowanie obrazu.
7. QR code dostaje krótki `qr_phase_blip`.
8. Na końcu QR code jest kopiowany ponownie jako czysty, statyczny, biało-czarny ekran.
9. Muzyka gra dalej w pętli.

## Dźwięk

Demo używa własnej prostej rutyny beeperowej przez port `$FE`.

- Border zostaje częścią efektu wizualnego.
- Bit EAR jest przełączany poprawnie, więc dźwięk jest słyszalny.
- Aktualny motyw to agresywniejsza fraza `Fruit Hunter`, dopasowana do klimatu zjadania owoców.

## QR Code

QR prowadzi do:

```text
https://www.linkedin.com/in/marek-piotrowski-7b5b388a/?locale=en
```

Generator:

- `demo/tools/make_qr_scr.py`
- używa OpenCV `QRCodeEncoder`
- generuje ekran `.scr` z atrybutami `PAPER WHITE`, `INK BLACK`, `BRIGHT`

QR został zweryfikowany dekoderem OpenCV po buildzie.

## Pliki demo

- `demo/Makefile` - build `.tap` i `.tzx`
- `demo/src/demo.asm` - kod Z80 demo
- `demo/tools/make_qr_scr.py` - generator QR do `.scr`
- `demo/gfx/splash.scr` - generowany splashscreen
- `demo/gfx/linkedin_qr.scr` - generowany QR screen
- `demo/build/` - generowane artefakty

## Ostatni sprawdzony build

Komenda:

```sh
make -C demo clean && make -C demo
```

Status:

- build `.tap`: OK
- build `.tzx`: OK
- QR decode: OK
