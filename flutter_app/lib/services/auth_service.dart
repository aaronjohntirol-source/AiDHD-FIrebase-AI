import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/user.dart';
import '../utils/input_validation.dart';

class AuthResult {
  final bool ok;
  final User? user;
  final String? error;
  const AuthResult.success(this.user)
      : ok = true,
        error = null;
  const AuthResult.failure(this.error)
      : ok = false,
        user = null;
}

class AuthService {
  firebase_auth.FirebaseAuth get _auth => firebase_auth.FirebaseAuth.instance;
  CollectionReference<Map<String, dynamic>> get _users =>
      FirebaseFirestore.instance.collection('users');
  CollectionReference<Map<String, dynamic>> get _usernameIndex =>
      FirebaseFirestore.instance.collection('username_index');

  User _userFromDocument(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data()!;
    return User(
      id: document.id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      username: data['username'] as String? ?? '',
      passwordHash: '',
      age: data['age'] as String? ?? '',
      gender: data['gender'] as String? ?? 'Prefer not to say',
      createdAt: data['createdAt'] as String? ?? '',
      initialAssessmentScore: data['initialAssessmentScore'] as int?,
      initialAssessmentCategory: data['initialAssessmentCategory'] as String?,
    );
  }

  Future<AuthResult> register({
    required String name,
    required String email,
    required String username,
    required String password,
    String age = '',
  }) async {
    final nameError = InputValidation.nameError(name);
    if (nameError != null) return AuthResult.failure(nameError);
    final ageError = InputValidation.ageError(age);
    if (ageError != null) return AuthResult.failure(ageError);
    final usernameError = InputValidation.usernameError(username);
    if (usernameError != null) return AuthResult.failure(usernameError);

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
          email: email.trim(), password: password);
      final firebaseUser = credential.user!;
      final usernameKey = username.trim().toLowerCase();
      final usernameDocument = _usernameIndex.doc(usernameKey);
      var usernameCreated = false;
      try {
        final usernameTaken = await FirebaseFirestore.instance
            .runTransaction<bool>((transaction) async {
          final existing = await transaction.get(usernameDocument);
          if (existing.exists) return true;
          transaction.set(usernameDocument, {
            'uid': firebaseUser.uid,
            'email': email.trim(),
          });
          return false;
        });
        if (usernameTaken) {
          await firebaseUser.delete();
          return const AuthResult.failure('Username already taken.');
        }
        usernameCreated = true;
        await _users.doc(firebaseUser.uid).set({
          'name': name.trim(),
          'email': email.trim(),
          'username': usernameKey,
          'age': age,
          'gender': 'Prefer not to say',
          'createdAt': DateTime.now().toIso8601String(),
        });
        return AuthResult.success(
            _userFromDocument(await _users.doc(firebaseUser.uid).get()));
      } catch (_) {
        if (usernameCreated) await usernameDocument.delete();
        await firebaseUser.delete();
        rethrow;
      }
    } on firebase_auth.FirebaseAuthException catch (error) {
      return AuthResult.failure(_authError(error));
    } on FirebaseException catch (error) {
      return AuthResult.failure(_firestoreError(error));
    } catch (_) {
      return const AuthResult.failure(
          'Unable to create your account right now.');
    }
  }

  Future<AuthResult> login(String usernameOrEmail, String password) async {
    try {
      var email = usernameOrEmail.trim();
      if (!email.contains('@')) {
        final usernameDocument =
            await _usernameIndex.doc(email.toLowerCase()).get();
        if (!usernameDocument.exists) {
          return const AuthResult.failure(
              'No account found with that username or email.');
        }
        email = usernameDocument.data()!['email'] as String;
      }
      final credential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      final document = await _users.doc(credential.user!.uid).get();
      if (!document.exists) {
        return const AuthResult.failure('Your profile could not be found.');
      }
      final profile = _userFromDocument(document);
      await _ensureUsernameIndex(profile);
      return AuthResult.success(profile);
    } on firebase_auth.FirebaseAuthException catch (error) {
      return AuthResult.failure(_authError(error));
    } on FirebaseException catch (error) {
      return AuthResult.failure(_firestoreError(error));
    } catch (_) {
      return const AuthResult.failure('Unable to sign in right now.');
    }
  }

  Future<void> _ensureUsernameIndex(User user) async {
    final document = _usernameIndex.doc(user.username.toLowerCase());
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final existing = await transaction.get(document);
      if (!existing.exists) {
        transaction.set(document, {
          'uid': user.id,
          'email': user.email,
        });
      }
    });
  }

  Future<User?> updateUser(String id,
      {String? name,
      String? age,
      String? gender,
      int? initialAssessmentScore,
      String? initialAssessmentCategory}) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (age != null) updates['age'] = age;
    if (gender != null) updates['gender'] = gender;
    if (initialAssessmentScore != null) {
      updates['initialAssessmentScore'] = initialAssessmentScore;
    }
    if (initialAssessmentCategory != null) {
      updates['initialAssessmentCategory'] = initialAssessmentCategory;
    }
    if (updates.isNotEmpty) await _users.doc(id).update(updates);
    final document = await _users.doc(id).get();
    return document.exists ? _userFromDocument(document) : null;
  }

  Future<User?> getSessionUser() async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) return null;
      final document = await _users.doc(firebaseUser.uid).get();
      return document.exists ? _userFromDocument(document) : null;
    } on firebase_auth.FirebaseException {
      return null;
    }
  }

  Future<void> logout() => _auth.signOut();

  String _authError(firebase_auth.FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'invalid-credential':
      case 'user-not-found':
      case 'wrong-password':
        return 'Incorrect email or password.';
      default:
        return error.message ?? 'Authentication failed.';
    }
  }

  String _firestoreError(FirebaseException error) {
    if (error.code == 'permission-denied') {
      return 'Firebase denied access to your profile. Check Firestore Rules.';
    }
    return error.message ?? 'Unable to save your profile right now.';
  }
}
