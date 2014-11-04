//
//  ZBTableView.m
//  ZBTableView
//
//  Created by zemyblue on 2014. 10. 19..
//  Copyright (c) 2014년 zemyblue. All rights reserved.
//

#import "ZBTableView.h"
#import "ZBTableFetchView.h"


typedef NS_ENUM(NSUInteger, ZBTableViewFetchState) {
    ZBTableViewFetchStateNormal,
    ZBTableViewFetchStateFetchRecent,
    ZBTableViewFetchStateFetchMore
};


NSString *const kContentOffset = @"contentOffset";


static void *ZBTableViewContentOffsetContext = &ZBTableViewContentOffsetContext;


@interface ZBTableView ()
@property (nonatomic, strong) ZBTableFetchView *fetchHeaderView;
@property (nonatomic, strong) ZBTableFetchView *fetchFooterView;
@property (nonatomic, strong) UIView *noDataView;
@property (nonatomic, assign) ZBTableViewFetchState fetchState;
@property (nonatomic, assign) BOOL checkingContentOffset; ///< contentOffset을 Observe로 수신해서 이벤트를 처리중일 경우에는 self.contentOffset으로 데이터를 변경하더라도 Observing 처리하지 않도록 사용한다.
@property (nonatomic, assign, getter = isFetching) BOOL fetching;
@property (nonatomic, assign) BOOL disableFetchMore; ///< fetch more를 못하도록 막을 경우 YES
@property (nonatomic, assign) CGFloat edgeInsetTop;
@property (nonatomic, assign) CGFloat edgeInsetBottom;
@end


@implementation ZBTableView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setShowsNoDataViewIfNeeded:YES];
        [self setContentOffsetWhenLoaded:(CGPointZero)];
    }
    return self;
}


- (void)dealloc
{
    [self setDelegate:nil];
    [self setDataSource:nil];
    [self removeObserver:self forKeyPath:kContentOffset];
}

- (void)removeFromSuperview
{
    [self setDelegate:nil];
    [self setDataSource:nil];
    [super removeFromSuperview];
}


#pragma mark - private


/// 데이터가 없을 때 데이터 없음을 표시하는 view를 생성해서 보여준다.
- (void)showNoDataView
{
    if (![self isShowsNoDataViewIfNeeded]) {
        return;
    }
    
    if (self.noDataView && [[self subviews] containsObject:self.noDataView]) {
        return;
    }
    
    if (!self.noDataView && self.makeNoDataView) {
        [self setNoDataView:self.makeNoDataView()];
    }
    
    [self addSubview:self.noDataView];
}


- (void)adjustContentInsets:(BOOL)animated
{
    UIEdgeInsets edgeInsets = UIEdgeInsetsMake(self.edgeInsetTop, 0, self.edgeInsetBottom, 0);
    if (animated) {
        __weak typeof(self) weakSelf = self;
        [UIView animateWithDuration:0.25f animations:^{
            [weakSelf setContentInset:edgeInsets];
        }];
    }
    else {
        [self setContentInset:edgeInsets];
    }
}


#pragma mark - set/get method Overwrite


- (void)adjustFetchHeaderViewFrame
{
    CGRect sFrame = self.fetchHeaderView.frame;
    if (self.sticksHeaderToTop && self.tableHeaderView) {
        sFrame.origin.y = self.tableHeaderView.frame.size.height - kZBListLoadViewHeight;
    }
    else {
        sFrame.origin.y = -kZBListLoadViewHeight;
    }
    [self.fetchHeaderView setFrame:sFrame];
}


- (void)adjustFetchFooterViewFrame
{
    CGRect sFrame = self.fetchFooterView.frame;
    if (self.sticksFooterToBottom && self.tableFooterView) {
        sFrame.origin.y = self.contentSize.height - self.tableFooterView.frame.size.height;
    }
    else {
        sFrame.origin.y = self.contentSize.height;
    }
    [self.fetchFooterView setFrame:sFrame];
}


- (void)setTableHeaderView:(UIView *)aTableHeaderView
{
    [super setTableHeaderView:aTableHeaderView];
    
    [self adjustFetchHeaderViewFrame];
}


- (void)setTableFooterView:(UIView *)aTableFooterView
{
    [super setTableFooterView:aTableFooterView];
    
    [self adjustFetchFooterViewFrame];
}


