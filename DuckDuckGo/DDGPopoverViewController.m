//
//  DDGPopoverViewController.m
//  Popover
//
//  Created by Johnnie Walker on 07/05/2013.
//  Copyright (c) 2013 Random Sequence. All rights reserved.
//

#import "DDGPopoverViewController.h"

@interface DDGPopoverBackgroundView : UIView
@property (nonatomic, strong) UIImage *backgroundImage;
@property (nonatomic, strong) UIImage *arrowImage;
@property (nonatomic) CGRect arrowRect;
@end

@implementation DDGPopoverBackgroundView

- (void)drawRect:(CGRect)rect {
    NSLog(@"drawing popover background in %@  with self.frame: %@ and arrowrect: %@",
          NSStringFromCGRect(rect), NSStringFromCGRect(self.frame), NSStringFromCGRect(self.arrowRect));
    [self.backgroundImage drawInRect:rect];
    [self.arrowImage drawInRect:self.arrowRect blendMode:kCGBlendModeNormal alpha:1.0];
}

@end

@interface DDGPopoverViewController ()
@property (nonatomic, strong, readwrite) UIViewController *contentViewController;
@property (nonatomic) UIEdgeInsets edgeInsets;
@property (nonatomic, strong) DDGPopoverBackgroundView *backgroundView;
@property (nonatomic, strong) UIImage* upArrowImage;
@end

@implementation DDGPopoverViewController

- (id)initWithContentViewController:(UIViewController *)viewController
{
    NSParameterAssert(nil != viewController);
    
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.contentViewController = viewController;
        self.edgeInsets = UIEdgeInsetsMake(12.0, 12.0, 12.0, 12.0);
    }
    return self;
}

- (void)loadView {
    self.upArrowImage = [UIImage imageNamed:@"popover-indicator"];
    self.backgroundView = [[DDGPopoverBackgroundView alloc] initWithFrame:CGRectZero];
    self.backgroundView.backgroundColor = [UIColor clearColor];
    self.backgroundView.backgroundImage = [[UIImage imageNamed:@"popover-frame"] resizableImageWithCapInsets:self.edgeInsets];
    self.view = [UIView new];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    self.view.opaque = NO;
    [self.view addSubview:self.backgroundView];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    [self.delegate popoverControllerDidDismissPopover:self];
    
    [self dismissPopoverAnimated:(duration > 0.0)];
}

