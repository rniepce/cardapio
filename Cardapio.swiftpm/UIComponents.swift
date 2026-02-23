import SwiftUI

// MARK: - Shared Formatters

private enum DateFormatters {
    static let monthYear: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "pt_BR")
        f.dateFormat = "MMMM yyyy"
        return f
    }()
    
    static let dayOfWeek: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "pt_BR")
        f.dateFormat = "E"
        return f
    }()
    
    static let dayOfMonth: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f
    }()
}

// MARK: - Date Selector

struct DateSelectorView: View {
    @Binding var selectedDate: Date
    var animation: Namespace.ID
    @State private var showingCalendar = false
    
    var weekDates: [Date] {
        var dates: [Date] = []
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate)
        guard let startOfWeek = calendar.date(from: dateComponents) else { return [] }
        
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: i, to: startOfWeek) {
                dates.append(date)
            }
        }
        return dates
    }
    
    var monthYearString: String {
        DateFormatters.monthYear.string(from: selectedDate).capitalized
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(monthYearString)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: { showingCalendar.toggle() }) {
                    Image(systemName: "calendar")
                        .font(.title3)
                        .foregroundColor(.orange)
                        .padding(10)
                        .background(Color.orange.opacity(0.15))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 20)
            
            HStack(spacing: 8) {
                ForEach(weekDates, id: \.self) { date in
                    let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
                    DatePillView(date: date, isSelected: isSelected, animation: animation)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                selectedDate = date
                            }
                        }
                }
            }
            .padding(.horizontal, 16)
        }
        .sheet(isPresented: $showingCalendar) {
            NavigationStack {
                VStack {
                    DatePicker("Selecione a Data", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .padding()
                        .environment(\.locale, Locale(identifier: "pt_BR"))
                        .tint(.orange)
                    Spacer()
                }
                .navigationTitle("Selecionar Data")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Concluído") {
                            showingCalendar = false
                        }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }
}

struct DatePillView: View {
    let date: Date
    let isSelected: Bool
    var animation: Namespace.ID
    
    var body: some View {
        VStack(spacing: 10) {
            Text(dayOfWeek(date))
                .font(.caption2)
                .fontWeight(.bold)
                .textCase(.uppercase)
                .foregroundColor(isSelected ? .white : .secondary)
            
            Text(dayOfMonth(date))
                .font(.body)
                .fontWeight(.black)
                .foregroundColor(isSelected ? .white : .primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .matchedGeometryEffect(id: "DatePill", in: animation)
                    .shadow(color: .orange.opacity(0.4), radius: 8, x: 0, y: 4)
            } else {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            }
        }
    }
    
    func dayOfWeek(_ date: Date) -> String {
        String(DateFormatters.dayOfWeek.string(from: date).prefix(3)).replacingOccurrences(of: ".", with: "")
    }
    
    func dayOfMonth(_ date: Date) -> String {
        DateFormatters.dayOfMonth.string(from: date)
    }
}

// MARK: - Meal Card

struct MealCardView: View {
    let meal: MealEntry
    let onAdd: () -> Void
    let onRemove: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Label(meal.type.rawValue, systemImage: meal.type.icon)
                    .font(.headline)
                    .foregroundColor(.secondary)
                Spacer()
                
                if meal.recipe != nil {
                    Button(action: onRemove) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color(UIColor.tertiaryLabel))
                    }
                }
            }
            .padding([.top, .horizontal])
            .padding(.bottom, 8)
            
            if let recipe = meal.recipe {
                HStack(spacing: 16) {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(LinearGradient(colors: [.orange.opacity(0.2), .red.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "fork.knife")
                                .foregroundColor(.orange)
                                .font(.title)
                        )
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(recipe.title)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                        
                        HStack {
                            Label(recipe.prepTime, systemImage: "clock")
                            if let firstTag = recipe.tags.first {
                                Text("•")
                                Text(firstTag)
                            }
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding()
                .contentShape(Rectangle())
                .onTapGesture(perform: onAdd)
            } else {
                Button(action: onAdd) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                        Text("Adicionar \(meal.type.rawValue)")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.orange)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.orange.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [8]))
                    )
                }
                .padding()
            }
        }
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Recipe Picker

struct RecipePickerView: View {
    let mealEntry: MealEntry
    @Binding var isPresented: Bool
    var onRecipeSelected: (MealEntry) -> Void
    
    @State private var allRecipes: [Recipe] = []
    @State private var searchText = ""
    @State private var isLoading = false
    
    private let api = APIService.shared
    
    var filteredRecipes: [Recipe] {
        var results = allRecipes
        
        if !searchText.isEmpty {
            results = results.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        } else {
            results.sort { (r1, r2) in
                let r1Matches = r1.targetMeals.contains(mealEntry.type.rawValue)
                let r2Matches = r2.targetMeals.contains(mealEntry.type.rawValue)
                if r1Matches && !r2Matches { return true }
                if !r1Matches && r2Matches { return false }
                return r1.title < r2.title
            }
        }
        
        return results
    }
    
    var isNewRecipe: Bool {
        !searchText.isEmpty && !allRecipes.contains(where: { $0.title.lowercased() == searchText.lowercased() })
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Buscar ou criar nova opção...", text: $searchText)
                        .autocorrectionDisabled()
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                .padding()
                
                if isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else {
                    List {
                        if isNewRecipe {
                            Section {
                                Button(action: {
                                    Task { await createAndSelect(title: searchText) }
                                }) {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundColor(.orange)
                                        Text("Criar nova opção: \"\(searchText)\"")
                                            .foregroundColor(.primary)
                                            .fontWeight(.medium)
                                    }
                                }
                            }
                        }
                        
                        Section(header: Text("Opções Salvas")) {
                            ForEach(filteredRecipes, id: \.id) { recipe in
                                Button(action: {
                                    Task { await selectRecipe(recipe) }
                                }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(recipe.title)
                                                .fontWeight(.bold)
                                                .foregroundColor(.primary)
                                            
                                            if !recipe.targetMeals.isEmpty {
                                                Text(recipe.targetMeals.joined(separator: ", "))
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        Spacer()
                                        if mealEntry.recipe?.id == recipe.id {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.orange)
                                                .fontWeight(.bold)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle(mealEntry.type.rawValue)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fechar") { isPresented = false }
                }
            }
            .task {
                await loadRecipes()
            }
        }
    }
    
    // MARK: - API Calls
    
    private func loadRecipes() async {
        isLoading = true
        do {
            allRecipes = try await api.fetchRecipes()
        } catch {
            // Silently fail — list stays empty
        }
        isLoading = false
    }
    
    private func createAndSelect(title: String) async {
        do {
            let newRecipe = try await api.createRecipe(title: title, targetMeals: [mealEntry.type])
            let updatedMeal = try await api.assignRecipe(mealId: mealEntry.id, recipeId: newRecipe.id)
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            onRecipeSelected(updatedMeal)
            isPresented = false
        } catch {
            // Could show an alert here
        }
    }
    
    private func selectRecipe(_ recipe: Recipe) async {
        do {
            let updatedMeal = try await api.assignRecipe(mealId: mealEntry.id, recipeId: recipe.id)
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            onRecipeSelected(updatedMeal)
            isPresented = false
        } catch {
            // Could show an alert here
        }
    }
}
