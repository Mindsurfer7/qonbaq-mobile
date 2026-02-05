import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_form_builder/flutter_form_builder.dart';
import '../../domain/usecases/upload_file.dart';

/// Виджет для загрузки файла в динамической форме
/// Сохраняет fileId в поле формы через FormBuilder
class FileUploadField extends StatefulWidget {
  final String name;
  final String label;
  final String? helperText;
  final bool isRequired;
  final String? initialValue; // fileId, если файл уже загружен
  final bool enabled;

  const FileUploadField({
    super.key,
    required this.name,
    required this.label,
    this.helperText,
    this.isRequired = false,
    this.initialValue,
    this.enabled = true,
  });

  @override
  State<FileUploadField> createState() => _FileUploadFieldState();
}

class _FileUploadFieldState extends State<FileUploadField> {
  String? _selectedFilePath;
  List<int>? _selectedFileBytes;
  String? _selectedFileName;
  bool _isUploading = false;
  bool _isFileUploaded = false;
  String? _uploadError;
  String? _uploadedFileId;
  String? _initialFileId;

  @override
  void initState() {
    super.initState();
    _initialFileId = widget.initialValue;
    if (_initialFileId != null && _initialFileId!.isNotEmpty) {
      _uploadedFileId = _initialFileId;
      _isFileUploaded = true;
      // Устанавливаем значение в форму после первого кадра
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _updateFormField(_initialFileId);
        }
      });
    }
  }

  @override
  void didUpdateWidget(FileUploadField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue) {
      _initialFileId = widget.initialValue;
      if (_initialFileId != null && _initialFileId!.isNotEmpty) {
        setState(() {
          _uploadedFileId = _initialFileId;
          _isFileUploaded = true;
        });
        _updateFormField(_initialFileId);
      }
    }
  }

  Future<void> _selectFile() async {
    if (!widget.enabled || _isUploading) return;

    try {
      FilePickerResult? result;

      if (kIsWeb) {
        result = await FilePicker.platform.pickFiles(
          type: FileType.any,
          allowMultiple: false,
          withData: true,
        );
      } else {
        result = await FilePicker.platform.pickFiles(
          type: FileType.any,
          allowMultiple: false,
        );
      }

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;
        final fileName = file.name;

        if (kIsWeb) {
          if (file.bytes != null) {
            setState(() {
              _selectedFilePath = null;
              _selectedFileBytes = file.bytes;
              _selectedFileName = fileName;
              _isFileUploaded = false;
              _uploadedFileId = null;
              _uploadError = null;
            });

            await _uploadFile();
          } else {
            setState(() {
              _uploadError =
                  'Не удалось загрузить файл. Попробуйте выбрать другой файл.';
            });
          }
        } else {
          if (file.path != null) {
            final filePath = file.path!;

            setState(() {
              _selectedFilePath = filePath;
              _selectedFileName = fileName;
              _selectedFileBytes = null;
              _isFileUploaded = false;
              _uploadedFileId = null;
              _uploadError = null;
            });

            await _uploadFile();
          } else {
            setState(() {
              _uploadError =
                  'Не удалось получить файл. Попробуйте выбрать другой файл.';
            });
          }
        }
      }
    } catch (e) {
      setState(() {
        _uploadError = 'Ошибка выбора файла: ${e.toString()}';
      });
    }
  }

  Future<void> _uploadFile() async {
    if ((_selectedFilePath == null && _selectedFileBytes == null) ||
        !mounted) {
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadError = null;
    });

    try {
      final uploadFileUseCase = Provider.of<UploadFile>(context, listen: false);
      final uploadResult = await uploadFileUseCase.call(
        UploadFileParams(
          file: _selectedFilePath,
          fileBytes: _selectedFileBytes,
          fileName: _selectedFileName ?? 'file',
          module: 'attachments',
        ),
      );

      if (!mounted) return;

      uploadResult.fold(
        (failure) {
          setState(() {
            _uploadError = failure.message;
            _isUploading = false;
            _isFileUploaded = false;
            _uploadedFileId = null;
          });
          _updateFormField(null);
        },
        (uploadResponse) {
          setState(() {
            _uploadedFileId = uploadResponse.fileId;
            _isUploading = false;
            _isFileUploaded = true;
            _uploadError = null;
          });
          _updateFormField(uploadResponse.fileId);
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _uploadError = 'Ошибка загрузки файла: $e';
        _isUploading = false;
        _isFileUploaded = false;
        _uploadedFileId = null;
      });
      _updateFormField(null);
    }
  }

  void _updateFormField(String? fileId) {
    // Находим FormBuilderState через контекст
    final formState = FormBuilder.of(context);
    if (formState != null && mounted) {
      final field = formState.fields[widget.name];
      if (field != null) {
        field.didChange(fileId);
        // Сохраняем форму, чтобы значение было доступно при submit
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && formState.mounted) {
            formState.save();
          }
        });
      }
    }
  }

  void _clearFile() {
    setState(() {
      _selectedFilePath = null;
      _selectedFileBytes = null;
      _selectedFileName = null;
      _isFileUploaded = false;
      _uploadedFileId = null;
      _uploadError = null;
    });
    _updateFormField(null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.isRequired ? '${widget.label} *' : widget.label,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        if (widget.helperText != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.helperText!,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 8),
        if (_selectedFileName != null || _uploadedFileId != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isFileUploaded ? Colors.green[50] : Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: _isFileUploaded
                  ? Border.all(color: Colors.green, width: 2)
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _isFileUploaded ? Icons.check_circle : Icons.attach_file,
                      color: _isFileUploaded ? Colors.green : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedFileName ?? 'Файл загружен',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    if (_isUploading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: widget.enabled ? _clearFile : null,
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
                if (_isFileUploaded)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Файл загружен',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          )
        else
          OutlinedButton.icon(
            onPressed: widget.enabled && !_isUploading ? _selectFile : null,
            icon: const Icon(Icons.attach_file),
            label: const Text('Выбрать файл'),
          ),
        if (_uploadError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _uploadError!,
              style: TextStyle(color: Colors.red[700], fontSize: 12),
            ),
          ),
        // Скрытое поле для FormBuilder, которое будет содержать fileId
        FormBuilderField<String>(
          name: widget.name,
          initialValue: _uploadedFileId ?? _initialFileId,
          enabled: widget.enabled,
          builder: (FormFieldState<String> field) {
            // Обновляем значение поля при изменении _uploadedFileId
            if (_uploadedFileId != null && field.value != _uploadedFileId) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && field.mounted) {
                  field.didChange(_uploadedFileId);
                }
              });
            } else if (_uploadedFileId == null && field.value != null) {
              // Очищаем поле, если файл был удален
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && field.mounted) {
                  field.didChange(null);
                }
              });
            }
            return const SizedBox.shrink();
          },
          validator: widget.isRequired
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return 'Поле "${widget.label}" обязательно';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }
}
