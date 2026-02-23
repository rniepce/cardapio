import Foundation

// MARK: - Models (Codable — synced via API)

enum MealType: String, CaseIterable, Identifiable, Codable {
    case breakfast = "Café da Manhã"
    case lunch = "Almoço"
    case dinner = "Jantar"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.stars.fill"
        }
    }
}

class Recipe: Codable, Identifiable, ObservableObject {
    let id: UUID
    var title: String
    var prepTime: String
    var tags: [String]
    var imageURL: String?
    var url: String?
    var targetMeals: [String]
    
    enum CodingKeys: String, CodingKey {
        case id, title, tags, url
        case prepTime = "prep_time"
        case imageURL = "image_url"
        case targetMeals = "target_meals"
    }
    
    init(id: UUID = UUID(), title: String, prepTime: String = "15 min", tags: [String] = [], imageURL: String? = nil, url: String? = nil, targetMeals: [MealType] = []) {
        self.id = id
        self.title = title
        self.prepTime = prepTime
        self.tags = tags
        self.imageURL = imageURL
        self.url = url
        self.targetMeals = targetMeals.map { $0.rawValue }
    }
}

class MealEntry: Codable, Identifiable, ObservableObject {
    let id: UUID
    var typeRawValue: String
    var recipe: Recipe?
    
    var type: MealType {
        MealType(rawValue: typeRawValue) ?? .lunch
    }
    
    enum CodingKeys: String, CodingKey {
        case id, recipe
        case typeRawValue = "type_raw_value"
    }
    
    init(id: UUID = UUID(), type: MealType, recipe: Recipe? = nil) {
        self.id = id
        self.typeRawValue = type.rawValue
        self.recipe = recipe
    }
}

class DailyMenu: Codable, Identifiable, ObservableObject {
    let id: UUID
    var date: String  // "YYYY-MM-DD" from API
    var meals: [MealEntry]
    
    init(id: UUID = UUID(), date: String, meals: [MealEntry] = []) {
        self.id = id
        self.date = date
        self.meals = meals
    }
}
