import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Endereço do back-end. Troque aqui quando o servidor for hospedado.
const String apiBase = String.fromEnvironment('API_BASE', defaultValue: 'http://localhost:3000');

// Erro devolvido pela API, com a mensagem que o servidor enviou
class ApiErro implements Exception {
  final int status;
  final String mensagem;
  ApiErro(this.status, this.mensagem);

  @override
  String toString() => mensagem;
}

Future<Map<String, String>> _cabecalhos() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  return {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };
}

dynamic _tratarResposta(http.Response resposta) {
  final dados = resposta.body.isEmpty ? null : jsonDecode(resposta.body);
  if (resposta.statusCode >= 200 && resposta.statusCode < 300) return dados;
  final mensagem = (dados is Map && dados['error'] != null)
      ? dados['error'].toString()
      : 'Erro inesperado (${resposta.statusCode})';
  throw ApiErro(resposta.statusCode, mensagem);
}

// GET em uma rota protegida (envia o token salvo no login)
Future<dynamic> apiGet(String caminho) async {
  final resposta = await http.get(
    Uri.parse('$apiBase$caminho'),
    headers: await _cabecalhos(),
  );
  return _tratarResposta(resposta);
}

// POST em uma rota protegida, com corpo em JSON
Future<dynamic> apiPost(String caminho, Map<String, dynamic> corpo) async {
  final resposta = await http.post(
    Uri.parse('$apiBase$caminho'),
    headers: await _cabecalhos(),
    body: jsonEncode(corpo),
  );
  return _tratarResposta(resposta);
}