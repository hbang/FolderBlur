#import <IOSurface/IOSurface.h>
#import <QuartzCore/QuartzCore.h>
#import <QuartzCore/CAFilter.h>
#import <SpringBoard/SpringBoard.h>
#import <SpringBoard/SBUIController.h>

UIView *blurView = nil;
CAFilter *filter = nil;
int folderCount = 0;

void HBWBFolderClosed(BOOL animated) {
	folderCount--;

	if (folderCount != 0) {
		return;
	}

	void (^completionHandler)(void) = ^{
		[blurView removeFromSuperview];
		[blurView release];
		blurView = nil;
	};

	if (animated) {
		[UIView animateWithDuration:0.25f animations:^{
			blurView.alpha = 0;
		} completion:^(BOOL finished) {
			completionHandler();
		}];
	} else {
		completionHandler();
	}
}

%hook SBIconController
- (void)openFolder:(id)folder animated:(BOOL)animated {
	// i have no fucking idea why, but folderCount is initially -1.
	if (folderCount == -1) {
		folderCount = 0;
	}

	folderCount++;

	if (folderCount != 1) {
		%orig;
		return;
	}

	SBWallpaperView *wallpaperView = ((SBUIController *)[%c(SBUIController) sharedInstance]).wallpaperView;
	//SBFolderSlidingView *upperSlidingView = MSHookIvar<SBFolderSlidingView *>(self, "_upperSlidingView");
	//SBFolderSlidingView *lowerSlidingView = MSHookIvar<SBFolderSlidingView *>(self, "_lowerSlidingView");
	//SBFolderSlidingView *upper = MSHookIvar<SBFolderSlidingView *>(self, "_upperSlidingView");
	//SBFolderSlidingView *lower = MSHookIvar<SBFolderSlidingView *>(self, "_lowerSlidingView");

	if (!blurView) {
		blurView = [[UIImageView alloc] initWithImage:wallpaperView.image];

		if (!filter) {
			filter = [[CAFilter alloc] initWithType:@"gaussianBlur"];
			[filter setValue:[NSNumber numberWithFloat:5.0f] forKey:@"inputRadius"];
		}

		blurView.layer.filters = [NSArray arrayWithObject:filter];
		blurView.layer.shouldRasterize = YES;
		blurView.userInteractionEnabled = NO;
	}

	[wallpaperView insertSubview:blurView atIndex:0];

	if (animated) {
		blurView.alpha = 0;
	}

	%orig;

	if (animated) {
		[UIView animateWithDuration:0.25f animations:^{
			blurView.alpha = 1;
		}];
	}
}

- (void)closeFolderAnimated:(BOOL)animated {
	%orig;

	HBWBFolderClosed(animated);
}

- (void)dealloc {
	[filter release];

	%orig;
}
%end

%group HBWBFolderEnhancer
%hook FEFolderWrapperView
- (void)dismiss:(BOOL)something {
	%orig;

	HBWBFolderClosed(YES);
}
%end
%end

%ctor {
	%init;

	if (%c(FEFolderWrapperView)) {
		%init(HBWBFolderEnhancer);
	}
}
