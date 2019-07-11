program chip8emu;

{$mode objfpc}{$H+}{$inline on}

uses
 GlobalConst,
 GlobalTypes,
 Platform,
 Threads,
 Console,
 Framebuffer,
 BCM2837,
 BCM2710,
 SysUtils,
 GPIO,
 Serial,
 Devices,
 math,
 SPI,
 MMC,
 HTTP,
 Winsock2,
 FileSystem,
 FATFS,
 SMSC95XX,
 DWCOTG,
 Shell,
 ShellFilesystem,
 ShellUpdate,
 RemoteShell,
 GlobalConfig,
 Classes,
 Keyboard;

const

 GBPalette:TFramebufferPalette = (
  Start:0;
  Count:256;
  Entries:
  ($FF000000,$FF88c070,$FF346856,$FFFFFFFF,$FFAA0000,$FFAA00AA,$FFAA5500,$FFAAAAAA,$FF555555,$FF5555FF,$FF55FF55,$FF55FFFF,$FFFF5555,$FFFF55FF,$FFFFFF55,$FFFFFFFF,
   $FF000000,$FF141414,$FF202020,$FF2C2C2C,$FF383838,$FF444444,$FF505050,$FF606060,$FF707070,$FF808080,$FF909090,$FFA0A0A0,$FFB4B4B4,$FFC8C8C8,$FFE0E0E0,$FFFCFCFC,
   $FF0000FC,$FF4000FC,$FF7C00FC,$FFBC00FC,$FFFC00FC,$FFFC00BC,$FFFC007C,$FFFC0040,$FFFC0000,$FFFC4000,$FFFC7C00,$FFFCBC00,$FFFCFC00,$FFBCFC00,$FF7CFC00,$FF40FC00,
   $FF00FC00,$FF00FC40,$FF00FC7C,$FF00FCBC,$FF00FCFC,$FF00BCFC,$FF007CFC,$FF0040FC,$FF7C7CFC,$FF9C7CFC,$FFBC7CFC,$FFDC7CFC,$FFFC7CFC,$FFFC7CDC,$FFFC7CBC,$FFFC7C9C,
   $FFFC7C7C,$FFFC9C7C,$FFFCBC7C,$FFFCDC7C,$FFFCFC7C,$FFDCFC7C,$FFBCFC7C,$FF9CFC7C,$FF7CFC7C,$FF7CFC9C,$FF7CFCBC,$FF7CFCDC,$FF7CFCFC,$FF7CDCFC,$FF7CBCFC,$FF7C9CFC,
   $FFB4B4FC,$FFC4B4FC,$FFD8B4FC,$FFE8B4FC,$FFFCB4FC,$FFFCB4E8,$FFFCB4D8,$FFFCB4C4,$FFFCB4B4,$FFFCC4B4,$FFFCD8B4,$FFFCE8B4,$FFFCFCB4,$FFE8FCB4,$FFD8FCB4,$FFC4FCB4,
   $FFB4FCB4,$FFB4FCC4,$FFB4FCD8,$FFB4FCE8,$FFB4FCFC,$FFB4E8FC,$FFB4D8FC,$FFB4C4FC,$FF000070,$FF1C0070,$FF380070,$FF540070,$FF700070,$FF700054,$FF700038,$FF70001C,
   $FF700000,$FF701C00,$FF703800,$FF705400,$FF707000,$FF547000,$FF387000,$FF1C7000,$FF007000,$FF00701C,$FF007038,$FF007054,$FF007070,$FF005470,$FF003870,$FF001C70,
   $FF383870,$FF443870,$FF543870,$FF603870,$FF703870,$FF703860,$FF703854,$FF703844,$FF703838,$FF704438,$FF705438,$FF706038,$FF707038,$FF607038,$FF547038,$FF447038,
   $FF387038,$FF387044,$FF387054,$FF387060,$FF387070,$FF386070,$FF385470,$FF384470,$FF505070,$FF585070,$FF605070,$FF685070,$FF705070,$FF705068,$FF705060,$FF705058,
   $FF705050,$FF705850,$FF706050,$FF706850,$FF707050,$FF687050,$FF607050,$FF587050,$FF507050,$FF507058,$FF507060,$FF507068,$FF507070,$FF506870,$FF506070,$FF505870,
   $FF000040,$FF100040,$FF200040,$FF300040,$FF400040,$FF400030,$FF400020,$FF400010,$FF400000,$FF401000,$FF402000,$FF403000,$FF404000,$FF304000,$FF204000,$FF104000,
   $FF004000,$FF004010,$FF004020,$FF004030,$FF004040,$FF003040,$FF002040,$FF001040,$FF202040,$FF282040,$FF302040,$FF382040,$FF402040,$FF402038,$FF402030,$FF402028,
   $FF402020,$FF402820,$FF403020,$FF403820,$FF404020,$FF384020,$FF304020,$FF284020,$FF204020,$FF204028,$FF204030,$FF204038,$FF204040,$FF203840,$FF203040,$FF202840,
   $FF2C2C40,$FF302C40,$FF342C40,$FF3C2C40,$FF402C40,$FF402C3C,$FF402C34,$FF402C30,$FF402C2C,$FF40302C,$FF40342C,$FF403C2C,$FF40402C,$FF3C402C,$FF34402C,$FF30402C,
   $FF2C402C,$FF2C4030,$FF2C4034,$FF2C403C,$FF2C4040,$FF2C3C40,$FF2C3440,$FF2C3040,$FF000000,$FF000000,$FF000000,$FF000000,$FF000000,$FF000000,$FF000000,$FF000000)
  );

 // textfont expected by chip8 programs
 textFont : Array[0..79] of Byte =
   (
     $F0, $90, $90, $90, $F0, // 0
     $20, $60, $20, $20, $70, // 1
     $F0, $10, $F0, $80, $F0, // 2
     $F0, $10, $F0, $10, $F0, // 3
     $90, $90, $F0, $10, $10, // 4
     $F0, $80, $F0, $10, $F0, // 5
     $F0, $80, $F0, $90, $F0, // 6
     $F0, $10, $20, $40, $40, // 7
     $F0, $90, $F0, $90, $F0, // 8
     $F0, $90, $F0, $10, $F0, // 9
     $F0, $90, $F0, $90, $90, // A
     $E0, $90, $E0, $90, $E0, // B
     $F0, $80, $80, $80, $F0, // C
     $E0, $90, $90, $90, $E0, // D
     $F0, $80, $F0, $80, $F0, // E
     $F0, $80, $F0, $80, $80  // F
   );

 { graphics for text }
  gbText : Array[0..3071] of Byte =
  (
    $00,$03,$03,$03,$03,$03,$00,$00,
    $03,$00,$00,$00,$00,$03,$03,$00,
    $03,$00,$00,$00,$03,$00,$03,$00,
    $03,$00,$00,$03,$00,$00,$03,$00,
    $03,$00,$03,$00,$00,$00,$03,$00,
    $03,$03,$00,$00,$00,$00,$03,$00,
    $00,$03,$03,$03,$03,$03,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$03,$00,$00,$00,$00,
    $00,$00,$03,$03,$00,$00,$00,$00,
    $00,$00,$00,$03,$00,$00,$00,$00,
    $00,$00,$00,$03,$00,$00,$00,$00,
    $00,$00,$00,$03,$00,$00,$00,$00,
    $00,$00,$00,$03,$00,$00,$00,$00,
    $00,$03,$03,$03,$03,$03,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $00,$03,$03,$03,$03,$03,$00,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $00,$00,$00,$00,$00,$00,$03,$00,
    $00,$00,$00,$03,$03,$03,$00,$00,
    $00,$03,$03,$00,$00,$00,$00,$00,
    $03,$00,$00,$00,$00,$00,$00,$00,
    $03,$03,$03,$03,$03,$03,$03,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $03,$03,$03,$03,$03,$03,$03,$00,
    $00,$00,$00,$00,$00,$03,$00,$00,
    $00,$00,$00,$03,$03,$00,$00,$00,
    $00,$00,$00,$00,$00,$03,$00,$00,
    $00,$00,$00,$00,$00,$00,$03,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $00,$03,$03,$03,$03,$03,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$03,$03,$00,$00,
    $00,$00,$00,$03,$00,$03,$00,$00,
    $00,$00,$03,$00,$00,$03,$00,$00,
    $00,$03,$00,$00,$00,$03,$00,$00,
    $03,$00,$00,$00,$00,$03,$00,$00,
    $03,$03,$03,$03,$03,$03,$03,$00,
    $00,$00,$00,$00,$00,$03,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $03,$03,$03,$03,$03,$03,$00,$00,
    $03,$00,$00,$00,$00,$00,$00,$00,
    $03,$03,$03,$03,$03,$03,$00,$00,
    $00,$00,$00,$00,$00,$00,$03,$00,
    $00,$00,$00,$00,$00,$00,$03,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $00,$03,$03,$03,$03,$03,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $00,$03,$03,$03,$03,$03,$00,$00,
    $03,$00,$00,$00,$00,$00,$00,$00,
    $03,$00,$00,$00,$00,$00,$00,$00,
    $03,$03,$03,$03,$03,$03,$00,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $00,$03,$03,$03,$03,$03,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $03,$03,$03,$03,$03,$03,$03,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $00,$00,$00,$00,$00,$03,$00,$00,
    $00,$00,$00,$00,$03,$00,$00,$00,
    $00,$00,$00,$03,$00,$00,$00,$00,
    $00,$00,$00,$03,$00,$00,$00,$00,
    $00,$00,$00,$03,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $00,$03,$03,$03,$03,$03,$00,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $00,$03,$03,$03,$03,$03,$00,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $00,$03,$03,$03,$03,$03,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $00,$03,$03,$03,$03,$03,$00,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $00,$03,$03,$03,$03,$03,$03,$00,
    $00,$00,$00,$00,$00,$00,$03,$00,
    $00,$00,$00,$00,$00,$00,$03,$00,
    $00,$03,$03,$03,$03,$03,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$03,$03,$00,$00,$00,$00,
    $00,$00,$03,$03,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$03,$03,$00,$00,$00,$00,
    $00,$00,$03,$03,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$03,$00,$00,$00,
    $00,$00,$03,$00,$03,$03,$03,$00,
    $03,$03,$03,$03,$03,$00,$00,$00,
    $00,$00,$03,$00,$03,$00,$00,$00,
    $00,$00,$03,$03,$03,$03,$03,$00,
    $03,$03,$03,$00,$03,$00,$00,$00,
    $00,$00,$03,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$03,$00,$00,$00,
    $00,$00,$00,$03,$00,$00,$00,$00,
    $00,$00,$03,$00,$00,$00,$00,$00,
    $00,$03,$00,$00,$00,$00,$00,$00,
    $00,$00,$03,$00,$00,$00,$00,$00,
    $00,$00,$00,$03,$00,$00,$00,$00,
    $00,$00,$00,$00,$03,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $00,$03,$03,$03,$03,$03,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $00,$03,$03,$03,$03,$03,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$03,$00,$00,$00,$00,$00,
    $00,$00,$00,$03,$00,$00,$00,$00,
    $00,$00,$00,$00,$03,$00,$00,$00,
    $00,$00,$00,$00,$00,$03,$00,$00,
    $00,$00,$00,$00,$03,$00,$00,$00,
    $00,$00,$00,$03,$00,$00,$00,$00,
    $00,$00,$03,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$03,$03,$03,$03,$00,$00,
    $00,$03,$00,$00,$00,$00,$03,$00,
    $00,$00,$00,$00,$00,$00,$03,$00,
    $00,$00,$00,$00,$03,$03,$00,$00,
    $00,$00,$00,$03,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$03,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $00,$03,$03,$03,$03,$03,$00,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $03,$00,$00,$03,$03,$00,$03,$00,
    $03,$00,$03,$00,$03,$00,$03,$00,
    $03,$00,$03,$03,$03,$03,$00,$00,
    $03,$00,$00,$00,$00,$00,$00,$00,
    $00,$03,$03,$03,$03,$03,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$03,$03,$03,$00,$00,$00,
    $00,$03,$00,$00,$00,$03,$00,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $03,$03,$03,$03,$03,$03,$03,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $03,$03,$03,$03,$03,$03,$00,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $03,$03,$03,$03,$03,$03,$00,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $03,$03,$03,$03,$03,$03,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $00,$03,$03,$03,$03,$03,$00,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $03,$00,$00,$00,$00,$00,$00,$00,
    $03,$00,$00,$00,$00,$00,$00,$00,
    $03,$00,$00,$00,$00,$00,$00,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $00,$03,$03,$03,$03,$03,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $03,$03,$03,$03,$03,$00,$00,$00,
    $03,$00,$00,$00,$00,$03,$00,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $03,$00,$00,$00,$00,$03,$00,$00,
    $03,$03,$03,$03,$03,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $03,$03,$03,$03,$03,$03,$03,$00,
    $03,$00,$00,$00,$00,$00,$00,$00,
    $03,$00,$00,$00,$00,$00,$00,$00,
    $03,$03,$03,$03,$03,$03,$00,$00,
    $03,$00,$00,$00,$00,$00,$00,$00,
    $03,$00,$00,$00,$00,$00,$00,$00,
    $03,$03,$03,$03,$03,$03,$03,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $03,$03,$03,$03,$03,$03,$03,$00,
    $03,$00,$00,$00,$00,$00,$00,$00,
    $03,$00,$00,$00,$00,$00,$00,$00,
    $03,$03,$03,$03,$03,$03,$00,$00,
    $03,$00,$00,$00,$00,$00,$00,$00,
    $03,$00,$00,$00,$00,$00,$00,$00,
    $03,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $00,$03,$03,$03,$03,$03,$00,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $03,$00,$00,$00,$00,$00,$00,$00,
    $03,$00,$00,$00,$00,$00,$00,$00,
    $03,$00,$00,$00,$03,$03,$03,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $00,$03,$03,$03,$03,$03,$03,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $03,$03,$03,$03,$03,$03,$03,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $00,$03,$03,$03,$03,$03,$00,$00,
    $00,$00,$00,$03,$00,$00,$00,$00,
    $00,$00,$00,$03,$00,$00,$00,$00,
    $00,$00,$00,$03,$00,$00,$00,$00,
    $00,$00,$00,$03,$00,$00,$00,$00,
    $00,$00,$00,$03,$00,$00,$00,$00,
    $00,$03,$03,$03,$03,$03,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$03,$03,$03,$03,$00,
    $00,$00,$00,$00,$00,$03,$00,$00,
    $00,$00,$00,$00,$00,$03,$00,$00,
    $00,$00,$00,$00,$00,$03,$00,$00,
    $00,$00,$00,$00,$00,$03,$00,$00,
    $03,$00,$00,$00,$00,$03,$00,$00,
    $00,$03,$03,$03,$03,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $03,$00,$00,$00,$00,$03,$00,$00,
    $03,$00,$00,$00,$03,$00,$00,$00,
    $03,$00,$00,$03,$00,$00,$00,$00,
    $03,$03,$03,$03,$00,$00,$00,$00,
    $03,$00,$00,$00,$03,$00,$00,$00,
    $03,$00,$00,$00,$00,$03,$00,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $00,$03,$00,$00,$00,$00,$00,$00,
    $00,$03,$00,$00,$00,$00,$00,$00,
    $00,$03,$00,$00,$00,$00,$00,$00,
    $00,$03,$00,$00,$00,$00,$00,$00,
    $00,$03,$00,$00,$00,$00,$00,$00,
    $00,$03,$00,$00,$00,$00,$00,$00,
    $00,$03,$03,$03,$03,$03,$03,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $03,$03,$00,$00,$00,$03,$03,$00,
    $03,$00,$03,$00,$03,$00,$03,$00,
    $03,$00,$00,$03,$00,$00,$03,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $03,$03,$00,$00,$00,$00,$03,$00,
    $03,$00,$03,$00,$00,$00,$03,$00,
    $03,$00,$00,$03,$00,$00,$03,$00,
    $03,$00,$00,$00,$03,$00,$03,$00,
    $03,$00,$00,$00,$00,$03,$03,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $00,$03,$03,$03,$03,$03,$00,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $00,$03,$03,$03,$03,$03,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $03,$03,$03,$03,$03,$03,$00,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $03,$03,$03,$03,$03,$03,$00,$00,
    $03,$00,$00,$00,$00,$00,$00,$00,
    $03,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $00,$03,$03,$03,$03,$03,$00,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $03,$00,$00,$03,$00,$00,$03,$00,
    $03,$00,$00,$00,$03,$00,$03,$00,
    $03,$00,$00,$00,$00,$03,$00,$00,
    $00,$03,$03,$03,$03,$00,$03,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $03,$03,$03,$03,$03,$03,$00,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $03,$00,$00,$00,$00,$03,$00,$00,
    $03,$03,$03,$03,$03,$00,$00,$00,
    $03,$00,$00,$00,$00,$03,$00,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $00,$03,$03,$03,$03,$03,$00,$00,
    $03,$00,$00,$00,$00,$00,$00,$00,
    $03,$00,$00,$00,$00,$00,$00,$00,
    $00,$03,$03,$03,$03,$03,$00,$00,
    $00,$00,$00,$00,$00,$00,$03,$00,
    $00,$00,$00,$00,$00,$00,$03,$00,
    $03,$03,$03,$03,$03,$03,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $03,$03,$03,$03,$03,$03,$03,$00,
    $00,$00,$00,$03,$00,$00,$00,$00,
    $00,$00,$00,$03,$00,$00,$00,$00,
    $00,$00,$00,$03,$00,$00,$00,$00,
    $00,$00,$00,$03,$00,$00,$00,$00,
    $00,$00,$00,$03,$00,$00,$00,$00,
    $00,$00,$00,$03,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $00,$03,$03,$03,$03,$03,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $00,$03,$00,$00,$00,$03,$00,$00,
    $00,$00,$03,$00,$03,$00,$00,$00,
    $00,$00,$00,$03,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $03,$00,$00,$03,$00,$00,$03,$00,
    $03,$00,$03,$00,$03,$00,$03,$00,
    $03,$03,$00,$00,$00,$03,$03,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $00,$03,$00,$00,$00,$03,$00,$00,
    $00,$00,$03,$00,$03,$00,$00,$00,
    $00,$00,$00,$03,$00,$00,$00,$00,
    $00,$00,$03,$00,$03,$00,$00,$00,
    $00,$03,$00,$00,$00,$03,$00,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $00,$03,$00,$00,$00,$03,$00,$00,
    $00,$00,$03,$00,$03,$00,$00,$00,
    $00,$00,$00,$03,$00,$00,$00,$00,
    $00,$00,$00,$03,$00,$00,$00,$00,
    $00,$00,$00,$03,$00,$00,$00,$00,
    $00,$00,$00,$03,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $03,$03,$03,$03,$03,$03,$03,$00,
    $00,$00,$00,$00,$00,$03,$00,$00,
    $00,$00,$00,$00,$03,$00,$00,$00,
    $00,$00,$00,$03,$00,$00,$00,$00,
    $00,$00,$03,$00,$00,$00,$00,$00,
    $00,$03,$00,$00,$00,$00,$00,$00,
    $03,$03,$03,$03,$03,$03,$03,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$03,$03,$03,$00,$00,
    $00,$00,$00,$03,$00,$00,$00,$00,
    $00,$00,$00,$03,$00,$00,$00,$00,
    $00,$00,$00,$03,$00,$00,$00,$00,
    $00,$00,$00,$03,$00,$00,$00,$00,
    $00,$00,$00,$03,$00,$00,$00,$00,
    $00,$00,$00,$03,$03,$03,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $03,$00,$00,$00,$00,$00,$00,$00,
    $00,$03,$00,$00,$00,$00,$00,$00,
    $00,$00,$03,$00,$00,$00,$00,$00,
    $00,$00,$00,$03,$00,$00,$00,$00,
    $00,$00,$00,$00,$03,$00,$00,$00,
    $00,$00,$00,$00,$00,$03,$00,$00,
    $00,$00,$00,$00,$00,$00,$03,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $00,$03,$03,$03,$00,$00,$00,$00,
    $00,$00,$00,$03,$00,$00,$00,$00,
    $00,$00,$00,$03,$00,$00,$00,$00,
    $00,$00,$00,$03,$00,$00,$00,$00,
    $00,$00,$00,$03,$00,$00,$00,$00,
    $00,$00,$00,$03,$00,$00,$00,$00,
    $00,$03,$03,$03,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$03,$00,$00,$00,$00,
    $00,$00,$03,$00,$03,$00,$00,$00,
    $00,$03,$00,$00,$00,$03,$00,$00,
    $03,$00,$00,$00,$00,$00,$03,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,
    $03,$03,$03,$03,$03,$03,$03,$00,
    $00,$00,$00,$00,$00,$00,$00,$00
  );

