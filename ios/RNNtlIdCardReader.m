// RNNtlIdCardReader.m

#import "RNNtlIdCardReader.h"
#import "winscard.h"
#import "ft301u.h"

//buffer    char [20]    "bR301"
//_readerName    __NSCFString *    @"FT_3481F433F880"    0x00000002835044b0
static id myobject;
SCARDCONTEXT gContxtHandle;
BOOL _autoConnect;
SCARDHANDLE gCardHandle;
NSString *gBluetoothID;
static NSString *autoConnectKey = @"autoConnect";

typedef NS_ENUM(NSInteger, FTReaderType) {
    FTReaderiR301 = 0,
    FTReaderbR301 = 1,
    FTReaderbR301BLE = 2,
    FTReaderbR500 = 3,
    FTReaderBLE = 4
};


@implementation RNNtlIdCardReader
{
    NSMutableArray *_deviceList;
    BOOL _isAutoConnect;
    BOOL _isCardConnect;
    NSMutableArray *_readers;
    NSString *_selectedReader;
    FTReaderType _readerType;
    NSString *_selectedDeviceName;
    NSInteger _itemHW;
    NSInteger _itemCountPerRow;
    NSMutableArray *_displayedItem;
    ReaderInterface *interface;
    LONG iRet;
}

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

RCT_EXPORT_MODULE();


RCT_EXPORT_METHOD(initCard)
{
    _isCardConnect = false;
    interface = [[ReaderInterface alloc] init];
    interface.delegate = self;
    @try {
        ULONG ret = SCardEstablishContext(SCARD_SCOPE_SYSTEM,NULL,NULL,&gContxtHandle);
        if(ret != 0){
            //            [[Tools shareTools] showError:[[Tools shareTools] mapErrorCode:ret]];
        }
    }  @finally {
        
    }
}


RCT_EXPORT_METHOD(initDidMount){
    //    interface = [[ReaderInterface alloc] init];
    
    //    dispatch_async(dispatch_get_global_queue(0, 0), ^{
    //        [self initReaderInterface];
    //    });
    
    //     _readerType = FTReaderbR301;
    //    _deviceList = [NSMutableArray array];
    //    _autoConnect = YES;
    
}


RCT_EXPORT_METHOD(getSN: (RCTResponseSenderBlock)callback) {
    char buffer[16] = {0};
    unsigned int length = 0;
    
    
    DWORD ret = FtGetSerialNum(gContxtHandle, &length, buffer);
    if(ret == SCARD_S_SUCCESS){
        NSData *data = [NSData dataWithBytes:buffer length:length];
        NSString *str = [NSString stringWithFormat:@"Serial Number: %@", data];
        callback(@[[NSNull null], str]);
    }
    else{
        callback(@[[NSNull null], @"error"]);
    }
}


RCT_EXPORT_METHOD(didEventCardisConnect : (RCTResponseSenderBlock)callback) {
    NSLog (@"bb :: didEventCardisConnect = %i", _isCardConnect);
    callback(@[[NSNull null], @(_isCardConnect)]);
}

RCT_EXPORT_METHOD(getInitStatus : (RCTResponseSenderBlock)callback) {
    NSLog (@"bb :: didEventCardisConnect = %i", _isCardConnect);
    LONG isValid = SCardIsValidContext(gContxtHandle);
    
    BOOL isInit = false;
    if(SCARD_S_SUCCESS == isValid){
        isInit = true;
    } else {
        isInit = false;
    }
    callback(@[@(isInit)]);
}

//RCT_EXPORT_METHOD(resetConnectCard : (RCTResponseSenderBlock)callback) {
//    _isCardConnect = false;
//    callback(@[[NSNull null], @(_isCardConnect)]);
//}


