#import "SocketSessionViewController.h"

@interface SocketSessionViewController ()
@property (weak, nonatomic) IBOutlet UITextField *idTextField;
@property (weak, nonatomic) IBOutlet UIView *sessionView;
@property (strong, nonatomic) NSMutableArray *messages;
@property (weak, nonatomic) IBOutlet UITextView *returnedDataTextField;

- (IBAction)joinSessionButtonAction:(id)sender;

@end


NSInputStream *inputStream;
NSOutputStream *outputStream;

@implementation SocketSessionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initNetworkCommunication];
    _messages = [[NSMutableArray alloc]init];
    self.returnedDataTextField.text = @"";
}

- (void)initNetworkCommunication {
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocketToHost(NULL, (CFStringRef)@"localhost", 85, &readStream, &writeStream);
    
    inputStream = (__bridge NSInputStream *)readStream;
    outputStream = (__bridge NSOutputStream *)writeStream;
    
    [inputStream setDelegate:self];
    [outputStream setDelegate:self];
    
    
    [inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    [inputStream open];
    [outputStream open];
}

- (IBAction)joinSessionButtonAction:(id)sender {
    NSString *response = [NSString stringWithFormat:@"connect:%@",self.idTextField.text];
    NSData *data = [[NSData alloc]initWithData:[response dataUsingEncoding:NSASCIIStringEncoding]];
    [outputStream write:[data bytes] maxLength:[data length]];
    
    self.returnedDataTextField.text = @"";
}

-(void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent {
    
    switch (streamEvent) {
            
        case NSStreamEventOpenCompleted:
            NSLog(@"Stream opened");
            break;
            
        case NSStreamEventHasBytesAvailable:
            if (theStream == inputStream) {
                
                uint8_t buffer[1024];
                int len;
                
                while ([inputStream hasBytesAvailable]) {
                    len = [inputStream read:buffer maxLength:sizeof(buffer)];
                    if (len > 0) {
                        
                        NSString *output = [[NSString alloc] initWithBytes:buffer length:len encoding:NSASCIIStringEncoding];
                        
                        if (nil != output) {
                            NSLog(@"server said: %@", output);
                            [self messageRevieved:output];
                        }
                    }
                }
            }
            break;
            
        case NSStreamEventErrorOccurred:
            NSLog(@"Can not connect to the host!");
            break;
            
        case NSStreamEventEndEncountered:
            break;
            
        default:
            NSLog(@"Unknown event");
    }
    
}

-(void)messageRevieved:(NSString *)message {
    
    NSMutableString *messagesString = [NSMutableString stringWithString:self.returnedDataTextField.text];
    [messagesString appendString:message];
    self.returnedDataTextField.text = messagesString;
    self.returnedDataTextField.contentOffset = CGPointMake(0, self.returnedDataTextField.contentSize.height - self.returnedDataTextField.frame.size.height);
}

@end