var
 PageSize:Integer;
 CurrentPage:Integer;
 BufferStart:Pointer;
 FramebufferDevice:PFramebufferDevice;
 FramebufferProperties:TFramebufferProperties;

 // chip8 specific variables
 romData : Array of Shortint;
 ch8_memory : Array[0..4095] of Byte;
 ch8_dataregister : Array[0..15] of Byte;
 ch8_addressregister :Word;
 ch8_stack : Array[0..16] of Word;
 ch8_stackPointer : Word;
 ch8_programCounter : Word;
 ch8_delayTimer : Word;
 ch8_soundTimer : Word;
 ch8_graphicBuffer : Array[0..2047] of Byte;
 ch8_drawFlag : boolean;
 ch8_keyInput : Array[0..$F] of Byte;
 keyPressed : string;

procedure PutPixel(X,Y,Color:Integer); inline;
var
 CurrentY:Integer;
 PixelOffset:Cardinal;
begin
 PixelOffset:=(CurrentPage * PageSize) + X + (Y * FramebufferProperties.Pitch);
 FillChar(Pointer(BufferStart + PixelOffset)^,1,Color);
end;
procedure drawImage(X, Y, width, height: Integer; buffer : Array of Byte; transparent : boolean);
var
 xPic : integer;
 yPic : integer;
 PixelOffset:Cardinal;

