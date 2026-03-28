import SwiftUI
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject var languageManager: LanguageManager
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
    
    var yearsLeft: Int { max(0, retirementAge - currentAge) }
    
    var body: some View {
        NavigationView {
            Form {
                Section(L("settings.section.profile")) {
                    NavigationLink(destination: ProfileEditView(
                        userName: $userName,
                        retirementAge: $retirementAge,
                        birthdayTimestamp: $birthdayTimestamp
                    )) {
                        HStack {
                            Text("🐝").font(.system(size: 40))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(userName.isEmpty ? L("settings.profile.placeholder") : userName)
                                    .font(.headline)
                                Text(String(format: L("settings.profile.subtitle"), currentAge, retirementAge, yearsLeft))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section(L("settings.section.notifications")) {
                    HStack {
                        // ✅ Fix: "settings.notifications.reminderTime" → L()
                        Text(L("settings.notifications.reminderTime"))
                        Spacer()
                        Stepper(
                            String(format: L("settings.notifications.reminderTime.format"), notificationHour),
                            value: $notificationHour, in: 0...23
                        )
                        .onChange(of: notificationHour) { updateNotification() }
                    }
                    // ✅ Fix: "settings.notifications.description" → L()
                    Text(L("settings.notifications.description"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(L("settings.section.about")) {
                    HStack {
                        // ✅ Fix: "settings.about.version" → L()
                        Text(L("settings.about.version"))
                        Spacer()
                        Text("1.0.0").foregroundColor(.secondary)
                    }
                    HStack {
                        // ✅ Fix: "settings.about.madeWith" → L()
                        Text(L("settings.about.madeWith"))
                        Spacer()
                        // ✅ Fix: "settings.about.madeWith.value" → L()
                        Text(L("settings.about.madeWith.value"))
                    }
                }
                
                Section {
                    Button(action: { showingResetAlert = true }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            // ✅ Fix: "settings.reset.button" → L()
                            Text(L("settings.reset.button"))
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            // ✅ Fix: "settings.title" → L()
            .navigationTitle(L("settings.title"))
            .navigationBarTitleDisplayMode(.inline)
            .alert(L("settings.reset.alert.title"), isPresented: $showingResetAlert) {
                Button(L("settings.reset.alert.cancel"), role: .cancel) {}
                Button(L("settings.reset.alert.confirm"), role: .destructive) {
                    hasCompletedOnboarding = false
                }
            } message: {
                // ✅ Fix: "settings.reset.alert.message" → L()
                Text(L("settings.reset.alert.message"))
            }
        }
        .refreshOnLanguageChange()
    }
    
    func updateNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["beehive_evening"])
        let content = UNMutableNotificationContent()
        content.title = "🐝 BeeHive"
        content.body = L("settings.notification.body")
        content.sound = .default
        var dateComponents = DateComponents()
        dateComponents.hour = notificationHour
        dateComponents.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "beehive_evening", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - Profile Edit View
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
            Section(L("profile.section.name")) {
                // ✅ Fix: placeholder도 L()로
                TextField(L("profile.name.placeholder"), text: $userName)
            }
            
            Section(L("profile.section.birthday")) {
                DatePicker(
                    L("profile.birthday.label"),
                    selection: $birthday,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .onChange(of: birthday) { birthdayTimestamp = birthday.timeIntervalSince1970 }
                
                HStack {
                    // ✅ Fix: "profile.currentAge" → L()
                    Text(L("profile.currentAge"))
                    Spacer()
                    Text("\(currentAge)").foregroundColor(.yellow).fontWeight(.semibold)
                }
            }
            
            Section(L("profile.section.goal")) {
                HStack {
                    // ✅ Fix: "profile.goalAge" → L()
                    Text(L("profile.goalAge"))
                    Spacer()
                    TextField(L("profile.goalAge.placeholder"), text: $retirementAgeText)
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
                        Text(String(format: L("profile.yearsLeft"), yearsLeft))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            }
        }
        // ✅ Fix: "profile.title" → L()
        .navigationTitle(L("profile.title"))
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
