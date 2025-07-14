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
          title: memoText != null ? const Text("Edit Memo") : const Text("Add Memo"),
          content: TextField(
            controller: textController,
          ),
          actions: [
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
                child: Text(memoText != null ? "Update" : "Add")
            )
          ],
        )
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Memo")),
      floatingActionButton: FloatingActionButton(
          onPressed: openNoteBox,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
          stream: firestoreService.getMemoStream(),
          builder: (context, snapshot) {
            if(snapshot.hasData) {
              List notesList = snapshot.data!.docs;

              return ListView.builder(
                itemCount: notesList.length,
                  itemBuilder: (context, index) {
                  //   get document individually
                    DocumentSnapshot document = notesList[index];
                    String docID = document.id;

                  //   get memo from each doc
                    Map<String, dynamic> data = document.data() as Map<String, dynamic>;
                    String memoText = data['memo'];

                  //   display as tile
                    return ListTile(
                      title: Text(memoText),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                        //   update button
                          IconButton(
                            onPressed: () => openNoteBox(docID: docID, memoText: memoText),
                            icon: const Icon(Icons.edit),
                          ),
                        //   delete button
                          IconButton(
                            onPressed: () => firestoreService.deleteMemo(docID),
                            icon: const Icon(Icons.delete),
                          ),
                        ],
                      )
                    );
                  },
              );
            } else {
              return const Text('No memos ..!');
            }
          }
      ),
    );
  }
}