begin
 for xPic := 0 to width-1 do
  begin
   for yPic := 0 to height-1 do
    begin
      if ( transparent ) then
      begin
            if ( buffer[xPic + (yPic * width)] <> $00 ) then
                        PutPixel( X + xPic, Y + yPic, buffer[xPic + (yPic * width)]);
      end
      else
      begin
            PutPixel( X + xPic, Y + yPic, buffer[xPic + (yPic * width)]);
      end;

    end;
  end;
end;
procedure drawText(X, Y : Integer; textstr : Ansistring);
var
 count : integer;
 tileNum: integer;
begin
     for count:= 1 to length( textstr ) do
     begin
      if ( (Ord(textstr[count]) > 47) and (Ord(textstr[count]) < 91) ) then
       begin
        tileNum :=  Ord(textstr[count]) - 48;
        drawImage(X + (count*8), Y, 8, 8, gbText[8*8*tileNum..8*8*(tileNum+1)], true);
       end
      else
      begin
       if ( (Ord(textstr[count]) = 32 )) then
        begin
              //drawImage(X + (count*8), Y, 8, 8, text[8*8*tileNum..8*8*(tileNum+1)]);
        end
       else
       begin
         tileNum :=  15;
         drawImage(X + (count*8), Y, 8, 8, gbText[8*8*tileNum..8*8*(tileNum+1)], true);
       end;
      end;

     end;