- (void)setFetchHeaderView:(ZBTableFetchView *)aFetchHeaderView
{
    [self addSubview:aFetchHeaderView];
    _fetchHeaderView = aFetchHeaderView;
    
    [self adjustFetchHeaderViewFrame];
}


- (void)setFetchFooterView:(ZBTableFetchView *)aFetchFooterView
{
    [self addSubview:aFetchFooterView];
    _fetchFooterView = aFetchFooterView;
    
    [self adjustFetchFooterViewFrame];
}


- (void)setDataSource:(id<ZBTableViewDataSource>)dataSource
{
    [super setDataSource:(id<UITableViewDataSource>)dataSource];
    
    BOOL isAttachFetchView = NO;
    if ([dataSource respondsToSelector:@selector(fetchRecentWithCompletion:)]) {
        [self setFetchHeaderView:[[ZBTableFetchView alloc] initWithHeaderWithFrame:CGRectMake(0, 0, self.frame.size.width, kZBListLoadViewHeight)]];
        [self setContentInset:UIEdgeInsetsMake(0, 0, self.edgeInsetBottom, 0)];
        [self.fetchHeaderView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        
        isAttachFetchView = YES;
    }
    
    if ([dataSource respondsToSelector:@selector(fetchMoreWithCompletion:)]) {
        [self setFetchFooterView:[[ZBTableFetchView alloc] initWithFooterWithFrame:CGRectMake(0, 0, self.frame.size.width, kZBListLoadViewHeight)]];
        [self.fetchFooterView setState:ZBTableFetchViewLoadStateHidden];
        [self.fetchFooterView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        
        isAttachFetchView = YES;
    }
    
    if (isAttachFetchView) {
        [self addObserver:self forKeyPath:kContentOffset options:NSKeyValueObservingOptionNew context:ZBTableViewContentOffsetContext];
    }
}


- (id<ZBTableViewDataSource>)dataSource
{
    return (id<ZBTableViewDataSource>)[super dataSource];
}


- (void)setSticksFooterToBottom:(BOOL)aSticksFooterToBottom
{
    _sticksFooterToBottom = aSticksFooterToBottom;
    if (self.fetchFooterView) {
        self.fetchFooterView.customViewAttachType = (aSticksFooterToBottom ? ZBTableFetchViewCustomAttachTypeBottom : ZBTableFetchViewCustomAttachTypeNoAttach);
    }
}


- (void)setSticksHeaderToTop:(BOOL)aSticksHeaderToTop
{
    _sticksHeaderToTop = aSticksHeaderToTop;
    
    [self adjustFetchHeaderViewFrame];
}


- (void)setLoadedOldestData:(BOOL)aLoadedOldestData
{
    if (_loadedOldestData == aLoadedOldestData) {
        return;
    }
    
    _loadedOldestData = aLoadedOldestData;
    
    if (_loadedOldestData) {
        [self setDisableFetchMore:YES];
        [self.fetchFooterView setState:ZBTableFetchViewLoadStateEndFooter];
        
        [self adjustFetchFooterViewFrame];
        [self setEdgeInsetBottom:kZBListLoadViewHeight animated:YES];
    }
    else {
        [self setDisableFetchMore:NO];
        [self.fetchFooterView setState:ZBTableFetchViewLoadStateHidden];
        
        [self adjustFetchFooterViewFrame];
        [self setEdgeInsetBottom:0 animated:YES];
    }
}


- (void)setEdgeInsetTop:(CGFloat)edgeInsetTop animated:(BOOL)animated
{
    if (self.edgeInsetTop == edgeInsetTop) {
        return;
    }
    
    [self setEdgeInsetTop:edgeInsetTop];
    
    [self adjustContentInsets:animated];
}


- (void)setEdgeInsetBottom:(CGFloat)edgeInsetBottom animated:(BOOL)animated
{
    if (self.edgeInsetBottom == edgeInsetBottom) {
        return;
    }
    
    [self setEdgeInsetBottom:edgeInsetBottom];
    
    [self adjustContentInsets:animated];
}


#pragma mark - overwrite method


- (int)totalRowCount
{
    int cellCount = 0;
    for (int i=0; i<[self numberOfSections]; ++i) {
        cellCount += [self numberOfRowsInSection:i];
    }
    return cellCount;
}


- (void)checkHasData
{
    int cellCount = [self totalRowCount];
    
    if (self.makeNoDataView) {
        if (cellCount == 0) {
            if (self.fetchState == ZBTableViewFetchStateNormal) {
                [self showNoDataView];
            }
        }
        else if (self.noDataView && [[self subviews] containsObject:self.noDataView]) {
            [self.noDataView removeFromSuperview];
            [self setNoDataView:nil];
        }
    }
    
    // 출력하는 데이터가 없을 경우에는 fetch more를 할 수 없도록 한다.
    [self setDisableFetchMore:(cellCount == 0)];
    
    // fetchFooter의 위치를 재조절한다.
    if (self.fetchFooterView) {
        [self adjustFetchFooterViewFrame];
    }
}


- (void)reloadData
{
    [super reloadData];
    
    if (self.fetchHeaderView) {
        CGFloat sOffsetY = self.contentOffset.y;
        if (self.sticksHeaderToTop && self.tableHeaderView && sOffsetY < 0) {
            CGRect sFrame = self.tableHeaderView.frame;
            sFrame.origin.y = sOffsetY;
            [self.tableHeaderView setFrame:sFrame];
        }
    }
    
    if (self.fetchFooterView && !self.disableFetchMore) {
        CGFloat sOffsetY = self.contentOffset.y;
        CGFloat sMaxOffsetY = MAX(self.contentSize.height - self.frame.size.height, 0);
        if (self.sticksFooterToBottom && self.tableFooterView && sOffsetY > sMaxOffsetY) {
            CGRect sFrame = self.tableFooterView.frame;
            sFrame.origin.y = (sOffsetY - sMaxOffsetY) + (self.contentSize.height - self.tableFooterView.frame.size.height);
            [self.tableFooterView setFrame:sFrame];
        }
    }
    
    [self checkHasData];
}


- (void)endUpdates
{
    [super endUpdates];
    
    if (self.fetchHeaderView) {
        CGFloat sOffsetY = self.contentOffset.y;
        if (self.sticksHeaderToTop && self.tableHeaderView && sOffsetY < 0) {
            CGRect sFrame = self.tableHeaderView.frame;
            sFrame.origin.y = sOffsetY;
            [self.tableHeaderView setFrame:sFrame];
        }
    }
    
    if (self.fetchFooterView && !self.disableFetchMore) {
        CGFloat sOffsetY = self.contentOffset.y;
        CGFloat sMaxOffsetY = MAX(self.contentSize.height - self.frame.size.height, 0);
        if (self.sticksFooterToBottom && self.tableFooterView && sOffsetY > sMaxOffsetY) {
            CGRect sFrame = self.tableFooterView.frame;
            sFrame.origin.y = (sOffsetY - sMaxOffsetY) + (self.contentSize.height - self.tableFooterView.frame.size.height);
            [self.tableFooterView setFrame:sFrame];
        }
    }
    
    [self checkHasData];
}


- (void)setContentSize:(CGSize)contentSize
{
    [super setContentSize:contentSize];
    
    if (self.fetchHeaderView) {
        CGFloat sOffsetY = self.contentOffset.y;
        if (self.sticksHeaderToTop && self.tableHeaderView && sOffsetY < 0) {
            CGRect sFrame = self.tableHeaderView.frame;
            sFrame.origin.y = sOffsetY;
            [self.tableHeaderView setFrame:sFrame];
        }
    }
    
    if (self.fetchFooterView) {
        CGFloat sOffsetY = self.contentOffset.y;
        CGFloat sMaxOffsetY = MAX(self.contentSize.height - self.frame.size.height, 0);
        if (self.sticksFooterToBottom && self.tableFooterView && sOffsetY > sMaxOffsetY) {
            CGRect sFrame = self.tableFooterView.frame;
            sFrame.origin.y = (sOffsetY - sMaxOffsetY) + (self.contentSize.height - self.tableFooterView.frame.size.height);
            [self.tableFooterView setFrame:sFrame];
        }
        
        // 화면 사이즈가 변경되었으므로.
        if (self.fetchFooterView.frame.origin.y != contentSize.height) {
            [self adjustFetchFooterViewFrame];
        }
    }
}


#pragma mark - fetch method

- (void)fetchRecent
{
    [self fetchRecentWithAnimated:YES];
}


- (void)fetchRecentWithAnimated:(BOOL)aAnimated
{
    // fetch 가 진행 중이라면, 여러번 호출되어도 fetch 되지 않게 하는 방어 로직
    if ([self isFetching]) {
        return;
    }
    
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(shouldFetchRecent)] && ![self.dataSource shouldFetchRecent]) {
        return;
    }
    
    [self setFetching:YES];
    [self setFetchState:ZBTableViewFetchStateFetchRecent];
    
    if ([self.fetchHeaderView state] != ZBTableFetchViewLoadStateUpdating) {
        [self.fetchHeaderView setState:ZBTableFetchViewLoadStateUpdating];
        
        if (aAnimated) {
            [self setEdgeInsetTop:kZBListLoadViewHeight animated:YES];
        }
    }
    
    __weak typeof(self) weakSelf = self;
    [self.dataSource fetchRecentWithCompletion:^(NSError *anError) {
        [weakSelf setFetching:NO];
        [weakSelf setFetchState:ZBTableViewFetchStateNormal];
        
        CGFloat sOffsetY = weakSelf.contentOffset.y;
        
        if (weakSelf.fetchHeaderView) {
            if (weakSelf.sticksHeaderToTop && weakSelf.tableHeaderView && sOffsetY < 0) {
                CGRect sFrame = weakSelf.tableHeaderView.frame;
                sFrame.origin.y = sOffsetY;
                [weakSelf.tableHeaderView setFrame:sFrame];
            }
        }
        
        CGFloat sInsetTop = anError ? kZBListLoadViewHeight : 0;
        
        if (sOffsetY < kZBListLoadViewHeight) {
            if (weakSelf.sticksHeaderToTop) {
                CGRect sFrame = weakSelf.tableHeaderView.frame;
                sFrame.origin.y = sInsetTop;
                [weakSelf.tableHeaderView setFrame:sFrame];
            }
            [weakSelf setEdgeInsetTop:sInsetTop animated:NO];
            
            if (anError == nil) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    @try {
                        [weakSelf setContentOffset:weakSelf.contentOffsetWhenLoaded animated:YES];
                    }
                    @catch (NSException *aException) {
                        NSLog(@"ZBTableView exception : %@", aException);
                    }
                });
            }
        }
        else {
            [weakSelf setEdgeInsetTop:sInsetTop animated:NO];
        }
        
        if (anError) {
            [weakSelf.fetchHeaderView setState:ZBTableFetchViewLoadStateFail];
            
            [weakSelf.fetchHeaderView setRetryBlock:^(ZBTableFetchView *aLoadView) {
                [aLoadView setState:ZBTableFetchViewLoadStateUpdating];
                [weakSelf fetchRecent];
            }];
        }
        else {
            [weakSelf.fetchHeaderView setState:ZBTableFetchViewLoadStateNormal];
            [weakSelf.fetchHeaderView setLastUpdateDate:[NSDate date]];
        }
        
        [weakSelf checkHasData];
    }];
}