RCT_EXPORT_METHOD(connectCardReader : (RCTResponseSenderBlock)callback) {
    //    interface = [[ReaderInterface alloc] init];
    //    [interface setDelegate:self];
        
//    [self connectCard];
    
    DWORD dwActiveProtocol = -1;
    NSString *reader = @"bR301";

    LONG ret = SCardConnect(gContxtHandle, [reader UTF8String], SCARD_SHARE_SHARED,SCARD_PROTOCOL_T0 | SCARD_PROTOCOL_T1, &gCardHandle, &dwActiveProtocol);
    NSLog (@"bb :: ret = %i", ret);

    BOOL isCardConnected = false;
    if(ret == 0){
        isCardConnected = true;
    } else {
        isCardConnected = false;
    }
    callback(@[@(isCardConnected)]);
    if(ret != 0){
        //        NSString *errorMsg = [[Tools shareTools] mapErrorCode:ret];
        //        [[Tools shareTools] showError:errorMsg];
        return;
    }


    unsigned char patr[33] = {0};
    DWORD len = sizeof(patr);
    ret = SCardGetAttrib(gCardHandle,NULL, patr, &len);
    if(ret != SCARD_S_SUCCESS)
    {
        NSLog(@"SCardGetAttrib error %08x",ret);
    }
    NSLog (@"bb :: connectCard = %i", _isCardConnect);
}

RCT_EXPORT_METHOD(disconnectCardReader) {
    //    interface = [[ReaderInterface alloc] init];
    //    [interface setDelegate:self];
    NSLog (@"bb :: disconnectCardReader = %i", _isCardConnect);
    [self disconnectCard];
}

RCT_EXPORT_METHOD(statusCardReader : (RCTResponseSenderBlock)callback) {
    NSString *s = [self getReaderList];
    if(s != nil){
        callback(@[[NSNull null], s]);
    }
    else{
        callback(@[[NSNull null], @""]);
    }
}

-(void)getReaderName
{
    //    unsigned int length = 0;
    //    char buffer[20] = {0};
    //    LONG ret = FtGetReaderName(gContxtHandle, &length, buffer);
    //    if (ret != SCARD_S_SUCCESS || length == 0) {
    ////        [self showMsg:errorMsg];
    //        return;
    //    }
    //
    //    NSString *readerName = [NSString stringWithUTF8String:buffer];
    //
    //
    //    if ([readerName isEqualToString:@"bR301"]) {
    //        _readerType = FTReaderbR301;
    //
    //    }else if ([readerName isEqualToString:@"iR301"]) {
    //        _readerType = FTReaderiR301;
    //
    //    }else if ([readerName isEqualToString:@"bR301BLE"]) {
    //        _readerType = FTReaderbR301BLE;
    //
    //    }else if ([readerName isEqualToString:@"bR500"]) {
    //        _readerType = FTReaderbR500;
    //    }
    
}