end;
procedure debug( txt : string );
begin
    // do nothing for now
end;

procedure FillRect(X,Y,Width,Height,Color:Integer); inline;
var
 CurrentY:Integer;
 PixelOffset:Cardinal;
begin
 PixelOffset:=(CurrentPage * PageSize) + X + (Y * FramebufferProperties.Pitch);
 
 for CurrentY:=0 to Height - 1 do
  begin
   FillChar(Pointer(BufferStart + PixelOffset)^,Width,Color);
   Inc(PixelOffset,FramebufferProperties.Pitch);
  end;
end;
procedure ClearScreen(Color:Integer); inline;
begin
 FillChar(Pointer(BufferStart + (CurrentPage * PageSize))^,PageSize,Color);
end;

procedure Flip;
var
 OffsetX:Integer;
 OffsetY:Integer;

begin
    if (FramebufferProperties.Flags and FRAMEBUFFER_FLAG_CACHED) <> 0 then
     begin
      CleanDataCacheRange(PtrUInt(BufferStart) + (CurrentPage * PageSize),PageSize);
     end;

    OffsetX:=0;
    OffsetY:=CurrentPage * FramebufferProperties.PhysicalHeight;
    FramebufferDeviceSetOffset(FramebufferDevice,OffsetX,OffsetY,True);

    if (FramebufferProperties.Flags and FRAMEBUFFER_FLAG_SYNC) <> 0 then
     begin
      FramebufferDeviceWaitSync(FramebufferDevice);
     end
    else
     begin
      MicrosecondDelay(1000000 div 30);
     end;

     CurrentPage:=(CurrentPage + 1) mod 2;