- (void)fetchMore
{
    // fetch 가 진행 중이라면, 여러번 호출되어도 fetch 되지 않게 하는 방어 로직
    if ([self isFetching]) {
        return;
    }
    
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(shouldFetchRecent)] && ![self.dataSource shouldFetchRecent]) {
        return;
    }
    
    [self setFetching:YES];
    [self setFetchState:(ZBTableViewFetchStateFetchMore)];
    
    __weak typeof(self) weakSelf = self;
    [self.dataSource fetchMoreWithCompletion:^(NSError *aError) {
        // 현재 table이 사용되지 않는 경우에는 데이터 응답결과를 실행하지 않도록 한다.
        if ([weakSelf superview] == nil) {
            return;
        }
        
        [weakSelf setFetching:NO];
        [weakSelf setFetchState:ZBTableViewFetchStateNormal];
        
        CGFloat sOffsetY = weakSelf.contentOffset.y;
        CGFloat sMaxOffsetY = MAX(weakSelf.contentSize.height - weakSelf.frame.size.height, 0);
        if (weakSelf.sticksFooterToBottom && weakSelf.tableFooterView && sOffsetY > sMaxOffsetY) {
            CGRect sFrame = weakSelf.tableFooterView.frame;
            sFrame.origin.y = (sOffsetY - sMaxOffsetY) + (weakSelf.contentSize.height - weakSelf.tableFooterView.frame.size.height);
            [weakSelf.tableFooterView setFrame:sFrame];
        }
        
        
        if (aError) {
            [weakSelf.fetchFooterView setState:ZBTableFetchViewLoadStateFail];
            [weakSelf.fetchFooterView setRetryBlock:^(ZBTableFetchView *aLoadView) {
                [aLoadView setState:ZBTableFetchViewLoadStateUpdating];
                [weakSelf fetchMore];
            }];
        }
        else {
            if (weakSelf.fetchFooterView.state != ZBTableFetchViewLoadStateEndFooter) {
                [weakSelf.fetchFooterView setState:ZBTableFetchViewLoadStateHidden];
            }
        }
        
        CGFloat sInsetBottom = aError ? kZBListLoadViewHeight : 0;
        [UIView animateWithDuration:0.2f animations:^{
            if (weakSelf.sticksFooterToBottom) {
                CGRect sFrame = weakSelf.tableFooterView.frame;
                sFrame.origin.y = (weakSelf.contentSize.height - weakSelf.tableFooterView.frame.size.height);
                [weakSelf.tableFooterView setFrame:sFrame];
            }
            if (weakSelf.dataSource && weakSelf.delegate) {
                [weakSelf setEdgeInsetBottom:sInsetBottom animated:NO];
            }
        }];
    }];
}


