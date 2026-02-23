import SwiftUI

struct ContentView: View {
    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var showingRecipePicker = false
    @State private var selectedMealForPicker: MealEntry? = nil
    @State private var currentMenu: DailyMenu? = nil
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @Namespace private var animation
    
    private let api = APIService.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    DateSelectorView(selectedDate: $selectedDate, animation: animation)
                        .padding(.top)
                    
                    if isLoading && currentMenu == nil {
                        Spacer()
                        ProgressView("Carregando cardápio...")
                            .foregroundColor(.secondary)
                        Spacer()
                    } else {
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: 24) {
                                if let menu = currentMenu {
                                    ForEach(menu.meals, id: \.id) { meal in
                                        MealCardView(
                                            meal: meal,
                                            onAdd: {
                                                selectedMealForPicker = meal
                                                showingRecipePicker = true
                                            },
                                            onRemove: {
                                                Task { await removeMealRecipe(meal) }
                                            }
                                        )
                                    }
                                }
                                
                                if let error = errorMessage {
                                    Text(error)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                        .padding()
                                }
                            }
                            .padding()
                            .padding(.bottom, 100)
                        }
                        .refreshable {
                            await loadMenu(for: selectedDate)
                        }
                    }
                }
            }
            .navigationTitle("Cardápio")
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingRecipePicker) {
                if let mealEntry = selectedMealForPicker {
                    RecipePickerView(
                        mealEntry: mealEntry,
                        isPresented: $showingRecipePicker,
                        onRecipeSelected: { updatedMeal in
                            replaceMealInMenu(updatedMeal)
                        }
                    )
                }
            }
            .task {
                await loadMenu(for: selectedDate)
            }
            .onChange(of: selectedDate) { _, newDate in
                Task { await loadMenu(for: newDate) }
            }
        }
    }
    
    // MARK: - API Calls
    
    private func loadMenu(for date: Date) async {
        isLoading = true
        errorMessage = nil
        do {
            currentMenu = try await api.fetchMenu(for: date)
        } catch {
            errorMessage = "Sem conexão. Verifique sua internet."
        }
        isLoading = false
    }
    
    private func removeMealRecipe(_ meal: MealEntry) async {
        do {
            let updated = try await api.removeRecipe(mealId: meal.id)
            replaceMealInMenu(updated)
        } catch {
            errorMessage = "Erro ao remover receita."
        }
    }
    
    private func replaceMealInMenu(_ updatedMeal: MealEntry) {
        guard let menu = currentMenu,
              let index = menu.meals.firstIndex(where: { $0.id == updatedMeal.id }) else { return }
        menu.meals[index] = updatedMeal
        // Force UI refresh
        currentMenu = nil
        currentMenu = menu
    }
}
