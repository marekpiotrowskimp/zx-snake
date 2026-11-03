# zxSnake - podsumowanie projektu

## Cel projektu

`zxSnake` to gra typu Snake dla ZX Spectrum 48K, napisana w asemblerze Z80. Projekt zawiera kod gry, dane graficzne, narzędzia budowania oraz gotowe pliki dystrybucyjne w formatach `.tap` i `.tzx`.

Gra jest przygotowana z myślą o uruchamianiu na ZX Spectrum 48K i kompatybilnych modelach, w tym 128K, +2, +3, klonach oraz emulatorach.

## Quick start

Wymagania: `python3` oraz lokalny assembler `tools/bin/pasmo`.

```sh
make
make run
```

Domyślny build tworzy `build/zxsnake.tap`. Gotowe pliki release znajdują się w `release/`.

## Gameplay

Gracz steruje wężem poruszającym się po planszy 16 x 11 kafli. Celem jest zbieranie owoców, unikanie ścian i własnego ogona oraz przechodzenie kolejnych poziomów.

Najważniejsze elementy rozgrywki:

- 8 ręcznie zaprojektowanych poziomów z różnymi układami przeszkód.
- System 3 żyć.
- Wynik zwiększany za przetrwanie ruchu oraz za zbieranie owoców.
- 4 typy owoców: jabłko, banan, winogrona i wiśnia.
- Punktacja owoców zależy od aktualnego poziomu.
- Tryb New Game+, który po ukończeniu 8 poziomów wraca do poziomu 1, ale zwiększa tempo i liczbę wymaganych owoców.
- Wybieralne sterowanie: QAOP, WASD albo Kempston joystick.

## Poziomy

Gra zawiera 8 poziomów:

1. Empty - otwarte pole bez przeszkod.
2. Border - ściany przy krawędziach.
3. Center - blok przeszkod w centrum.
4. Corners - przeszkody w rogach.
5. Cross - przeszkody w kształcie krzyża.
6. Diamonds - wzór diamentów.
7. Pillars - pionowe filary.
8. Maze - bardziej złożony labirynt.

Poziomy są zapisane w `src/main.asm` jako dane plansz o rozmiarze 176 komórek.

## Sterowanie

Sterowanie wybiera się z menu głównego:

- `1` - QAOP: `Q` góra, `A` dół, `O` lewo, `P` prawo.
- `2` - WASD: `W` góra, `S` dół, `A` lewo, `D` prawo.
- `3` - Kempston joystick.

Kod wejścia znajduje się w sekcji `INPUT` w `src/main.asm`.

## Architektura kodu

Główny kod gry znajduje się w `src/main.asm` i startuje pod adresem `32768`.

Program jest zorganizowany jako pętla stanów:

- `ST_MENU` - menu główne i wybór sterowania.
- `ST_PLAYING` - aktywna rozgrywka.
- `ST_GAMEOVER` - ekran końca gry.
- `ST_LEVELUP` - przejście na kolejny poziom.
- `ST_PAUSED` - zdefiniowany stan pauzy, obecnie niewidoczny w głównej pętli.

Najważniejsze systemy w kodzie:

- inicjalizacja poziomu i planszy,
- ładowanie danych poziomu,
- ruch węża,
- wykrywanie kolizji,
- obsługa jedzenia owoców,
- naliczanie punktów i high score,
- rysowanie planszy, HUD, menu i ekranów komunikatów,
- odtwarzanie efektów dźwiękowych i prostych melodii,
- tablica adresów linii ekranu ZX Spectrum do szybszego rysowania.

## Grafika

Gra korzysta z kafli 16 x 16 pikseli. Sprite'y węża i owoców są zapisane jako dane bajtowe Z80.

Główne pliki graficzne:

- `src/sprites.asm` - sprite'y głowy, ciała, zakrętów, ogona i owoców.
- `src/font.asm` - dane fontu.
- `gfx/loading.scr` - ekran ładowania.
- `gfx/menu.scr` - ekran menu.

Sprite'y zawierają osobne warianty dla kierunków ruchu oraz zakrętów, dzięki czemu wąż nie jest rysowany jako proste bloki.

## Dźwięk

Projekt zawiera proste procedury dźwiękowe w `src/main.asm`:

- dźwięk zbierania owocu,
- dźwięk utraty życia,
- dźwięk przejścia poziomu,
- muzyka menu,
- muzyka game over,
- sekwencja dźwiękowa `GET READY`.

