//
//  JKLLockScreenViewController.h
//  JKLib
//
//  @date   2015. 03. 25.
//  @author Choi JoongKwan
//  @email  joongkwan.choi@gmail.com
//  @brief  Lock Screen View Controller class
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, LockScreenMode) {
    LockScreenModeNormal = 0,
    LockScreenModeNew,
    LockScreenModeChange,
    LockScreenModeTurnOff,
};

@protocol JKLLockScreenViewControllerDelegate;
@protocol JKLLockScreenViewControllerDataSource;

@interface JKLLockScreenViewController : UIViewController

@property (nonatomic, assign) LockScreenMode lockScreenMode;
@property (nonatomic, weak) IBOutlet id<JKLLockScreenViewControllerDelegate> delegate;
@property (nonatomic, weak) IBOutlet id<JKLLockScreenViewControllerDataSource> dataSource;

@property (nonatomic, strong) UIColor *tintColor;

@property (nonatomic, strong) UIColor *titleColor;

@end

@protocol JKLLockScreenViewControllerDelegate <NSObject>
@optional
- (void)unlockWasSuccessfulLockScreenViewController:(JKLLockScreenViewController *)lockScreenViewController pincode:(NSString *)pincode;    // support for number
- (void)unlockWasSuccessfulLockScreenViewController:(JKLLockScreenViewController *)lockScreenViewController;                                // support for touch id
- (void)unlockWasCancelledLockScreenViewController:(JKLLockScreenViewController *)lockScreenViewController;
- (void)unlockWasFailureLockScreenViewController:(JKLLockScreenViewController *)lockScreenViewController;
@end

@protocol JKLLockScreenViewControllerDataSource <NSObject>
@required
- (BOOL)lockScreenViewController:(JKLLockScreenViewController *)lockScreenViewController pincode:(NSString *)pincode;
@optional
- (BOOL)allowTouchIDLockScreenViewController:(JKLLockScreenViewController *)lockScreenViewController;
@end
