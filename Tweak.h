@interface SBStatusBarStateAggregator : NSObject
+(id)sharedInstance;
-(BOOL)_setItem:(int)arg1 enabled:(BOOL)arg2;
-(void)updateStatusBarItem:(int)arg1;
@end

@interface UIStatusBarItem : NSObject
+(id)itemWithType:(int)arg1 idiom:(long long)arg2;
@end
