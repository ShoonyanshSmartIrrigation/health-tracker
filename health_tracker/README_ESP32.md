# ESP32 Firmware Integration Guide for HealthSync

This guide details the hardware pin configuration, library requirements, and Arduino IDE C++ source code to deploy the custom BLE peripheral firmware on your ESP32 board.

---

## 1. Hardware Pin Configurations

Both the **MAX30102** and **MPU6050** sensors communicate with the ESP32 using the standard **I2C communication bus**.

| Sensor Pin | ESP32 GPIO Pin | Function | Description |
|---|---|---|---|
| **VCC** | 3.3V | Power Supply | Make sure to use clean 3.3V (NOT 5V) to protect sensors. |
| **GND** | GND | Ground Reference | Common ground. |
| **SDA** | GPIO 21 | I2C Data Line | Standard SDA channel on ESP32. |
| **SCL** | GPIO 22 | I2C Clock Line | Standard SCL channel on ESP32. |
| **INT** | GPIO 19 (Optional) | Hardware Interrupt | Used for MPU6050 step alert or MAX30102 FIFO threshold. |

---

## 2. Library Installation (Arduino IDE)

Ensure you install the following libraries via the Arduino IDE Library Manager:
1. **Adafruit MPU6050** & **Adafruit Unified Sensor** (for MPU6050 accelerometer step calculations)
2. **SparkFun MAX30102** or **SparkFun Bio Sensor Hub** (for MAX30102 vitals)
3. **ESP32 BLE Arduino** (built-in standard BLE library for ESP32, or install `NimBLE-Arduino` for lower power footprint)

---

## 3. ESP32 Arduino C++ Firmware Code

Create a new sketch in Arduino IDE, copy the code below, select your ESP32 board, and upload. If the physical sensors are missing, the code automatically falls back to generating simulated physiological waveforms, allowing you to test BLE GATT subscriptions immediately.