Dźwięk jest realizowany przez procedury typu beep i odwołania do mechanizmów ZX Spectrum.

## Narzedzia

Katalog `tools/` zawiera narzędzia pomocnicze:

- `bin2tap.py` - tworzy plik `.tap` z binarki Z80, BASIC loadera i opcjonalnego ekranu ładowania.
- `tap2tzx.py` - konwertuje `.tap` do `.tzx`.
- `makescreen.py` - generuje ekran ładowania `.scr`.
- `png2scr.py` - konwersja grafiki do formatu ekranu ZX Spectrum.
- `png2sprite.py` - konwersja sprite'ów PNG 16 x 16 do deklaracji asemblerowych `DB`.
- `tools/bin/pasmo` - lokalny assembler Pasmo.
- `tools/pasmo_src/` - źródła Pasmo.

## Budowanie

Budowanie obsługuje `Makefile`.

Glowne targety:

- `make` albo `make all` - buduje finalny `build/zxsnake.tap` z ekranem ładowania.
- `make test` - buduje `build/test.tap` bez ekranu ładowania, szybciej do testów.
- `make release` - buduje `release/zxsnake_v1.0.tap` i `release/zxsnake_v1.0.tzx`.
- `make screen` - generuje sam ekran ładowania.
- `make run` - próbuje uruchomić grę w emulatorze FUSE.
- `make clean` - usuwa artefakty z katalogu `build/` i pliki `.scr` z `gfx/`.

Proces budowania:

1. Kod Z80 z `src/main.asm` jest składany przez `tools/bin/pasmo` do `build/zxsnake.bin`.
2. `tools/bin2tap.py` opakowuje binarkę w `.tap`, dodając BASIC loader i ekran ładowania.
3. Wydanie może zawierać także wersję `.tzx`, tworzoną konwerterem `tap2tzx.py`.

## Artefakty release

Katalog `release/` zawiera gotowe materiały dystrybucyjne:

- `release/zxsnake_v1.0.tap`
- `release/zxsnake_v1.0.tzx`
- `release/README.txt`
- `release/promo/description.txt`
- `release/promo/metadata.txt`
- `release/social_media/linkedin_post.md`

Metadane release wskazuja:

- tytuł: `zxSnake`,
- wersja: `1.0`,
- autor: Marek Piotrowski,
- rok: 2026,
- platforma: ZX Spectrum 48K,
- licencja: Freeware,
- rozmiar kodu: 13 928 bajtow,
- rozmiar paczki z ekranem ładowania: około 21 KB.

## Struktura projektu

```text
.
|-- Makefile
|-- src/
|   |-- main.asm
|   |-- sprites.asm
|   `-- font.asm
|-- gfx/
|   |-- loading.scr
|   `-- menu.scr
|-- tools/
|   |-- bin2tap.py
|   |-- tap2tzx.py
|   |-- makescreen.py
|   |-- png2scr.py
|   |-- png2sprite.py
|   |-- bin/pasmo
|   `-- pasmo_src/
|-- build/
|   |-- zxsnake.bin
|   |-- zxsnake.tap
|   `-- test.tap
`-- release/
    |-- zxsnake_v1.0.tap
    |-- zxsnake_v1.0.tzx
    |-- README.txt
    |-- promo/
    `-- social_media/
```

## Uwagi techniczne

- Wersja projektu jest ujednolicona jako `1.0` w kodzie, metadanych release i dokumentacji.
- `tools/pasmo_src/` jest widoczny jako nieznany katalog w statusie Git. Warto zdecydować, czy źródła narzędzia mają być śledzone w repozytorium.
- Kod gry trzyma dane planszy, stan węża, jedzenie, wynik i zmienne tymczasowe bezpośrednio w pamięci programu, co jest typowe dla projektu na ZX Spectrum.
- Plansza ma rozmiar 16 x 11 kafli, czyli 256 x 176 pikseli, zostawiajac miejsce na HUD.

## Podsumowanie

`zxSnake` jest kompletnym projektem retro gry dla ZX Spectrum: ma kod gry w Z80, własne sprite'y, ekran ładowania, menu, dźwięki, system poziomów, narzędzia do budowania i gotowe pliki release. Projekt nadaje się zarówno do uruchamiania w emulatorze, jak i do dalszego dopracowywania pod publikację jako gra freeware dla społeczności ZX Spectrum.
