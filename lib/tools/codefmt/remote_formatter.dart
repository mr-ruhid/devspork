import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'models.dart';

class RemoteFormatter {
  RemoteFormatter._();

  static final http.Client _client = http.Client();

  static Future<FormatResult> format(
      String input,
      CodeLanguage language,
      FormatOptions options,
      ) async {
    final String trimmed = input.trim();
    if (trimmed.isEmpty) {
      return const FormatResult(errorKey: 'codefmt_error_empty');
    }

    final String? parser = _parserFor(language);
    if (parser == null) {
      return const FormatResult(errorKey: 'codefmt_error_unsupported');
    }

    final Stopwatch sw = Stopwatch()..start();

    try {
      final http.Response response = await _client
          .post(
        Uri.parse(RemoteConfig.endpoint),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(<String, dynamic>{
          'code': input,
          'parser': parser,
          'semi': true,
          'singleQuote': true,
          'tabWidth': options.indentSize,
          'useTabs': options.useTabs,
        }),
      )
          .timeout(RemoteConfig.timeout);

      sw.stop();

      if (response.statusCode != 200) {
        return FormatResult(
          errorKey: 'codefmt_error_http',
          errorDetail: 'HTTP ${response.statusCode}',
          durationMs: sw.elapsedMilliseconds,
        );
      }

      final dynamic decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return FormatResult(
          errorKey: 'codefmt_error_response',
          errorDetail: 'Invalid response format',
          durationMs: sw.elapsedMilliseconds,
        );
      }

      final bool success = decoded['success'] as bool? ?? false;
      if (!success) {
        final String err = decoded['error']?.toString() ?? 'Unknown error';
        return FormatResult(
          errorKey: 'codefmt_error_parse',
          errorDetail: err,
          durationMs: sw.elapsedMilliseconds,
        );
      }

      final String result = decoded['result']?.toString() ?? '';
      if (result.isEmpty) {
        return FormatResult(
          errorKey: 'codefmt_error_empty_result',
          durationMs: sw.elapsedMilliseconds,
        );
      }

      return FormatResult(
        output: result.trimRight(),
        durationMs: sw.elapsedMilliseconds,
      );
    } on TimeoutException {
      sw.stop();
      return FormatResult(
        errorKey: 'codefmt_error_timeout',
        durationMs: sw.elapsedMilliseconds,
      );
    } on SocketException catch (e) {
      sw.stop();
      return FormatResult(
        errorKey: 'codefmt_error_socket',
        errorDetail: e.message,
        durationMs: sw.elapsedMilliseconds,
      );
    } on http.ClientException catch (e) {
      sw.stop();
      return FormatResult(
        errorKey: 'codefmt_error_client',
        errorDetail: e.message,
        durationMs: sw.elapsedMilliseconds,
      );
    } on FormatException catch (e) {
      sw.stop();
      return FormatResult(
        errorKey: 'codefmt_error_format',
        errorDetail: e.message,
        durationMs: sw.elapsedMilliseconds,
      );
    } catch (e) {
      sw.stop();
      return FormatResult(
        errorKey: 'codefmt_error_unknown',
        errorDetail: e.toString(),
        durationMs: sw.elapsedMilliseconds,
      );
    }
  }

  static String? _parserFor(CodeLanguage language) {
    switch (language) {
      case CodeLanguage.javascript:
        return 'babel';
      case CodeLanguage.typescript:
        return 'typescript';
      default:
        return null;
    }
  }

  static Future<bool> ping() async {
    try {
      final http.Response response = await _client
          .get(Uri.parse(RemoteConfig.endpoint))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static void dispose() {
    _client.close();
  }
}