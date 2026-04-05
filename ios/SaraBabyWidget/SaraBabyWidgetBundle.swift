import WidgetKit

/// Widget Extension'ın giriş noktası.
/// Her yeni widget buraya eklenir.
@main
struct SaraBabyWidgetBundle: WidgetBundle {
    var body: some Widget {
        SleepWidget()
        // BreastfeedWidget()  // Adım 3: Breastfeed widget eklenince uncomment edilir
        // PumpWidget()        // Adım 4: Pump widget eklenince uncomment edilir
    }
}