end;
procedure drawGraphics();
var x : integer;
    y : integer;
    count : integer;
    dt : string;
begin
     x := 0;
     y := 0;
     dt := '';
     for count:= 0 to (32*64)-1 do
     begin
       if (ch8_graphicBuffer[count] = 1 ) then
       begin
              FillRect(x*5, y*5, 5, 5, 15);
       end
       else
       begin
              FillRect(x*5, y*5, 5, 5, 0);
       end;
       x:=x + 1;
       if x = 64 then
       begin
        x:= 0;
        y:= y + 1;
        end;
     end;

end;
function doCycle() : boolean;
var opcode : Word;
    regNum : Byte;
    tempNum : Byte;
    tempNumWord  :Word;
    count : Byte;
    counter : Word;
    Character : Char;
    keyBuffer : String;

    // for drawing graphics
    x : Word;
    y : Word;
    spriteHeight : Word;
    pixel : Word;
    yline : integer;
    xline : integer;
begin
    // clear keys
    for count:= 0 to $F do
        ch8_keyInput[count] := 0;

    // check keyboard input
    {
    if ConsoleKeypressed then
     if ConsoleGetKey(Character,nil) then
      begin
       keyPressed := 'KEY :' + IntToStr(Ord(Character));
        case (Character) of
         '1' : begin ch8_keyInput[1] := 1; end;
         '2' : begin ch8_keyInput[2] := 1; end;
         '3' : begin ch8_keyInput[3] := 1; end;
         '4' : begin ch8_keyInput[$C] := 1; end;
         'q' : begin ch8_keyInput[4] := 1; end;
         'w' : begin ch8_keyInput[5] := 1; end;
         'e' : begin ch8_keyInput[6] := 1; end;
         'r' : begin ch8_keyInput[$D] := 1; end;
         'a' : begin ch8_keyInput[7] := 1; end;
         's' : begin ch8_keyInput[8] := 1; end;
         'd' : begin ch8_keyInput[9] := 1; end;
         'f' : begin ch8_keyInput[$E] := 1; end;
         'z' : begin ch8_keyInput[$A] := 1; end;
         'x' : begin ch8_keyInput[0] := 1; end;
         'c' : begin ch8_keyInput[$B] := 1; end;
         'v' : begin ch8_keyInput[$F] := 1; end;
        end;
      end;
      }

  // get next opcode
  opcode := (ch8_memory[ch8_programCounter] << 8) or (ch8_memory[ch8_programCounter + 1]);
  debug( 'opcode : ' + hexStr( opcode, 4 ));

  // decode opcode
  case (opcode and $F000) of
       $0000 :
          begin
            if ( opcode = $00EE ) then // return from function
            begin
             debug( 'return from function' );
             ch8_stackPointer:= ch8_stackPointer - 1;
             ch8_programCounter:= ch8_stack[ch8_stackPointer];
            end;

            if ( opcode = $00E0 ) then // clear the screen
            begin
             debug( 'clear screen' );
             for counter:= 0 to (64*32)-1 do
               ch8_graphicBuffer[counter] := 0;
             ch8_programCounter := ch8_programCounter + 2;
             ch8_drawFlag := true;
            end;
          end;

       $1000 : // jump to Address NNN
         begin
           tempNumWord:= (opcode and $0FFF);
           debug( 'Jump to Address ' + hexStr( tempNumWord, 4 ));
           ch8_programCounter := tempNumWord;
         end;

       $2000 : // Call Subfunction at Address
         begin
           tempNumWord:= (opcode and $0FFF);
           debug( 'Call Subfunction at Address ' + hexStr( tempNumWord, 4 ));
           ch8_stack[ch8_stackPointer] := ch8_programCounter+2;
           ch8_stackPointer := ch8_stackPointer + 1;
           ch8_programCounter := tempNumWord;
         end;

       $3000: // Skips the next instruction if VX equals NN.
         begin
           debug('Skips the next instruction if VX equal NN.');
           x:= (opcode and $0F00) >> 8;
           tempNum := (opcode and $00FF);
           if ( ch8_dataregister[x] = tempNum ) then
             ch8_programCounter := ch8_programCounter + 4
           else
             ch8_programCounter := ch8_programCounter + 2;
         end;

       $4000: // Skips the next instruction if VX doesn't equal NN.
         begin
           debug('Skips the next instruction if VX doesnt equal NN.');
           x:= (opcode and $0F00) >> 8;
           tempNum := (opcode and $00FF);
           if ( ch8_dataregister[x] <> tempNum ) then
             ch8_programCounter := ch8_programCounter + 4
           else
             ch8_programCounter := ch8_programCounter + 2;
         end;

       $5000:
         begin
           debug('Skips the next instruction if VX equals VY');
           x:= (opcode and $0F00) >> 8;
           y:= (opcode and $00F0) >> 4;
           if ( ch8_dataregister[x] = ch8_dataregister[y] ) then
             ch8_programCounter := ch8_programCounter + 4
           else
             ch8_programCounter := ch8_programCounter + 2;
         end;

       $6000 :
         begin // set VX to NN
           regNum := (opcode and $0F00) >> 8;
           debug( 'Set VF[' + IntToStr(regNum) + '] = ' + IntToStr(opcode and $00FF));
           ch8_dataregister[regNum] := (opcode and $00FF);
           ch8_programCounter := ch8_programCounter + 2;
         end;
       $7000:
         begin
           debug('Adds NN to VX. (Carry flag is not changed)');
           x:= (opcode and $0F00) >> 8;
           tempNum := (opcode and $00FF);
           ch8_dataregister[x] := ch8_dataregister[x] + tempNum;
           ch8_programCounter := ch8_programCounter + 2;
         end;

       $8000:
         begin
           if ( opcode and $000F) = $0 then // Sets VX to the value of VY.
           begin
            debug ('Sets VX to the value of VY.' );
            x:= (opcode and $0F00) >> 8;
            y:= (opcode and $00F0) >> 4;
            ch8_dataregister[x] := ch8_dataregister[y];
            ch8_programCounter := ch8_programCounter + 2;
           end;

           if ( opcode and $000F) = $1 then // Sets VX to VX or VY. (Bitwise OR operation)
           begin
            debug( 'Sets VX to VX OR VY' );
            x:= (opcode and $0F00) >> 8;
            y:= (opcode and $00F0) >> 4;
            ch8_dataregister[x] := ch8_dataregister[x] or ch8_dataregister[y];
            ch8_programCounter := ch8_programCounter + 2;
           end;

           if ( opcode and $000F) = $2 then // Sets VX to VX and VY. (Bitwise AND operation)
           begin
            debug( 'Sets VX to VX AND VY');
            x:= (opcode and $0F00) >> 8;
            y:= (opcode and $00F0) >> 4;
            ch8_dataregister[x] := ch8_dataregister[x] and ch8_dataregister[y];
            ch8_programCounter := ch8_programCounter + 2;
           end;

           if ( opcode and $000F) = $3 then // Sets VX to VX xor VY.
           begin
            debug( 'Sets VX to VX XOR VY' );
            x:= (opcode and $0F00) >> 8;
            y:= (opcode and $00F0) >> 4;
            ch8_dataregister[x] := ch8_dataregister[x] xor ch8_dataregister[y];
            ch8_programCounter := ch8_programCounter + 2;
           end;

           if ( opcode and $000F) = $4 then // Adds VY to VX. VF is set to 1 when there's a carry

             begin
              debug ('VX = VY + VX' );
              x:= (opcode and $0F00) >> 8;
              y:= (opcode and $00F0) >> 4;

              if x + y > 255 then
                 ch8_dataRegister[$F] := 1
              else
               ch8_dataRegister[$F] := 0;

              ch8_dataRegister[x] := ch8_dataRegister[x] + ch8_dataRegister[y];
              ch8_programCounter := ch8_programCounter + 2;
             end;

           if ( opcode and $0005 ) = $5 then // VY is subtracted from VX. VF is set to 0 when there's a borrow, and 1 when there isn't
           begin
            debug( 'VX - VY' );
            x:= (opcode and $0F00) >> 8;
            y:= (opcode and $00F0) >> 4;

            if ch8_dataregister[y] > ch8_dataregister[x] then
              ch8_dataregister[$F] := 0
            else
              ch8_dataregister[$F] := 1;

            ch8_dataregister[x] := ch8_dataregister[x] - ch8_dataregister[y];
            ch8_programCounter := ch8_programCounter + 2;
           end;

           if ( opcode and $000F) = $6 then // Set Vx = Vx SHL 1
           begin
            debug( 'Set Vx = Vx SHR 1' );
            x:= (opcode and $0F00) >> 8;
            y:= (opcode and $00F0) >> 4;
            ch8_dataregister[$F] := ch8_dataregister[x] and $1;
            ch8_dataregister[x ] := ch8_dataregister[x] >> 1;
            ch8_programCounter := ch8_programCounter + 2;
           end;

           if ( opcode and $0005 ) = $7 then // Sets VX to VY minus VX. VF is set to 0 when there's a borrow, and 1 when there isn't
           begin
            debug( 'VY - VX' );
            x:= (opcode and $0F00) >> 8;
            y:= (opcode and $00F0) >> 4;

            if ch8_dataregister[x] > ch8_dataregister[y] then
              ch8_dataregister[$F] := 0
            else
              ch8_dataregister[$F] := 1;

            ch8_dataregister[x] := ch8_dataregister[y] - ch8_dataregister[x];
            ch8_programCounter := ch8_programCounter + 2;
           end;


           if ( opcode and $000F) = $E then // Set Vx = Vx SHL 1
           begin
            debug( 'Set Vx = Vx SHL 1' );
            x:= (opcode and $0F00) >> 8;
            y:= (opcode and $00F0) >> 4;
            ch8_dataregister[$F] := ch8_dataregister[x] >> 7;
            ch8_dataregister[x ] := ch8_dataregister[x] << 1;
            ch8_programCounter := ch8_programCounter + 2;
           end;
        end;

       $9000:   // Skips the next instruction if VX not equals VY
         begin
           debug('Skips the next instruction if VX not equals VY');
           x:= (opcode and $0F00) >> 8;
           y:= (opcode and $00F0) >> 4;
           if ( ch8_dataregister[x] <> ch8_dataregister[y] ) then
             ch8_programCounter := ch8_programCounter + 4
           else
             ch8_programCounter := ch8_programCounter + 2;
         end;


       $A000 : // Set I to Address NNN
         begin
           debug( 'Set I to Address NNN' );
           ch8_addressregister:= (opcode and $0FFF);
           ch8_programCounter := ch8_programCounter + 2;
         end;

       $B000: // Jumps to the address NNN plus V0.
         begin
           tempNumWord:= (opcode and $0FFF);
           debug( 'Jump to Address ' + hexStr( tempNumWord, 4 ) + hexStr(ch8_dataregister[0],4));
           ch8_programCounter := tempNumWord + ch8_dataRegister[0];
         end;

       $C000 : // Sets VX to the result of a bitwise and operation on a random number (Typically: 0 to 255) and NN.
         begin
           debug ('Sets VX to the result of a bitwise and operation on a random number and NN' );
           x := (opcode and $0F00) >> 8;
           tempNum := opcode and $00FF;
           ch8_dataregister[x] := random(254) and tempNum;
           ch8_programCounter := ch8_programCounter + 2;
         end;

       $D000:
         begin // draw sprite at XYN
           x := ch8_dataregister[(opcode and $0F00) >> 8];
           y := ch8_dataregister[(opcode and $00F0) >> 4];
           spriteHeight := opcode and $000F;
           ch8_dataregister[$F] := 0;

           for yline:= 0 to spriteHeight-1 do
           begin
             pixel := ch8_memory[ch8_addressregister + yline];

             for xline := 0 to 7 do
             begin
               if ( pixel and ($80 >> xline )) <> 0 then
               begin
                if ch8_graphicBuffer[(x + xline + ((y + yline) * 64))] = 1 then
                   ch8_dataregister[$F] := 1;
                ch8_graphicBuffer[x + xline + ((y + yline) * 64)] := ch8_graphicBuffer[x + xline + ((y + yline) * 64)] xor 1
               end;
             end;
           end;

           ch8_drawFlag:= true;
           ch8_programCounter := ch8_programCounter + 2;
         end;

       $E000:
         begin
           if ( opcode and $00FF ) = $9E  then // Skips the next instruction if the key stored in VX is pressed
           begin
                debug( 'skip if button ' + hexStr(x,2) + ' is pressed - todo' );
                x:= (opcode and $0F00) >> 8;

                if ch8_keyInput[ ch8_dataregister[x] ] = 1 then
                   ch8_programCounter := ch8_programCounter + 4
                else
                  ch8_programCounter := ch8_programCounter + 2
           end;

           if ( opcode and $00FF ) = $A1  then  // Skips the next instruction if the key stored in VX isn't pressed
           begin
                if ch8_keyInput[ ch8_dataregister[x] ] = 0 then
                   ch8_programCounter := ch8_programCounter + 4
                else
                  ch8_programCounter := ch8_programCounter + 2
           end;
         end;

       $F000:
         begin
           if (opcode and $00FF) = $1E then   // I +=Vx	Adds VX to I
           begin
            debug( 'Add VX to I' );
            tempNum := (opcode and $0F00) >> 8;
            ch8_addressregister:= ch8_addressregister + ch8_dataregister[tempnum];
            ch8_programCounter := ch8_programCounter + 2;
           end;

           if (opcode and $00FF) = $65 then  // Fills V0 to VX (including VX) with values from memory starting at address I.
           begin
            tempNum := (opcode and $0F00) >> 8;
            debug( 'Fill from I into V0 to V' + IntToStr(tempNum) );
            for count:=0 to tempNum do
            begin
              ch8_dataregister[count] := ch8_memory[ch8_addressregister + count];
            end;
            ch8_programCounter := ch8_programCounter + 2;
           end;

           if (opcode and $00FF) = $55 then  // Stores V0 to VX (including VX) in memory starting at address I.
           begin
            tempNum := (opcode and $0F00) >> 8;
            debug( 'Store in memory at I from V0 to V' + IntToStr(tempNum) );
            for count:=0 to tempNum do
            begin
              ch8_memory[ch8_addressregister + count] := ch8_dataregister[count];
            end;
            ch8_programCounter := ch8_programCounter + 2;
           end;

           if (opcode and $00FF) = $33 then   // set_BCD(Vx)
           begin
            tempNum := (opcode and $0F00) >> 8;
            ch8_memory[ch8_addressregister+0] := ch8_dataregister[tempNum] div 100;
            ch8_memory[ch8_addressregister+1] := (ch8_dataregister[tempNum] div 10) mod 10;
            ch8_memory[ch8_addressregister+2] := (ch8_dataregister[tempNum] mod 100) mod 10;
            ch8_programCounter := ch8_programCounter + 2;
           end;

           if (opcode and $00FF) = $15 then   // Sets the delay timer to VX.
           begin
             x:= (opcode and $0F00) >> 8;
             ch8_delayTimer:= ch8_dataregister[x];
             ch8_programCounter := ch8_programCounter + 2;
           end;

           if (opcode and $00FF ) = $07 then   // Sets VX to the value of the delay timer
           begin
             x:= (opcode and $0F00) >> 8;
             ch8_dataregister[x] := ch8_delayTimer;
             ch8_programCounter := ch8_programCounter + 2;
           end;

           if (opcode and $00FF) = $18 then  // Sets the sound timer to VX.
           begin
             x:= (opcode and $0F00) >> 8;
             ch8_soundTimer := ch8_dataregister[x];
             ch8_programCounter := ch8_programCounter + 2;
           end;

           if (opcode and $00FF ) = $29 then //Sets I to the location of the sprite for the character in VX
           begin
             x:= (opcode and $0F00) >> 8;
             ch8_addressregister:= (ch8_dataregister[x]*5);
             ch8_programCounter := ch8_programCounter + 2;
           end;

           if (opcode and $00FF ) = $0A then // block until a keypress is given in VX
           begin
             debug( 'need to block for a keypress' );
             x:= (opcode and $0F00) >> 8;

             for count:= 0 to $F do
             begin
               if  ch8_keyInput[count] = 1 then
               begin
                 ch8_dataregister[x] := count;
                 ch8_programCounter := ch8_programCounter + 2;
                 Break;
               end;
             end;

           end;
         end;
       otherwise
         debug( 'Unknown opcode' );
  end;

  // update timers
  if ch8_delayTimer > 0 then
    ch8_delayTimer := ch8_delayTimer - 1;

  if ch8_soundTimer > 0 then
  begin
    ch8_soundTimer := ch8_soundTimer - 1;
    debug( 'beep!!' );
  end;

  // draw ?
  if ch8_drawFlag = true then
  begin
   ClearScreen(0);
   drawGraphics;
   Flip();
   ch8_drawFlag := false;
  end;

  doCycle := true;