- (void)presentPopoverFromRect:(CGRect)originRect inView:(UIView *)originView permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections animated:(BOOL)animated
{
    CGSize contentSize = self.contentViewController.preferredContentSize;
    CGRect contentBounds = CGRectMake(0, 0, contentSize.width, contentSize.height);
    
    UIEdgeInsets insets = self.edgeInsets;
    UIEdgeInsets inverseInsets = UIEdgeInsetsMake(-insets.top, -insets.left, -insets.bottom, -insets.right);
    
    CGRect outsetRect = UIEdgeInsetsInsetRect(contentBounds, inverseInsets);
    outsetRect.origin = CGPointZero;
    
    self.view.bounds = outsetRect;
    
    CGRect bounds = originView.bounds;
    CGRect frame = self.view.frame;
    
    frame.size.width = MIN(frame.size.width, bounds.size.width);
    
    frame = CGRectMake(originRect.origin.x + (originRect.size.width / 2.0) - (outsetRect.size.width/2.0),
                       originRect.origin.y + originRect.size.height,
                       frame.size.width,
                       frame.size.height);
    frame = CGRectIntegral(frame);
    frame.origin.x = MAX(bounds.origin.x, frame.origin.x);
    if (frame.origin.x + frame.size.width > bounds.origin.x + bounds.size.width) {
        frame.origin.x = bounds.origin.x + bounds.size.width - frame.size.width;
    }

    UIViewController *rootViewController = originView.window.rootViewController;    
    CGRect backgroundRect = [rootViewController.view convertRect:frame fromView:originView];
    self.view.frame = rootViewController.view.frame; // the containing frame should cover the entire root view
    
    UIView *contentView = self.contentViewController.view;
    contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    contentView.opaque = NO;
    
    [self addChildViewController:self.contentViewController]; // calls [childViewController willMoveToParentViewController:self]
    [self.view addSubview:contentView];
    [self.contentViewController didMoveToParentViewController:self];

    self.view.alpha = 0.0;
    self.view.layer.shouldRasterize = YES;
    self.view.layer.rasterizationScale = [[UIScreen mainScreen] scale];
    
    [rootViewController addChildViewController:self];
    [rootViewController.view addSubview:self.view];
    
    [self didMoveToParentViewController:rootViewController];
    
    originRect = [self.view convertRect:originRect fromView:originView];
    
    UIPopoverArrowDirection arrowDir = UIPopoverArrowDirectionUp;
    
    // if the popover thing is off of the screen and flipping the Y coordinates will
    // bring it fully back on-screen, then do so.
    if(arrowDirections & UIPopoverArrowDirectionUp && backgroundRect.origin.y + backgroundRect.size.height <= self.view.frame.size.height) {
        // the arrow can point up and has enough room to do so... the current rect is acceptable
        arrowDir = UIPopoverArrowDirectionUp;
    } else if(arrowDirections & UIPopoverArrowDirectionDown) { // backgroundRect.origin.y - originRect.size.height - backgroundRect.size.height > 0
        // the arrow can point down.  We may not have room for it to do so, but we'll do it anyway because there wasn't room or the option to point up
        backgroundRect.origin.y -= originRect.size.height + backgroundRect.size.height;
        arrowDir = UIPopoverArrowDirectionDown;
    }
    contentView.frame = UIEdgeInsetsInsetRect(backgroundRect, insets);
    
    self.backgroundView.frame = backgroundRect; // the popover frame image should be placed around the content
    
    CGSize arrowSize = self.upArrowImage.size;
    
    switch(arrowDir) {
        case UIPopoverArrowDirectionDown:
            self.backgroundView.arrowRect = CGRectMake(originRect.origin.x - backgroundRect.origin.x + (originRect.size.width/2.0) - (arrowSize.width / 2.0),
                                                       backgroundRect.size.height - arrowSize.height,
                                                       arrowSize.width,
                                                       arrowSize.height);
            self.backgroundView.arrowImage = [UIImage imageWithCGImage:self.upArrowImage.CGImage scale:self.upArrowImage.scale orientation:UIImageOrientationUpMirrored];
            NSLog(@"flipping arrow image");
            break;
        case UIPopoverArrowDirectionUp:
        default:
            self.backgroundView.arrowRect = CGRectMake(originRect.origin.x - backgroundRect.origin.x + (originRect.size.width/2.0) - (arrowSize.width / 2.0),
                                                       0,
                                                       arrowSize.width,
                                                       arrowSize.height);
            self.backgroundView.arrowImage = self.upArrowImage;
            break;
    }
    
    NSTimeInterval duration = animated ? 0.4 : 0.0;
    [UIView animateWithDuration:duration
                     animations:^{
                         self.view.alpha = 1.0;
                     } completion:^(BOOL finished) {
                         self.view.layer.shouldRasterize = NO;
                     }];
}

- (void)dismissPopoverAnimated:(BOOL)animated {
    NSTimeInterval duration = animated ? 0.2 : 0.0;
    
    self.view.layer.shouldRasterize = YES;
    self.view.layer.rasterizationScale = [[UIScreen mainScreen] scale];
    
    [UIView animateWithDuration:duration
                     animations:^{
                         self.view.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self willMoveToParentViewController:nil];
        [self.view removeFromSuperview];
        [self removeFromParentViewController];
        
        [self.contentViewController willMoveToParentViewController:nil];
        [self.contentViewController.view removeFromSuperview];
        [self.contentViewController removeFromParentViewController]; // calls [childViewController didMoveToParentViewController:nil]        
    }];
}

-(void)dismissViewControllerAnimated:(BOOL)animated completion:(void (^)(void))completion
{
    NSTimeInterval duration = animated ? 0.2 : 0.0;
    
    self.view.layer.shouldRasterize = YES;
    self.view.layer.rasterizationScale = [[UIScreen mainScreen] scale];
    
    [UIView animateWithDuration:duration
                     animations:^{
                         self.view.alpha = 0.0;
                     } completion:^(BOOL finished) {
                         [self willMoveToParentViewController:nil];
                         [self.view removeFromSuperview];
                         [self removeFromParentViewController];
                         
                         [self.contentViewController willMoveToParentViewController:nil];
                         [self.contentViewController.view removeFromSuperview];
                         [self.contentViewController removeFromParentViewController]; // calls [childViewController didMoveToParentViewController:nil]
                         
                         if(completion!=NULL) completion();
                     }];

}


-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self dismissPopoverAnimated:TRUE];
}


@end
