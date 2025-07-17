import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pie_chart/pie_chart.dart';


class AvailableQuizzesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Available Quizzes")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('quizzes').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error loading quizzes"));
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator(color: Colors.green,));

          final quizzes = snapshot.data!.docs;

          return ListView.builder(
            //padding: EdgeInsets.all(6),
            itemCount: quizzes.length,
            itemBuilder: (context, index) {
              final quiz = quizzes[index];
              return ListTile(
                
                //borderRadius: BorderRadius.circular(8),
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey.shade300, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                //leading: Icon(Icons.quiz, color: Colors.blue),
                tileColor:index%2==0? Colors.grey.shade100:Colors.white,
                title: Text(quiz['title']),
                subtitle: Text("Code: ${quiz['code']}"),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      final codeController = TextEditingController();
                      return AlertDialog(
                        title: Text("Enter Quiz Code"),
                        content: TextField(
                          controller: codeController,
                          decoration: InputDecoration(hintText: "Code"),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              if (codeController.text.trim() == quiz['code']) {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => StudentQuizPage(quizData: quiz),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Incorrect Code")),
                                );
                              }
                            },
                            child: Text("Submit"),
                          )
                        ],
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}


class StudentQuizPage extends StatefulWidget {
  final dynamic quizData;
  const StudentQuizPage({required this.quizData});

  @override
  _StudentQuizPageState createState() => _StudentQuizPageState();
}

class _StudentQuizPageState extends State<StudentQuizPage> {
  Map<int, int?> selectedAnswers = {};

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.quizData['questions'].length; i++) {
      selectedAnswers[i] = null;
    }
  }

  void _submitQuiz() {
    int correct = 0;
    int incorrect = 0;
    int unattempted = 0;
    List<int> correctQuestions = [];
    List<int> incorrectQuestions = [];

    for (int i = 0; i < widget.quizData['questions'].length; i++) {
      final question = widget.quizData['questions'][i];
      final correctIndex = question['correctOptionIndex'];

      if (selectedAnswers[i] == null) {
        unattempted++;
      } else if (selectedAnswers[i] == correctIndex) {
        correct++;
        correctQuestions.add(i + 1);
      } else {
        incorrect++;
        incorrectQuestions.add(i + 1);
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizResultPage(
          correct: correct,
          incorrect: incorrect,
          unattempted: unattempted,
          correctQuestions: correctQuestions,
          incorrectQuestions: incorrectQuestions,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final questions = List<Map<String, dynamic>>.from(widget.quizData['questions']);

    return Scaffold(
      appBar: AppBar(title: Text("Attempt Quiz")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            ...List.generate(questions.length, (index) {
              final question = questions[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Q${index + 1}: ${question['questionText']}", style: TextStyle(fontWeight: FontWeight.bold)),
                  ...List.generate(4, (optIdx) {
                    final selected = selectedAnswers[index] == optIdx;
                    return GestureDetector(
                      onTap: () { 
                        setState(() {
                          if (selected) {
                            selectedAnswers[index] = null;
                          } else {
                            selectedAnswers[index] = optIdx;
                          }
                        });
                      },
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 4),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: selected ? Colors.blue.shade100 : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(question['options'][optIdx]),
                      ),
                    );
                  }),
                  SizedBox(height: 12),
                ],
              );
            }),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitQuiz,
              child: Text("Submit Quiz"),
            )
          ],
        ),
      ),
    );
  }
}

class QuizResultPage extends StatelessWidget {
  final int correct;
  final int incorrect;
  final int unattempted;
  final List<int> correctQuestions;
  final List<int> incorrectQuestions;

  const QuizResultPage({
    required this.correct,
    required this.incorrect,
    required this.unattempted,
    required this.correctQuestions,
    required this.incorrectQuestions,
  });

  @override
  Widget build(BuildContext context) {
    Map<String, double> dataMap = {
      "Correct": correct.toDouble(),
      "Incorrect": incorrect.toDouble(),
      "Unattempted": unattempted.toDouble(),
    };

    return Scaffold(
      appBar: AppBar(title: Text("Result"),leading: SizedBox(),),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            PieChart(dataMap: dataMap),
            SizedBox(height: 20),
            Text("Correct Answers: $correct", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text("Questions: ${correctQuestions.join(', ')}"),
            SizedBox(height: 10),
            Text("Incorrect Answers: $incorrect", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text("Questions: ${incorrectQuestions.join(', ')}"),
            SizedBox(height: 10),
            //Text("Questions: ${unattemptedQuestions.join(', ')}"),
            Text("Unattempted: $unattempted", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
