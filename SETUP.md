# SmartKassa — Орнату нұсқаулығы

## 1-қадам: Flutter жобасын ашу

VS Code-та Terminal → New Terminal ашып:

```bash
cd C:\Users\taraz\electronic_register
flutter pub get
```

## 2-қадам: Firebase конфигурациясы

Терминалда:

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=electronic-register-97138
```

Бұл команда `lib/firebase_options.dart` файлын автоматты жасайды.

## 3-қадам: Firebase Firestore ережелерін орнату

Firebase Console → Firestore → Rules:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

(Бұл тест режимі — кейін аутентификация қосасыз)

## 4-қадам: Windows платформасын қосу

```bash
flutter create --platforms=windows .
```

## 5-қадам: Іске қосу

```bash
flutter run -d windows
```

## 6-қадам: Таразы баптаулары

1. Таразыны USB-Serial кабель арқылы жалғаңыз
2. Қосымшада **Баптаулар** → Таразы бетіне өтіңіз
3. COM портты таңдаңыз (мысалы COM3)
4. Baud Rate: 9600 (таразы нұсқаулығынан тексеріңіз)
5. **Таразыны жалғау** батырмасын басыңыз

## 7-қадам: Принтер баптаулары

1. Xprinter драйверін орнатыңыз
2. Windows → Принтер мен сканерлер → Xprinter қосыңыз
3. Қосымшада **Баптаулар** → Принтер бетінде принтерді таңдаңыз

---

## Жоба құрылымы

```
lib/
├── main.dart              — Бастапқы файл
├── firebase_options.dart  — Firebase конфигурациясы
├── models/
│   ├── product.dart       — Тауар моделі
│   ├── cart_item.dart     — Себет жолы
│   └── sale.dart          — Сатылым моделі
├── services/
│   ├── firebase_service.dart  — Firestore CRUD
│   ├── scale_service.dart     — COM порт / таразы
│   └── printer_service.dart   — PDF чек + принтер
├── providers/
│   ├── products_provider.dart — Тауарлар стейті
│   ├── cart_provider.dart     — Себет стейті
│   └── sales_provider.dart    — Сатылымдар стейті
└── screens/
    ├── main_layout.dart       — Sidebar + навигация
    ├── cashier_screen.dart    — Касса беті
    ├── payment_screen.dart    — Төлем беті
    ├── receipt_screen.dart    — Чек беті
    ├── products_screen.dart   — Тауарлар беті
    ├── reports_screen.dart    — Есептер беті
    └── settings_screen.dart   — Баптаулар беті
```

## Негізгі пакеттер

| Пакет | Мақсаты |
|-------|---------|
| firebase_core / cloud_firestore | Firebase деректер базасы |
| provider | State management |
| flutter_libserialport | Таразы COM порт |
| pdf / printing | Чек жасап принтерге жіберу |
| intl | Күн форматтау |
| uuid | Уникалды ID |
