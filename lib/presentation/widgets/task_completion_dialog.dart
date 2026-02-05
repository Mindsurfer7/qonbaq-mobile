import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../domain/usecases/upload_file.dart';

/// Диалог для ввода результата выполнения задачи и загрузки файла
class TaskCompletionDialog extends StatefulWidget {
  final String taskTitle;

  const TaskCompletionDialog({super.key, required this.taskTitle});

  @override
  State<TaskCompletionDialog> createState() => _TaskCompletionDialogState();
}

class _TaskCompletionDialogState extends State<TaskCompletionDialog> {
  final TextEditingController _resultTextController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _selectedFilePath;
  List<int>? _selectedFileBytes;
  String? _selectedFileName;
  bool _isUploading = false;
  bool _isFileUploaded = false;
  String? _uploadError;
  String? _uploadedFileId;

  @override
  void dispose() {
    _resultTextController.dispose();
    super.dispose();
  }

  Future<void> _selectFile() async {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📁 FILE SELECTION START (Task Completion Dialog)');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🌐 Platform: ${kIsWeb ? "Web" : "Mobile"}');

    try {
      FilePickerResult? result;

      if (kIsWeb) {
        // На вебе используем withData: true для загрузки данных сразу
        // Это помогает избежать проблем с инициализацией
        print('📂 Opening file picker (Web) with withData: true');
        result = await FilePicker.platform.pickFiles(
          type: FileType.any,
          allowMultiple: false,
          withData: true, // Важно для веба - загружаем данные сразу
        );
      } else {
        // Для мобильных платформ
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
          // На вебе всегда используем bytes
          print('   Bytes: ${file.bytes != null ? "${file.bytes!.length} bytes" : "null"}');
          if (file.bytes != null) {
            final fileBytes = file.bytes!;
            print('✅ File bytes loaded successfully');

            setState(() {
              _selectedFilePath = null;
              _selectedFileBytes = fileBytes;
              _selectedFileName = fileName;
              _isFileUploaded = false;
              _uploadedFileId = null;
              _uploadError = null;
            });

            await _uploadFile();
          } else {
            print('❌ File bytes are null!');
            print('   File size from picker: ${file.size} bytes');
            setState(() {
              _uploadError =
                  'Не удалось загрузить файл (размер: ${(file.size / 1024).toStringAsFixed(2)} KB). Попробуйте выбрать другой файл.';
            });
          }
        } else {
          // Для мобильных платформ используем path
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
      print('❌ FILE SELECTION ERROR (Task Completion Dialog)');
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
    if (_selectedFilePath == null && _selectedFileBytes == null) {
      print('⚠️ Upload cancelled: no file data');
      print('   _selectedFilePath: ${_selectedFilePath ?? "null"}');
      print('   _selectedFileBytes: ${_selectedFileBytes != null ? "${_selectedFileBytes!.length} bytes" : "null"}');
      return;
    }

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🚀 FILE UPLOAD START (Task Completion Dialog)');
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

      uploadResult.fold(
        (failure) {
          print('❌ Upload failed: ${failure.message}');
          setState(() {
            _uploadError = failure.message;
            _isUploading = false;
            _isFileUploaded = false;
            _uploadedFileId = null;
          });
        },
        (uploadResponse) {
          print('✅ Upload successful! File ID: ${uploadResponse.fileId}');
          setState(() {
            _uploadedFileId = uploadResponse.fileId;
            _isUploading = false;
            _isFileUploaded = true;
            _uploadError = null;
          });
        },
      );
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    } catch (e, stackTrace) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('❌ FILE UPLOAD ERROR (Task Completion Dialog)');
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
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final resultText = _resultTextController.text.trim();
    if (resultText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите текст результата работы'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Если файл выбран, но еще не загружен, загружаем его
    if ((_selectedFilePath != null || _selectedFileBytes != null) &&
        !_isFileUploaded) {
      await _uploadFile();
      // Если загрузка не удалась, не продолжаем
      if (!_isFileUploaded) {
        return;
      }
    }

    // Возвращаем результат
    Navigator.of(
      context,
    ).pop({'resultText': resultText, 'resultFileId': _uploadedFileId});
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Завершить задачу'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed:
                    _isUploading ? null : () => Navigator.of(context).pop(),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        widget.taskTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _resultTextController,
                        decoration: const InputDecoration(
                          labelText: 'Результат работы *',
                          hintText: 'Опишите результат выполнения задачи',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 5,
                        enabled: !_isUploading,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Введите текст результата работы';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Приложить файл (необязательно)',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      if (_selectedFileName != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                _isFileUploaded
                                    ? Colors.green[50]
                                    : Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            border:
                                _isFileUploaded
                                    ? Border.all(color: Colors.green, width: 2)
                                    : null,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _isFileUploaded
                                        ? Icons.check_circle
                                        : Icons.attach_file,
                                    color:
                                        _isFileUploaded ? Colors.green : null,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(_selectedFileName!)),
                                  if (_isUploading)
                                    const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  else
                                    IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () {
                                        setState(() {
                                          _selectedFilePath = null;
                                          _selectedFileBytes = null;
                                          _selectedFileName = null;
                                          _isFileUploaded = false;
                                          _uploadedFileId = null;
                                          _uploadError = null;
                                        });
                                      },
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
                          onPressed: _isUploading ? null : _selectFile,
                          icon: const Icon(Icons.attach_file),
                          label: const Text('Выбрать файл'),
                        ),
                      if (_uploadError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _uploadError!,
                            style: TextStyle(color: Colors.red[700]),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _isUploading ? null : () => Navigator.of(context).pop(),
                    child: const Text('Отмена'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed:
                        (_isUploading ||
                                (_selectedFileName != null && !_isFileUploaded))
                            ? null
                            : _handleSubmit,
                    child:
                        _isUploading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Text('Завершить'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
