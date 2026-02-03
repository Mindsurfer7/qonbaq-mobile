# TODO: Безопасность хранения данных

## Критические задачи

- [ ] **Удалить сохранение пароля** 
  - Убрать сохранение пароля из `CredentialsStorage.saveCredentials()`
  - Удалить загрузку пароля в `auth_page.dart` (`_loadSavedCredentials`)
  - Удалить поле `saved_password` из Local Storage
  - Оставить только сохранение email для удобства пользователя

## Задачи безопасности

- [ ] **Мигрировать токены на безопасное хранилище**
  - Добавить зависимость `flutter_secure_storage` в `pubspec.yaml`
  - Переписать `TokenStorage` для использования `flutter_secure_storage` вместо `SharedPreferences`
  - Обновить методы сохранения/загрузки токенов
  - Протестировать работу на iOS и Android

## Нормально (не требует изменений)

- ✅ `saved_email` - можно оставить в SharedPreferences
- ✅ `selected_workspace_id` - можно оставить в SharedPreferences
