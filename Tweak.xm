#import <IOSurface/IOSurface.h>
#import <QuartzCore/QuartzCore.h>
#import <QuartzCore/CAFilter.h>
#import <SpringBoard/SpringBoard.h>
#import <SpringBoard/SBFolderSlidingView.h>
#import <SpringBoard/SBUIController.h>

UIView *blurView = nil;
UIView *upperBlurView = nil;
UIView *lowerBlurView = nil;
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

		[upperBlurView removeFromSuperview];
		[upperBlurView release];
		upperBlurView = nil;

		[lowerBlurView removeFromSuperview];
		[lowerBlurView release];
		lowerBlurView = nil;
	};

	if (animated) {
		[UIView animateWithDuration:0.25f animations:^{
			blurView.alpha = 0;
			upperBlurView.alpha = 0;
			lowerBlurView.alpha = 0;
		} completion:^(BOOL finished) {
			completionHandler();
		}];
	} else {
		completionHandler();
	}
}

%hook SBIconController
- (void)openFolder:(id)folder animated:(BOOL)animated {
	%orig;

	// i have no fucking idea why, but folderCount is initially -1.
	if (folderCount == -1) {
		folderCount = 0;
	}

	folderCount++;

	if (folderCount != 1) {
		return;
	}

	SBWallpaperView *wallpaperView = ((SBUIController *)[%c(SBUIController) sharedInstance]).wallpaperView;

	SBFolderSlidingView *upperSlidingView = MSHookIvar<SBFolderSlidingView *>(self, "_upperSlidingView");
	SBWallpaperView *upperWallpaperView = MSHookIvar<SBWallpaperView *>(upperSlidingView, "_wallpaperView");

	SBFolderSlidingView *lowerSlidingView = MSHookIvar<SBFolderSlidingView *>(self, "_lowerSlidingView");
	SBWallpaperView *lowerWallpaperView = MSHookIvar<SBWallpaperView *>(lowerSlidingView, "_wallpaperView");

	if (!filter) {
		filter = [[CAFilter alloc] initWithType:@"gaussianBlur"];
		[filter setValue:[NSNumber numberWithFloat:5.0f] forKey:@"inputRadius"];
	}

	if (!blurView) {
		blurView = [[UIImageView alloc] initWithImage:wallpaperView.image];

		blurView.layer.filters = [NSArray arrayWithObject:filter];
		blurView.layer.shouldRasterize = YES;
		blurView.userInteractionEnabled = NO;
	}

	[wallpaperView insertSubview:blurView atIndex:0];

	if (!upperBlurView) {
		upperBlurView = [[UIImageView alloc] initWithImage:upperWallpaperView.image];

		upperBlurView.layer.filters = [NSArray arrayWithObject:filter];
		upperBlurView.layer.shouldRasterize = YES;
		upperBlurView.userInteractionEnabled = NO;
	}

	[upperWallpaperView insertSubview:upperBlurView atIndex:0];

	if (!lowerBlurView) {
		lowerBlurView = [[UIImageView alloc] initWithImage:lowerWallpaperView.image];

		lowerBlurView.layer.filters = [NSArray arrayWithObject:filter];
		lowerBlurView.layer.shouldRasterize = YES;
		lowerBlurView.userInteractionEnabled = NO;
	}

	[lowerWallpaperView insertSubview:lowerBlurView atIndex:0];

	if (animated) {
		blurView.alpha = 0;
		upperBlurView.alpha = 0;
		lowerBlurView.alpha = 0;

		[UIView animateWithDuration:0.25f animations:^{
			blurView.alpha = 1;
			upperBlurView.alpha = 1;
			lowerBlurView.alpha = 1;
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
