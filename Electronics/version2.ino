#include <DHT.h>

// --- Sensor Configuration ---
// Define the pin the DHT sensor is connected to
#define DHTPIN 4
// Define the type of DHT sensor (DHT11 or DHT22)
#define DHTTYPE DHT11

// Initialize the DHT sensor object
DHT dht(DHTPIN, DHTTYPE);

void setup() {
  // Start the Serial Monitor at 115200 baud
  Serial.begin(115200); 
  Serial.println("DHT11 Test - Starting");

  // Initialize the DHT sensor
  dht.begin();
}

void loop() {
  // Wait a couple of seconds between measurements.
  delay(2000);

  // Read Humidity
  float humidity = dht.readHumidity();
  // Read Temperature as Celsius
  float temperature = dht.readTemperature();

  // Check if any readings failed (common with DHT sensors)
  if (isnan(humidity) || isnan(temperature)) {
    Serial.println("Failed to read from DHT sensor!");
    return;
  }

  // --- Print Readings to Serial Monitor ---
  Serial.print("Humidity: ");
  Serial.print(humidity);
  Serial.print(" %  |  ");
  
  Serial.print("Temperature: ");
  Serial.print(temperature);
  Serial.println(" *C");
}

