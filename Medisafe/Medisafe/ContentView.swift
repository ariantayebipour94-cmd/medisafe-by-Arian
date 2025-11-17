import SwiftUI

// MARK: - Model

struct Dose: Identifiable {
    let id = UUID()
    let time: String
    let medicationName: String
    let dosage: String          // e.g. "Take 1 pill(s)"
    var note: String? = nil     // user reaction / side effects
}

// Which sheet is open
enum ActiveSheet: Identifiable {
    case note
    case alerts
    case addMedication
    case editName
    
    var id: Int {
        switch self {
        case .note:          return 1
        case .alerts:        return 2
        case .addMedication: return 3
        case .editName:      return 4
        }
    }
}

// MARK: - Main View

struct ContentView: View {
    // saved user name (persists between launches)
    @AppStorage("username") private var username: String = ""
    
    // start EMPTY – user will add medications
    @State private var doses: [Dose] = []
    
    @State private var selectedDoseIndex: Int? = nil
    @State private var activeSheet: ActiveSheet? = nil
    
    // date for the header & week strip
    @State private var selectedDate: Date = Date()
    @State private var showCalendar: Bool = false
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                // background
                Color(red: 0.96, green: 0.97, blue: 0.98)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // BLUE HEADER
                    TopHeaderView(
                        name: username.isEmpty ? "Your Name" : username,
                        date: selectedDate,
                        onAlertTap: { activeSheet = .alerts },
                        onAddTap:   { activeSheet = .addMedication },
                        onProfileTap: { activeSheet = .editName }
                    )
                    
                    // WEEK STRIP – uses selectedDate
                    DayStripView(selectedDate: selectedDate)
                    
                    // CHANGE DATE BUTTON + CALENDAR
                    VStack(spacing: 8) {
                        Button {
                            withAnimation {
                                showCalendar.toggle()
                            }
                        } label: {
                            Text(showCalendar ? "Hide calendar" : "Change date")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                        
                        if showCalendar {
                            DatePicker(
                                "",
                                selection: $selectedDate,
                                displayedComponents: .date
                            )
                            .datePickerStyle(.graphical)
                            .background(Color.white)
                            .cornerRadius(14)
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 8)
                    
                    // LIST OR EMPTY STATE
                    if doses.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "pills")
                                .font(.system(size: 40))
                                .foregroundColor(.gray.opacity(0.4))
                            
                            Text("No medications added yet.")
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            Text("Tap + to add your first medication.")
                                .font(.subheadline)
                                .foregroundColor(.gray.opacity(0.8))
                        }
                        .padding(.top, 60)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    } else {
                        List {
                            ForEach(doses.indices, id: \.self) { index in
                                DoseRow(
                                    dose: doses[index],
                                    onNoteTap: {
                                        selectedDoseIndex = index
                                        activeSheet = .note
                                    }
                                )
                                .listRowInsets(EdgeInsets())
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                            }
                            .onDelete { indexSet in
                                doses.remove(atOffsets: indexSet)
                            }
                        }
                        .listStyle(.plain)
                        .background(Color.clear)
                    }
                }
            }
            .navigationBarHidden(true)
            // Single sheet controller for all sheets
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .note:
                    let index = selectedDoseIndex ?? 0
                    ReactionEditorView(
                        initialText: doses[index].note ?? "",
                        medicationTitle: "\(doses[index].medicationName) • \(doses[index].time)"
                    ) { newText in
                        if let realIndex = selectedDoseIndex {
                            doses[realIndex].note = newText.isEmpty ? nil : newText
                        }
                        activeSheet = nil
                    } onCancel: {
                        activeSheet = nil
                    }
                    
                case .alerts:
                    AlertsView {
                        activeSheet = nil
                    }
                    
                case .addMedication:
                    AddMedicationView { newName, newTime, newDosage in
                        if !newName.isEmpty {
                            doses.append(
                                Dose(
                                    time: newTime,
                                    medicationName: newName,
                                    dosage: newDosage.isEmpty ? "Take 1 pill(s)" : newDosage
                                )
                            )
                        }
                        activeSheet = nil
                    } onCancel: {
                        activeSheet = nil
                    }
                    
                case .editName:
                    NameEditorView(
                        currentName: username
                    ) { newName in
                        username = newName
                        activeSheet = nil
                    } onCancel: {
                        activeSheet = nil
                    }
                }
            }
        }
    }
}

// MARK: - Top Blue Header (avatar + date + icons)

struct TopHeaderView: View {
    let name: String
    let date: Date
    let onAlertTap: () -> Void
    let onAddTap: () -> Void
    let onProfileTap: () -> Void
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMM"
        return formatter.string(from: date)
    }
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Solid blue background that extends under the Dynamic Island
            Color(red: 0.0, green: 0.48, blue: 0.98)
                .ignoresSafeArea(edges: .top)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Button(action: onProfileTap) {
                        HStack(spacing: 10) {
                            Circle()
                                .fill(Color.white.opacity(0.3))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .foregroundColor(.white)
                                )
                            
                            Text(name)
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    HStack(spacing: 16) {
                        Button(action: onAlertTap) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.white)
                        }
                        
                        Button(action: onAddTap) {
                            Image(systemName: "plus")
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 40)   // pushes avatar/name/icons below the island
                
                Spacer()
                
                Text(formattedDate)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal)
                    .padding(.bottom, 10)
            }
        }
        .frame(height: 150)
    }
}

