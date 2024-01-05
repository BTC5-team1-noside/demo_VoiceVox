import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import "package:just_audio/just_audio.dart";

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'VOICEVOX App',
      home: VoiceVoxScreen(),
    );
  }
}

class VoiceVoxScreen extends StatefulWidget {
  const VoiceVoxScreen({super.key});

  @override
  _VoiceVoxScreenState createState() => _VoiceVoxScreenState();
}

class _VoiceVoxScreenState extends State<VoiceVoxScreen> {
  String _voiceText = 'こんにちは、VOICEVOXです。';

  final AudioPlayer audioPlayer = AudioPlayer();

  void playVoiceFromData(Uint8List data) async {
    final source = MyStreamAudioSource(data);
    await audioPlayer.setAudioSource(source);
    audioPlayer.play();
  }

  Future<void> _synthesizeVoice() async {
    var url = 'http://localhost:50021/audio_query?text=$_voiceText&speaker=1';
    var response = await http.post(
      Uri.parse(url),
      headers: {
        HttpHeaders.contentTypeHeader: 'application/json',
      },
      body: json.encode({
        'text': _voiceText,
      }),
    );
    if (response.statusCode == 200) {
      var body = json.decode(response.body);
      var audioQuery = body;
      // var audioQuery = body['accent_phrases'];

      // 生成したクエリを使って実際に音声を生成する
      var synthesisHost = 'localhost:50021';
      var synthesisPath = '/synthesis';
      var synthesisResponse = await http.post(
        Uri.http(
          synthesisHost,
          synthesisPath,
          {
            "speaker": "13", //speakerのvalueを変更することで話者を変更
          },
        ),
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
        },
        body: json.encode(audioQuery),
      );
      if (synthesisResponse.statusCode == 200) {
        final data = synthesisResponse.bodyBytes;
        // debugPrint("$data");

        playVoiceFromData(data);
        debugPrint('音声生成成功!');
      } else {
        debugPrint('音声生成失敗: ${synthesisResponse.reasonPhrase}');
      }
    } else {
      debugPrint('クエリ生成失敗: ${response.reasonPhrase}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VOICEVOX App'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              onChanged: (value) {
                setState(() {
                  _voiceText = value;
                });
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'テキストを入力',
              ),
            ),
            ElevatedButton(
              onPressed: _synthesizeVoice,
              child: const Text('音声を生成'),
            ),
          ],
        ),
      ),
    );
  }
}

class MyStreamAudioSource extends StreamAudioSource {
  final Uint8List audioData;

  MyStreamAudioSource(this.audioData);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end = end ?? audioData.length;

    return StreamAudioResponse(
      sourceLength: audioData.length,
      contentLength: end - start,
      offset: start,
      contentType: "audio/mpeg",
      stream: Stream.value(audioData.sublist(start, end)),
    );
  }
}
