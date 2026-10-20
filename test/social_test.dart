import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twohearts/features/social/social_models.dart';
import 'package:twohearts/features/social/social_repository.dart';
import 'package:twohearts/features/social/social_screen.dart';

class SessionDemo extends DemoSocialRepository {
  String? identity = 'demo-me';
  final changes = StreamController<String?>.broadcast();
  bool failComment = true;
  @override
  String? get userId => identity;
  @override
  Stream<String?> get authChanges => changes.stream;
  @override
  Future<void> comment(String post, String text) async {
    if (failComment) throw Exception('Offline');
    await super.comment(post, text);
  }
}

void main() {
  test('Lifetime excludes its exact expiry boundary', () {
    final created = DateTime.utc(2026, 10, 10),
        expires = created.add(const Duration(hours: 24));
    final post = SocialPost(
      id: '1',
      name: 'Example',
      type: 'phrase',
      content: 'Example',
      caption: '',
      createdAt: created,
      expiresAt: expires,
    );
    expect(
      post.activeAt(expires.subtract(const Duration(microseconds: 1))),
      isTrue,
    );
    expect(post.activeAt(expires), isFalse);
  });
  test(
    'A retry of the same like state does not increase the count twice',
    () async {
      final demo = DemoSocialRepository();
      final post = demo.posts.first;
      await demo.like(post, true);
      await demo.like(post, true);
      expect(demo.posts.first.likes, post.likes + 1);
      await demo.like(demo.posts.first, false);
      expect(demo.posts.first.likes, post.likes);
    },
  );
  test('Image type rejects HTML and unsupported bytes', () {
    expect(
      () => imageExtension(Uint8List.fromList('<html>'.codeUnits)),
      throwsFormatException,
    );
    expect(imageExtension(Uint8List.fromList([255, 216, 255, 0])), 'jpg');
  });
  testWidgets(
    'Demo is visibly isolated and logout removes old account content',
    (tester) async {
      final repository = SessionDemo();
      addTearDown(repository.changes.close);
      await tester.pumpWidget(
        MaterialApp(home: SocialScreen(repository: repository)),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Demostración'), findsWidgets);
      await tester.scrollUntilVisible(
        find.text('Hoy elegimos pasar más tiempo juntos.'), 160,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Hoy elegimos pasar más tiempo juntos.'),
        findsOneWidget,
      );
      repository.identity = null;
      repository.changes.add(null);
      await tester.pumpAndSettle();
      expect(find.text('Hoy elegimos pasar más tiempo juntos.'), findsNothing);
      expect(find.textContaining('Inicia sesión'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'A failed comment keeps its draft and retry submits exactly once',
    (tester) async {
      final repository = SessionDemo();
      addTearDown(repository.changes.close);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SocialCommentsSheet(
              repository: repository,
              post: repository.posts.last,
              now: () => DateTime.now().toUtc(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Qué lindo recuerdo');
      await tester.tap(find.text('Comentar'));
      await tester.pumpAndSettle();
      expect(find.text('Qué lindo recuerdo'), findsOneWidget);
      expect(find.textContaining('Conservamos'), findsOneWidget);
      repository.failComment = false;
      await tester.tap(find.text('Comentar'));
      await tester.pumpAndSettle();
      expect((await repository.comments(repository.posts.last.id)).length, 1);
      expect(find.text('Qué lindo recuerdo'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('Comments remain usable above a mobile keyboard', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = DemoSocialRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 700),
            viewInsets: EdgeInsets.only(bottom: 300),
          ),
          child: Scaffold(
            body: SocialCommentsSheet(
              repository: repository,
              post: repository.posts.last,
              now: () => DateTime.now().toUtc(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Comentar'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