// MARK: - Dynamic Day Strip (week of selectedDate)

struct DayStripView: View {
    let selectedDate: Date
    
    // generate 7 dates for the week containing selectedDate
    private var weekDates: [Date] {
        let calendar = Calendar.current
        
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate)
        let startOfWeek = calendar.date(from: components) ?? selectedDate
        
        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: startOfWeek)
        }
    }
    
    private var weekdayFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "EEE"  // Mon, Tue, ...
        return f
    }
    
    private var dayFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "d"    // 3, 4, 5 ...
        return f
    }
    
    var body: some View {
        HStack(spacing: 16) {
            ForEach(weekDates, id: \.self) { day in
                let isSelected = Calendar.current.isDate(day, inSameDayAs: selectedDate)
                
                VStack(spacing: 4) {
                    Text(weekdayFormatter.string(from: day))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                    
                    if isSelected {
                        Text(dayFormatter.string(from: day))
                            .font(.headline)
                            .foregroundColor(.blue)
                            .frame(width: 30, height: 30)
                            .background(Color.white)
                            .clipShape(Circle())
                    } else {
                        Text(dayFormatter.string(from: day))
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color(red: 0.0, green: 0.48, blue: 0.98))
    }
}

// MARK: - Dose Card (no selection, just notes)

struct DoseRow: View {
    let dose: Dose
    let onNoteTap: () -> Void         // open note editor
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            
            Text(dose.time)
                .font(.headline)
                .foregroundColor(Color(red: 0.0, green: 0.48, blue: 0.98))
                .padding(.horizontal, 4)
            
            HStack(spacing: 14) {
                
                // Static circle icon (no selection)
                ZStack {
                    Circle()
                        .strokeBorder(Color.gray.opacity(0.4), lineWidth: 1.5)
                        .frame(width: 34, height: 34)
                    
                    Image(systemName: "pills.fill")
                        .foregroundColor(.gray.opacity(0.6))
                        .font(.system(size: 18))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(dose.medicationName.capitalized)
                        .font(.headline)
                    Text(dose.dosage)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                if dose.note != nil {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .foregroundColor(.blue)
                }
                
                Button(dose.note == nil ? "Add Note" : "Edit Note") {
                    onNoteTap()
                }
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(14)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .padding(.vertical, 4)
        .padding(.horizontal)
    }
}

// MARK: - Reaction / Side-Effect Editor

struct ReactionEditorView: View {
    @State private var text: String
    let medicationTitle: String
    let onSave: (String) -> Void
    let onCancel: () -> Void
    
    init(initialText: String, medicationTitle: String, onSave: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
        _text = State(initialValue: initialText)
        self.medicationTitle = medicationTitle
        self.onSave = onSave
        self.onCancel = onCancel
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Write how you felt after taking this medication.")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                    
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $text)
                            .frame(minHeight: 180)
                            .padding(8)
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        
                        if text.isEmpty {
                            Text("E.g. headache, dizzy, sleepy, no side effects…")
                                .foregroundColor(.gray.opacity(0.6))
                                .padding(.top, 16)
                                .padding(.leading, 14)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle(medicationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onCancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { onSave(text) }
                        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

// MARK: - Alerts View (for ⚠️ button)

struct AlertsView: View {
    let onClose: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Text("No alerts right now.")
                    .font(.headline)
                    .padding(.top)
                
                Text("Missed doses, warnings and important messages will appear here.")
                    .foregroundColor(.gray)
                    .font(.subheadline)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Alerts")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Close") { onClose() }
                }
            }
        }
    }
}

// MARK: - Add Medication View (for ➕ button)

struct AddMedicationView: View {
    @State private var name: String = ""
    @State private var time: Date = Date()
    @State private var dosage: String = ""
    
    let onSave: (String, String, String) -> Void   // name, timeString, dosage
    let onCancel: () -> Void
    
    // format Date → "HH:mm"
    private var timeFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Medication name")) {
                    TextField("e.g. Ibuprofen", text: $name)
                }
                
                Section(header: Text("Time")) {
                    DatePicker(
                        "Reminder time",
                        selection: $time,
                        displayedComponents: .hourAndMinute
                    )
                }
                
                Section(header: Text("Dosage")) {
                    TextField("e.g. Take 1 pill(s)", text: $dosage)
                }
            }
            .navigationTitle("Add Medication")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let cleanName   = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        let cleanDosage = dosage.trimmingCharacters(in: .whitespacesAndNewlines)
                        let timeString  = timeFormatter.string(from: time)
                        onSave(cleanName, timeString, cleanDosage)
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

// MARK: - Name Editor View (for tapping avatar)

struct NameEditorView: View {
    @State private var name: String
    let onSave: (String) -> Void
    let onCancel: () -> Void
    
    init(currentName: String, onSave: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
        _name = State(initialValue: currentName)
        self.onSave = onSave
        self.onCancel = onCancel
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Your name")) {
                    TextField("Enter your name", text: $name)
                }
            }
            .navigationTitle("Edit Profile")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onCancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { onSave(name) }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
