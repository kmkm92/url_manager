import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_manager/database.dart';
import 'package:url_manager/view_models/url_view_model.dart';

class AddUrlFormView extends ConsumerStatefulWidget {
  final Url? url;

  AddUrlFormView({this.url});

  @override
  _AddUrlFormViewState createState() => _AddUrlFormViewState();
}

class _AddUrlFormViewState extends ConsumerState<AddUrlFormView> {
  final _titleController = TextEditingController();
  final _urlController = TextEditingController();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.url != null) {
      _titleController.text = widget.url!.message;
      _urlController.text = widget.url!.url;
    }
    _urlController.addListener(_updateUrlFieldHeight);
  }

  @override
  void dispose() {
    _urlController.removeListener(_updateUrlFieldHeight);
    _titleController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _updateUrlFieldHeight() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(30.0),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(Icons.check),
              onPressed: _addOrUpdateUrl,
            ),
          ],
        ),
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.0),
              topRight: Radius.circular(20.0),
            ),
          ),
          child: ListView(
            children: [
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.all(1.0),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        floatingLabelStyle: TextStyle(
                          color: Colors.black,
                        ),
                        labelText: 'タイトル',
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _urlController,
                      minLines: 1,
                      maxLines: null,
                      decoration: InputDecoration(
                        floatingLabelStyle: TextStyle(
                          color: Colors.black,
                        ),
                        labelText: 'URL',
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _addOrUpdateUrl,
                      child: Text(widget.url == null ? '追加' : '更新'),
                      style: ElevatedButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addOrUpdateUrl() async {
    if (_urlController.text.isEmpty) {
      setState(() {
        _errorMessage = 'URLを入力してください。';
      });
      return;
    }
    if (_titleController.text.length >= 100) {
      setState(() {
        _errorMessage = '最大文字数は100文字です。';
      });
      return;
    }

    final newUrl = Url(
      id: widget.url?.id,
      message: _titleController.text,
      url: _urlController.text,
      details: '',
      savedAt: DateTime.now(),
    );
    ref.read(urlListProvider.notifier).addOrUpdateUrl(newUrl);
    Navigator.pop(context);
  }
}