end;

procedure init(width, height: integer );
begin
    ThreadSetCPU(ThreadGetCurrent,CPU_ID_3);
    FramebufferDevice:=FramebufferDeviceGetDefault;
    if FramebufferDevice <> nil then
     begin
      FramebufferDeviceGetProperties(FramebufferDevice,@FramebufferProperties);
      FramebufferDeviceRelease(FramebufferDevice);
      Sleep(1000);
      FramebufferProperties.Depth:=8;
      FramebufferProperties.PhysicalWidth:=width;
      FramebufferProperties.PhysicalHeight:=height;
      FramebufferProperties.VirtualWidth:=FramebufferProperties.PhysicalWidth;
      FramebufferProperties.VirtualHeight:=FramebufferProperties.PhysicalHeight * 2;
      FramebufferDeviceAllocate(FramebufferDevice,@FramebufferProperties);
      Sleep(1000);
      FramebufferDeviceSetPalette(FramebufferDevice,@GBPalette);
      FramebufferDeviceGetProperties(FramebufferDevice,@FramebufferProperties);
      BufferStart:=Pointer(FramebufferProperties.Address);
      PageSize:=FramebufferProperties.Pitch * FramebufferProperties.PhysicalHeight;
      CurrentPage:=0;
     end;
end;


procedure loadFile( fileName : string);
var
  romFile : File of Byte;
  count : integer;
