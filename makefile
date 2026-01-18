.PHONY: run run-chrome run-ios run-android dev clean

# Запуск на Chrome с фиксированным портом для веб-сервера И VM Service
# Примечание: HTML-рендерер удален в Flutter 3.29+. 
# Если нужен HTML-рендерер для копирования текста, используй Flutter 3.27 или ниже с флагом --web-renderer html
run-web:
	flutter run -d chrome --web-port 1111 --host-vmservice-port 1112

# Запуск на iOS
run-ios:
	flutter run -d ios --host-vmservice-port 1111

# Запуск на Android
run-android:
	flutter run -d android --host-vmservice-port 1111

# Короткий алиас для Chrome
run: run-web

# Dev режим с hot reload (то же самое, просто понятное имя)
dev: run-web

# Очистка
clean:
	flutter clean

# Обновление зависимостей
deps:
	flutter pub get