import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  // get collection of memos
  final CollectionReference memos =
      FirebaseFirestore.instance.collection('memos');

  // create
  Future<void> addMemo(String note) {
    return memos.add({
      'memo': note,
      'timestamp': Timestamp.now(),
    });
  }

  // read
  Stream<QuerySnapshot> getMemoStream() {
    final memosStream = memos.orderBy('timestamp', descending: true).snapshots();
    return memosStream;
  }

  // update
  Future<void> updateMemo(String docID, String newMemo) {
    return memos.doc(docID).update({
      'memo': newMemo,
      'timestamp': Timestamp.now(),
    });
  }

  // delete
  Future<void> deleteMemo(String docID) {
    return memos.doc(docID).delete();
  }
}