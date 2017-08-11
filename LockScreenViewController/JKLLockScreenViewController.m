//
//  JKLLockScreenViewController.m
//

#import "JKLLockScreenViewController.h"

#import "JKLLockScreenPincodeView.h"
#import "JKLLockScreenNumber.h"

#import <AudioToolbox/AudioToolbox.h>
#import <LocalAuthentication/LocalAuthentication.h>

static const NSTimeInterval LSVSwipeAnimationDuration = 0.3f;
static const NSTimeInterval LSVDismissWaitingDuration = 0.4f;
static const NSTimeInterval LSVShakeAnimationDuration = 0.5f;
static const NSTimeInterval LSVUpdateViewAnimationDuration = 1.0f;


typedef NS_ENUM(NSInteger, LockScreenInternalMode) {
    LockScreenInternalModeUnknown = -1,
    LockScreenInternalModeNormal = 0,
    LockScreenInternalModeNewPincode,
    LockScreenInternalModeNewPincodeVerification,
    LockScreenInternalModeChangeOldPincode,
    LockScreenInternalModeChangeNewPincode,
    LockScreenInternalModeChangeNewPincodeVerification,
    LockScreenInternalModeTurnOff,
};


@interface JKLLockScreenViewController()<JKLLockScreenPincodeViewDelegate> {
    NSString * _confirmPincode;
}
@property (nonatomic, assign) LockScreenInternalMode lockScreenInternalMode;
@property (nonatomic, weak) IBOutlet UILabel  * titleLabel;
@property (nonatomic, weak) IBOutlet UILabel  * subtitleLabel;
@property (nonatomic, weak) IBOutlet UIButton * cancelButton;
@property (weak, nonatomic) IBOutlet UIButton * deleteButton;
@property (strong, nonatomic) IBOutletCollection(JKLLockScreenNumber) NSArray *numberButtons;

@property (nonatomic, weak) IBOutlet JKLLockScreenPincodeView * pincodeView;

@end


@implementation JKLLockScreenViewController

- (LockScreenInternalMode)internalModeForExternalMode:(LockScreenMode)mode{
    if(mode==LockScreenModeNormal){
        return LockScreenInternalModeNormal;
    }
    else if(mode==LockScreenModeNew){
        return LockScreenInternalModeNewPincode;
    }
    else if(mode==LockScreenModeChange){
        return LockScreenInternalModeChangeOldPincode;
    }
    else if(mode==LockScreenModeTurnOff){
        return LockScreenInternalModeTurnOff;
    }
    return LockScreenInternalModeUnknown;
}

- (void)setLockScreenInternalModeInitial{
    _lockScreenInternalMode = [self internalModeForExternalMode:_lockScreenMode];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setLockScreenInternalModeInitial];

    [self updateViewForMode];
    
    if (_tintColor){
        [self tintSubviewsWithColor:_tintColor];
    }
    
    if(_titleColor){
        [self tintTitleSubviewsWithColor:_titleColor];
    }
}

