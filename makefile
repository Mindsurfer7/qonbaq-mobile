.PHONY: run run-chrome run-ios run-android dev clean

# Запуск на Chrome с фиксированным портом для веб-сервера И VM Service
run-chrome:
	flutter run -d chrome --web-port 1111 --host-vmservice-port 1112

# Запуск на iOS
run-ios:
	flutter run -d ios --host-vmservice-port 1111

# Запуск на Android
run-android:
	flutter run -d android --host-vmservice-port 1111

# Короткий алиас для Chrome
run: run-chrome

# Dev режим с hot reload (то же самое, просто понятное имя)
dev: run-chrome

# Очистка
clean:
	flutter clean

# Обновление зависимостей
deps:
	flutter pub get