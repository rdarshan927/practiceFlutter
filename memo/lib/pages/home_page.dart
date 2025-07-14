import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:memo/services/firestore.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirestoreService firestoreService = FirestoreService();
  final TextEditingController textController = TextEditingController();

  // open modal to add memo
  void openNoteBox({String? docID, String? memoText}) {
    if (memoText != null) {
      textController.text = memoText;
    } else {
      textController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          memoText != null ? "Edit Memo" : "Add Memo",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: textController,
          decoration: InputDecoration(
            hintText: "Enter your memo here",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[100],
          ),
          maxLines: 5,
          minLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if(docID == null) {
                firestoreService.addMemo(textController.text);
              } else {
                firestoreService.updateMemo(docID, textController.text);
              }
              textController.clear();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(memoText != null ? "Update" : "Add")
          )
        ],
      )
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Memo", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: openNoteBox,
        elevation: 4,
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: firestoreService.getMemoStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            
            if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
              List notesList = snapshot.data!.docs;

              return ListView.builder(
                itemCount: notesList.length,
                itemBuilder: (context, index) {
                  DocumentSnapshot document = notesList[index];
                  String docID = document.id;
                  Map<String, dynamic> data = document.data() as Map<String, dynamic>;
                  String memoText = data['memo'];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(
                        memoText,
                        style: const TextStyle(fontSize: 16),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => openNoteBox(docID: docID, memoText: memoText),
                            icon: Icon(Icons.edit, color: Theme.of(context).primaryColor),
                            tooltip: 'Edit',
                          ),
                          IconButton(
                            onPressed: () {
                              // Add a confirmation dialog
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Memo'),
                                  content: const Text('Are you sure you want to delete this memo?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        firestoreService.deleteMemo(docID);
                                        Navigator.pop(context);
                                      },
                                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );
                            },
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Delete',
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            } else {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.note_alt_outlined, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No memos yet',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    Text(
                      'Tap + to add your first memo',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }
          }
        ),
      ),
    );
  }
}