RCT_EXPORT_METHOD(sendCommand: (RCTResponseSenderBlock)callback)
{
    
    NSMutableArray *idCardArray = [NSMutableArray array];
    unsigned  int capdulen;
    unsigned char capdu[2048 + 128];
    memset(capdu, 0, 2048 + 128);
    
    unsigned char resp[2048 + 128];
    memset(resp, 0, 2048 + 128);
    unsigned int resplen = sizeof(resp) ;
    
    unsigned char readPhoto[2048 + 128];
    memset(readPhoto, 0, 2048 + 128);
    unsigned int readPhotolen = sizeof(readPhoto) ;
    
    unsigned char readData[2048 + 128];
    memset(readData, 0, 2048 + 128);
    unsigned int readDatalen = sizeof(resp) ;
    
    unsigned char readData2[2048 + 128];
    memset(readData2, 0, 2048 + 128);
    unsigned int readDatalen2 = sizeof(resp) ;
    
    unsigned char readData3[2048 + 128];
    memset(readData3, 0, 2048 + 128);
    unsigned int readDatalen3 = sizeof(resp) ;
    
    unsigned char readData4[2048 + 128];
    memset(readData4, 0, 2048 + 128);
    unsigned int readDatalen4 = sizeof(resp) ;
    int i;
    NSString *rsStr;
    
    NSMutableArray *istapdu = [NSMutableArray arrayWithObjects: @"00A4040008A000000054480001", @"80B0000402000D", @"80B000110200D1", @"80B01579020064", @"80B00167020012", nil];
    
    for (i = 0; i < [istapdu count]; i++) {
        // do something with object
        NSLog (@"istapdu = %@", [istapdu objectAtIndex: i]);
        NSData *apduData =[self hexFromString:[istapdu objectAtIndex: i]];
        NSLog (@"hexFromString = %@", apduData);
        [apduData getBytes:capdu length:apduData.length];
        NSLog (@"apduData = %@", apduData);
        capdulen = (unsigned int)[apduData length];
        NSLog (@"capdulen = %i", capdulen);
        
        //3.send data
        SCARD_IO_REQUEST pioSendPci;
        iRet = SCardTransmit(gContxtHandle, &pioSendPci, (unsigned char*)capdu, capdulen, NULL, resp, &resplen);
        NSLog (@"iRet = %i", iRet);
        if (iRet != 0) {
            //            [self showMsg:[[Tools shareTools] mapErrorCode:iRet]];
            //            [self updateDeviceStatusImage:FTCardStatusError];
        }else {
            if(i == 0){
                //                [self showMsg:@"reset card"];
            }else if (i == 1){
                NSData *readapduData =[self hexFromString:@"00C000000D"];
                NSLog (@"hexFromString2 = %@", readapduData);
                [readapduData getBytes:capdu length:readapduData.length];
                NSLog (@"apduData2 = %@", readapduData);
                capdulen = (unsigned int)[readapduData length];
                NSLog (@"capdulen2 = %i", capdulen);
                
                //                [self updateDeviceStatusImage:FTCardStatusExcute];
                
                SCARD_IO_REQUEST pioSendPci;
                LONG iRet2 = SCardTransmit(gContxtHandle, &pioSendPci, (unsigned char*)capdu, capdulen, NULL, readData, &readDatalen);
                NSLog (@"CMD_CID===");
                NSMutableData *RevData2 = [NSMutableData data];
                NSLog (@"readData = %s", readData);
                NSLog (@"readDatalen = %i", readDatalen);
                NSLog (@"iRet2 = %i", iRet2);
                [RevData2 appendBytes:readData length:readDatalen];
                NSString *dataShow = [NSString stringWithFormat:@"%s", readData];
                dataShow = [dataShow stringByReplacingOccurrencesOfString:@"ê"  withString:@""];
                NSLog (@"dataShow:%@;",dataShow);
                
                rsStr =  dataShow;
                [idCardArray addObject:(dataShow)];
                
            }else if (i == 2){
                NSData *readapduData =[self hexFromString:@"00C00000D1"];
                NSLog (@"hexFromString2 = %@", readapduData);
                [readapduData getBytes:capdu length:readapduData.length];
                NSLog (@"apduData2 = %@", readapduData);
                capdulen = (unsigned int)[readapduData length];
                NSLog (@"capdulen2 = %i", capdulen);
                
                //                [self updateDeviceStatusImage:FTCardStatusExcute];
                
                SCARD_IO_REQUEST pioSendPci;
                LONG iRet2 = SCardTransmit(gContxtHandle, &pioSendPci, (unsigned char*)capdu, capdulen, NULL, readData2, &readDatalen2);
                NSLog (@"CMD_PERSON_INFO===");
                NSLog (@"readData2 = %s", readData2);
                NSLog (@"readDatalen2 = %i", readDatalen2);
                NSLog (@"iRet2 = %i", iRet2);
                NSString *dataShow = [NSString stringWithFormat:@"%s", readData2];
                dataShow = [dataShow stringByReplacingOccurrencesOfString:@"ê"
                                                               withString:@""];
                dataShow = [dataShow stringByReplacingOccurrencesOfString:@"Ó"
                                                               withString:@""];
                
                NSLog (@"dataShow:%@",dataShow);
                // rsStr =    [NSString stringWithFormat: @";%@%@", rsStr, dataShow];
                [idCardArray addObject:(dataShow)];
            }else if (i == 3){
                NSData *readapduData =[self hexFromString:@"00C0000064"];
                NSLog (@"hexFromString2 = %@", readapduData);
                [readapduData getBytes:capdu length:apduData.length];
                NSLog (@"apduData2 = %@", readapduData);
                capdulen = (unsigned int)[readapduData length];
                NSLog (@"capdulen2 = %i", capdulen);
                
                //                [self updateDeviceStatusImage:FTCardStatusExcute];
                
                SCARD_IO_REQUEST pioSendPci;
                LONG iRet2 = SCardTransmit(gContxtHandle, &pioSendPci, (unsigned char*)capdu, capdulen, NULL, readData3, &readDatalen3);
                NSLog (@"CMD_ADDRESS===");
                NSMutableData *RevData2 = [NSMutableData data];
                NSLog (@"readData3 = %s", readData3);
                NSLog (@"readDatalen3 = %i", readDatalen3);
                NSLog (@"iRet2 = %i", iRet2);
                [RevData2 appendBytes:readData3 length:readDatalen3];
                NSString *dataShow = [NSString stringWithFormat:@"%s", readData3];
                dataShow = [dataShow stringByReplacingOccurrencesOfString:@"ê"
                                                               withString:@""];
                NSLog (@"dataShow:%@",dataShow);
                //rsStr =  [NSString stringWithFormat: @";%@%@", rsStr, dataShow];
                [idCardArray addObject:(dataShow)];
                
            }else if (i == 4){
                NSData *readapduData =[self hexFromString:@"00C0000012"];
                NSLog (@"hexFromString2 = %@", readapduData);
                [readapduData getBytes:capdu length:apduData.length];
                NSLog (@"apduData2 = %@", readapduData);
                capdulen = (unsigned int)[readapduData length];
                NSLog (@"capdulen2 = %i", capdulen);
                
                //                [self updateDeviceStatusImage:FTCardStatusExcute];
                
                SCARD_IO_REQUEST pioSendPci;
                LONG iRet2 = SCardTransmit(gContxtHandle, &pioSendPci, (unsigned char*)capdu, capdulen, NULL, readData4, &readDatalen4);
                NSLog (@"CMD_CARD_ISSUE_EXPIRE===");
                NSMutableData *RevData2 = [NSMutableData data];
                NSLog (@"readData4 = %s", readData4);
                NSLog (@"readDatalen4 = %i", readDatalen4);
                NSLog (@"iRet2 = %i", iRet2);
                [RevData2 appendBytes:readData4 length:readDatalen4];
                NSString *dataShow = [NSString stringWithFormat:@"%s", readData4];
                dataShow = [dataShow stringByReplacingOccurrencesOfString:@"ê"
                                                               withString:@""];
                NSLog (@"dataShow:%@",dataShow);
                // rsStr =  [NSString stringWithFormat: @";%@%@", rsStr, dataShow];
                [idCardArray addObject:(dataShow)];
            }else{
                NSLog (@"===================");
            }
        }
        
    }
    NSLog (@"%@", rsStr);
    NSLog (@"bb :: sendCommand = %i", _isCardConnect);
    callback(@[[NSNull null],idCardArray]);
    
}


