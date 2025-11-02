#include <WiFi.h>
#include <HTTPClient.h>
#include <Preferences.h>
#include <DHT.h>

// --- WiFi Credentials ---
// IMPORTANT: Change these to your actual WiFi credentials
const char* defaultSSID = "motoedge60fusion_542";
const char* defaultPassword = "9827665701";

// Use Preferences to store credentials (optional, but good practice)
Preferences preferences;

// --- API & Device Configuration ---
const String API_KEY = "13ccf99210e38d8a3aa6710f";
const String API_KEY_g = "sWs3PQl051D7WtKBYSzpdQV591YZEErV";
const String DEVICE_ID = "device_1";
const char* googleScriptUrl = "https://script.google.com/macros/s/AKfycbzoO_SOCkgTWcRVDM7_ThDG_eycGDlhuo1HPiPf3dfIbadwagZb8D8ltpmMWCrAXpwH7g/exec";
const char* apiURL = "https://us-central1-grooth-1.cloudfunctions.net/api/api";

// --- Sensor Pins ---
const int moistureSensorPin = 32;
#define DHTPIN 4
#define DHTTYPE DHT11

// --- Component Pins ---
const int buzzerPin = 15;

// --- Global Objects ---
DHT dht(DHTPIN, DHTTYPE);
bool isWifiConnected = false;

void setup() {
  Serial.begin(115200);
  
  // Initialize Sensors
  pinMode(moistureSensorPin, INPUT);
  dht.begin();
  
  // Initialize Buzzer
  pinMode(buzzerPin, OUTPUT);
  Serial.println("Booting... Beeping buzzer.");
  digitalWrite(buzzerPin, HIGH);
  delay(1000);
  digitalWrite(buzzerPin, LOW);

  // Initialize Preferences
  preferences.begin("WiFiCreds", false);

  // Load Wi-Fi credentials from memory, or use the hard-coded defaults
  String savedSSID = preferences.getString("ssid", defaultSSID);
  String savedPassword = preferences.getString("password", defaultPassword);

  // Save the defaults into Preferences for next time
  // This ensures that even after changing the code, it uses the correct credentials
  preferences.putString("ssid", savedSSID);
  preferences.putString("password", savedPassword);

  // Try to connect to Wi-Fi
  if (connectToWiFi(savedSSID.c_str(), savedPassword.c_str())) {
    isWifiConnected = true;
  } else {
    isWifiConnected = false;
    Serial.println("Failed to connect to WiFi. Will retry in loop.");
  }
}

void loop() {
  // Check if WiFi is connected
  if (WiFi.status() == WL_CONNECTED) {
    if (!isWifiConnected) {
       // Just got reconnected
       Serial.println("WiFi Reconnected!");
       triggerBuzzer(2);
       isWifiConnected = true;
    }

    // --- Read All Sensors ---
    int moistureValue = analogRead(moistureSensorPin);
    float humidity = dht.readHumidity();
    float temperature = dht.readTemperature();

    // Check if DHT readings are valid
    if (!isnan(humidity) && !isnan(temperature)) {
      Serial.println("--- New Sensor Readings ---");
      Serial.print("Soil Moisture: ");
      Serial.println(moistureValue);
      Serial.print("Humidity: ");
      Serial.print(humidity);
      Serial.println(" %");
      Serial.print("Temperature: ");
      Serial.print(temperature);
      Serial.println(" *C");
      Serial.println("---------------------------");

      // Log data to Google Sheets
      sendDataToGoogleScript(moistureValue, temperature, humidity);
    } else {
      Serial.println("Failed to read from DHT sensor!");
    }
    
    // Wait 10 seconds between readings
    delay(10000); 

  } else {
    // WiFi is not connected
    if (isWifiConnected) {
        Serial.println("WiFi connection lost!");
        isWifiConnected = false;
    }
    Serial.println("Attempting to reconnect to WiFi...");
    
    // Try to reconnect
    String savedSSID = preferences.getString("ssid", defaultSSID);
    String savedPassword = preferences.getString("password", defaultPassword);
    
    if (connectToWiFi(savedSSID.c_str(), savedPassword.c_str())) {
        isWifiConnected = true;
    } else {
        isWifiConnected = false;
        // Wait 5 seconds before retrying
        delay(5000);
    }
  }
}

bool connectToWiFi(const char* ssid, const char* password) {
  Serial.print("Connecting to Wi-Fi: ");
  Serial.println(ssid);
  WiFi.begin(ssid, password);
  int attempts = 0;

  // Try for 10 seconds (20 * 500ms)
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    delay(500);
    Serial.print(".");
    attempts++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\nConnected to Wi-Fi.");
    triggerBuzzer(2);
    return true;
  } else {
    Serial.println("\nFailed to connect to Wi-Fi.");
    return false;
  }
}

void triggerBuzzer(int n) {
  for(int i=0; i<n; i++) {
    digitalWrite(buzzerPin, HIGH);
    delay(100); // Shorter beeps
    digitalWrite(buzzerPin, LOW);
    delay(100);
  }
}

void sendDataToGoogleScript(int moistureValue, float temperature, float humidity) {
  // Check WiFi status again just before sending
  if (WiFi.status() == WL_CONNECTED) {
    HTTPClient http;
    
    // --- First API Call (Grooth) ---
    String url = String(apiURL) + 
                 "?apiKey=" + API_KEY + 
                 "&deviceId=" + DEVICE_ID + 
                 "&moisture=" + String(moistureValue) + 
                 "&temperature=" + String(temperature) + 
                 "&humidity=" + String(humidity);
                 
    Serial.println("Sending data to Grooth API...");
    Serial.println(url); // Print the URL to the monitor
    
    http.begin(url);
    int httpResponseCode = http.GET();
    
    if (httpResponseCode > 0) {
      Serial.print("Grooth API Response: ");
      Serial.println(http.getString());
    } else {
      Serial.print("Error sending to Grooth API: ");
      Serial.println(httpResponseCode);
    }
    http.end();

    // --- Second API Call (Google Script) ---
    String url2 = String(googleScriptUrl) + 
                  "?apiKey=" + API_KEY_g + 
                  "&deviceId=" + DEVICE_ID + 
                  "&moisture=" + String(moistureValue) + 
                  "&temperature=" + String(temperature) + 
                  "&humidity=" + String(humidity) +
                  "&isFetch=false";
                  
    Serial.println("Sending data to Google Script...");
    Serial.println(url2); // Print the URL to the monitor

    http.begin(url2);
    int httpResponseCode2 = http.GET();
    
    if (httpResponseCode2 > 0) {
      Serial.print("Google Script Response: ");
      Serial.println(http.getString());
    } else {
      Serial.print("Error sending to Google Script: ");
      Serial.println(httpResponseCode2);
    }
    http.end();
    
  } else {
    Serial.println("Wi-Fi not connected, skipping data send.");
  }
}

