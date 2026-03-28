import Foundation
import Combine
import SwiftUI
 
class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    // ✅ Fix: 저장된 언어가 없을 때 기기 언어를 감지해서 초기값으로 사용
    // 기존: ?? "en" → 항상 영어로 시작
    // 수정: 기기가 한국어면 "ko", 나머지는 "en"으로 초기화
    @Published var currentLanguage: String = {
        if let saved = UserDefaults.standard.string(forKey: "appLanguage") {
            return saved  // 저장된 값 최우선
        }
        let deviceLang = Locale.current.language.languageCode?.identifier ?? "en"
        return deviceLang == "ko" ? "ko" : "en"
    }()
    
    private init() {}
    
    func setLanguage(_ lang: String) {
        UserDefaults.standard.set(lang, forKey: "appLanguage")
        DispatchQueue.main.async {
            self.currentLanguage = lang
        }
    }
}
 
// ✅ Fix: L() 함수도 동일하게 기기 언어 감지 로직 추가
// 기존: ?? "en" → 항상 영어 fallback
// 수정: 저장값 없으면 기기 언어 확인
func L(_ key: String) -> String {
    let language: String
    if let saved = UserDefaults.standard.string(forKey: "appLanguage") {
        language = saved
    } else {
        let deviceLang = Locale.current.language.languageCode?.identifier ?? "en"
        language = deviceLang == "ko" ? "ko" : "en"
    }
    guard let path = Bundle.main.path(forResource: "Localizable", ofType: "strings", inDirectory: nil, forLocalization: language),
          let dict = NSDictionary(contentsOfFile: path) as? [String: String],
          let value = dict[key] else {
        return key
    }
    return value
}
 
// MARK: - 통화 포맷 함수
// 한글: ₩50,000 (천단위 콤마, 소수점 없음)
// 영어: $50,000 (천단위 콤마, 소수점 없음)
func formatCurrency(_ amount: Double) -> String {
    let language: String
    if let saved = UserDefaults.standard.string(forKey: "appLanguage") {
        language = saved
    } else {
        let deviceLang = Locale.current.language.languageCode?.identifier ?? "en"
        language = deviceLang == "ko" ? "ko" : "en"
    }
    
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = 0
    formatter.minimumFractionDigits = 0
    
    let formatted = formatter.string(from: NSNumber(value: amount)) ?? "\(Int(amount))"
    
    if language == "ko" {
        return "₩\(formatted)"
    } else {
        return "$\(formatted)"
    }
}
 
extension View {
    func refreshOnLanguageChange() -> some View {
        self.id(LanguageManager.shared.currentLanguage)
    }
}