- (void)updateViewForMode{

    switch (_lockScreenInternalMode) {
            
        case LockScreenInternalModeNormal: {
            [_cancelButton setHidden:YES];
            [self lsv_updateTitle:NSLocalizedString(@"Enter Passcode",   nil)
                         subtitle:NSLocalizedString(@"Enter your passcode", nil)];
        }
            break;
            
        case LockScreenInternalModeTurnOff: {
            [self lsv_updateTitle:NSLocalizedString(@"Enter Passcode",   nil)
                         subtitle:NSLocalizedString(@"Enter your passcode", nil)];
        }
            break;

        case LockScreenInternalModeNewPincode: {
            [self lsv_updateTitle:NSLocalizedString(@"Set Passcode",  nil)
                         subtitle:NSLocalizedString(@"Enter a passcode", nil)];
        }
            break;
            
        case LockScreenInternalModeNewPincodeVerification: {
            [self lsv_updateTitle:NSLocalizedString(@"Set Passcode",  nil)
                             subtitle:NSLocalizedString(@"Verify your new passcode", nil)];
            break;
        }
            
        case LockScreenInternalModeChangeOldPincode:{
            [self lsv_updateTitle:NSLocalizedString(@"Change Passcode", nil)
                             subtitle:NSLocalizedString(@"Enter your old passcode", nil)];
        }
            break;
            
        case LockScreenInternalModeChangeNewPincode:{
            [self lsv_updateTitle:NSLocalizedString(@"Change Passcode", nil)
                         subtitle:NSLocalizedString(@"Enter your new passcode", nil)];
        }
            break;
            
        case LockScreenInternalModeChangeNewPincodeVerification:{
            [self lsv_updateTitle:NSLocalizedString(@"Change Passcode", nil)
                         subtitle:NSLocalizedString(@"Verify your new passcode", nil)];
        }
            break;
            
        default:
            break;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    BOOL isModeNormal = (_lockScreenInternalMode == LockScreenInternalModeNormal || _lockScreenInternalMode == LockScreenInternalModeTurnOff);
    if (isModeNormal && [_delegate respondsToSelector:@selector(allowTouchIDLockScreenViewController:)]) {
        if ([_dataSource allowTouchIDLockScreenViewController:self]) {
            [self lsv_policyDeviceOwnerAuthentication];
        }
    }
}

/**
 *  Changes buttons tint color
 *
 *  @param color tint color for buttons
 */
- (void)tintSubviewsWithColor: (UIColor *) color{
    [_cancelButton setTitleColor:color forState:UIControlStateNormal];
    [_deleteButton setTitleColor:color forState:UIControlStateNormal];
    [_pincodeView setPincodeColor:color];
    
    for (JKLLockScreenNumber * number in _numberButtons)
    {
        [number setTintColor:color];
    }
}

- (void)tintTitleSubviewsWithColor: (UIColor *) color{
    [_titleLabel setTextColor:color];
    [_subtitleLabel setTextColor:color];
    for (JKLLockScreenNumber * number in _numberButtons)
    {
        [number setTitleColor:color forState:UIControlStateNormal];
    }
}

- (void)lsv_policyDeviceOwnerAuthentication {
    
    NSError   * error   = nil;
    LAContext * context = [[LAContext alloc] init];
    
    // check if the policy can be evaluated
    if ([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error]) {
        // evaluate
        [context evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
                localizedReason:NSLocalizedString(@"Press Home to Unlock", nil)
                          reply:^(BOOL success, NSError * authenticationError) {
                              if (success) {
                                  [self lsv_unlockDelayDismissViewController:LSVDismissWaitingDuration];
                              }
                              else {
                                  NSLog(@"LAContext::Authentication Error : %@", authenticationError);
                              }
                          }];
    }
    else {
        NSLog(@"LAContext::Policy Error : %@", [error localizedDescription]);
    }
    
}


- (void)lsv_unlockDelayDismissViewController:(NSTimeInterval)delay {
    __weak id weakSelf = self;
    
    [_pincodeView wasCompleted];
    
    dispatch_time_t delayInSeconds = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC));
    dispatch_after(delayInSeconds, dispatch_get_main_queue(), ^(void){
        [self dismissViewControllerAnimated:NO completion:^{
            if ([_delegate respondsToSelector:@selector(unlockWasSuccessfulLockScreenViewController:)]) {
                [_delegate unlockWasSuccessfulLockScreenViewController:weakSelf];
            }
        }];
    });
}

- (BOOL)isPasscodeVerification{
    return _lockScreenInternalMode==LockScreenInternalModeNewPincodeVerification || _lockScreenInternalMode==LockScreenInternalModeChangeNewPincodeVerification;
}

- (BOOL)lsv_isPincodeValid:(NSString *)pincode {
    if ([self isPasscodeVerification]) {
        return [_confirmPincode isEqualToString:pincode];
    }
    return [_dataSource lockScreenViewController:self pincode:pincode];
}

- (void)lsv_updateTitle:(NSString *)title subtitle:(NSString *)subtitle {
    [_titleLabel    setText:title];
    [_subtitleLabel setText:subtitle];
}


- (void)lsv_unlockScreenSuccessful:(NSString *)pincode {
    [self dismissViewControllerAnimated:NO completion:^{
        if ([_delegate respondsToSelector:@selector(unlockWasSuccessfulLockScreenViewController:pincode:)]) {
            [_delegate unlockWasSuccessfulLockScreenViewController:self pincode:pincode];
        }
    }];
}


- (void)lsv_unlockScreenFailure {
    if ([self isPasscodeVerification] == NO) {
        if ([_delegate respondsToSelector:@selector(unlockWasFailureLockScreenViewController:)]) {
            [_delegate unlockWasFailureLockScreenViewController:self];
        }
    }
    
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    
    // make shake animation
    CAAnimation * shake = [self lsv_makeShakeAnimation];
    [_pincodeView.layer addAnimation:shake forKey:@"shake"];
    [_pincodeView setEnabled:NO];
    
    if ([self isPasscodeVerification]) {
        [_subtitleLabel setText:NSLocalizedString(@"Passcodes did not match. Try again.",  nil)];
    }
    else{
        [_subtitleLabel setText:NSLocalizedString(@"Incorrect passcode",  nil)];
    }
   
    dispatch_time_t delayInSeconds = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(LSVShakeAnimationDuration * NSEC_PER_SEC));
    dispatch_after(delayInSeconds, dispatch_get_main_queue(), ^(void){
        [_pincodeView setEnabled:YES];
        [_pincodeView initPincode];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(LSVUpdateViewAnimationDuration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void){
            [self updateViewForMode];
        });
    });
}


