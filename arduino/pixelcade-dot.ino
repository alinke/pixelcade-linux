// Max 7219 Single Color LED Matrix, 7 Segment Display, and OLED Accessories for Pixelcade
// 
// MD_MAX72XX library can be found at https://github.com/MajicDesigns/MD_MAX72XX
//

#include <MD_Parola.h>
#include <MD_MAX72xx.h>
#include <SPI.h>
#include <Wire.h>
#include "SSD1306Ascii.h"
#include "SSD1306AsciiWire.h"

//TO DO add firmware string that java can read, have strings for led matrix , oled displays, and any other accessories
// TO DO would also be nice to add high scores

#define HANDSHAKE_INIT "pixelcadeh"   //the pixelcade software on the PC or Pi will send this string to the Arduino to trigger the handshake
#define HANDSHAKE_RETURN 45           //once pixelcadeh is received, arduino will send back 45 45. Once the PC receives that, we know we are communicating correctly
#define FW_VERSION "MAX70001"         //PMAX is the platform or short for PMAX7219 in this case and 0001 is the version

/* Pin connections are as follows:
LED Matrix 1
DIN--> 11
CS-->  10
CLK--> 13
If connecting a second or third matrix, just daisy chain them
OLED 1
SCL--> SCL 
SDA--> SDA   
Note there are no SDA and SCL pins on Arduino Nano so use instead SDA\-->A4 and SCL-->A5
 */

// ****************** LED MATRIX ***************
#define HARDWARE_TYPE MD_MAX72XX::FC16_HW
#define MAX_DEVICES 4                 //in this case we have 8 modules total 
#define NUM_ZONES   1                 //but if you have 2 moduels of 4 each , then change this to 2 zones meaning we treat one zone of 4 and the second zone of 4 and can control them independently
#define CLK_PIN     13
#define DATA_PIN    11
#define CS_PIN      10

MD_Parola P = MD_Parola(HARDWARE_TYPE, CS_PIN, MAX_DEVICES);
// LED MATRIX Scrolling parameters
uint8_t scrollSpeed = 25;    // default frame delay value
textEffect_t scrollEffectIn = PA_SCROLL_RIGHT;
textEffect_t scrollEffectOut = PA_GROW_DOWN;  
textPosition_t scrollAlign = PA_RIGHT;
uint16_t scrollPause = 2000; // in milliseconds
unsigned long delaytime=250;

/* Other possible scroll effects you can experiment with
  PA_PRINT,
  PA_SCAN_HORIZ,
  PA_SCROLL_LEFT,
  PA_WIPE,
  PA_SCROLL_UP_LEFT,
  PA_SCROLL_UP,
  PA_OPENING_CURSOR,
  PA_GROW_UP,
  PA_MESH,
  PA_SCROLL_UP_RIGHT,
  PA_BLINDS,
  PA_CLOSING,
  PA_RANDOM,
  PA_GROW_DOWN,
  PA_SCAN_VERT,
  PA_SCROLL_DOWN_LEFT,
  PA_WIPE_CURSOR,
  PA_DISSOLVE,
  PA_OPENING,
  PA_CLOSING_CURSOR,
  PA_SCROLL_DOWN_RIGHT,
  PA_SCROLL_RIGHT,
  PA_SLICE,
  PA_SCROLL_DOWN,
*/

// Global message buffers shared by Serial and Scrolling functions
#define  BUF_SIZE  200     //had to increase the buffer size from the default of 75 becasue our string length was exceeding and note on the pixelcade side we also truncate to ensure the incoming serial message is not too long
char curMessage[BUF_SIZE] = { "" };
char newMessage[BUF_SIZE] = { "Pixelcade" };
bool newMessageAvailable = true;
// **********************************************

//*************** OLED display
#define RTN_CHECK 1
// 0X3C+SA0 - 0x3C or 0x3D
#define I2C_ADDRESS_1 0x3C
#define I2C_ADDRESS_2 0x3D
// Define proper RST_PIN if required.
#define RST_PIN -1
SSD1306AsciiWire oled1;
//**********************************

bool    handShakeResponse = false;
int     gameYearArray[4] = {8, 8, 8, 8};  //used for the 7segment LED display
String  gameTitle="";
String  gameYear="";
String  gameManufacturer="";
String  gameGenre="";
String  gameRating="";
String  MatrixMessage="";
int i = 0;

