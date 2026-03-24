import SwiftUI
import UserNotifications

struct SettingsView: View {
    @AppStorage("userName") var userName: String = ""
    @AppStorage("retirementAge") var retirementAge: Int = 45
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = true
    @AppStorage("notificationHour") var notificationHour: Int = 21
    @AppStorage("birthday") var birthdayTimestamp: Double = 0
    
    @State private var showingResetAlert = false
    
    var currentAge: Int {
        guard birthdayTimestamp > 0 else { return 0 }
        let birthday = Date(timeIntervalSince1970: birthdayTimestamp)
        return Calendar.current.dateComponents([.year], from: birthday, to: Date()).year ?? 0
    }
    
    var yearsLeft: Int {
        max(0, retirementAge - currentAge)
    }
    
    var body: some View {
        NavigationView {
            Form {
                // 프로필
                Section("Profile") {
                    NavigationLink(destination: ProfileEditView(
                        userName: $userName,
                        retirementAge: $retirementAge,
                        birthdayTimestamp: $birthdayTimestamp
                    )) {
                        HStack {
                            Text("🐝")
                                .font(.system(size: 40))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(userName.isEmpty ? "Your name" : userName)
                                    .font(.headline)
                                Text("Age \(currentAge) · Goal: \(retirementAge) · \(yearsLeft) years left")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                // 알림 설정
                Section("Notifications") {
                    HStack {
                        Text("Reminder Time")
                        Spacer()
                        Stepper("\(notificationHour):00", value: $notificationHour, in: 0...23)
                            .onChange(of: notificationHour) {
                                updateNotification()
                            }
                    }
                    Text("You'll get a daily reminder to log your expenses 🐝")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // 앱 정보
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Made with")
                        Spacer()
                        Text("🐝 & ❤️")
                    }
                }
                
                // 리셋
                Section {
                    Button(action: { showingResetAlert = true }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset Onboarding")
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("⚙️ Settings")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Reset BeeHive?", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    hasCompletedOnboarding = false
                }
            } message: {
                Text("This will take you back to the onboarding screen.")
            }
        }
    }
    
    func updateNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["beehive_evening"])
        let content = UNMutableNotificationContent()
        content.title = "🐝 BeeHive"
        content.body = "Don't forget to log your expenses today!"
        content.sound = .default
        var dateComponents = DateComponents()
        dateComponents.hour = notificationHour
        dateComponents.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "beehive_evening", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}

// 프로필 편집 화면
struct ProfileEditView: View {
    @Binding var userName: String
    @Binding var retirementAge: Int
    @Binding var birthdayTimestamp: Double
    
    @State private var birthday: Date = Date()
    @State private var retirementAgeText: String = ""
    
    var currentAge: Int {
        Calendar.current.dateComponents([.year], from: birthday, to: Date()).year ?? 0
    }
    
    var yearsLeft: Int {
        let retirement = Int(retirementAgeText) ?? retirementAge
        return max(0, retirement - currentAge)
    }
    
    var body: some View {
        Form {
            Section("Name") {
                TextField("Your name", text: $userName)
            }
            
            Section("Birthday") {
                DatePicker(
                    "Birthday",
                    selection: $birthday,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .onChange(of: birthday) {
                    birthdayTimestamp = birthday.timeIntervalSince1970
                }
                
                HStack {
                    Text("Current Age")
                    Spacer()
                    Text("\(currentAge)")
                        .foregroundColor(.yellow)
                        .fontWeight(.semibold)
                }
            }
            
            Section("Goal") {
                HStack {
                    Text("Goal Age")
                    Spacer()
                    TextField("e.g. 45", text: $retirementAgeText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(.yellow)
                        .fontWeight(.semibold)
                }
            }
            
            if yearsLeft > 0 {
                Section {
                    HStack {
                        Spacer()
                        Text("🐝 \(yearsLeft) years to financial freedom!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if birthdayTimestamp > 0 {
                birthday = Date(timeIntervalSince1970: birthdayTimestamp)
            }
            retirementAgeText = "\(retirementAge)"
        }
        .onDisappear {
            if let age = Int(retirementAgeText) { retirementAge = age }
        }
    }
}

#Preview {
    SettingsView()
}
