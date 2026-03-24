import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @AppStorage("userName") var userName: String = ""
    @AppStorage("retirementAge") var retirementAge: Int = 45
    @AppStorage("currentAge") var currentAge: Int = 20
    
    @State private var step = 0
    @State private var nameInput = ""
    @State private var birthday: Date = Date()
    @State private var retirementAgeInput = ""
    
    var body: some View {
        VStack {
            // 진행 표시
            HStack(spacing: 8) {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(i <= step ? Color.yellow : Color.gray.opacity(0.3))
                        .frame(width: 10, height: 10)
                }
            }
            .padding(.top, 40)
            
            Spacer()
            
            // 단계별 화면
            if step == 0 {
                WelcomeStep()
            } else if step == 1 {
                NameStep(nameInput: $nameInput)
            } else {
                GoalStep(
                    birthday: $birthday,
                    retirementAgeInput: $retirementAgeInput
                )
            }
            
            Spacer()
            
            // 다음 버튼
            Button(action: nextStep) {
                Text(step == 2 ? "Start Saving 🐝" : "Next")
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
    }
    
    var isNextDisabled: Bool {
        if step == 1 { return nameInput.isEmpty }
        if step == 2 { return retirementAgeInput.isEmpty }
        return false
    }
    
    func nextStep() {
        if step < 2 {
            withAnimation { step += 1 }
        } else {
            userName = nameInput
            UserDefaults.standard.set(birthday.timeIntervalSince1970, forKey: "birthday")
            retirementAge = Int(retirementAgeInput) ?? 45
            hasCompletedOnboarding = true
        }
    }
}

// 1단계: 환영
struct WelcomeStep: View {
    var body: some View {
        VStack(spacing: 24) {
            Text("🐝")
                .font(.system(size: 80))
            Text("Welcome to\nBeeHive")
                .font(.system(size: 36, weight: .bold))
                .multilineTextAlignment(.center)
            Text("Build the habit of tracking your spending.\nWork towards financial freedom, one day at a time.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
}

// 2단계: 이름
struct NameStep: View {
    @Binding var nameInput: String
    
    var body: some View {
        VStack(spacing: 24) {
            Text("🐝")
                .font(.system(size: 60))
            Text("What's your name?")
                .font(.title2)
                .fontWeight(.bold)
            Text("The hive needs to know who's\nbuilding it 😄")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            TextField("Your name", text: $nameInput)
                .font(.title3)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal, 24)
        }
    }
}

// 3단계: 목표
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
            Text("🍯")
                .font(.system(size: 60))
            Text("Set your goal")
                .font(.title2)
                .fontWeight(.bold)
            Text("When do you want to achieve\nfinancial freedom?")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 16) {
                // 생일 입력
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Birthday")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 24)
                    DatePicker(
                        "Birthday",
                        selection: $birthday,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                    .padding(.horizontal, 24)
                }
                
                // 현재 나이 자동 계산
                HStack {
                    Text("Current Age")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(currentAge)")
                        .fontWeight(.bold)
                        .foregroundColor(.yellow)
                }
                .padding(.horizontal, 24)
                
                // 목표 나이
                VStack(alignment: .leading, spacing: 8) {
                    Text("Goal Age")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 24)
                    TextField("e.g. 45", text: $retirementAgeInput)
                        .keyboardType(.numberPad)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal, 24)
                }
            }
            
            if yearsLeft > 0 {
                Text("🐝 \(yearsLeft) years to freedom!")
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