- (CAAnimation *)lsv_makeShakeAnimation {
    
    CAKeyframeAnimation * shake = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.x"];
    [shake setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
    [shake setDuration:LSVShakeAnimationDuration];
    [shake setValues:@[ @(-20), @(20), @(-20), @(20), @(-10), @(10), @(-5), @(5), @(0) ]];
    
    return shake;
}

- (void)lsv_swipeSubtitleAndPincodeView {
    
    __weak UIView * weakView = self.view;
    __weak UIView * weakCode = _pincodeView;
    
    [(id)weakCode setEnabled:NO];
    
    CGFloat width = CGRectGetWidth([self view].bounds);
    NSLayoutConstraint * centerX = [self lsv_findLayoutConstraint:weakView  childView:_subtitleLabel attribute:NSLayoutAttributeCenterX];
    
    centerX.constant = width;
    [UIView animateWithDuration:LSVSwipeAnimationDuration animations:^{
        [weakView layoutIfNeeded];
    } completion:^(BOOL finished) {
        
        [(id)weakCode initPincode];
        centerX.constant = -width;
        [weakView layoutIfNeeded];
        
        centerX.constant = 0;
        [UIView animateWithDuration:LSVSwipeAnimationDuration animations:^{
            [weakView layoutIfNeeded];
        } completion:^(BOOL finished) {
            [(id)weakCode setEnabled:YES];
        }];
    }];
}

#pragma mark -
#pragma mark NSLayoutConstraint
- (NSLayoutConstraint *)lsv_findLayoutConstraint:(UIView *)superview childView:(UIView *)childView attribute:(NSLayoutAttribute)attribute {
    for (NSLayoutConstraint * constraint in superview.constraints) {
        if (constraint.firstItem == superview && constraint.secondItem == childView && constraint.firstAttribute == attribute) {
            return constraint;
        }
    }
    
    return nil;
}

#pragma mark -
#pragma mark IBAction
- (IBAction)onNumberClicked:(id)sender {
    
    NSInteger number = [sender tag];
    [_pincodeView appendingPincode:[@(number) description]];
}

- (IBAction)onCancelClicked:(id)sender {
    
    if ([_delegate respondsToSelector:@selector(unlockWasCancelledLockScreenViewController:)]) {
        [_delegate unlockWasCancelledLockScreenViewController:self];
    }
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)onDeleteClicked:(id)sender {
    
    [_pincodeView removeLastPincode];
}

#pragma mark -
#pragma mark JKLLockScreenPincodeViewDelegate
- (void)lockScreenPincodeView:(JKLLockScreenPincodeView *)lockScreenPincodeView pincode:(NSString *)pincode {
    
    switch (_lockScreenInternalMode) {
            
        case LockScreenInternalModeNormal:
        case LockScreenInternalModeTurnOff:{
            if ([self lsv_isPincodeValid:pincode]) {
                [self lsv_unlockScreenSuccessful:pincode];
            }
            else {
                [self lsv_unlockScreenFailure];
            }
        }
            break;
            
        case LockScreenInternalModeNewPincode: {
            _confirmPincode = pincode;
            _lockScreenInternalMode = LockScreenInternalModeNewPincodeVerification;
            [self updateViewForMode];
            [self lsv_swipeSubtitleAndPincodeView];
        }
            break;
            
        case LockScreenInternalModeChangeNewPincodeVerification:
        case LockScreenInternalModeNewPincodeVerification: {
            if ([self lsv_isPincodeValid:pincode]) {
                [self lsv_unlockScreenSuccessful:pincode];
            }
            else {
                [self lsv_unlockScreenFailure];
                [self setLockScreenInternalModeInitial];
            }
            break;
        }
            
        case LockScreenInternalModeChangeOldPincode:{
            if ([self lsv_isPincodeValid:pincode]) {
                _lockScreenInternalMode = LockScreenInternalModeChangeNewPincode;
                [self updateViewForMode];
                [self lsv_swipeSubtitleAndPincodeView];
            }
            else {
                [self lsv_unlockScreenFailure];
                [self setLockScreenInternalModeInitial];
            }
        }
            break;
            
        case LockScreenInternalModeChangeNewPincode:{
            _confirmPincode = pincode;
            _lockScreenInternalMode = LockScreenInternalModeChangeNewPincodeVerification;
            [self updateViewForMode];
            [self lsv_swipeSubtitleAndPincodeView];
        }
            break;
            
        default:
            break;
            
    }

}

#pragma mark - 
#pragma mark LockScreenViewController Orientation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation{
    return YES;
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
}

- (BOOL)prefersStatusBarHidden{
    return YES;
}

- (UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleDefault;
}

@end
