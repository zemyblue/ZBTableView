//
//  ZBTableFetchView.m
//  ZBTableView
//
//  Created by zemyblue on 2014. 11. 4..
//  Copyright (c) 2014년 zemyblue. All rights reserved.
//

#import "ZBTableFetchView.h"

@interface ZBTableFetchView ()
@property (nonatomic, strong) UIView *messageView;
@property (nonatomic, strong) UIButton *retryButton;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) UILabel *mainMessage;
@property (nonatomic, strong) UIView *lineView;
@property (nonatomic, strong) UIImageView *bottomLine;
@property (nonatomic, assign) CGFloat adjustY;
@property (nonatomic, strong) UIView *noMoreView;
@end


@interface NSDateFormatter (ZBListLoadView)
+ (NSDateFormatter *)localizedDateFormatter;
@end


@implementation ZBTableFetchView

- (id)initWithFrame:(CGRect)rect
{
    self = [super initWithFrame:rect];
    
    if (self) {
        UIView *messageView = [[UIView alloc] initWithFrame:self.bounds];
        [messageView setBackgroundColor:[UIColor clearColor]];
        [messageView setAutoresizingMask:(UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight)];
        [self addSubview:messageView];
        [self setMessageView:messageView];
        
        NSString *retryTitle = NSLocalizedString(@"Check network and retry", nil);
        UIFont *retryTitleFont = [UIFont systemFontOfSize:13.f];
        
        UIButton *sButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [sButton setFrame:messageView.bounds];
        [sButton setTitle:retryTitle forState:(UIControlStateNormal)];
//        [sButton setImage:retryImage forState:UIControlStateNormal];
        [sButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        [sButton.titleLabel setFont:retryTitleFont];
//        [sButton setTitleEdgeInsets:(UIEdgeInsetsMake(0, -(retryImage.size.width + 3), 0, (retryImage.size.width + 3)))];
//        [sButton setImageEdgeInsets:(UIEdgeInsetsMake(0, (retryTitleSize.width + 4), 0, -(retryTitleSize.width + 4)))];
        [sButton addTarget:self action:@selector(retryButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.messageView addSubview:sButton];
        [self setRetryButton:sButton];
        [self.retryButton setHidden:YES];
        
        UIActivityIndicatorView *activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [activityIndicatorView setCenter:CGPointMake(CGRectGetWidth(self.messageView.frame) / 2.f, CGRectGetHeight(self.messageView.frame) / 2.f)];
        [activityIndicatorView setAutoresizingMask:(UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleBottomMargin)];
        [activityIndicatorView setHidesWhenStopped:YES];
        [self.messageView addSubview:activityIndicatorView];
        [self setActivityIndicator:activityIndicatorView];
        
        UILabel *sLabel = [[UILabel alloc] initWithFrame:self.messageView.bounds];
        [sLabel setAutoresizingMask:(UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight)];
        [sLabel setBackgroundColor:[UIColor clearColor]];
        [sLabel setFont:retryTitleFont];
        [sLabel setTextColor:[UIColor grayColor]];
        [sLabel setTextAlignment:NSTextAlignmentCenter];
        [self.messageView addSubview:sLabel];
        [self setMainMessage:sLabel];
        
        [self setEnableSeparator:YES];
        
        [self adjustState:ZBTableFetchViewLoadStateNormal];
        
        [self setBackgroundColor:[UIColor clearColor]];
    }
    
    return self;
}


- (id)initWithHeaderWithFrame:(CGRect)rect
{
    self = [self initWithFrame:rect];
    if (self) {
        [self setAdjustY:-kZBListLoadViewHeight];
        [self setCustomViewAttachType:ZBTableFetchViewCustomAttachTypeBottom];
    }
    return self;
}


- (id)initWithFooterWithFrame:(CGRect)rect
{
    self = [self initWithFrame:rect];
    if (self) {
        [self setCustomViewAttachType:ZBTableFetchViewCustomAttachTypeTop];
    }
    return self;
}


- (void)setCustomView:(UIView *)aCustomView
{
    [self.customView removeFromSuperview];
    
    _customView = aCustomView;
    
    if (_customView) {
        [self addSubview:_customView];
    }
    
    [self adjustState:self.state];
}


- (void)setEnableSeparator:(BOOL)enableSeparator
{
    _enableSeparator = enableSeparator;
    
    [self.lineView setHidden:!_enableSeparator];
    [self.bottomLine setHidden:!_enableSeparator];
}


/* 이전 어떤 상태였든 상관없이 상태가 바로 적용되도록 한다. */
- (void)adjustState:(ZBTableFetchViewLoadState)aState
{
    _state = aState;
    
    CGRect  sRect = self.frame;
    CGFloat sCustomViewHeight = self.customView ? CGRectGetHeight(self.customView.frame) : 0;
    
    if (aState == ZBTableFetchViewLoadStateUpdating) {
        sRect.size.height = sCustomViewHeight + kZBListLoadViewHeight;
        [self.activityIndicator startAnimating];
    } else if (_state == ZBTableFetchViewLoadStateFail || _state == ZBTableFetchViewLoadStateEndFooter) {
        sRect.size.height = sCustomViewHeight + kZBListLoadViewHeight;
        if ([self.activityIndicator isAnimating]) {
            [self.activityIndicator stopAnimating];
        }
    } else {
        sRect.size.height = sCustomViewHeight;
        if ([self.activityIndicator isAnimating]) {
            [self.activityIndicator stopAnimating];
        }
    }
    
    if (self.noMoreView.superview) {
        [self.noMoreView removeFromSuperview];
    }
    
    switch (aState) {
        case ZBTableFetchViewLoadStateWait:
        {
            [self.retryButton setHidden:YES];
            [self.mainMessage setText:NSLocalizedString(@"Wait to update...", nil)];
            break;
        }
            
        case ZBTableFetchViewLoadStatePulling:
        case ZBTableFetchViewLoadStateNormal:
        {
            [self.retryButton setHidden:YES];
            [self.mainMessage setText:NSLocalizedString(@"Pull and release to update", nil)];
            break;
        }
            
        case ZBTableFetchViewLoadStateUpdating:
        {
            [self.retryButton setHidden:YES];
            [self.mainMessage setText:nil];
            break;
        }
            
        case ZBTableFetchViewLoadStateFail:
        {
            [self.retryButton setHidden:NO];
            [self.retryButton setEnabled:YES];
            [self.mainMessage setText:nil];
            break;
        }
            
        case ZBTableFetchViewLoadStateEndFooter:
        {
            [self.mainMessage setText:nil];
            
            if (self.noMoreView == nil) {
                [self setNoMoreView:[[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, kZBListLoadViewHeight)]];
            }
            [self addSubview:self.noMoreView];
            break;
        }
            
        case ZBTableFetchViewLoadStateHidden:
        {
            [self setHidden:YES];
        }
        case ZBTableFetchViewLoadStateNoSign:
        default:
        {
            [self.retryButton setHidden:YES];
            [self.mainMessage setText:nil];
            break;
        }
    }
    
    if (aState != ZBTableFetchViewLoadStateHidden && self.isHidden) {
        [self setHidden:NO];
    }
    
    [self.retryButton setEnabled:!self.retryButton.isHidden];
    [self.mainMessage setHidden:(self.mainMessage.text == nil)];
}


/* 상태값을 설정한다. 이전하고 같은 상태로 설정할 경우에는 적용되지 않는다. */
- (void)setState:(ZBTableFetchViewLoadState)state
{
    if (state != _state) {
        [self adjustState:state];
    }
}


- (void)setLastUpdateDate:(NSDate *)aLastUpdateDate
{
    BOOL sNeedReset = FALSE;
    if ((_lastUpdateDate == nil && aLastUpdateDate != nil) ||
        (_lastUpdateDate != nil && aLastUpdateDate == nil)) {
        sNeedReset = TRUE;
    }
    
    _lastUpdateDate = aLastUpdateDate;
    
    if (sNeedReset) {
        ZBTableFetchViewLoadState aState = _state;
        _state = -1;
        [self setState:aState];
    }
}


- (NSString *)lastUpdateString
{
    if (self.lastUpdateDate == nil) {
        return nil;
    }
    
    NSString *sDateString = [[NSDateFormatter localizedDateFormatter] stringFromDate:self.lastUpdateDate];
    return [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Last update time", nil), sDateString];
}


- (void)retryButtonTapped:(id)aSender
{
    if (self.retryBlock) {
        [self.retryButton setEnabled:NO];
        self.retryBlock(self);
    }
}

@end


@implementation NSDateFormatter (ZBListLoadView)

+ (NSDateFormatter *)localizedDateFormatter
{
    static NSDateFormatter *sDateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableDictionary *sComponents = [[NSLocale componentsFromLocaleIdentifier:NSLocalizedString(@"api_lang", nil)] mutableCopy];
        [sComponents setValue:[[NSCalendar currentCalendar] calendarIdentifier] forKey:@"calendar"];
        NSString *sLocaleIdentifier = [NSLocale localeIdentifierFromComponents:sComponents];
        NSLocale *sLocale = [[NSLocale alloc] initWithLocaleIdentifier:sLocaleIdentifier];
        
        sDateFormatter = [[NSDateFormatter alloc] init];
        [sDateFormatter setLocale:sLocale];
        [sDateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [sDateFormatter setTimeStyle:NSDateFormatterShortStyle];
    });
    
    return sDateFormatter;
}

@end


#pragma mark - ZBTableFetchHeaderView


@implementation ZBTableFetchHeaderView

- (void)setCustomView:(UIView *)aCustomView
{
    [super setCustomView:aCustomView];
}


- (void)setCustomViewAttachType:(ZBTableFetchViewCustomAttachType)aCustomViewAttachType
{
    [super setCustomViewAttachType:aCustomViewAttachType];
}


- (void)tableViewDidScroll:(UITableView *)aTableView
{
    if (self.customViewAttachType == ZBTableFetchViewCustomAttachTypeTop) {
        if (self.customView) {
            CGRect sRect = self.customView.frame;
            sRect.origin.y = MIN(aTableView.contentOffset.y, 0);
            [self.customView setFrame:sRect];
        }
    }
}

@end