begin
  AssignFile( romFile, fileName);
  Reset( romFile );
  debug( 'File Size: ' + IntToStr(FileSize(romFile)));
  setLength(romData, FileSize(romFile));

  for count := 0 to FileSize(romFile)-1 do
  begin
    Read(romFile, ch8_memory[512 + count]);
  end;

  CloseFile(romFile);

  // load text font in memory
  for count:= 0 to 79 do
  begin
    ch8_memory[count] :=  textFont[count];
  end;

  // reset
  randomize;
  ch8_programCounter := 0;
  ch8_delayTimer := 0;
  ch8_soundTimer := 0;
  ch8_stackPointer := 0;
  ch8_programCounter := $200;
  ch8_addressregister:= 0;
  keyPressed := '';

  for count:= 0 to $F do
    ch8_dataregister[count] := 0;
    ch8_keyInput[count] := 0;

  for count:= 0 to (64*32)-1 do
    ch8_graphicBuffer[count] := 0;

  drawGraphics();

//  visualDebug();
end;

begin

 while not DirectoryExists('C:\') do
   begin
    {Sleep for a second}
    Sleep(1000);
   end;

 init(320,240);

 loadFile( 'c:\pong.ch8' );

 while true do
   doCycle();
 
 ThreadHalt(0);
end.
