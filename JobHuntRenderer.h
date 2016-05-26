/////////////////////////////////////////////////////////////////
//
//  "JobHunt" A Google Cardboard/Job Search Experiment
//
//  MICHAEL LOUIS RICCA, MPS
//
//  (917) 942-0281
//
//  http://linkedin.com/in/mikericca
//
//
//  Original code from Google Cardboard SDK. Based on
//  "Treasure Hunt" example. Code Assignment excercise prepared
//  for Verizon.
//
//  CC License 2016
//
/////////////////////////////////////////////////////////////////

#import "GVRCardboardView.h"

/** JobHunt renderer delegate. */
@protocol JobHuntRendererDelegate <NSObject>
@optional

/** Called to pause the render loop because a 2D UI is overlaid on top of the renderer. */
- (void)shouldPauseRenderLoop:(BOOL)pause;

@end

/** JobHunt renderer. */
@interface JobHuntRenderer : NSObject<GVRCardboardViewDelegate>

@property(nonatomic, weak) id<JobHuntRendererDelegate> delegate;

@end

