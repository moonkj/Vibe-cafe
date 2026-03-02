import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';
import '../../features/map/presentation/map_controller.dart';

// ──────────────────────────────────────────────────────────────────────────
// Constants
// ──────────────────────────────────────────────────────────────────────────
const double _gangnamLat = 37.4979;
const double _gangnamLng = 127.0276;
const String _dummyPrefix = 'DUMMY:';

// ──────────────────────────────────────────────────────────────────────────
// 30 realistic cafes spread ~1 km around Gangnam Station
// dB profile: 6 very-quiet(<45) / 8 quiet(45-55) / 8 mid(55-65) / 5 loud(65-75) / 3 very-loud(>75)
// Chains + indie mix to exercise chain-detection & badge logic
// ──────────────────────────────────────────────────────────────────────────
const _spots = [
  // ── Very quiet < 45 dB ──────────────────────────────────────────────────
  _S(
    name: '블루보틀 강남점',
    lat: 37.4975, lng: 127.0270,
    addr: '서울 강남구 강남대로 454',
    avgDb: 38.5, cnt: 22, trust: 3.5, sticker: 'STUDY', recent: 3, hoursAgo: 2,
    reports: [
      _R(-2.3, 'STUDY',      '집중하기 좋아요',         5),
      _R( 1.1, 'STUDY',      '소음 거의 없음',           3),
      _R(-1.5, 'STUDY_ZONE', null,                      1),
      _R( 0.7, 'STUDY',      '공부하기 딱이에요',         6),
      _R(-0.9, 'MINIMAL',    '미니멀 인테리어, 집중 잘 됨', 0),
    ],
  ),
  _S(
    name: '프릳츠 강남점',
    lat: 37.4992, lng: 127.0248,
    addr: '서울 강남구 봉은사로 114',
    avgDb: 36.9, cnt: 25, trust: 3.8, sticker: 'STUDY', recent: 2, hoursAgo: 3,
    reports: [
      _R(-1.9, 'STUDY',      '도서관 수준으로 조용해요', 4),
      _R( 2.1, 'STUDY',      null,                    1),
      _R(-0.8, 'STUDY_ZONE', '혼공하기 완벽',           2),
      _R( 1.3, 'MINIMAL',    '군더더기 없는 분위기',     7),
      _R(-2.0, 'STUDY',      '재방문 의사 100%',        0),
    ],
  ),
  _S(
    name: '요거프레소 강남점',
    lat: 37.4945, lng: 127.0270,
    addr: '서울 강남구 강남대로 298',
    avgDb: 39.8, cnt: 8, trust: 1.5, sticker: 'STUDY', recent: 1, hoursAgo: 10,
    reports: [
      _R(-1.2, 'STUDY',   '생각보다 조용해요', 3),
      _R( 0.8, 'COZY',    null,              5),
      _R(-2.1, 'HEALING', '힐링되는 조용한 공간', 1),
      _R( 1.5, 'STUDY',   '집중 잘 됩니다',   0),
    ],
  ),
  _S(
    name: '어니언 강남점',
    lat: 37.4975, lng: 127.0330,
    addr: '서울 강남구 선릉로 161',
    avgDb: 41.6, cnt: 31, trust: 4.0, sticker: 'MINIMAL', recent: 4, hoursAgo: 1,
    reports: [
      _R(-3.1, 'MINIMAL',    '미니멀 인테리어 최고',  2),
      _R( 1.4, 'INSTA',      '사진 찍기 좋아요',      1),
      _R(-0.6, 'STUDY',      '조용해서 작업하기 좋음', 4),
      _R( 2.2, 'COZY',       '아늑한 공간',          0),
      _R(-1.8, 'MINIMAL',    null,                  6),
    ],
  ),
  _S(
    name: '아모레 라운지 강남점',
    lat: 37.5012, lng: 127.0270,
    addr: '서울 강남구 강남대로 522',
    avgDb: 42.3, cnt: 21, trust: 3.5, sticker: 'COZY', recent: 2, hoursAgo: 5,
    reports: [
      _R(-2.0, 'COZY',    '고급스럽고 조용해요',  3),
      _R( 1.3, 'HEALING', null,                  1),
      _R(-1.1, 'MINIMAL', '차분한 분위기',         5),
      _R( 0.9, 'COZY',    '럭셔리한 카페',         0),
      _R(-1.5, 'INSTA',   '인테리어 감성 넘침',     2),
    ],
  ),
  _S(
    name: '할리스 강남역점',
    lat: 37.4962, lng: 127.0274,
    addr: '서울 강남구 강남대로 382',
    avgDb: 43.2, cnt: 9, trust: 2.0, sticker: 'HEALING', recent: 1, hoursAgo: 8,
    reports: [
      _R(-1.3, 'HEALING', '힐링되는 카페',       5),
      _R( 0.6, 'RELAX',   '여유로운 오후',        2),
      _R(-2.4, 'HEALING', null,                  1),
      _R( 1.8, 'GREEN',   '식물 인테리어 예뻐요',  4),
      _R(-0.5, 'COZY',    '포근한 공간',          0),
    ],
  ),

  // ── Quiet 45–55 dB ──────────────────────────────────────────────────────
  _S(
    name: '폴바셋 강남점',
    lat: 37.4970, lng: 127.0280,
    addr: '서울 강남구 강남대로 408',
    avgDb: 45.1, cnt: 18, trust: 3.0, sticker: 'STUDY_ZONE', recent: 2, hoursAgo: 4,
    reports: [
      _R(-1.1, 'STUDY_ZONE', '조용한 스터디 공간',   5),
      _R( 0.9, 'STUDY',      '집중력 올라가는 느낌',  2),
      _R(-2.0, 'STUDY_ZONE', null,                   1),
      _R( 1.6, 'MINIMAL',    '미니멀한 인테리어',     4),
      _R(-0.5, 'STUDY',      '소음 적어서 좋아요',    0),
    ],
  ),
  _S(
    name: '더벤티 강남역점',
    lat: 37.4958, lng: 127.0265,
    addr: '서울 강남구 강남대로 344',
    avgDb: 47.3, cnt: 11, trust: 2.2, sticker: 'COZY', recent: 1, hoursAgo: 7,
    reports: [
      _R(-2.1, 'COZY',    '가성비 좋고 조용해요', 3),
      _R( 1.7, 'RELAX',   '여유롭게 쉬기 좋음',   1),
      _R(-0.8, 'COZY',    null,                  2),
      _R( 2.3, 'HEALING', '편안한 분위기',         0),
    ],
  ),
  _S(
    name: '달콤커피 강남점',
    lat: 37.4980, lng: 127.0318,
    addr: '서울 강남구 선릉로 139',
    avgDb: 48.5, cnt: 15, trust: 2.8, sticker: 'COZY', recent: 2, hoursAgo: 6,
    reports: [
      _R(-1.5, 'COZY',    '달콤한 분위기',       4),
      _R( 1.2, 'RELAX',   '조용한 편이에요',      2),
      _R(-2.3, 'COZY',    null,                  1),
      _R( 0.8, 'HEALING', '포근한 카페',          0),
      _R(-1.0, 'STUDY',   '집중 가능한 수준',     5),
    ],
  ),
  _S(
    name: '베어바리스타 강남점',
    lat: 37.5005, lng: 127.0258,
    addr: '서울 강남구 봉은사로 130',
    avgDb: 46.8, cnt: 12, trust: 2.4, sticker: 'HEALING', recent: 1, hoursAgo: 9,
    reports: [
      _R(-2.2, 'HEALING',    '힐링 감성 카페',   3),
      _R( 1.0, 'COZY',       '편안한 분위기',    1),
      _R(-0.7, 'STUDY_ZONE', null,               2),
      _R( 1.8, 'GREEN',      '식물이 많아요',    0),
    ],
  ),
  _S(
    name: '드롭탑 강남점',
    lat: 37.4988, lng: 127.0310,
    addr: '서울 강남구 선릉로 157',
    avgDb: 44.7, cnt: 13, trust: 2.5, sticker: 'STUDY_ZONE', recent: 1, hoursAgo: 11,
    reports: [
      _R(-1.7, 'STUDY_ZONE', '조용한 편',       4),
      _R( 2.0, 'RELAX',      null,              1),
      _R(-0.9, 'COZY',       '아늑한 분위기',   2),
      _R( 1.4, 'HEALING',    '힐링 공간',       0),
      _R(-1.2, 'STUDY',      '공부하기 좋음',   6),
    ],
  ),
  _S(
    name: '이디야 선릉역점',
    lat: 37.5025, lng: 127.0310,
    addr: '서울 강남구 선릉로 211',
    avgDb: 50.2, cnt: 14, trust: 2.6, sticker: 'STUDY_ZONE', recent: 2, hoursAgo: 5,
    reports: [
      _R(-1.3, 'STUDY_ZONE', '생각보다 조용해요', 3),
      _R( 2.1, 'RELAX',      null,              1),
      _R(-0.6, 'COZY',       '평화로운 분위기',   2),
      _R( 1.5, 'STUDY',      '집중 가능',         0),
    ],
  ),
  _S(
    name: '아티제 강남점',
    lat: 37.4955, lng: 127.0280,
    addr: '서울 강남구 강남대로 330',
    avgDb: 52.6, cnt: 24, trust: 3.5, sticker: 'MINIMAL', recent: 3, hoursAgo: 4,
    reports: [
      _R(-2.1, 'MINIMAL',    '세련된 분위기',    2),
      _R( 1.4, 'COZY',       '편안한 공간',      1),
      _R(-1.0, 'INSTA',      '인테리어 감각적',  4),
      _R( 0.8, 'RELAX',      null,              0),
      _R(-1.6, 'MINIMAL',    '대화 가능한 수준', 5),
    ],
  ),

  // ── Mid 55–65 dB ────────────────────────────────────────────────────────
  _S(
    name: '커피빈 강남역점',
    lat: 37.4968, lng: 127.0288,
    addr: '서울 강남구 강남대로 396',
    avgDb: 51.4, cnt: 27, trust: 3.8, sticker: 'COZY', recent: 4, hoursAgo: 3,
    reports: [
      _R(-1.4, 'COZY',   '편안하고 아늑해요',  4),
      _R( 0.8, 'RELAX',  '여유로운 분위기',    2),
      _R(-2.1, 'COZY',   null,                1),
      _R( 1.2, 'HEALING','힐링되는 공간',      6),
      _R(-0.6, 'COZY',   '조용하고 포근해요',  3),
      _R( 1.9, 'MINIMAL','깔끔한 인테리어',    0),
    ],
  ),
  _S(
    name: '스타벅스 강남대로점',
    lat: 37.4985, lng: 127.0283,
    addr: '서울 강남구 강남대로 390',
    avgDb: 57.2, cnt: 35, trust: 4.2, sticker: 'RELAX', recent: 5, hoursAgo: 1,
    reports: [
      _R(-1.8, 'RELAX',  '여유롭게 쉬기 좋아요', 4),
      _R( 3.2, 'RELAX',  null,                  2),
      _R(-0.5, 'COZY',   '아늑한 분위기',         1),
      _R( 2.1, 'VIBE',   '활기차고 에너지 넘침',  7),
      _R(-1.0, 'RELAX',  '커피 향이 가득',        3),
      _R( 1.4, 'MUSIC',  '음악 취향 저격',        0),
    ],
  ),
  _S(
    name: '컴포즈커피 강남점',
    lat: 37.4995, lng: 127.0255,
    addr: '서울 강남구 봉은사로 106',
    avgDb: 55.8, cnt: 16, trust: 3.0, sticker: 'RELAX', recent: 2, hoursAgo: 4,
    reports: [
      _R(-2.0, 'RELAX',   '가성비 최고',      3),
      _R( 1.6, 'VIBE',    '적당히 활기참',    1),
      _R(-0.9, 'COZY',    null,              2),
      _R( 2.4, 'MEETING', '대화하기 좋음',    0),
      _R(-1.3, 'RELAX',   '보통 수준이에요',  5),
    ],
  ),
  _S(
    name: '노티드 도넛 강남점',
    lat: 37.4948, lng: 127.0258,
    addr: '서울 강남구 강남대로 308',
    avgDb: 54.3, cnt: 28, trust: 3.8, sticker: 'INSTA', recent: 4, hoursAgo: 2,
    reports: [
      _R(-1.4, 'INSTA',   '인스타 감성 최고',  1),
      _R( 2.1, 'DATE',    '데이트하기 좋아요',  0),
      _R(-0.8, 'INSTA',   null,               3),
      _R( 1.7, 'COZY',    '도넛 맛있고 분위기 굿', 2),
      _R(-1.5, 'RELAX',   '적당한 소음',       5),
    ],
  ),
  _S(
    name: '커피에반하다 강남점',
    lat: 37.5008, lng: 127.0285,
    addr: '서울 강남구 강남대로 506',
    avgDb: 59.4, cnt: 20, trust: 3.2, sticker: 'RELAX', recent: 3, hoursAgo: 3,
    reports: [
      _R(-2.4, 'RELAX',   '편안한 분위기',  4),
      _R( 1.8, 'VIBE',    '활기찬 편이에요', 2),
      _R(-0.7, 'COZY',    null,            1),
      _R( 2.2, 'MEETING', '대화 가능',      0),
      _R(-1.1, 'RELAX',   '보통이에요',     6),
    ],
  ),
  _S(
    name: '테일러커피 강남점',
    lat: 37.4960, lng: 127.0310,
    addr: '서울 강남구 선릉로 121',
    avgDb: 58.7, cnt: 9, trust: 1.8, sticker: 'RELAX', recent: 1, hoursAgo: 8,
    reports: [
      _R(-1.9, 'RELAX',  '적당한 분위기',  3),
      _R( 2.3, 'VIBE',   null,            1),
      _R(-0.5, 'COZY',   '아늑함',         2),
      _R( 1.6, 'INSTA',  '감성 카페',      0),
    ],
  ),
  _S(
    name: '스타벅스 신논현점',
    lat: 37.5018, lng: 127.0295,
    addr: '서울 강남구 봉은사로 152',
    avgDb: 60.4, cnt: 33, trust: 4.0, sticker: 'RELAX', recent: 5, hoursAgo: 1,
    reports: [
      _R(-2.1, 'RELAX',   '익숙한 스타벅스 분위기', 4),
      _R( 3.0, 'VIBE',    '주말엔 좀 시끄러워요',   2),
      _R(-0.8, 'COZY',    null,                    1),
      _R( 1.5, 'MEETING', '미팅하기 좋아요',         7),
      _R(-1.4, 'RELAX',   '커피 맛 안정적',          0),
    ],
  ),
  _S(
    name: '탐앤탐스 강남역점',
    lat: 37.4965, lng: 127.0250,
    addr: '서울 강남구 강남대로 356',
    avgDb: 61.2, cnt: 19, trust: 3.2, sticker: 'MEETING', recent: 2, hoursAgo: 4,
    reports: [
      _R(-1.7, 'MEETING', '그룹 미팅하기 좋음',  3),
      _R( 2.5, 'VIBE',    null,                 1),
      _R(-0.9, 'RELAX',   '적당한 카페분위기',   4),
      _R( 1.3, 'MEETING', '대화 소리 보통',      0),
      _R(-2.0, 'COZY',    '편안한 좌석',         5),
    ],
  ),

  // ── Loud 65–75 dB ───────────────────────────────────────────────────────
  _S(
    name: '메가커피 강남역점',
    lat: 37.4988, lng: 127.0295,
    addr: '서울 강남구 강남대로 436',
    avgDb: 63.7, cnt: 14, trust: 2.8, sticker: 'VIBE', recent: 2, hoursAgo: 5,
    reports: [
      _R( 2.3, 'VIBE',    '활기찬 에너지',      3),
      _R(-1.7, 'VIBE',    '사람 많고 시끄러움',  1),
      _R( 3.5, 'MEETING', null,                 5),
      _R(-0.8, 'RELAX',   '나쁘지 않은 분위기', 2),
      _R( 1.1, 'PEAK',    '피크타임은 복잡함',   0),
    ],
  ),
  _S(
    name: '카페 모카 강남점',
    lat: 37.4962, lng: 127.0298,
    addr: '서울 강남구 선릉로 109',
    avgDb: 66.1, cnt: 17, trust: 3.0, sticker: 'MEETING', recent: 3, hoursAgo: 3,
    reports: [
      _R(-2.3, 'MEETING',  '회의하기 좋아요',  2),
      _R( 3.1, 'VIBE',     '활기차요',         1),
      _R(-1.0, 'GATHERING','모임 많아요',       4),
      _R( 2.4, 'MEETING',  null,              0),
      _R(-1.5, 'RELAX',    '대화 가능한 수준',  6),
    ],
  ),
  _S(
    name: '이디야 강남역점',
    lat: 37.4982, lng: 127.0262,
    addr: '서울 강남구 강남대로 368',
    avgDb: 69.3, cnt: 12, trust: 2.5, sticker: 'MEETING', recent: 1, hoursAgo: 6,
    reports: [
      _R( 1.7, 'MEETING',  '회의하기 딱이에요', 3),
      _R(-2.3, 'MEETING',  '대화 편하게 됨',   1),
      _R( 3.1, 'GATHERING','모임하기 좋음',     6),
      _R(-1.0, 'MEETING',  null,              2),
      _R( 0.5, 'VIBE',     '활기찬 분위기',    0),
    ],
  ),
  _S(
    name: '메가커피 신논현역점',
    lat: 37.4938, lng: 127.0275,
    addr: '서울 강남구 강남대로 242',
    avgDb: 65.8, cnt: 11, trust: 2.2, sticker: 'MEETING', recent: 1, hoursAgo: 7,
    reports: [
      _R( 2.0, 'MEETING',  '대화하기 좋아요',  3),
      _R(-1.8, 'VIBE',     null,              1),
      _R( 3.2, 'GATHERING','모임 분위기',      2),
      _R(-0.9, 'RELAX',    '적당히 시끄러움',   0),
    ],
  ),
  _S(
    name: '카페베네 강남역점',
    lat: 37.5000, lng: 127.0275,
    addr: '서울 강남구 강남대로 474',
    avgDb: 68.9, cnt: 10, trust: 2.0, sticker: 'VIBE', recent: 2, hoursAgo: 5,
    reports: [
      _R(-1.5, 'VIBE',    '활기찬 편이에요',  4),
      _R( 2.7, 'MEETING', '대화 가능해요',   1),
      _R(-2.1, 'VIBE',    null,            2),
      _R( 1.9, 'PEAK',    '주말엔 복잡함',   0),
    ],
  ),

  // ── Very loud > 75 dB ───────────────────────────────────────────────────
  _S(
    name: '투썸플레이스 강남역점',
    lat: 37.4992, lng: 127.0268,
    addr: '서울 강남구 강남대로 422',
    avgDb: 78.8, cnt: 8, trust: 1.5, sticker: 'VIBE', recent: 0, hoursAgo: 30,
    reports: [
      _R( 4.2, 'VIBE',      '피크타임에 시끄러움', 0),
      _R(-3.1, 'PEAK',      '주말 오후 가득참',    1),
      _R( 2.8, 'MEETING',   '대화 소리가 큼',      2),
      _R( 1.5, 'GATHERING', null,                 4),
    ],
  ),
  _S(
    name: '엔제리너스 강남역점',
    lat: 37.4972, lng: 127.0245,
    addr: '서울 강남구 강남대로 374',
    avgDb: 76.3, cnt: 6, trust: 1.2, sticker: 'PEAK', recent: 0, hoursAgo: 36,
    reports: [
      _R( 3.7, 'PEAK',     '매우 시끄러워요',   1),
      _R(-2.5, 'VIBE',     null,               3),
      _R( 4.1, 'GATHERING','모임 많아서 복잡함', 0),
      _R( 1.8, 'MEETING',  '대화 잘 들림',      5),
    ],
  ),
  _S(
    name: '카페 온도 강남점',
    lat: 37.4965, lng: 127.0240,
    addr: '서울 강남구 강남대로 350',
    avgDb: 73.5, cnt: 5, trust: 1.0, sticker: 'VIBE', recent: 0, hoursAgo: 48,
    reports: [
      _R( 2.5, 'VIBE',     '활기차고 시끄러움',   2),
      _R(-1.8, 'MEETING',  null,                 1),
      _R( 3.9, 'GATHERING','모임 공간으로 유명',   0),
      _R( 1.2, 'PEAK',     '피크타임 정신없어요',  4),
    ],
  ),
  _S(
    name: '빽다방 강남점',
    lat: 37.4978, lng: 127.0300,
    addr: '서울 강남구 선릉로 135',
    avgDb: 71.4, cnt: 7, trust: 1.5, sticker: 'GATHERING', recent: 0, hoursAgo: 24,
    reports: [
      _R( 3.1, 'GATHERING','모임하기 좋아요',   1),
      _R(-1.9, 'VIBE',     '꽤 시끄럽네요',     2),
      _R( 2.6, 'MEETING',  null,              0),
      _R( 1.4, 'PEAK',     '평일도 제법 붐빔',  3),
    ],
  ),
];

