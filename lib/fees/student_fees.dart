import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class student_fees extends StatefulWidget {
  final String classId;
  final String className;
  final String studentUid;

  const student_fees({
    super.key,
    required this.classId,
    required this.className,
    required this.studentUid,
  });

  @override
  State<student_fees> createState() => _student_feesState();
}

class _student_feesState extends State<student_fees> {
  String? _qrUrl;
  File? _screenshotFile;
  Uint8List? _screenshotData;
  String? _screenshotUrl;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _errorMsg;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    _fetchQrUrl();
    _fetchScreenshotUrl();
  }

  String get _monthKey => DateFormat('yyyy-MM').format(_selectedMonth);

  Future<void> _fetchQrUrl() async {
    final doc = await FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.classId)
        .get();
    if (doc.exists && doc.data() != null && doc.data()!['feesQrUrl'] != null) {
      setState(() {
        _qrUrl = doc.data()!['feesQrUrl'];
      });
    }
  }

  Future<void> _fetchScreenshotUrl() async {
    final doc = await FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.classId)
        .collection('fees')
        .doc(_monthKey)
        .get();
    if (doc.exists && doc.data() != null && doc.data()!['url'] != null) {
      setState(() {
        _screenshotUrl = doc.data()!['url'];
      });
    } else {
      setState(() {
        _screenshotUrl = null;
      });
    }
  }

  Future<void> _pickScreenshotAndUpload() async {
    setState(() {
      _isUploading = true;
      _errorMsg = null;
    });

    XFile? pickedFile;

    if (kIsWeb) {
      pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        _screenshotData = await pickedFile.readAsBytes();
      }
    } else {
      pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        _screenshotFile = File(pickedFile.path);
      }
    }

    if (pickedFile == null) {
      setState(() {
        _isUploading = false;
        _errorMsg = 'No file selected.';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    final fileName = 'fees_screenshots/${widget.classId}/$_monthKey/${widget.studentUid}.jpg';
    final ref = FirebaseStorage.instance.ref().child(fileName);
    UploadTask uploadTask;

    if (kIsWeb && _screenshotData != null) {
      uploadTask = ref.putData(_screenshotData!, SettableMetadata(contentType: 'image/jpeg'));
    } else if (_screenshotFile != null) {
      uploadTask = ref.putFile(_screenshotFile!);
    } else {
      setState(() {
        _isUploading = false;
        _errorMsg = 'No file selected.';
      });
      return;
    }

    uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) async {
      final progress = snapshot.bytesTransferred / snapshot.totalBytes;
      setState(() => _uploadProgress = progress);

      if (snapshot.state == TaskState.success) {
        final downloadUrl = await ref.getDownloadURL();
        // Store the download URL in Firestore under the class/fees/month/studentUid
        await FirebaseFirestore.instance
            .collection('classes')
            .doc(widget.classId)
            .collection('fees')
            .doc(_monthKey)
            .set({'url': downloadUrl}, SetOptions(merge: true));
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
          _screenshotUrl = downloadUrl;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Screenshot uploaded!')),
        );
      }
    }, onError: (e) {
      setState(() {
        _isUploading = false;
        _errorMsg = 'Upload error: $e';
      });
    });
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(now.year - 2, 1),
      lastDate: DateTime(now.year + 2, 12),
      helpText: 'Select Month',
      fieldLabelText: 'Month/Year',
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      selectableDayPredicate: (date) => date.day == 1,
    );
    if (picked != null) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month);
      });
      await _fetchScreenshotUrl();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.className} - Fees'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text('Scan the QR code below to pay your fees:', ),
              const SizedBox(height: 12),
              Center(
                child: SizedBox(
                  height: 180,
                  width: 180,
                  child: Card(
                    elevation: 2,
                    child: _qrUrl != null
                        ? Image.network(_qrUrl!, fit: BoxFit.cover)
                        : const Center(child: Text('No QR/Photo uploaded')),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Month: ${DateFormat('MMMM yyyy').format(_selectedMonth)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.calendar_month),
                    label: const Text('Change'),
                    onPressed: _pickMonth,
                  ),
                ],
              ),
              const Divider(),
              Text('Upload your payment screenshot for this month:', ),
              const SizedBox(height: 12),
              _isUploading
                  ? Column(
                      children: [
                        LinearProgressIndicator(value: _uploadProgress),
                        const SizedBox(height: 8),
                        Text('${(_uploadProgress * 100).toStringAsFixed(0)}% uploaded'),
                      ],
                    )
                  : _screenshotUrl != null
                      ? Column(
                          children: [
                            SizedBox(
                              height: 180,
                              width: 180,
                              child: Image.network(_screenshotUrl!, fit: BoxFit.cover),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              icon: const Icon(Icons.upload),
                              label: const Text('Replace Screenshot'),
                              onPressed: _pickScreenshotAndUpload,
                            ),
                          ],
                        )
                      : ElevatedButton.icon(
                          icon: const Icon(Icons.upload),
                          label: const Text('Upload Screenshot'),
                          onPressed: _pickScreenshotAndUpload,
                        ),
              if (_errorMsg != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(_errorMsg!, style: const TextStyle(color: Colors.red)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}