//init readerInterface and card context
- (void)initReaderInterface
{
    NSNumber *value = [[NSUserDefaults standardUserDefaults] valueForKey:autoConnectKey];
    if (value == nil) {
        _autoConnect = NO;
    }
    _autoConnect = value.boolValue;
    //    [interface setAutoPair:_autoConnect];
    //     [interface setDelegate:self];
    
    //set support device type, default support all readers;
    //    [FTDeviceType setDeviceType:(FTDEVICETYPE)(IR301_AND_BR301 | BR301BLE_AND_BR500)];
    
    ULONG ret = SCardEstablishContext(SCARD_SCOPE_SYSTEM,NULL,NULL,&gContxtHandle);
    if(ret != 0){
        //        [[Tools shareTools] showError:[[Tools shareTools] mapErrorCode:ret]];
    }
}



//status card
- (BOOL)statusCard {
    DWORD dwAtrLen, dwProt=0, dwState=0;
    DWORD dwReaderLen;
    LPSTR pcReaders;
    LONG  rv;
    dwReaderLen = 10000;
    dwAtrLen = 0;
    
    rv = SCardStatus(gContxtHandle, (LPSTR) NULL, &dwReaderLen,
                     &dwState, &dwProt, NULL, &dwAtrLen );
    NSLog(@"bb :: statusCard %i", rv);

    if ( rv == SCARD_S_SUCCESS )
    {
        return true;
    }
    else{
        NSLog(@"statusCard %08x",rv);
        return false;
    }
    
}