// ──────────────────────────────────────────────────────────────────────────
// Service
// ──────────────────────────────────────────────────────────────────────────

class AdminDummyService {
  AdminDummyService._();

  static const double gangnamLat = _gangnamLat;
  static const double gangnamLng = _gangnamLng;

  /// 30 fake first-reporter nicknames — one per dummy cafe, in _spots order.
  static const _fakeNames = [
    '조용한탐험가', '힐링러',      '스터디킹',    '집중마스터',  '조용파',
    '힐링추구자',   '스터디마스터', '노마드라이프', '커피탐험가',  '집중러',
    '스터디탐험가', '카페탐험가',  '힐링마스터',  '커피러버',    '바이브헌터',
    '카페고수',     '소음감지사',  '바이브탐험가', '커피고수',    '카페론',
    '바이브마스터', '소음측정러',  '카페킹',      '소음헌터',    '바이브러',
    '카페바이브러', '소음마스터',  '카페마스터',  '힐링고수',    '바이브고수',
  ];

  /// Inserts 30 test spots + reports near Gangnam Station.
  /// Idempotent — skips if test data already exists.
  static Future<void> insertDummyData(SupabaseClient client) async {
    final userId = client.auth.currentUser?.id;
    debugPrint('[DummyMode] userId=$userId');
    if (userId == null) throw Exception('로그인 필요');

    // Guard: already exists?
    debugPrint('[DummyMode] Checking existing test data...');
    final existing = await client
        .from('spots')
        .select('id')
        .like('google_place_id', '$_dummyPrefix%')
        .limit(1);
    debugPrint('[DummyMode] Existing count: ${(existing as List).length}');
    if ((existing).isNotEmpty) {
      debugPrint('[DummyMode] Test data already exists, skipping insert.');
      return;
    }

    final now = DateTime.now().toUtc();
    final rng = Random(42); // deterministic for reproducibility

    // ── Insert spots ────────────────────────────────────────────────────
    final spotRows = <Map<String, dynamic>>[];
    for (int i = 0; i < _spots.length; i++) {
      final s = _spots[i];
      spotRows.add({
        'name': s.name,
        // Encode fake reporter name in google_place_id for "첫 바이브" display.
        // Pattern: DUMMY:<index>:<nickname>  — used for cleanup identification.
        'google_place_id': '$_dummyPrefix$i:${_fakeNames[i % _fakeNames.length]}',
        'location': 'POINT(${s.lng} ${s.lat})',
        'average_db': s.avgDb,
        'report_count': s.cnt,
        'trust_score': s.trust,
        'representative_sticker': _dbSticker(s.sticker),
        'last_report_at': now.subtract(Duration(hours: s.hoursAgo)).toIso8601String(),
      });
    }

    debugPrint('[DummyMode] Inserting ${spotRows.length} spots...');
    final inserted =
        await client.from('spots').insert(spotRows).select('id, name');
    debugPrint('[DummyMode] Spots inserted: ${(inserted as List).length}');
    final nameToId = <String, String>{
      for (final row in inserted)
        row['name'] as String: row['id'] as String,
    };

    // ── Insert reports ──────────────────────────────────────────────────
    final reportRows = <Map<String, dynamic>>[];
    for (final s in _spots) {
      final spotId = nameToId[s.name];
      if (spotId == null) continue;

      for (int i = 0; i < s.reports.length; i++) {
        final t = s.reports[i];
        final measuredDb = (s.avgDb + t.dbOffset).clamp(20.0, 115.0);
        final hoursBack = t.daysAgo * 24 + rng.nextInt(10);
        final createdAt = now.subtract(Duration(hours: hoursBack));

        reportRows.add({
          'user_id': userId,
          'spot_id': spotId,
          'measured_db': measuredDb,
          'selected_sticker': _dbSticker(t.sticker),
          'created_at': createdAt.toIso8601String(),
        });
      }
    }

    if (reportRows.isNotEmpty) {
      // Insert in batches of 50 to stay well under Supabase payload limits
      for (int i = 0; i < reportRows.length; i += 50) {
        final batch = reportRows.sublist(
          i,
          (i + 50).clamp(0, reportRows.length),
        );
        await client.from('reports').insert(batch);
      }
    }
  }