- (void)fetchMoreAutomatically
{
    if (self.fetchFooterView.state == ZBTableFetchViewLoadStateFail) {
        return;
    }
    
    [self.fetchFooterView setState:(ZBTableFetchViewLoadStateUpdating)];
    [self setEdgeInsetBottom:kZBListLoadViewHeight animated:NO];
    
    [self fetchMore];
}


#pragma mark - KVO


- (void)tableViewDidScroll:(CGPoint)offset
{
    static BOOL isDecelerating = NO;
    CGFloat     sOffsetY = offset.y;
    
    if (isDecelerating != [self isDecelerating]) {
        isDecelerating = [self isDecelerating];
        if (isDecelerating && [self tableViewDidEndDragging]) {
            return;
        }
    }
    
    // header fetch 확인
    if (self.fetchHeaderView) {
        if (self.sticksHeaderToTop && self.tableHeaderView && sOffsetY < 0 && self.tableHeaderView.frame.origin.y != sOffsetY) {
            CGRect sFrame = self.tableHeaderView.frame;
            sFrame.origin.y = sOffsetY;
            [self.tableHeaderView setFrame:sFrame];
        }
        
        ZBTableFetchViewLoadState sState = [self.fetchHeaderView state];
        if (sState != ZBTableFetchViewLoadStateUpdating && sState != ZBTableFetchViewLoadStateWait) {
            if (self.dataSource && [self.dataSource respondsToSelector:@selector(shouldFetchRecent)] && ![self.dataSource shouldFetchRecent]) {
                [self.fetchHeaderView setHidden:YES];
                return;
            }
            else {
                [self.fetchHeaderView setHidden:NO];
            }
            
            if (sOffsetY + kZBListLoadViewHeight < 0) {
                if (sState == ZBTableFetchViewLoadStateNormal) {
                    [self.fetchHeaderView setState:ZBTableFetchViewLoadStatePulling];
                }
            }
            else if (sOffsetY < 0) {
                if (sState == ZBTableFetchViewLoadStatePulling) {
                    [self.fetchHeaderView setState:ZBTableFetchViewLoadStateNormal];
                }
            }
        }
    }
    
    // footer fetch 확인
    if (self.fetchFooterView && !self.disableFetchMore) {
        if (self.dataSource && [self.dataSource respondsToSelector:@selector(shouldFetchRecent)] && ![self.dataSource shouldFetchMore]) {
            [self.fetchFooterView setHidden:YES];
            return;
        }
        else {
            [self.fetchFooterView setHidden:NO];
        }
        
        CGFloat sMaxOffsetY = MAX(self.contentSize.height - self.frame.size.height, 0);
        if (self.sticksFooterToBottom && self.tableFooterView && sOffsetY > sMaxOffsetY)  {
            CGRect sFrame = self.tableFooterView.frame;
            sFrame.origin.y = (sOffsetY - sMaxOffsetY) + (self.contentSize.height - self.tableFooterView.frame.size.height);
            [self.tableFooterView setFrame:sFrame];
        }
        
        ZBTableFetchViewLoadState state = [self.fetchFooterView state];
        if (sOffsetY > 0) {
            if (sOffsetY > sMaxOffsetY + kZBListLoadViewHeight) {
                if (state == ZBTableFetchViewLoadStateNormal) {
                    [self.fetchFooterView setState:ZBTableFetchViewLoadStatePulling];
                }
            }
            else if (sOffsetY > sMaxOffsetY) {
                if (state == ZBTableFetchViewLoadStateHidden || state == ZBTableFetchViewLoadStatePulling) {
                    [self.fetchFooterView setState:ZBTableFetchViewLoadStateNormal];
                }
            }
        }
        else if (![self isDragging]) {
            if (state == ZBTableFetchViewLoadStateNormal) {
                [self.fetchFooterView setState:ZBTableFetchViewLoadStateHidden];
            }
        }
    }
}