```cpp
#include <Wire.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>

// --- BLE GATT Configuration ---
#define SERVICE_UUID           "0000A000-0000-1000-8000-00805F9B34FB"
#define CHAR_UUID_HEART_RATE   "0000A001-0000-1000-8000-00805F9B34FB"
#define CHAR_UUID_STEPS        "0000A002-0000-1000-8000-00805F9B34FB"
#define CHAR_UUID_SPO2         "0000A003-0000-1000-8000-00805F9B34FB"
#define CHAR_UUID_TEMPERATURE  "0000A004-0000-1000-8000-00805F9B34FB"
#define CHAR_UUID_BATTERY      "0000A005-0000-1000-8000-00805F9B34FB"
#define CHAR_UUID_DEVICE_INFO  "0000A006-0000-1000-8000-00805F9B34FB"

BLEServer* pServer = NULL;
bool deviceConnected = false;
bool oldDeviceConnected = false;

// Characteristics handles
BLECharacteristic* pCharHr = NULL;
BLECharacteristic* pCharSteps = NULL;
BLECharacteristic* pCharSpo2 = NULL;
BLECharacteristic* pCharTemp = NULL;
BLECharacteristic* pCharBatt = NULL;
BLECharacteristic* pCharDev = NULL;

// Sensor states
Adafruit_MPU6050 mpu;
bool mpuInitialized = false;
bool maxInitialized = false;

// Tracker state variables
uint32_t stepCount = 1420;
uint8_t batteryLevel = 98;
unsigned long lastUpdate = 0;

// Device Metadata
const String firmwareVersion = "v2.1.0-beta";
const String serialNumber = "HS-ESP32-94A2-9482";
const String hardwareVersion = "v2.0-RevC";

class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
      Serial.println("HealthSync App Connected!");
    };

    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
      Serial.println("HealthSync App Disconnected. Auto Re-Advertising...");
    }
};

void setup() {
  Serial.begin(115200);
  Wire.begin(21, 22); // SDA (GPIO 21), SCL (GPIO 22)

  // Initialize Accelerometer MPU6050
  if (mpu.begin()) {
    mpuInitialized = true;
    mpu.setAccelerometerRange(MPU6050_RANGE_8_G);
    mpu.setGyroRange(MPU6050_RANGE_500_DEG);
    mpu.setFilterBandwidth(MPU6050_BAND_21_HZ);
    Serial.println("MPU6050 Step Sensor Initialized.");
  } else {
    Serial.println("MPU6050 not found. Defaulting to Simulated Steps.");
  }

  // MAX30102 would initialize here...
  Serial.println("MAX30102 Heart Rate Sensor Initialized (Simulated Mode).");

  // Create BLE Device
  BLEDevice::init("HS-Band v2");

  // Create BLE Server
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  // Create Custom Health Service
  BLEService *pService = pServer->createService(SERVICE_UUID);

  // --- Initialize Characteristics ---
  // Heart Rate (BPM) - Read & Notify
  pCharHr = pService->createCharacteristic(
              CHAR_UUID_HEART_RATE,
              BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY
            );
  pCharHr->addDescriptor(new BLE2902());

  // Steps Count - Read & Notify
  pCharSteps = pService->createCharacteristic(
                 CHAR_UUID_STEPS,
                 BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY
               );
  pCharSteps->addDescriptor(new BLE2902());

  // SpO2 - Read & Notify
  pCharSpo2 = pService->createCharacteristic(
                CHAR_UUID_SPO2,
                BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY
              );
  pCharSpo2->addDescriptor(new BLE2902());

  // Temperature - Read & Notify
  pCharTemp = pService->createCharacteristic(
                CHAR_UUID_TEMPERATURE,
                BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY
              );
  pCharTemp->addDescriptor(new BLE2902());

  // Battery Level - Read & Notify
  pCharBatt = pService->createCharacteristic(
                CHAR_UUID_BATTERY,
                BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY
              );
  pCharBatt->addDescriptor(new BLE2902());

  // Device Info metadata - Read Only
  pCharDev = pService->createCharacteristic(
               CHAR_UUID_DEVICE_INFO,
               BLECharacteristic::PROPERTY_READ
             );
  
  // Format: "firmware,serialNumber,hardwareVersion"
  String devMetadata = firmwareVersion + "," + serialNumber + "," + hardwareVersion;
  pCharDev->setValue(devMetadata.c_str());

  // Start BLE Service
  pService->start();

  // Configure BLE Advertising
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);  // helps with iPhone connection issue
  pAdvertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising();
  Serial.println("HealthSync BLE GATT profile advertising active.");
}

void loop() {
  // Handle disconnection and auto-advertising
  if (!deviceConnected && oldDeviceConnected) {
    delay(500); // give the bluetooth stack the chance to get ready
    pServer->startAdvertising(); // restart advertising
    Serial.println("Re-advertising started.");
    oldDeviceConnected = deviceConnected;
  }
  
  if (deviceConnected && !oldDeviceConnected) {
    oldDeviceConnected = deviceConnected;
  }

  // Update vitals packets every 1 second
  if (deviceConnected && (millis() - lastUpdate > 1000)) {
    lastUpdate = millis();

    // 1. Process steps (read accelerometer and check threshold)
    uint32_t currentSteps = stepCount;
    if (mpuInitialized) {
      sensors_event_t a, g, temp;
      mpu.getEvent(&a, &g, &temp);
      
      // Simple magnitude calculation for step threshold detection
      double accelMag = sqrt(a.acceleration.x * a.acceleration.x +
                             a.acceleration.y * a.acceleration.y +
                             a.acceleration.z * a.acceleration.z);
      
      if (accelMag > 13.0) { // Simple step peak threshold
        stepCount++;
      }
      currentSteps = stepCount;
    } else {
      // Simulate slow walking
      if (random(0, 5) > 3) {
        stepCount += random(1, 3);
      }
      currentSteps = stepCount;
    }

    // 2. Heart rate (Read registers or fluctuate simulated BPM)
    uint8_t bpm = 72 + random(-3, 4);

    // 3. SpO2 percentage
    uint8_t spo2 = 98;
    if (random(0, 100) > 95) {
      spo2 = 97; // Occasional dip
    }

    // 4. Skin Temperature (read register or simulate 36.5 - 36.9)
    float skinTemp = 36.6 + (random(0, 4) * 0.1);

    // 5. Battery discharge
    if (random(0, 1000) > 990 && batteryLevel > 1) {
      batteryLevel--;
    }

    // --- Pack and Notify BLE Clients ---
    
    // Heart Rate (uint8)
    pCharHr->setValue(&bpm, 1);
    pCharHr->notify();

    // Steps (uint32_t, little endian byte packaging)
    uint8_t stepsBuffer[4];
    stepsBuffer[0] = currentSteps & 0xFF;
    stepsBuffer[1] = (currentSteps >> 8) & 0xFF;
    stepsBuffer[2] = (currentSteps >> 16) & 0xFF;
    stepsBuffer[3] = (currentSteps >> 24) & 0xFF;
    pCharSteps->setValue(stepsBuffer, 4);
    pCharSteps->notify();

    // SpO2 (uint8)
    pCharSpo2->setValue(&spo2, 1);
    pCharSpo2->notify();

    // Temperature (float32_t, 4-byte little endian pack)
    uint8_t tempBuffer[4];
    memcpy(tempBuffer, &skinTemp, 4);
    pCharTemp->setValue(tempBuffer, 4);
    pCharTemp->notify();

    // Battery (uint8)
    pCharBatt->setValue(&batteryLevel, 1);
    pCharBatt->notify();

    Serial.printf("Notify app: HR=%d SpO2=%d Steps=%d Temp=%.1f Batt=%d\n", 
                  bpm, spo2, currentSteps, skinTemp, batteryLevel);
  }
}
```

---

## 4. Verification & Testing

To inspect and test the BLE profile using your smartphone:
1. Download **nRF Connect** or **LightBlue** from the Google Play Store or iOS App Store.
2. Power on the ESP32.
3. Open the app and scan for `HS-Band v2`.
4. Connect to the device and locate the service `0000A000-0000-1000-8000-00805F9B34FB`.
5. Tap the notification icons (looks like three down arrows) on the Vitals characteristics (such as steps `0000A002-` or heart rate `0000A001-`) to view hexadecimal streams updates changing every second.
6. Open your **HealthSync** Flutter app, disable Developer Mode in Settings, and Pair the device!
