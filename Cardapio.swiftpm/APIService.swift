import Foundation

// MARK: - API Service

@MainActor
class APIService: ObservableObject {
    static let shared = APIService()
    
    // ⚠️ CHANGE THIS to your Railway URL after deploy
    private let baseURL = "https://YOUR-SERVER.up.railway.app"
    
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        return d
    }()
    
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        return e
    }()
    
    // MARK: - Menus
    
    func fetchMenu(for date: Date) async throws -> DailyMenu {
        let dateString = Self.dateFormatter.string(from: date)
        let url = URL(string: "\(baseURL)/menus/\(dateString)")!
        
        let (data, response) = try await URLSession.shared.data(from: url)
        try Self.checkResponse(response)
        return try decoder.decode(DailyMenu.self, from: data)
    }
    
    // MARK: - Meals
    
    func assignRecipe(mealId: UUID, recipeId: UUID) async throws -> MealEntry {
        let url = URL(string: "\(baseURL)/meals/\(mealId.uuidString)/recipe")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["recipe_id": recipeId.uuidString]
        request.httpBody = try encoder.encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try Self.checkResponse(response)
        return try decoder.decode(MealEntry.self, from: data)
    }
    
    func removeRecipe(mealId: UUID) async throws -> MealEntry {
        let url = URL(string: "\(baseURL)/meals/\(mealId.uuidString)/recipe")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try Self.checkResponse(response)
        return try decoder.decode(MealEntry.self, from: data)
    }
    
    // MARK: - Recipes
    
    func fetchRecipes() async throws -> [Recipe] {
        let url = URL(string: "\(baseURL)/recipes")!
        
        let (data, response) = try await URLSession.shared.data(from: url)
        try Self.checkResponse(response)
        return try decoder.decode([Recipe].self, from: data)
    }
    
    func createRecipe(title: String, targetMeals: [MealType]) async throws -> Recipe {
        let url = URL(string: "\(baseURL)/recipes")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "title": title.trimmingCharacters(in: .whitespacesAndNewlines),
            "target_meals": targetMeals.map { $0.rawValue }
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try Self.checkResponse(response)
        return try decoder.decode(Recipe.self, from: data)
    }
    
    func deleteRecipe(id: UUID) async throws {
        let url = URL(string: "\(baseURL)/recipes/\(id.uuidString)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        let (_, response) = try await URLSession.shared.data(for: request)
        try Self.checkResponse(response)
    }
    
    // MARK: - Helpers
    
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()
    
    private static func checkResponse(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            throw APIError.serverError(statusCode: http.statusCode)
        }
    }
}

// MARK: - Errors

enum APIError: LocalizedError {
    case invalidResponse
    case serverError(statusCode: Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Resposta inválida do servidor"
        case .serverError(let code):
            return "Erro do servidor (código \(code))"
        }
    }
}