void readSerial(void)
{
  static char *cp = newMessage;

  while (Serial.available())
  {
    *cp = (char)Serial.read();
    if ((*cp == '\n') || (cp - newMessage >= BUF_SIZE-2))  {   // end of message character or full buffer
   
      *cp = '\0'; // end the string
      cp = newMessage;  //reset the pointer for the next incoming string
      
      //now let's test if we received the handshake string from pixelcade and response back if yes. But if not, we'll just continue
      if (String(cp).equals(HANDSHAKE_INIT)) {
       
        newMessageAvailable = false;
        handShakeResponse = true;
        Serial.println("went here");  //IMPORTANT: the handshake with pixelcade will break if you delete this one so be sure and leave as is 
        
      } else {

            //char string[50] ="Test,string1,Test,string2:Test:string3";
            char *p;
            //printf ("String  \"%s\" is split into tokens:\n",cp);
            Serial.println(p);
            i = 0;
            p = strtok (cp,"%");
            while (p!= NULL)
            {
              //printf ("%s\n",p);
              //Serial.println("%s\n",p);
              //Serial.println(p);

               switch(i)
              {
                  case 0:
                      //gameTitle = trim(p);
                      gameTitle = p;
                      break;
                  case 1:
                      //gameYear = trim(p);
                      gameYear = p;
                      break;
                  case 2:
                       //gameManufacturer = trim(p);
                      gameManufacturer = p;
                      break;
                  case 3:
                      //gameGenre = trim(p);
                      gameGenre = p;
                      break;
                  case 4:
                      //gameRating = trim(p);
                      gameRating = p;
                      break; 
                  default:
                      printf("string is longer, ignoring rest of string");
              }
              p = strtok (NULL, "%");
              i++;
            }
            
            int YearStr_len = gameYear.length(); 
      
            Serial.print(gameTitle);
            Serial.print("\n");
            
            for (int i = 0; i < 4; i++) {
              gameYearArray[i] = gameYear.substring(i, i+1).toInt();
            }

            //newMessage is what actuallly gets sent to the LED matrix so we'll manipulate our desired string here based on the meta-data we have available, you can customize here as you like!
            Serial.println(gameYear);  //not sure why, but if this is removed, the handshake with pixelcade breaks so leave this here
             MatrixMessage = gameTitle;
            
            if (!gameTitle.equals("dummy")) {
                MatrixMessage.toCharArray(newMessage, BUF_SIZE);
                newMessageAvailable = true;
                handShakeResponse = false; 
            }
       
      }
    }
    
    else  // move char pointer to next position
      cp++;
  }
}


void writeOled () {
  oled1.setFont(Adafruit5x7);
  oled1.clear();
  
  if (gameTitle.equals("")) {                   //this means we haven't connected yet or have no good data coming in
    oled1.println("Pixelcade Dot"); 
    //oled1.set2X();
    oled1.println("");
    oled1.println("OLED Display");  
    oled1.println("Ready..."); 
  } 
  
  else {
  
      //now let's do something different depending if we have full meta data or just the rom name
    
      if (gameYear.equals("0000")) {  //then we only have the rom name and no additional meta data
        
          if (gameTitle.length() < 10) { //we can use the larger font
               oled1.set2X();
               oled1.println(gameTitle);
          } else {                      //rom  name too long so let's use the smaller font
    
               oled1.set1X();
               oled1.println(gameTitle);
          }
        
      } else {                          //we have the game creation year so let's assume we have good meta-data and show all the stuff
      
        oled1.set1X();
        oled1.println(gameTitle);
        oled1.println(gameManufacturer);
        oled1.println();
        oled1.set2X();
        oled1.println(gameYear);
        oled1.set1X();
        oled1.println(gameGenre);
        oled1.println(gameRating);
        
      }
  }
}


void setup()
{
  
  /////******** for OLED screen ***************
   Wire.begin();
   Wire.setClock(400000L);
    #if RST_PIN >= 0
    oled1.begin(&Adafruit128x64, I2C_ADDRESS_1, RST_PIN);
    #else // RST_PIN >= 0
    oled1.begin(&Adafruit128x64, I2C_ADDRESS_1);
    #endif // RST_PIN >= 0
  /////*****************************************
  
  Serial.begin(57600);
  Serial.setTimeout(50);
  Serial.print(FW_VERSION);
 
  P.begin(NUM_ZONES);   
  P.setZone(0, 0, 3);      //one module of 4 with one zone
  // P.setZone(0, 0, 7);   //one module of 8 with one zone
  //P.setZone(0, 0, 3);   //two modules of 4 with two zones, the first zone is modules 0-3 and second zone is modules 4-7
  //P.setZone(1, 4, 7);

  // change these to true if your displays are upside down
  P.setZoneEffect(0, false, PA_FLIP_UD);
  P.setZoneEffect(0, false, PA_FLIP_LR);

  for (uint8_t i=0; i<NUM_ZONES; i++) {
    P.displayZoneText(i, curMessage, scrollAlign, scrollSpeed, scrollPause, scrollEffectIn, scrollEffectOut);
  }

}

void loop()
{
  
  if (P.displayAnimate())
  {
    if (handShakeResponse) {
       Serial.write(HANDSHAKE_RETURN);
       Serial.write(HANDSHAKE_RETURN);
       handShakeResponse = false;
    }
    
    if (newMessageAvailable)
    {
      strcpy(curMessage, newMessage);
      writeOled ();                     //write to the OLED
      newMessageAvailable = false;
    }
    P.displayReset();
  }
  readSerial();
  
}
