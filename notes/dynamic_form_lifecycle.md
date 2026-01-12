# Управление жизненным циклом динамических форм

## Проблема

При работе с динамическими формами в диалогах возникали следующие ошибки:
1. `'_dependents.isEmpty': is not true` - при закрытии диалога
2. `Cannot hit test a render box that has never been laid out` - при взаимодействии с UI после закрытия
3. `'!_debugDuringDeviceUpdate': is not true` - проблемы с mouse tracker

## Причины

1. **Асинхронные callback после dispose**: `addPostFrameCallback` продолжал выполняться после закрытия диалога
2. **FormBuilderField builder**: Builder-функция вызывалась даже после dispose виджета
3. **Неконтролируемые setState**: Вызовы setState после dispose виджета
4. **Доступ к невалидному контексту**: Использование `context.mounted` и `FormBuilder.of(context)` после dispose

## Решение

### 1. Флаг `_isDisposed`

Добавлен явный флаг для отслеживания состояния dispose:

```dart
class _DynamicBlockFormState extends State<DynamicBlockForm> {
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
```

### 2. Безопасный `_handleFieldChanged`

Проверка `_isDisposed` перед любыми асинхронными операциями:

```dart
void _handleFieldChanged(String fieldName, dynamic value) {
  // Проверяем, что виджет не disposed
  if (_isDisposed || !mounted) return;
  
  _localFieldValues[fieldName] = value;

  if (mounted) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed && mounted) {
        setState(() {});
      }
    });
  }
}
```

### 3. Защита в FormBuilderField builder

Множественные проверки в builder-функции:

```dart
return FormBuilderField<String>(
  builder: (FormFieldState<String> field) {
    // Проверяем disposed и mounted перед использованием контекста
    if (_isDisposed || !mounted) {
      return const SizedBox.shrink();
    }
    
    // Проверяем перед использованием context
    if (_isDisposed || !mounted || !context.mounted) {
      return const SizedBox.shrink();
    }
    
    // Безопасная работа с контекстом
    final theme = context.appTheme;
    // ...
  },
);
```

### 4. Безопасные onChanged callback

Проверка mounted перед вызовом callback:

```dart
onChanged: (value) {
  // Проверяем disposed перед любыми действиями
  if (_isDisposed || !mounted) return;
  
  _currentValue = value;
  field.didChange(value);
  
  if (!_isDisposed && mounted) {
    widget.onFieldChanged?.call(widget.fieldName, value);
  }
},
```

### 5. Безопасное использование FormBuilder.of(context)

Всегда оборачиваем в try-catch с проверками:

```dart
FormBuilderState? formState;
if (widget.formKey?.currentState != null) {
  formState = widget.formKey!.currentState;
} else {
  try {
    // Проверяем, что контекст еще валиден
    if (mounted && context.mounted) {
      formState = FormBuilder.of(context);
    }
  } catch (e) {
    // FormBuilder не найден или контекст невалиден
    formState = null;
  }
}
```

## Принципы безопасной работы

### 1. Проверяй перед действием
Всегда проверяй `_isDisposed` и `mounted` перед:
- `setState()`
- Асинхронными операциями
- Использованием контекста
- Вызовом callback

### 2. Используй явный флаг dispose
`mounted` может быть недостаточно, используй `_isDisposed` для явного контроля

### 3. Защищай асинхронные операции
Всегда проверяй состояние в callback:
```dart
WidgetsBinding.instance.addPostFrameCallback((_) {
  if (!_isDisposed && mounted) {
    // Безопасная операция
  }
});
```

### 4. Возвращай безопасные виджеты
При невалидном состоянии возвращай `SizedBox.shrink()`, а не `null`

### 5. Предпочитай formKey вместо FormBuilder.of(context)
Когда возможно, передавай `formKey` и используй его напрямую

## Применение

Эти принципы применяются во всех динамических формах:
- `DynamicBlockForm` - основная форма с блоками
- `DynamicApprovalForm` - форма согласований
- `_ReactiveSelectField` - реактивные select-поля
- `ElementFormSwitcher` - элементы формы

## Тестирование

Для проверки корректности:
1. Открыть диалог редактирования
2. Изменить несколько полей
3. Быстро закрыть диалог (не дожидаясь завершения операций)
4. Проверить отсутствие ошибок в консоли
5. Повторить несколько раз

## Дальнейшие улучшения

1. Рассмотреть использование `AutomaticKeepAliveClientMixin` для сложных форм
2. Добавить debounce для `_handleFieldChanged` для уменьшения частоты перестроений
3. Рассмотреть использование `ValueListenableBuilder` вместо `setState` для локальных изменений
