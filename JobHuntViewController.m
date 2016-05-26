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

#import "JobHuntViewController.h"

#import "JobHuntRenderLoop.h"
#import "JobHuntRenderer.h"

@interface JobHuntViewController ()<JobHuntRendererDelegate> {
  GVRCardboardView *_cardboardView;
  JobHuntRenderer *_JobHuntRenderer;
  JobHuntRenderLoop *_renderLoop;
}
@end

@implementation JobHuntViewController

- (void)loadView {
  _JobHuntRenderer = [[JobHuntRenderer alloc] init];
  _JobHuntRenderer.delegate = self;

  _cardboardView = [[GVRCardboardView alloc] initWithFrame:CGRectZero];
  _cardboardView.delegate = _JobHuntRenderer;
  _cardboardView.autoresizingMask =
      UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

  _cardboardView.vrModeEnabled = YES;

  // Use double-tap gesture to toggle between VR and magic window mode.
  UITapGestureRecognizer *doubleTapGesture =
      [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didDoubleTapView:)];
  doubleTapGesture.numberOfTapsRequired = 2;
  [_cardboardView addGestureRecognizer:doubleTapGesture];

  self.view = _cardboardView;
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];

  _renderLoop = [[JobHuntRenderLoop alloc] initWithRenderTarget:_cardboardView
                                                            selector:@selector(render)];
}

- (void)viewDidDisappear:(BOOL)animated {
  [super viewDidDisappear:animated];

  // Invalidate the render loop so that it removes the strong reference to cardboardView.
  [_renderLoop invalidate];
  _renderLoop = nil;
}

#pragma mark - JobHuntRendererDelegate

- (void)shouldPauseRenderLoop:(BOOL)pause {
  _renderLoop.paused = pause;
}

#pragma mark - Implementation

- (void)didDoubleTapView:(id)sender {
  _cardboardView.vrModeEnabled = !_cardboardView.vrModeEnabled;
}

@end
