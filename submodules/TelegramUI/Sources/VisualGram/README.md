# VisualGram — Интеграция в форк Telegram iOS

## Файлы

```
VisualGram/Sources/
├── VisualGramManager.swift          # Хранилище данных, модели
├── VGActivationViewController.swift # Главное меню + система активации
├── VGProfileViewController.swift    # Настройки профиля
├── VGBalancesViewController.swift   # Балансы Stars + GRAM + карточка
├── VGGiftsViewController.swift      # Магазин подарков + мои подарки
└── VGTripleTapIntegration.swift     # Интеграция тройного тапа
```

---

## Шаги интеграции

### 1. Клонировать форк Telegram iOS

```bash
git clone https://github.com/nicegram/Telegram-iOS.git
cd Telegram-iOS
```

### 2. Скопировать файлы

Скопировать все .swift файлы из папки `VisualGram/Sources/` в:
```
Telegram-iOS/submodules/TelegramUI/Sources/VisualGram/
```

### 3. Добавить файлы в Xcode проект

1. Открыть `Telegram.xcworkspace` в Xcode
2. В навигаторе найти `TelegramUI`
3. Правый клик → Add Files → выбрать папку VisualGram
4. Убедиться что Target = TelegramUI

### 4. Интегрировать тройной тап

Найти файл `ChatListController.swift` или `TabBarController.swift`

В `viewDidLoad` добавить:
```swift
setupVisualGramTripleTap()
```

### 5. Получить API credentials

1. Зайти на https://my.telegram.org
2. Apps → Create new application
3. Получить `api_id` и `api_hash`
4. Вставить в `BuildConfig.xcconfig`

### 6. Собрать проект

```
Xcode → Product → Build (Cmd+B)
```

### 7. Получить IPA

**С подписью (нужен Apple Developer):**
```
Product → Archive → Distribute App
```

**Без подписи (для TrollStore):**
```
Product → Build
Найти .app в ~/Library/Developer/Xcode/DerivedData/
Упаковать в IPA:
  mkdir Payload
  cp -r App.app Payload/
  zip -r VisualGram.ipa Payload/
```

---

## GitHub Actions (без Mac)

Создать файл `.github/workflows/build.yml`:

```yaml
name: Build IPA

on:
  push:
    branches: [ main ]

jobs:
  build:
    runs-on: macos-latest
    steps:
    - uses: actions/checkout@v3
    - name: Build
      run: |
        xcodebuild -workspace Telegram.xcworkspace \
          -scheme Telegram \
          -configuration Release \
          -derivedDataPath build
    - name: Package IPA
      run: |
        mkdir Payload
        cp -r build/Build/Products/Release-iphoneos/Telegram.app Payload/
        zip -r VisualGram.ipa Payload/
    - uses: actions/upload-artifact@v3
      with:
        name: VisualGram.ipa
        path: VisualGram.ipa
```

---

## Функции VisualGram

### Тройной тап на "Чаты"
- Без ключа → экран активации
- С пробным периодом (24ч) → полное меню
- С ключом → полное меню навсегда

### Профиль
- ✅ Telegram Premium (визуальный)
- ✅ Галочка Telegram (визуальная)
- ✅ Верификация: Major / Hold
- ✅ NFT-юзернейм
- ✅ Коллекционный номер +888 (Fragment стиль)
- ✅ Уровень Telegram
- ✅ Юзернеймы
- ✅ Цвета и фон
- ✅ Часы работы
- ✅ Адрес

### Подарки
- ✅ Магазин (All Gifts / Collectibles)
- ✅ Покупка за Stars с конфетти
- ✅ Улучшение → NFT карточка
- ✅ Добавить NFT по slug/ссылке
- ✅ Мои подарки
- ✅ История операций

### Балансы
- ✅ Stars баланс (ручной ввод)
- ✅ GRAM баланс (ручной ввод)
- ✅ Карточка GRAM (кастомизация фона + наклейки)

---

## Система ключей активации

Формат: `XXXX-XXXX-XXXX-XXXX-XXXX`

Для генерации ключей используй скрипт:

```python
import random, string

def gen_key():
    chars = string.ascii_uppercase + string.digits
    parts = [''.join(random.choices(chars, k=4)) for _ in range(5)]
    return '-'.join(parts)

# Генерация 10 ключей
for _ in range(10):
    print(gen_key())
```

Ключи сейчас принимаются без серверной валидации.
Для серверной валидации — добавить Supabase endpoint в `activateWithKey()`.
