import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get uid => _auth.currentUser!.uid;

  // Collections: Users/{uid}/Friends (accepted), Users/{uid}/Requests (incoming), Users/{uid}/Sent (outgoing)

  Stream<List<Map<String, dynamic>>> friendsStream() {
    return _db
        .collection('Users')
        .doc(uid)
        .collection('Friends')
        .snapshots()
        .asyncMap((snap) async {
      final List<Map<String, dynamic>> list = [];
      for (final d in snap.docs) {
        final friendId = d.id;
        final userDoc = await _db.collection('Users').doc(friendId).get();
        if (userDoc.exists) list.add(userDoc.data()!..putIfAbsent('uid', () => friendId));
      }
      return list;
    });
  }

  Future<void> sendRequest(String toUid) async {
    if (toUid == uid) return;
    final batch = _db.batch();
    final meSent = _db.collection('Users').doc(uid).collection('Sent').doc(toUid);
    final themIncoming =
        _db.collection('Users').doc(toUid).collection('Requests').doc(uid);
    batch.set(meSent, {
      'at': FieldValue.serverTimestamp(),
    });
    batch.set(themIncoming, {
      'at': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> acceptRequest(String fromUid) async {
    final batch = _db.batch();
    // remove pending
    batch.delete(_db.collection('Users').doc(uid).collection('Requests').doc(fromUid));
    batch.delete(_db.collection('Users').doc(fromUid).collection('Sent').doc(uid));
    // add to friends both sides
    batch.set(_db.collection('Users').doc(uid).collection('Friends').doc(fromUid), {
      'since': FieldValue.serverTimestamp(),
    });
    batch.set(
        _db.collection('Users').doc(fromUid).collection('Friends').doc(uid), {
      'since': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Stream<List<Map<String, dynamic>>> incomingRequestsStream() {
    return _db
        .collection('Users')
        .doc(uid)
        .collection('Requests')
        .snapshots()
        .asyncMap((snap) async {
      final List<Map<String, dynamic>> list = [];
      for (final d in snap.docs) {
        final requesterId = d.id;
        final userDoc = await _db.collection('Users').doc(requesterId).get();
        if (userDoc.exists) list.add(userDoc.data()!..putIfAbsent('uid', () => requesterId));
      }
      return list;
    });
  }
}
