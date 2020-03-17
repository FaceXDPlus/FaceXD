#import <GLKit/GLKit.h>
#import <UIKit/UIKit.h>

@interface ViewController : GLKViewController<GLKViewControllerDelegate,UITextFieldDelegate>


@end

const int constFps = 30;
float timeInOneFps = 1000.0f/constFps;
UInt64 lastRecordTime = 0;


int socketTag = 0;
