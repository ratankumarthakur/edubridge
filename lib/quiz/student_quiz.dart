import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pie_chart/pie_chart.dart';

class AvailableQuizzesScreen extends StatefulWidget {
  @override
  State<AvailableQuizzesScreen> createState() => _AvailableQuizzesScreenState();
}

class _AvailableQuizzesScreenState extends State<AvailableQuizzesScreen> {
  String searchQuery = '';
  String searchBy = 'title';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Available Quizzes")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: Colors.green, width: 2),
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: searchBy == "title"
                            ? 'Search by title...'
                            : 'Search by class name...',
                        hintStyle: const TextStyle(color: Colors.black54),
                        border: InputBorder.none,
                        icon: const Icon(Icons.search, color: Colors.green),
                      ),
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      onChanged: (value) {
                        setState(() => searchQuery = value.trim());
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                  decoration: BoxDecoration(
                    color:
                        Colors.green.withOpacity(0.1), // light background hint
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: Colors.green, width: 2),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      focusColor: Colors.white,
                      value: searchBy,
                      items: const [
                        DropdownMenuItem(value: 'title', child: Text('Title')),
                        DropdownMenuItem(
                            value: 'class name', child: Text('Class Name')),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => searchBy = value);
                      },
                      icon:
                          const Icon(Icons.arrow_downward, color: Colors.green),
                      dropdownColor: Colors.green.shade50,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('quizzes').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text("Error loading quizzes"));
                }
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(color: Colors.green));
                }

                final quizzes = snapshot.data!.docs.where((quiz) {
                  final field = quiz[searchBy]?.toString().toLowerCase() ?? '';
                  return field.contains(searchQuery.toLowerCase());
                }).toList();

                return ListView.builder(
                  itemCount: quizzes.length,
                  itemBuilder: (context, index) {
                    final quiz = quizzes[index];
                    final Timestamp timestamp = quiz['createdAt'];
                    final DateTime date = timestamp.toDate();
                    final formatted =
                        DateFormat('MMM d, yyyy – hh:mm a').format(date);
                    
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              // or use Image.asset for local images
                              'https://static.vecteezy.com/system/resources/previews/046/386/166/non_2x/abstract-blue-and-pink-glowing-lines-curved-overlapping-background-template-premium-award-design-vector.jpg',
                              height: 100,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Container(
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.black.withOpacity(
                                  0.1), // dark overlay for contrast
                            ),
                          ),
                          Positioned.fill(
                            child: Card(
                              color: Colors.transparent,
                              elevation: 6,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                title: Text(
                                  quiz['title'] ?? 'Unnamed quiz',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${quiz['class name'] ?? 'N/A'}',
                                          style: const TextStyle(
                                              color: Colors.white70),
                                        ),
                                        Icon(
                                          Icons.arrow_forward,
                                          color: Colors.white,
                                        ),
                                      ],
                                    ),
                                    Text(
                                      'Created at: $formatted',
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.white70),
                                    ),
                                  ],
                                ),
                                //trailing:Icon(Icons.arrow_forward,color: Colors.white,) ,
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      final codeController =
                                          TextEditingController();
                                      return AlertDialog(
                                        title: const Text("Enter Quiz Code"),
                                        content: TextField(
                                          controller: codeController,
                                          decoration: const InputDecoration(
                                              hintText: "Code"),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              if (codeController.text.trim() ==
                                                  quiz['code']) {
                                                Navigator.pop(context);
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        StudentQuizPage(
                                                            quizData: quiz),
                                                  ),
                                                );
                                              } else {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                      content: Text(
                                                          "Incorrect Code")),
                                                );
                                              }
                                            },
                                            child: const Text("Submit"),
                                          )
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
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
    final questions =
        List<Map<String, dynamic>>.from(widget.quizData['questions']);

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
                  Text("Q${index + 1}: ${question['questionText']}",
                      style: TextStyle(fontWeight: FontWeight.bold)),
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
                          color: selected
                              ? Colors.blue.shade100
                              : Colors.grey.shade200,
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
      appBar: AppBar(
        title: Text("Result"),
        leading: SizedBox(),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            PieChart(dataMap: dataMap),
            SizedBox(height: 20),
            Text("Correct Answers: $correct",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text("Questions: ${correctQuestions.join(', ')}"),
            SizedBox(height: 10),
            Text("Incorrect Answers: $incorrect",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text("Questions: ${incorrectQuestions.join(', ')}"),
            SizedBox(height: 10),
            //Text("Questions: ${unattemptedQuestions.join(', ')}"),
            Text("Unattempted: $unattempted",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