- (BOOL)tableViewDidEndDragging
{
    __weak typeof(self) weakSelf = self;
    
    CGFloat sOffsetY = self.contentOffset.y;
    
    // pull down으로 최신 데이터를 요청할 경우.
    if (self.fetchHeaderView) {
        ZBTableFetchViewLoadState state = [self.fetchHeaderView state];
        if (state == ZBTableFetchViewLoadStatePulling) {
            [self.fetchHeaderView setState:ZBTableFetchViewLoadStateUpdating];
            
            if (self.sticksHeaderToTop) {
                CGRect sFrame = self.tableHeaderView.frame;
                sFrame.origin.y = sOffsetY;
                [self.tableHeaderView setFrame:sFrame];
            }
            
            [UIView animateWithDuration:0.2f animations:^{
                if (weakSelf.sticksHeaderToTop) {
                    CGRect sFrame = weakSelf.tableHeaderView.frame;
                    sFrame.origin.y = kZBListLoadViewHeight;
                    [weakSelf.tableHeaderView setFrame:sFrame];
                }
                [weakSelf setEdgeInsetTop:kZBListLoadViewHeight animated:NO];
            }];
            
            [self fetchRecent];
            return YES;
        }
    }
    
    // footer의 fetch 가능 여부를 체크한다.
    if (self.fetchFooterView && !self.disableFetchMore && !self.loadedOldestData && sOffsetY > 0) {
        ZBTableFetchViewLoadState state = [self.fetchFooterView state];
        if (state == ZBTableFetchViewLoadStateFail || state == ZBTableFetchViewLoadStateUpdating) {
            return NO;
        }
        
        // 스크롤다운시 맨 마지막을 넘어선 경우 fetch more를 할 수 있는 경우에 fetchMore를 실행한다.
        if (state == ZBTableFetchViewLoadStatePulling) {
            [self.fetchFooterView setState:ZBTableFetchViewLoadStateUpdating];
            
            CGFloat sMaxOffsetY = MAX(self.contentSize.height - self.frame.size.height, 0);
            if (self.sticksFooterToBottom && self.tableFooterView && sOffsetY > sMaxOffsetY) {
                CGRect sFrame = self.tableFooterView.frame;
                sFrame.origin.y = (sOffsetY - sMaxOffsetY) + (self.contentSize.height - self.tableFooterView.frame.size.height);
                [self.tableFooterView setFrame:sFrame];
            }
            
            [UIView animateWithDuration:0.2f animations:^{
                if (weakSelf.sticksFooterToBottom) {
                    CGRect sFrame = weakSelf.tableFooterView.frame;
                    sFrame.origin.y = (weakSelf.contentSize.height - weakSelf.tableFooterView.frame.size.height);
                    [weakSelf.tableFooterView setFrame:sFrame];
                }
                [weakSelf setEdgeInsetBottom:kZBListLoadViewHeight animated:NO];
            }];
            
            [self fetchMore];
            return YES;
        }
    }
    
    return NO;
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (self.checkingContentOffset) {
        return;
    }
    
    if (context == ZBTableViewContentOffsetContext) {
        [self setCheckingContentOffset:YES];
        [self tableViewDidScroll:self.contentOffset];
        [self setCheckingContentOffset:NO];
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}


@end