//connect card
- (void)connectCard {
    DWORD dwActiveProtocol = -1;
    NSString *reader = @"bR301";
    
    LONG ret = SCardConnect(gContxtHandle, [reader UTF8String], SCARD_SHARE_SHARED,SCARD_PROTOCOL_T0 | SCARD_PROTOCOL_T1, &gCardHandle, &dwActiveProtocol);
//    NSLog (@"bb :: ret = %i", ret);
    if(ret != 0){
        //        NSString *errorMsg = [[Tools shareTools] mapErrorCode:ret];
        //        [[Tools shareTools] showError:errorMsg];
        return;
    }
    
    
    unsigned char patr[33] = {0};
    DWORD len = sizeof(patr);
    ret = SCardGetAttrib(gCardHandle,NULL, patr, &len);
    if(ret != SCARD_S_SUCCESS)
    {
        NSLog(@"SCardGetAttrib error %08x",ret);
    }
    NSLog (@"bb :: connectCard = %i", _isCardConnect);
}


- (void)disconnectCard {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        SCardDisconnect(gCardHandle, SCARD_UNPOWER_CARD);
    });
    NSLog (@"bb :: disconnectCard = %i", _isCardConnect);
//    _isCardConnect = false;
}


- (NSString *)getReaderList
{
    DWORD readerLength = 0;
    LONG ret = SCardListReaders(gContxtHandle, nil, nil, &readerLength);
    if(ret != 0){
        return nil;
    }
    
    LPSTR readers = (LPSTR)malloc(readerLength * sizeof(LPSTR));
    ret = SCardListReaders(gContxtHandle, nil, readers, &readerLength);
    if(ret != 0){
        return nil;
    }
    
    return [NSString stringWithUTF8String:readers];
}

//- (BOOL) isCardAttached;

- (void)cardInterfaceDidDetach:(BOOL)attached {
    // DID METHOD WHEN PUSH CARD OR REJECT CARD
    
//    NSLog (@"bb :: isCardAttached = %i", isCardAttached);
    _isCardConnect = attached;
    NSLog (@"bb :: attached = %i", attached);
    NSLog (@"bb :: isInsertCard = %i", _isCardConnect);
    if (attached) {
        NSLog(@"card present");
        
    }else {
        NSLog(@"card not present");
    }
}

- (void)didGetBattery:(NSInteger)battery {
    
}

- (void)findPeripheralReader:(NSString *)readerName {
    NSLog([NSString stringWithFormat:@"Find Reader: %@", readerName]);
}

- (void)readerInterfaceDidChange:(BOOL)attached bluetoothID:(NSString *)bluetoothID{
    NSLog(@"readerInterfaceDidChange");
}
//    if (attached) {
//        gBluetoothID = bluetoothID;
//
//
//
//        dispatch_async(dispatch_get_global_queue(0, 0), ^{
//
//            NSString *reader = [self getReaderList];
//            if (reader.length == 0 || reader == nil) {
//                return ;
//            }
//
//            dispatch_async(dispatch_get_main_queue(), ^{
////                _readerNameLabel.text = reader;
//            });
//
//            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//
//                if (_autoConnect) {
//                    _selectedDeviceName = [self getReaderList];
//                }  });
//        });
//    }else {
//        dispatch_async(dispatch_get_main_queue(), ^{
////            _readerNameLabel.text = @"No reader detected";
//        });
//    }
//}


-(NSData *)hexFromString:(NSString *)cmd
{
    NSData *cmdData = nil;
    char *pbDest = NULL;
    unsigned int length = 0;
    
    char h1,h2;
    unsigned char s1,s2;
    pbDest = malloc(cmd.length/2 + 1);
    for (int i=0; i<[cmd length]/2; i++)
    {
        
        h1 = [cmd characterAtIndex:2*i];
        h2 = [cmd characterAtIndex:2*i+1];
        
        s1 = toupper(h1) - 0x30;
        if (s1 > 9)
            s1 -= 7;
        
        s2 = toupper(h2) - 0x30;
        if (s2 > 9)
            s2 -= 7;
        
        pbDest[i] = s1*16 + s2;
        length++;
    }
    
    cmdData = [NSData dataWithBytes:pbDest length:length];
    return cmdData;
}
@end
