//
//  ClassificationCandidateImp.swift
//  ProPaint AR
//
//  Created by Davido Hyer on 1/26/23.
//  Copyright © 2023 Passio Inc. All rights reserved.
//

import Foundation

typealias PassioID = String

struct ClassificationCandidateImp {
    var passioID: PassioID
    var confidence: Double
}

var passioIDDic = [
    "MAT0010": ["en": "aluminum", "ar": ""],
    "1000320": ["en": "Plain steel surface", "ar": ""],
    "100031": ["en": "loose layers", "ar": ""],
    "1000580": ["en": "Plain painted concrete", "ar": ""],
    "1000581": ["en": "plain unpainted concrete surface", "ar": ""],
    "1002933": ["en": "empty room", "ar": ""],
    "ABN0006": ["en": "integrated old paint", "ar": ""],
    "ABN006": ["en": "Integrated old paint", "ar": ""],
    "MAT0003": ["en": "plaster", "ar": ""],
    "MAT0005": ["en": "cement board", "ar": ""],
    "MAT0006": ["en": "wood", "ar": ""],
    "MAT0008": ["en": "steel", "ar": ""],
    "MAT0011": ["en": "Corrugated sheet", "ar": ""],
    "1000331": ["en": "plain aluminum surface", "ar": "سطح من الألمنيوم العادي"],
    "1000332": ["en": "aluminum object", "ar": "أشياء من الألومنيوم"],
    "1000819": ["en": "plain painted architectural surface materials", "ar": "مواد سطح معماري عادي مطلي"],
    "1000820": ["en": "plain unpainted architectural surface materials", "ar": "مواد سطح معماري عادي غير مطلي"], // swiftlint:disable:this line_length
    "1000821": ["en": "steel surface", "ar": "سطح حديدي"],
    "1000822": ["en": "steel object", "ar": ""],
    "1000651": ["en": "loose layers", "ar": "الطبقات الضعيفة"],
    "1000669": ["en": "moisture damage", "ar": "عيوب تتعلق بالرطوبة"],
    "1000719": ["en": "damage area holes", "ar": "منطقة متهالكة كثقوب"],
    "1000720": ["en": "damage area cracks", "ar": "منطقة متهالكة كشقوق"],
    "1000721": ["en": "damage area loose layers", "ar": "منطقة متهالكة كالطبقات الضعيفة"],
    "1000086": ["en": "regular joints", "ar": ""],
    "ABN0007": ["en": "oil or grease", "ar": "زيوت أو شحوم"],
    "ABN0013": ["en": "cracks", "ar": "شقوق"],
    "ABN0014": ["en": "hair cracks", "ar": "شقوق شعرية"],
    "ABN0015": ["en": "small cracks", "ar": "شقوق صغيرة, اصغر من ١ سنتمتر"],
    "ABN0016": ["en": "medium cracks", "ar": "شقوق متوسطة, مابين ١-٢ سنتمتر"],
    "ABN0017": ["en": "huge cracks", "ar": "شقوق كبيرة, اكبر من ٢ سنتمتر"],
    "ABN0019": ["en": "uneven wall surface", "ar": ""],
    "ABN0020": ["en": "holes", "ar": "ثقوب"],
    "ABN0024": ["en": "yellowing", "ar": "اصفرار"],
    "ABN0025": ["en": "sagging", "ar": "تسييل في طبقة الدهان"],
    "ABN0029": ["en": "removing sticker", "ar": "ازالة الملصقات"],
    "ABN0031": ["en": "graffiti", "ar": "كتابة"],
    "ABN0032": ["en": "stain", "ar": "بقع"],
    "ABN0033": ["en": "change color", "ar": ""],
    "ABN0036": ["en": "pitting", "ar": "تنقير"],
    "ABN0037": ["en": "rust", "ar": "صدأ"],
    "ABN0042": ["en": "abrasion", "ar": "خدَّش"],
    "ABN0046": ["en": "crazy cracks", "ar": "تشققات عنكبوتية"],
    "BKG0001": ["en": "background", "ar": ""],
    "ENV0004": ["en": "living room", "ar": "غرفة المعيشة"],
    "ENV0005": ["en": "bedroom", "ar": "غرفة النوم"],
    "ENV0006": ["en": "dining area", "ar": "صالة طعام"],
    "ENV0007": ["en": "kids room", "ar": "غرفة أطفال"],
    "ENV0008": ["en": "smoking area", "ar": "منطقة تدخين داخلية"],
    "ENV0010": ["en": "balcony", "ar": "شرفة"],
    "ENV0011": ["en": "study room", "ar": "غرفة دراسة"],
    "ENV0013": ["en": "inside stores", "ar": "مستودعات داخلية"],
    "ENV0014": ["en": "offices", "ar": "مكاتب"],
    "ENV0015": ["en": "washroom", "ar": "الحمام"],
    "ENV0016": ["en": "utility or laundry area", "ar": "منطقة غسيل"],
    "ENV0017": ["en": "kitchen", "ar": "مطبخ"],
    "ENV0018": ["en": "inside parking", "ar": "موقف سيارات داخلي"],
    "ENV0019": ["en": "outside parking", "ar": "موقف سيارات خارجي"],
    "ENV0020": ["en": "car workshop", "ar": "ورشة سيارات"],
    "ENV0021": ["en": "stairwell", "ar": "بيت الدرج"],
    "ENV0022": ["en": "facades", "ar": "واجهات"],
    "ENV0023": ["en": "showrooms", "ar": "معارض"],
    "ENV0024": ["en": "water tank", "ar": "خزان ماء"],
    "ENV0025": ["en": "roofs", "ar": "سطوح"],
    "ENV0026": ["en": "fences", "ar": "أسوار"],
    "ENV0027": ["en": "walkways", "ar": "ممرات"],
    "ENV0028": ["en": "outside kids playground", "ar": "ملعب أطفال خارجي"],
    "ENV0029": ["en": "inside kids playground", "ar": "ملعب أطفال داخلي"],
    "ENV0031": ["en": "swimming pool", "ar": "حوض سباحة"],
    "ENV0032": ["en": "building foundations", "ar": "قواعد المباني الانشائية"],
    "ENV0034": ["en": "inside window", "ar": "نافذة داخلية"],
    "ENV0035": ["en": "inside door", "ar": "باب داخلي"],
    "ENV0036": ["en": "outside door", "ar": "باب خارجي"],
    "ENV0037": ["en": "outside window", "ar": "نافذة خارجية"],
    "MAT0004": ["en": "gypsum", "ar": "جبس"],
    "MAT0007": ["en": "grc", "ar": "خرسانة مسلحة بالألياف الزجاجية"],
    "MAT0012": ["en": "plain wooden surface", "ar": "سطح خشبي عادي"],
    "MAT0013": ["en": "wooden object", "ar": "أشياء خشبية"]
]
