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

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📁 FILE SELECTION START');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🌐 Platform: ${kIsWeb ? "Web" : "Mobile"}');

    try {
      FilePickerResult? result;

      if (kIsWeb) {
        print('📂 Opening file picker (Web) with withData: true');
        result = await FilePicker.platform.pickFiles(
          type: FileType.any,
          allowMultiple: false,
          withData: true,
        );
      } else {
        print('📂 Opening file picker (Mobile)');
        result = await FilePicker.platform.pickFiles(
          type: FileType.any,
          allowMultiple: false,
        );
      }

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;
        final fileName = file.name;
        print('✅ File selected: $fileName');
        print('   Size: ${file.size} bytes (${(file.size / 1024).toStringAsFixed(2)} KB)');
        print('   Extension: ${file.extension ?? "unknown"}');

        if (kIsWeb) {
          print('   Bytes: ${file.bytes != null ? "${file.bytes!.length} bytes" : "null"}');
          if (file.bytes != null) {
            print('✅ File bytes loaded successfully');
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
            print('❌ File bytes are null!');
            print('   File size from picker: ${file.size} bytes');
            print('   This might be a file_picker issue in production');
            setState(() {
              _uploadError =
                  'Не удалось загрузить файл (размер: ${(file.size / 1024).toStringAsFixed(2)} KB). Попробуйте выбрать другой файл.';
            });
          }
        } else {
          print('   Path: ${file.path ?? "null"}');
          if (file.path != null) {
            final filePath = file.path!;
            print('✅ File path obtained successfully');

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
            print('❌ File path is null');
            setState(() {
              _uploadError =
                  'Не удалось получить файл. Попробуйте выбрать другой файл.';
            });
          }
        }
      } else {
        print('ℹ️ File selection cancelled or empty');
      }
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    } catch (e, stackTrace) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('❌ FILE SELECTION ERROR');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('💥 Error type: ${e.runtimeType}');
      print('💥 Error message: $e');
      print('📚 Stack trace:');
      print('$stackTrace');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      setState(() {
        _uploadError = 'Ошибка выбора файла: ${e.toString()}';
      });
    }
  }

  Future<void> _uploadFile() async {
    if ((_selectedFilePath == null && _selectedFileBytes == null) ||
        !mounted) {
      print('⚠️ Upload cancelled: no file data or widget not mounted');
      print('   _selectedFilePath: ${_selectedFilePath ?? "null"}');
      print('   _selectedFileBytes: ${_selectedFileBytes != null ? "${_selectedFileBytes!.length} bytes" : "null"}');
      print('   mounted: $mounted');
      return;
    }

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🚀 FILE UPLOAD START (Widget)');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📋 File name: ${_selectedFileName ?? "unknown"}');
    print('📦 File size: ${_selectedFileBytes != null ? "${_selectedFileBytes!.length} bytes" : "path: $_selectedFilePath"}');

    setState(() {
      _isUploading = true;
      _uploadError = null;
    });

    try {
      final uploadFileUseCase = Provider.of<UploadFile>(context, listen: false);
      print('✅ UploadFile use case obtained');
      
      final uploadResult = await uploadFileUseCase.call(
        UploadFileParams(
          file: _selectedFilePath,
          fileBytes: _selectedFileBytes,
          fileName: _selectedFileName ?? 'file',
          module: 'attachments',
        ),
      );

      if (!mounted) {
        print('⚠️ Widget unmounted during upload');
        return;
      }

      uploadResult.fold(
        (failure) {
          print('❌ Upload failed: ${failure.message}');
          setState(() {
            _uploadError = failure.message;
            _isUploading = false;
            _isFileUploaded = false;
            _uploadedFileId = null;
          });
          _updateFormField(null);
        },
        (uploadResponse) {
          print('✅ Upload successful! File ID: ${uploadResponse.fileId}');
          setState(() {
            _uploadedFileId = uploadResponse.fileId;
            _isUploading = false;
            _isFileUploaded = true;
            _uploadError = null;
          });
          _updateFormField(uploadResponse.fileId);
        },
      );
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    } catch (e, stackTrace) {
      if (!mounted) {
        print('⚠️ Widget unmounted during error handling');
        return;
      }
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('❌ FILE UPLOAD ERROR (Widget)');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('💥 Error type: ${e.runtimeType}');
      print('💥 Error message: $e');
      print('📚 Stack trace:');
      print('$stackTrace');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
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
