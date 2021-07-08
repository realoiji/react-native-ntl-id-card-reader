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
    
    int i;

    NSString *CM_MOI_AID = @"A000000054480001"; // normal
    NSString *CM_MOI5_AID = @"A000000054480005"; // ข้อมูลทะเบียนบ้านปัจจุบัน
    NSString *CM_NHSO_AID = @"A000000054480083"; // สิทธิรักษาพยาบาล
    NSString *CM_ADM_AID = @"A000000084060002"; //
    NSString *CM_BIO_AID = @"A000000054480084";

    NSString *CM_SELECT = @"00A4040008";
    NSString *CM_SELECTED = [CM_SELECT stringByAppendingString:CM_MOI_AID]; //
    NSString *CM_MOI5_SELECTED = [CM_SELECT stringByAppendingString:CM_MOI5_AID];
    NSString *CM_ADM_SELECTED = [CM_SELECT stringByAppendingString:CM_BIO_AID];

    NSString *CM_GET_RESPONSE = @"00C00000";
    NSString *CM_TH_ID = @"80B0000402000D";
    NSString *CM_TH_FULLNAME = @"80B00011020064";
    NSString *CM_EN_FULLNAME = @"80B00075020064";
    NSString *CM_DATE_OF_BIRTH = @"80B000D9020008";
    NSString *CM_GENDER = @"80B000E1020001";
    NSString *CM_REQUEST_NO = @"80B000E2020014";
    NSString *CM_CARD_ISSUE_PLACE = @"80B000F6020064";
    NSString *CM_CARD_ISSUER = @"80B0015A02000D";
    NSString *CM_ISSUE_DATE = @"80B00167020008";
    NSString *CM_EXPIRE_DATE = @"80B0016F020008";
    NSString *CM_ADDRESS = @"80B01579020064";
    NSString *CM_BP1NO = @"80B0000402000B";
    
    // NSMutableArray *istapdu = [NSMutableArray arrayWithObjects: @"00A4040008A000000054480001", @"80B0000402000D", @"80B000110200D1", @"80B01579020064", @"80B00167020012", nil];
    NSMutableArray *istapdu = [NSMutableArray arrayWithObjects: CM_SELECTED, CM_TH_ID, CM_TH_FULLNAME, CM_EN_FULLNAME, CM_DATE_OF_BIRTH, CM_GENDER, CM_REQUEST_NO, CM_CARD_ISSUE_PLACE, CM_CARD_ISSUER, CM_ISSUE_DATE, CM_EXPIRE_DATE, CM_ADDRESS, CM_MOI5_SELECTED, CM_BP1NO, nil];
    
    for (i = 0; i < [istapdu count]; i++) {
        // do something with object
        NSString *targetHex = [istapdu objectAtIndex: i];
        NSString *hexLength = [targetHex substringFromIndex: [targetHex length] - 2];
        NSData *apduData =[self hexFromString:[istapdu objectAtIndex: i]];
        [apduData getBytes:capdu length:apduData.length];
        capdulen = (unsigned int)[apduData length];
    
        // NSLog (@"istapdu = %@", [istapdu objectAtIndex: i]);
        // NSLog (@"bb apduData = %@", apduData);
        // NSLog (@"bb capdulen = %i", capdulen);
        // NSLog (@"bb i = %d", i);
        // NSLog (@"bb targetHex = %@", targetHex);
        // NSLog (@"bb hexLength = %@", hexLength);
        
        //3.send data
        SCARD_IO_REQUEST pioSendPci;
        iRet = SCardTransmit(gContxtHandle, &pioSendPci, (unsigned char*)capdu, capdulen, NULL, resp, &resplen);
        // NSLog (@"bb iRet = %i", iRet);

        if (iRet != 0) {

        } else {
            if (i != 0 && i != 12) {
                NSString *hexResponse = [CM_GET_RESPONSE stringByAppendingString:hexLength];
                NSData *readapduData =[self hexFromString:hexResponse];
                [readapduData getBytes:capdu length:readapduData.length];
                capdulen = (unsigned int)[readapduData length];

                unsigned char readData[2048 + 128];
                memset(readData, 0, 2048 + 128);
                unsigned int readDatalen = sizeof(resp);

//                NSLog (@"bb hexResponse = %@", hexResponse);
//                NSLog (@"bb readapduData = %@", readapduData);

                SCARD_IO_REQUEST pioSendPci;
                LONG iRet2 = SCardTransmit(gContxtHandle, &pioSendPci, (unsigned char*)capdu, capdulen, NULL, readData, &readDatalen);
//                NSString *dataShow = [NSString stringWithFormat:@"%s", readData];
//                NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISOLatinThai);
//                NSString *unicode = [NSString stringWithFormat:@"%s", readData];
//                NSString *standard = [unicode stringByReplacingOccurrencesOfString:@"ê" withString:@""];
//                NSData *data = [standard dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
//                NSData *data = [standard dataUsingEncoding:enc  allowLossyConversion:YES];
                
                NSData *data = [NSData dataWithBytes:readData length:readDatalen ];
                NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISOLatinThai);
                NSString *dataShow = [[NSString alloc] initWithData:data encoding:enc];
                
//                dataShow = [dataShow stringByReplacingOccurrencesOfString:@"\u0000" withString:@""];
//                dataShow = [dataShow stringByReplacingOccurrencesOfString:@"NUL"  withString:@""];
//                dataShow = [dataShow stringByReplacingOccurrencesOfString:@"#"  withString:@" "];
//                dataShow = [dataShow stringByReplacingOccurrencesOfString:@"  "  withString:@" "];
                if (targetHex == CM_CARD_ISSUE_PLACE) {
                    dataShow = [dataShow stringByReplacingOccurrencesOfString:@"/"  withString:@" "];
                }
                // NSLog (@"bb dataShow = %@", dataShow);

                [idCardArray addObject:(dataShow)];
            }
        }
        // NSLog (@"bb =========");
    }
    // NSLog (@"bb :: sendCommand = %i", _isCardConnect);
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
