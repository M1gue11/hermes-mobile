import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/domain/models/gateway_command.dart';
import 'package:hermes_mobile/domain/models/skill_invocation.dart';
import 'package:hermes_mobile/domain/models/chat_message.dart';
import 'package:hermes_mobile/domain/models/conversation_search.dart';

void main() {
  test(
    'slash parser preserves multiline arguments and leaves paths/prose alone',
    () {
      expect(parseSlashInvocation('/GOAL  preparar\n\n  manter recuo  '), (
        name: 'goal',
        arguments: 'preparar\n\n  manter recuo',
      ));
      for (final text in [
        '/usr/local/bin',
        'veja /status',
        '/',
        '/   status',
      ]) {
        expect(parseSlashInvocation(text), isNull, reason: text);
      }
    },
  );

  test(
    'catalog binds aliases, Skills, custom overrides and hidden native metadata',
    () {
      final catalog = GatewayCommandCatalog.fromJson({
        'pairs': [
          ['/status', 'Status'],
          ['/work', 'Trabalhar'],
          ['/status', 'Meu script'],
        ],
        'canon': {'/s': '/status'},
        'categories': [
          {
            'name': 'User commands',
            'pairs': [
              ['/status', 'Meu script'],
            ],
          },
        ],
        'commands': {
          '/model': {'desktop': 'hidden', 'argument_mode': 'mixed'},
        },
        'skills': {
          '/work': {'usage': 2},
        },
      });
      expect(catalog.find('s')!.description, 'Meu script');
      expect(catalog.find('status')!.needsConfirmation(''), isTrue);
      expect(catalog.find('work')!.skill, isTrue);
      expect(catalog.find('work')!.needsConfirmation('faça a tarefa'), isFalse);
      expect(catalog.find('model')!.desktop, 'hidden');
      expect(
        catalog.commands.where((command) => command.name == 'model'),
        isEmpty,
      );
    },
  );

  test(
    'read-only forms run directly; destructive and argument-bearing forms confirm',
    () {
      expect(
        const GatewayCommand(
          name: 'status',
          description: '',
        ).needsConfirmation(''),
        isFalse,
      );
      expect(
        const GatewayCommand(
          name: 'usage',
          description: '',
        ).needsConfirmation('reset'),
        isTrue,
      );
      expect(
        const GatewayCommand(
          name: 'undo',
          description: '',
        ).needsConfirmation(''),
        isTrue,
      );
      expect(
        const GatewayCommand(
          name: 'compress',
          description: '',
        ).needsConfirmation(''),
        isTrue,
      );
      expect(
        const GatewayCommand(
          name: 'clear',
          description: '',
          desktop: 'terminal',
        ).unavailableReason,
        isNull,
      );
      expect(
        const GatewayCommand(name: 'quit', description: '').unavailableReason,
        isNotNull,
      );
    },
  );

  test(
    'result parser refuses unknown, malformed or missing prompt directives',
    () {
      expect(() => GatewayCommandResult.fromJson({}), throwsFormatException);
      expect(
        () => GatewayCommandResult.fromJson({'type': 'skill', 'name': 'work'}),
        throwsFormatException,
      );
      expect(
        () => GatewayCommandResult.fromJson({'type': 'alias', 'target': ''}),
        throwsFormatException,
      );
      expect(
        GatewayCommandResult.fromJson({'output': 'ok'}).kind,
        GatewayCommandResultKind.output,
      );
      expect(
        GatewayCommandResult.fromJson({
          'type': 'prefill',
          'message': 'revise',
        }).message,
        'revise',
      );
    },
  );

  test('Skill projection exposes invocation, never its body or runtime note', () {
    const raw =
        '[IMPORTANT: The user has invoked the "work" skill, indicating they want you to follow its instructions.\n'
        'The full skill content is loaded below.]\n\nSEGREDO INTERNO DO PROMPT\n\n'
        'The user has provided the following instruction alongside the skill invocation: corrija\n\n  e teste'
        '\n\n[Runtime note: hidden]';
    expect(skillInvocationText(raw), '/work corrija e teste');
    const messages = [
      UserMessage(
        id: 'u',
        text: raw,
        time: '',
        displayText: '/work corrija e teste',
      ),
    ];
    expect(conversationSearchMatches(messages, 'SEGREDO INTERNO'), isEmpty);
    expect(conversationSearchMatches(messages, 'corrija'), [0]);
    expect(skillInvocationText('Minha pergunta normal'), isNull);
    expect(
      skillInvocationText(
        '[IMPORTANT: The user has invoked the "/a /b" stacked skill bundle, loading 2 skills together.]'
        '\nUser instruction: faça isso\n\n[Loaded as part of the stacked skill invocation "a".]\nBODY',
      ),
      '/a /b faça isso',
    );
  });
}
