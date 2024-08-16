import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as converts;


class NetworkUtil {
  static Future<String?> fetchUrl(Uri uri, {Map<String, String>? headers}) async{
    try{
      final response = await http.get(uri, headers: headers);
      if(response.statusCode == 200){
        return response.body;
      }
    }
    catch(e){
      debugPrint(e.toString());
    }
    return null;
  }
}

class HttpSession {
  Map<String, String> headers = {
    'Content-Type': 'application/json; charset=UTF-8',
    'Connection': 'Keep-Alive'
  };
  List<http.Response> lastResponses = [];
  bool verify = false;

  Future<http.Response> get(String url, [Map<String, dynamic>? data, int timeout = 9000]) async {
    var uri = Uri.parse(url);
    if(data != null) uri = uri.replace(queryParameters: data);
    http.Response response = await http.get(uri, headers: headers).timeout(Duration(milliseconds: timeout));
    updateCookie(response);
    lastResponses.add(response);
    return response;
  }

  Future<http.Response> post(String url, [Map<String, dynamic>? data, int timeout = 9000]) async {
    var uri = Uri.parse(url);
    http.Response response = await http.post(uri, body: converts.jsonEncode(data), headers: headers).timeout(Duration(milliseconds: timeout));
    updateCookie(response);
    lastResponses.add(response);
    return response;
  }

  Future<http.Response> put(String url, [Map<String, dynamic>? data, int timeout = 9000]) async {
    var uri = Uri.parse(url);
    http.Response response = await http.put(uri, body: converts.jsonEncode(data), headers: headers).timeout(Duration(milliseconds: timeout));
    updateCookie(response);
    lastResponses.add(response);
    return response;
  }

  void updateCookie(http.Response response) {
    String? rawCookie = response.headers['set-cookie'];
    if (rawCookie != null) {
      int index = rawCookie.indexOf(';');
      headers['cookie'] =
          (index == -1) ? rawCookie : rawCookie.substring(0, index);
    }
  }
}