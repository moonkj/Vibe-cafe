import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:cafe_vibe/core/services/places_service.dart';

// ──────────────────────────────────────────────────────────────
// Mock HTTP client — returns StreamedResponse with utf8-encoded body
// so Korean characters in JSON don't cause Latin-1 encoding errors.
// ──────────────────────────────────────────────────────────────

typedef _StreamHandler = Future<http.StreamedResponse> Function(http.BaseRequest);

class _MockClient extends http.BaseClient {
  final _StreamHandler handler;
  _MockClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) => handler(request);
}

http.StreamedResponse _ok(String jsonBody) => http.StreamedResponse(
      Stream.fromIterable([utf8.encode(jsonBody)]),
      200,
      headers: const {'content-type': 'application/json; charset=utf-8'},
    );

http.StreamedResponse _err(int code) =>
    http.StreamedResponse(Stream.fromIterable([]), code);

PlacesService _svc(_StreamHandler h) => PlacesService(client: _MockClient(h));

// ──────────────────────────────────────────────────────────────
// Tests
// ──────────────────────────────────────────────────────────────

void main() {
  // ── autocomplete (Places New API) ─────────────────────────
  group('PlacesService.autocomplete', () {
    test('빈(공백만) 입력 → HTTP 호출 없이 빈 리스트 반환', () async {
      var called = false;
      final svc = _svc((_) async {
        called = true;
        return _ok('');
      });
      expect(await svc.autocomplete('  '), isEmpty);
      expect(called, isFalse);
    });

    test('정상 응답 — suggestions.placePrediction 파싱', () async {
      final body = jsonEncode({
        'suggestions': [
          {
            'placePrediction': {
              'placeId': 'place_001',
              'structuredFormat': {
                'mainText': {'text': '스타벅스 강남점'},
                'secondaryText': {'text': '서울 강남구'},
              },
            },
          },
          {
            'placePrediction': {
              'placeId': 'place_002',
              'structuredFormat': {
                'mainText': {'text': '메가커피 종로점'},
                'secondaryText': {'text': '서울 종로구'},
              },
            },
          },
        ],
      });
      final svc = _svc((_) async => _ok(body));
      final result = await svc.autocomplete('스타벅스');
      expect(result.length, 2);
      expect(result[0].placeId, 'place_001');
      expect(result[0].mainText, '스타벅스 강남점');
      expect(result[0].secondaryText, '서울 강남구');
    });

    test('secondaryText 없을 때 빈 문자열', () async {
      final body = jsonEncode({
        'suggestions': [
          {
            'placePrediction': {
              'placeId': 'place_003',
              'structuredFormat': {
                'mainText': {'text': '카페베이지'},
              },
            },
          },
        ],
      });
      final svc = _svc((_) async => _ok(body));
      final result = await svc.autocomplete('카페');
      expect(result[0].mainText, '카페베이지');
      expect(result[0].secondaryText, '');
    });

    test('suggestions 빈 배열 → 빈 리스트', () async {
      final body = jsonEncode({'suggestions': []});
      final svc = _svc((_) async => _ok(body));
      expect(await svc.autocomplete('없는검색어'), isEmpty);
    });

    test('HTTP 500 오류 → 빈 리스트', () async {
      final svc = _svc((_) async => _err(500));
      expect(await svc.autocomplete('test'), isEmpty);
    });

    test('네트워크 예외 → 빈 리스트', () async {
      final svc = _svc((_) => Future.error(const _FakeException('timeout')));
      expect(await svc.autocomplete('test'), isEmpty);
    });
  });

  // ── getDetails ────────────────────────────────────────────
  group('PlacesService.getDetails', () {
    test('정상 응답 — lat/lng 파싱', () async {
      final body = jsonEncode({
        'status': 'OK',
        'result': {
          'geometry': {
            'location': {'lat': 37.5665, 'lng': 126.9780},
          },
        },
      });
      final svc = _svc((_) async => _ok(body));
      final result = await svc.getDetails('ChIJ_test');
      expect(result, isNotNull);
      expect(result!.lat, closeTo(37.5665, 0.0001));
      expect(result.lng, closeTo(126.9780, 0.0001));
    });

    test('HTTP 오류 → null', () async {
      final svc = _svc((_) async => _err(500));
      expect(await svc.getDetails('ChIJ_test'), isNull);
    });

    test('result 없음(geometry 없음) → null', () async {
      final body = jsonEncode({'status': 'OK', 'result': {}});
      final svc = _svc((_) async => _ok(body));
      expect(await svc.getDetails('ChIJ_test'), isNull);
    });

    test('geometry location 없음 → null', () async {
      final body = jsonEncode({
        'status': 'OK',
        'result': {'geometry': {}},
      });
      final svc = _svc((_) async => _ok(body));
      expect(await svc.getDetails('ChIJ_test'), isNull);
    });

    test('네트워크 예외 → null', () async {
      final svc = _svc((_) => Future.error(const _FakeException('timeout')));
      expect(await svc.getDetails('ChIJ_test'), isNull);
    });
  });

  // ── geocodeAddress ────────────────────────────────────────
  group('PlacesService.geocodeAddress', () {
    test('빈(공백) 주소 → HTTP 호출 없이 null', () async {
      var called = false;
      final svc = _svc((_) async {
        called = true;
        return _ok('');
      });
      expect(await svc.geocodeAddress('   '), isNull);
      expect(called, isFalse);
    });

    test('정상 응답 — 좌표 파싱', () async {
      final body = jsonEncode({
        'status': 'OK',
        'results': [
          {
            'geometry': {
              'location': {'lat': 37.5546, 'lng': 126.9706},
            },
          },
        ],
      });
      final svc = _svc((_) async => _ok(body));
      final result = await svc.geocodeAddress('서울역');
      expect(result, isNotNull);
      expect(result!.lat, closeTo(37.5546, 0.001));
      expect(result.lng, closeTo(126.9706, 0.001));
    });

    test('status ZERO_RESULTS → null', () async {
      final body = jsonEncode({'status': 'ZERO_RESULTS', 'results': []});
      final svc = _svc((_) async => _ok(body));
      expect(await svc.geocodeAddress('존재하지않는주소xyz'), isNull);
    });

    test('results 빈 배열 → null', () async {
      final body = jsonEncode({'status': 'OK', 'results': []});
      final svc = _svc((_) async => _ok(body));
      expect(await svc.geocodeAddress('서울역'), isNull);
    });

    test('HTTP 오류 → null', () async {
      final svc = _svc((_) async => _err(500));
      expect(await svc.geocodeAddress('서울역'), isNull);
    });

    test('네트워크 예외 → null', () async {
      final svc = _svc((_) => Future.error(const _FakeException('timeout')));
      expect(await svc.geocodeAddress('서울역'), isNull);
    });
  });

  // ── nearbyCafes (Places New API) ──────────────────────────
  group('PlacesService.nearbyCafes', () {
    test('카페 2개 반환 — id/name/location/formattedAddress 파싱', () async {
      final body = jsonEncode({
        'places': [
          {
            'id': 'cafe_001',
            'displayName': {'text': '카페A', 'languageCode': 'ko'},
            'location': {'latitude': 37.500, 'longitude': 127.000},
            'formattedAddress': '서울 강남구',
          },
          {
            'id': 'cafe_002',
            'displayName': {'text': '카페B', 'languageCode': 'ko'},
            'location': {'latitude': 37.501, 'longitude': 127.001},
            // formattedAddress 없음 → null
          },
        ],
      });
      final svc = _svc((_) async => _ok(body));
      final result = await svc.nearbyCafes(lat: 37.5, lng: 127.0);
      expect(result.length, 2);
      expect(result[0].placeId, 'cafe_001');
      expect(result[0].name, '카페A');
      expect(result[0].formattedAddress, '서울 강남구');
      expect(result[1].placeId, 'cafe_002');
      expect(result[1].formattedAddress, isNull);
    });

    test('비카페 블랙리스트(PC방) 필터링', () async {
      final body = jsonEncode({
        'places': [
          {
            'id': 'pc_001',
            'displayName': {'text': '찐빵PC방', 'languageCode': 'ko'},
            'location': {'latitude': 37.500, 'longitude': 127.000},
          },
          {
            'id': 'cafe_001',
            'displayName': {'text': '스타벅스 강남점', 'languageCode': 'ko'},
            'location': {'latitude': 37.501, 'longitude': 127.001},
          },
        ],
      });
      final svc = _svc((_) async => _ok(body));
      final result = await svc.nearbyCafes(lat: 37.5, lng: 127.0);
      expect(result.length, 1);
      expect(result[0].placeId, 'cafe_001');
    });

    test('location 없는 결과는 무시', () async {
      final body = jsonEncode({
        'places': [
          {
            'id': 'cafe_no_geo',
            'displayName': {'text': '위치없는카페', 'languageCode': 'ko'},
            // location 없음
          },
        ],
      });
      final svc = _svc((_) async => _ok(body));
      expect(await svc.nearbyCafes(lat: 37.5, lng: 127.0), isEmpty);
    });

    test('빈 응답(places 없음) → 빈 리스트', () async {
      final body = jsonEncode(<String, dynamic>{});
      final svc = _svc((_) async => _ok(body));
      expect(await svc.nearbyCafes(lat: 37.5, lng: 127.0), isEmpty);
    });

    test('HTTP 오류 → 빈 리스트', () async {
      final svc = _svc((_) async => _err(500));
      expect(await svc.nearbyCafes(lat: 37.5, lng: 127.0), isEmpty);
    });

    test('네트워크 예외 → 빈 리스트', () async {
      final svc = _svc((_) => Future.error(const _FakeException('fail')));
      expect(await svc.nearbyCafes(lat: 37.5, lng: 127.0), isEmpty);
    });
  });

  // ── getPhotoUrl ───────────────────────────────────────────
  group('PlacesService.getPhotoUrl', () {
    test('빌드 시 MAPS_API_KEY 미설정(빈 문자열) → HTTP 호출 없이 null 반환', () async {
      // In test environment: String.fromEnvironment('MAPS_API_KEY') == ''
      // → getPhotoUrl() returns null immediately without HTTP call
      var called = false;
      final svc = _svc((_) async {
        called = true;
        return _ok('');
      });
      final result = await svc.getPhotoUrl('ChIJ_test');
      expect(result, isNull);
      expect(called, isFalse, reason: 'API 키 없으면 HTTP 호출 하지 않아야 함');
    });
  });

  // ── PlacePrediction / PlaceLatLng / PlaceResult 모델 ──────
  group('PlacePrediction 모델', () {
    test('필드 저장 확인', () {
      const p = PlacePrediction(
        placeId: 'id_001',
        mainText: '스타벅스',
        secondaryText: '강남구',
      );
      expect(p.placeId, 'id_001');
      expect(p.mainText, '스타벅스');
      expect(p.secondaryText, '강남구');
    });
  });

  group('PlaceLatLng 모델', () {
    test('lat/lng 필드 저장 확인', () {
      const ll = PlaceLatLng(lat: 37.5665, lng: 126.9780);
      expect(ll.lat, 37.5665);
      expect(ll.lng, 126.9780);
    });
  });

  group('PlaceResult 모델', () {
    test('필수 필드 저장 확인', () {
      const r = PlaceResult(
        placeId: 'res_001',
        name: '메가커피',
        lat: 37.0,
        lng: 127.0,
      );
      expect(r.placeId, 'res_001');
      expect(r.formattedAddress, isNull);
    });

    test('선택 필드(formattedAddress) 저장 확인', () {
      const r = PlaceResult(
        placeId: 'res_002',
        name: '카페',
        lat: 37.0,
        lng: 127.0,
        formattedAddress: '서울 강남구',
      );
      expect(r.formattedAddress, '서울 강남구');
    });
  });
}

// ── Network error stub ────────────────────────────────────────
class _FakeException implements Exception {
  final String message;
  const _FakeException(this.message);
}