  /// Removes all test spots (reports cascade-delete via FK).
  /// Requires "spots_delete_admin" RLS policy (migration 016).
  static Future<void> cleanupDummyData(SupabaseClient client) async {
    // New format: DUMMY:<index>:<name> in google_place_id
    await client.from('spots').delete().like('google_place_id', '$_dummyPrefix%');
    // Legacy format: [테스트] prefix in name (old dummy mode sessions)
    await client.from('spots').delete().like('name', '%[테스트]%');
  }

  /// Maps any sticker key to the 3 DB-valid values (CHECK constraint).
  static String _dbSticker(String key) => switch (key) {
        'STUDY' || 'STUDY_ZONE' || 'WORK' || 'NOMAD' => 'STUDY',
        'MEETING' || 'GATHERING' || 'DATE' || 'FAMILY' || 'VIBE' || 'PEAK' =>
          'MEETING',
        _ => 'RELAX',
      };

}

// ──────────────────────────────────────────────────────────────────────────
// Provider
// ──────────────────────────────────────────────────────────────────────────

class AdminDummyModeNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async => false;

  Future<void> enable() async {
    state = const AsyncValue.loading();
    try {
      final client = ref.read(supabaseClientProvider);
      debugPrint('[DummyMode] Starting insertDummyData...');
      await AdminDummyService.insertDummyData(client);
      debugPrint('[DummyMode] insertDummyData done. Setting dummy location...');
      await ref
          .read(mapControllerProvider.notifier)
          .setDummyLocation(AdminDummyService.gangnamLat, AdminDummyService.gangnamLng);
      debugPrint('[DummyMode] enable complete.');
      state = const AsyncValue.data(true);
    } catch (e, st) {
      debugPrint('[DummyMode] enable ERROR: $e\n$st');
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> disable() async {
    state = const AsyncValue.loading();
    try {
      final client = ref.read(supabaseClientProvider);
      await AdminDummyService.cleanupDummyData(client);
      await ref.read(mapControllerProvider.notifier).resetRealLocation();
      state = const AsyncValue.data(false);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final adminDummyModeProvider =
    AsyncNotifierProvider<AdminDummyModeNotifier, bool>(
  AdminDummyModeNotifier.new,
);

// ──────────────────────────────────────────────────────────────────────────
// Fake Position at Gangnam coords (for map dummy location)
// ──────────────────────────────────────────────────────────────────────────

Position gangnamPosition() => Position(
      latitude: _gangnamLat,
      longitude: _gangnamLng,
      timestamp: DateTime.now(),
      accuracy: 1.0,
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: 0.0,
      headingAccuracy: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      isMocked: true,
    );

// ──────────────────────────────────────────────────────────────────────────
// Private data structures
// ──────────────────────────────────────────────────────────────────────────

class _S {
  final String name;
  final double lat, lng;
  final String addr;
  final double avgDb, trust;
  final int cnt, recent, hoursAgo;
  final String sticker;
  final List<_R> reports;
  const _S({
    required this.name,
    required this.lat,
    required this.lng,
    required this.addr,
    required this.avgDb,
    required this.cnt,
    required this.trust,
    required this.sticker,
    required this.recent,
    required this.hoursAgo,
    required this.reports,
  });
}

class _R {
  final double dbOffset;
  final String sticker;
  final String? mood;
  final int daysAgo;
  const _R(this.dbOffset, this.sticker, this.mood, this.daysAgo);
}
