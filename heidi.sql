#include <SoftwareSerial.h>
#include <LiquidCrystal.h>

#define RX 9        
#define RELAY_PIN 10 

LiquidCrystal lcd(7, 6, 5, 4, 3, 2);
SoftwareSerial RFID(RX, 0); 

String lastUID = ""; 

void setup() {
    Serial.begin(9600);
    RFID.begin(9600);

    lcd.begin(20, 4);
    lcd.setCursor(0, 0);
    lcd.print("Przyloz legitymacje");

    pinMode(RELAY_PIN, OUTPUT);
    digitalWrite(RELAY_PIN, LOW); 

    while (RFID.available()) RFID.read();
}

void loop() {
    if (RFID.available() > 0) {
        char receivedData[14]; 
        int index = 0;
        bool validData = false;

        // Odczyt UID z RFID
        while (RFID.available()) {
            char c = RFID.read();

           
            if (c == 2) { 
                index = 0;
                validData = true;
            }

            if (validData) {
                receivedData[index++] = c;
            }

            if (c == 3) break;

            if (index >= 14) break;
        }

        String uid = "";
        for (int i = 1; i < 11; i++) { 
            uid += receivedData[i];
        }

        if (uid.length() != 10) return;

        if (uid == lastUID) return;
        lastUID = uid; 

        Serial.println(uid);

        unsigned long startTime = millis();
        while (!Serial.available()) {
            if (millis() - startTime > 5000) {
                lcd.clear();
                lcd.setCursor(0, 0);
                lcd.print("Brak odp. z PC!");
                digitalWrite(RELAY_PIN, LOW);
                delay(2000);
                lcd.clear();
                lcd.print("Przyloz legitymacje");
                return;
            }
        }

        String userData = Serial.readStringUntil('\n');
        userData.trim();

        if (userData.length() == 0) {
            lcd.clear();
            lcd.setCursor(0, 0);
            lcd.print("Błąd odczytu!");
            digitalWrite(RELAY_PIN, LOW);
            delay(2000);
            lcd.clear();
            lcd.print("Przyloz legitymacje");
            return;
        }

        int firstSpace = userData.indexOf(' ');
        int lastSpace = userData.lastIndexOf(' ');

        if (firstSpace == -1 || lastSpace == -1 || firstSpace == lastSpace) {
            lcd.clear();
            lcd.setCursor(0, 0);
            lcd.print("Bledne dane!");
            digitalWrite(RELAY_PIN, LOW);
            delay(2000);
            lcd.clear();
            lcd.print("Przyloz legitymacje");
            return;
        }

        String firstName = userData.substring(0, firstSpace);
        String lastName = userData.substring(firstSpace + 1, lastSpace);
        String userClass = userData.substring(lastSpace + 1);

        lcd.clear();
        lcd.setCursor(0, 0);
        lcd.print("Uzytkownik:");
        lcd.setCursor(0, 1);
        lcd.print(firstName + " " + lastName);
        lcd.setCursor(0, 2);
        lcd.print("Klasa: " + userClass);

        digitalWrite(RELAY_PIN, HIGH);
        delay(5000);
        digitalWrite(RELAY_PIN, LOW);

        lcd.clear();
        lcd.setCursor(0, 0);
        lcd.print("Przyloz legitymacje");

        while (RFID.available()) RFID.read(); 
        delay(2000); 
    }
}
