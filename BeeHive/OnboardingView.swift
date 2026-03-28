import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @AppStorage("userName") var userName: String = ""
    @AppStorage("retirementAge") var retirementAge: Int = 45
    @AppStorage("appLanguage") var appLanguage: String = "en"
    
    @State private var step = 0
    @State private var nameInput = ""
    @State private var birthday: Date = Date()
    @State private var retirementAgeInput = ""
    
    var body: some View {
        VStack {
            // 진행 표시 (4단계)
            HStack(spacing: 8) {
                ForEach(0..<4) { i in
                    Circle()
                        .fill(i <= step ? Color.yellow : Color.gray.opacity(0.3))
                        .frame(width: 10, height: 10)
                }
            }
            .padding(.top, 40)
            
            Spacer()
            
            if step == 0 {
                LanguageStep(appLanguage: $appLanguage)
            } else if step == 1 {
                WelcomeStep()
            } else if step == 2 {
                NameStep(nameInput: $nameInput)
            } else {
                GoalStep(birthday: $birthday, retirementAgeInput: $retirementAgeInput)
            }
            
            Spacer()
            
            Button(action: nextStep) {
                Text(step == 3 ? L("onboarding.button.start") : L("onboarding.button.next"))
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.yellow)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
            .disabled(isNextDisabled)
            .opacity(isNextDisabled ? 0.5 : 1)
        }
        .refreshOnLanguageChange()
    }
    
    var isNextDisabled: Bool {
        if step == 2 { return nameInput.isEmpty }
        if step == 3 { return retirementAgeInput.isEmpty }
        return false
    }
    
    func nextStep() {
        if step < 3 {
            withAnimation { step += 1 }
        } else {
            userName = nameInput
            UserDefaults.standard.set(birthday.timeIntervalSince1970, forKey: "birthday")
            retirementAge = Int(retirementAgeInput) ?? 45
            hasCompletedOnboarding = true
        }
    }
}

// MARK: - Language Step
struct LanguageStep: View {
    @Binding var appLanguage: String
    
    var body: some View {
        VStack(spacing: 32) {
            Text("🐝")
                .font(.system(size: 80))
            
            Text("Language / 언어")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 16) {
                LanguageButton(
                    title: "English",
                    subtitle: "Continue in English",
                    isSelected: appLanguage == "en",
                    action: {
                        appLanguage = "en"
                        LanguageManager.shared.setLanguage("en")
                        print("저장된 언어: \(UserDefaults.standard.string(forKey: "appLanguage") ?? "없음")")
                    }
                )
                LanguageButton(
                    title: "한국어",
                    subtitle: "한국어로 계속하기",
                    isSelected: appLanguage == "ko",
                    action: {
                        appLanguage = "ko"
                        LanguageManager.shared.setLanguage("ko")
                    }
                )
            }
            .padding(.horizontal, 24)
        }
    }
}

struct LanguageButton: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.yellow)
                        .font(.title2)
                }
            }
            .padding()
            .background(isSelected ? Color.yellow.opacity(0.15) : Color(.systemGray6))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.yellow : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - Welcome Step
struct WelcomeStep: View {
    var body: some View {
        VStack(spacing: 24) {
            Text("🐝").font(.system(size: 80))
            Text(L("onboarding.welcome.title"))
                .font(.system(size: 36, weight: .bold))
                .multilineTextAlignment(.center)
            Text(L("onboarding.welcome.subtitle"))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
}

// MARK: - Name Step
struct NameStep: View {
    @Binding var nameInput: String
    
    var body: some View {
        VStack(spacing: 24) {
            Text("🐝").font(.system(size: 60))
            Text(L("onboarding.name.title"))
                .font(.title2)
                .fontWeight(.bold)
            Text(L("onboarding.name.subtitle"))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            TextField(L("onboarding.name.placeholder"), text: $nameInput)
                .font(.title3)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal, 24)
        }
    }
}

// MARK: - Goal Step
struct GoalStep: View {
    @Binding var birthday: Date
    @Binding var retirementAgeInput: String
    
    var currentAge: Int {
        Calendar.current.dateComponents([.year], from: birthday, to: Date()).year ?? 0
    }
    
    var yearsLeft: Int {
        let retirement = Int(retirementAgeInput) ?? 0
        return max(0, retirement - currentAge)
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Text("🍯").font(.system(size: 60))
            Text(L("onboarding.goal.title"))
                .font(.title2)
                .fontWeight(.bold)
            Text(L("onboarding.goal.subtitle"))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L("onboarding.goal.birthday"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 24)
                    DatePicker(
                        L("onboarding.goal.birthday"),
                        selection: $birthday,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                    .padding(.horizontal, 24)
                }
                
                HStack {
                    Text(L("onboarding.goal.currentAge")).foregroundColor(.secondary)
                    Spacer()
                    Text("\(currentAge)").fontWeight(.bold).foregroundColor(.yellow)
                }
                .padding(.horizontal, 24)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(L("onboarding.goal.goalAge"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 24)
                    TextField(L("onboarding.goal.goalAge.placeholder"), text: $retirementAgeInput)
                        .keyboardType(.numberPad)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal, 24)
                }
            }
            
            if yearsLeft > 0 {
                Text(String(format: L("onboarding.goal.yearsLeft"), yearsLeft))
                    .font(.headline)
                    .foregroundColor(.yellow)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.yellow.opacity(0.15))
                    .cornerRadius(12)
            }
        }
    }
}

#Preview {
    OnboardingView()
}
