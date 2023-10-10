#include <Arduino.h>
#include <WiFi.h>
#include <stdint.h>
#include <PubSubClient.h>
#include <FastLED.h>

#define LED_PIN 13
#define NUM_LEDS 3
#define WIFI_CONNECT_TRIES 10
#define wait_for_input() while (Serial.available() == 0) { delay(100); }

WiFiClient wifi_client;
PubSubClient client(wifi_client);
CRGB leds[NUM_LEDS];

bool wifi_connect(String ssid, String password);
void wifi_input(String &ssid, String &password);
bool mqtt_connect(String user, String password, String broker, int port);
void mqtt_input(String &user, String &password, String &topic, String &broker, int &port);
void callback(char *topic, byte *payload, unsigned int length);

void setup() {
  // Setup serial connection and initialize LEDs
  Serial.begin(9600);
  FastLED.addLeds<WS2812, LED_PIN, GRB>(leds, NUM_LEDS);

  String wifi_ssid = "";
  String wifi_password = "";
  
  int mqtt_port = 1883;
  String mqtt_broker = "";
  String mqtt_topic = "esp/demo";
  String mqtt_username = "";
  String mqtt_password = "";

  // WiFi credentials input loop
  while (true) {
    wifi_input(wifi_ssid, wifi_password);

    if (wifi_connect(wifi_ssid, wifi_password)) {
      Serial.println("Connected to the WiFi network");
      break;
    }

    Serial.println("Could not connect to the WiFi network.");
    Serial.println("Check your wifi credentials.");
  }

  // MQTT details input loop
  while (true) {
    mqtt_input(mqtt_username, mqtt_password, mqtt_topic, mqtt_broker, mqtt_port);

    Serial.println("Connecting to mqtt broker");
    
    if (mqtt_connect(mqtt_username, mqtt_password, mqtt_broker, mqtt_port)) {
      Serial.println("Connected to MQTT broker");
      break;
    }

    Serial.println("Could not connect to the MQTT broker.");
    Serial.println("Check your broker details.");
  }

  // After setting everything up successfully, subscribe to the MQTT topic
  client.subscribe(mqtt_topic.c_str());
}

void loop() {
  // Check for MQTT updates
  client.loop();
}

bool wifi_connect(String ssid, String password) {
  // Connect to WiFi using credentials
  WiFi.begin(ssid, password);

  // Wait for WiFi to connect
  for (int i = 0; WiFi.status() != WL_CONNECTED && i < WIFI_CONNECT_TRIES; i++) {
    Serial.println("Connecting to WiFi ...");
    delay(2000);
  }

  // Return final state of WiFi connection
  return WiFi.status() == WL_CONNECTED;
}

void wifi_input(String &ssid, String &password) {
  Serial.print("Input the WiFi-SSID: ");
  wait_for_input();
  ssid = Serial.readStringUntil('\n');
  Serial.println("Input: " + ssid);

  Serial.print("Input the WiFi-Password: ");
  wait_for_input();
  password = Serial.readStringUntil('\n');
  Serial.println("Input: " + password);
}

bool mqtt_connect(String user, String password, String broker, int port) {
  // Set broker details
  client.setServer(broker.c_str(), port);

  // Set the callback function for the MQTT subscription
  client.setCallback(callback);

  // Generate a client ID for the ESP
  String client_id = "esp32-client-";
  client_id += String(WiFi.macAddress());

  Serial.println("Client-ID: " + client_id);

  // Connect to broker and return success state
  return client.connect(client_id.c_str(), user.c_str(), password.c_str());
}

void mqtt_input(String &user, String &password, String &topic, String &broker, int &port) {
  Serial.print("Input the broker's IP: ");
  wait_for_input();
  broker = Serial.readStringUntil('\n');
  Serial.println("Input: " + broker);

  Serial.printf("Input the broker's port (default: %d): ", port);
  wait_for_input();
  port = Serial.readStringUntil('\n').toInt();
  Serial.println("Input: " + port);

  Serial.printf("Input the MQTT topic (default: %s): ", topic);
  wait_for_input();
  topic = Serial.readStringUntil('\n');
  Serial.println("Input: " + topic);

  Serial.print("Input the username (default: none): ");
  wait_for_input();
  user = Serial.readStringUntil('\n');
  Serial.println("Input: " + user);

  Serial.print("Input the password (default: none): ");
  wait_for_input();
  password = Serial.readStringUntil('\n');
  Serial.println("Input: " + password);
}

void callback(char *topic, byte *payload, unsigned int length) {
  Serial.print("Message arrived in topic: ");
  Serial.println(topic);
  Serial.print("Message: ");

  for (int i = 0; i < length; i++) {
    Serial.print((char)payload[i]);
  }
  Serial.println();

  // Ignore every message with < 7 length
  if (length < 7) {
    Serial.print("Message to short!\n");
    return;
  }

  // Ignore if message does not start with "#"
  if (payload[0] != '#') {
    Serial.print("Message does not start with '#'!\n");
    return;
  }

  // Only use char 1 to 7 of message
  payload += 1;
  payload[6] = '\0';

  char *endptr;

  // Read the color code into a 32 bit unsigned integer
  uint32_t color = strtol((char *)payload, &endptr, 16);

  // Check if the color code was not parsed fully
  if (*endptr != '\0') {
    Serial.print("Invalid color code!\n");
    return;
  }
      
  // Extract individual color components
  uint8_t red = color >> 16;
  uint8_t green = (color >> 8) & 0xFF;
  uint8_t blue = color & 0xFF;

  Serial.printf("LED-Color: %d, %d, %d\n", red, green, blue);

  // Display the color on the LEDs
  FastLED.showColor(CRGB(red, green, blue));

  Serial.println();
}
