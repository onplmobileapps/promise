import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:railway_hrms/core/utils/field_rules.dart';

/// [value] put through [formatters], as typed or pasted.
String typed(List<TextInputFormatter> formatters, String value) => formatters
    .fold(
      TextEditingValue.empty,
      (old, formatter) => formatter.formatEditUpdate(
        old,
        TextEditingValue(
          text: old == TextEditingValue.empty ? value : old.text,
        ),
      ),
    )
    .text;

void main() {
  group('FieldRules', () {
    final id = FieldRules.all([
      FieldRules.required('Required'),
      FieldRules.digits('Digits only'),
      FieldRules.minLength(4, 'Too short'),
      FieldRules.maxLength(10, 'Too long'),
    ]);

    test('the first rule broken speaks', () {
      expect(id(null), 'Required');
      expect(id('   '), 'Required');
      expect(id('12a4'), 'Digits only');
      expect(id('123'), 'Too short');
      expect(id('12345678901'), 'Too long');
      expect(id('10482'), isNull);
    });

    test('each rule leaves an empty value to required', () {
      for (final rule in [
        FieldRules.digits('x'),
        FieldRules.minLength(3, 'x'),
        FieldRules.email('x'),
        FieldRules.pakistaniMobile('x'),
        FieldRules.pattern(RegExp(r'^A'), 'x'),
      ]) {
        expect(rule(''), isNull);
      }
    });

    test('spaces, e-mail, mobile and a value typed again', () {
      expect(FieldRules.noSpaces('No spaces')('a b'), 'No spaces');
      expect(FieldRules.email('E-mail')('ali@pr.gov.pk'), isNull);
      expect(FieldRules.email('E-mail')('ali@'), 'E-mail');
      expect(FieldRules.pakistaniMobile('Mobile')('03001234567'), isNull);
      expect(FieldRules.pakistaniMobile('Mobile')('0300123'), 'Mobile');
      var password = 'secret';
      final again = FieldRules.sameAs(() => password, 'Different');
      expect(again('secret'), isNull);
      password = 'changed';
      expect(again('secret'), 'Different');
    });
  });

  group('FieldInput', () {
    test('keeps out spaces and what is too long', () {
      expect(
        typed(FieldInput.noSpaces(maxLength: 10), ' 12 345 678 9012 '),
        '1234567890',
      );
      expect(typed(FieldInput.noSpaces(), 'a b\tc'), 'abc');
      expect(typed(FieldInput.digits(maxLength: 4), '1a2b3c4d5'), '1234');
      expect(typed(FieldInput.limited(3), 'abcdef'), 'abc');
    });
  });
}
