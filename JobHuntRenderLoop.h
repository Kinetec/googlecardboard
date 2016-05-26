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

#import <UIKit/UIKit.h>

@interface JobHuntRenderLoop : NSObject

/**
 * Initializes the render loop with target and selector. The underlying |CADisplayLink| instance
 * holds a strong reference to the target until the |invalidate| method is called.
 */
- (instancetype)initWithRenderTarget:(id)target selector:(SEL)selector;

/**
 * Invalidates this instance and the underlying |CADisplayLink| instance releases its strong
 * reference to the render target.
 */
- (void)invalidate;

/** Sets or returns the paused state of the underlying |CADisplayLink| reference. */
@property(nonatomic) BOOL paused;

@end

