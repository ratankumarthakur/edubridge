import 'package:chat/quiz/quizlist.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateQuizScreen extends StatefulWidget {
  final String clas;
  final String classname;
  CreateQuizScreen({required this.clas,required this.classname});
  @override
  _CreateQuizScreenState createState() => _CreateQuizScreenState();
}

class _CreateQuizScreenState extends State<CreateQuizScreen> {
  final _titleController = TextEditingController();
  final _codeController = TextEditingController();

  void _proceedToAddQuestions() {
    final title = _titleController.text.trim();
    final code = _codeController.text.trim();

    if (title.isNotEmpty && code.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddQuestionsScreen(
              classname: widget.classname,
            classId: widget.clas,
            quizTitle: title,
            quizCode: code,
          ),
        ),
      );
    } else {
      // Show error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Quiz'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Quiz Title'),
            ),
            TextField(
              controller: _codeController,
              decoration: InputDecoration(labelText: 'Unique Code'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _proceedToAddQuestions,
              child: Text('Add Questions'),
            ),
          ],
        ),
      ),
    );
  }
}


class AddQuestionsScreen extends StatefulWidget {
  final String quizTitle;
  final String quizCode;
  final String classId;
  final String classname;

  AddQuestionsScreen({required this.classId,required this.quizTitle, required this.quizCode, required this.classname});

  @override
  _AddQuestionsScreenState createState() => _AddQuestionsScreenState();
}

class _AddQuestionsScreenState extends State<AddQuestionsScreen> {
  final _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers =
      List.generate(4, (_) => TextEditingController());
  int _correctOptionIndex = 0;
  List<Question> _questions = [];

  void _addQuestion() {
    final questionText = _questionController.text.trim();
    final options = _optionControllers.map((c) => c.text.trim()).toList();

    if (questionText.isNotEmpty &&
        options.every((option) => option.isNotEmpty)) {
      final question = Question(
        questionText: questionText,
        options: options,
        correctOptionIndex: _correctOptionIndex,
      );

      setState(() {
        _questions.add(question);
        _questionController.clear();
        _optionControllers.forEach((c) => c.clear());
        _correctOptionIndex = 0;
      });
    } else {
      // Show error
    }
  }

  void _publishQuiz() async {
    final quiz = Quiz(
      classname:widget.classname ,
      //userid: ,
      createdAt:FieldValue.serverTimestamp(),
      title: widget.quizTitle,
      code: widget.quizCode,
      questions: _questions,
    );

    final firestore = FirebaseFirestore.instance;
final quizRef = firestore
    .collection('classes')
    .doc(widget.classId)
    .collection('quizzes')
    .doc(); // Don't call .set() yet

final quizId = quizRef.id;

    await FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.classId)
        .collection('quizzes')
        .doc(quizId)
        .set(quiz.toMap());

    await FirebaseFirestore.instance
        .collection('quizzes').doc(quizId)
        .set(quiz.toMap());

    // Navigate back or show success message
    Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => TeacherQuizzesPage(classname: widget.classname, classid: widget.classId,),
  ),
);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Quiz Published Successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Questions'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _questionController,
              decoration: InputDecoration(labelText: 'Question'),
            ),
            SizedBox(height: 10),
            ...List.generate(4, (index) {
              return ListTile(
                leading: Radio<int>(
                  value: index,
                  groupValue: _correctOptionIndex,
                  onChanged: (value) {
                    setState(() {
                      _correctOptionIndex = value!;
                    });
                  },
                ),
                title: TextField(
                  controller: _optionControllers[index],
                  decoration: InputDecoration(labelText: 'Option ${index + 1}'),
                ),
              );
            }),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addQuestion,
              child: Text('Add Question'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _questions.isNotEmpty ? _publishQuiz : null,
              child: Text('Publish Quiz'),
            ),
          ],
        ),
      ),
    );
  }
}

class Quiz {
  final String title;
  final String code;
  final dynamic createdAt;
  //final String userid;
  final String classname;
  final List<Question> questions;

  Quiz({required this.createdAt,required this.classname,required this.title, required this.code, required this.questions});

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'code': code,
      //'created by':userid,
      'createdAt':createdAt,
      'class name':classname,
      'questions': questions.map((q) => q.toMap()).toList(),
    };
  }
}

class Question {
  final String questionText;
  final List<String> options;
  final int correctOptionIndex;

  Question({
    required this.questionText,
    required this.options,
    required this.correctOptionIndex,
  });

  Map<String, dynamic> toMap() {
    return {
      'questionText': questionText,
      'options': options,
      'correctOptionIndex': correctOptionIndex,
    };
  }
}
