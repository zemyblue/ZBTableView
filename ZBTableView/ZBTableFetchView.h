//
//  ZBTableFetchView.h
//  ZBTableView
//
//  Created by zemyblue on 2014. 11. 4..
//  Copyright (c) 2014년 zemyblue. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kZBListLoadViewHeight       60.f


/* ZBTableFetchView의 현재의 상태 정의 */
typedef NS_ENUM(NSInteger, ZBTableFetchViewLoadState)
{
    ZBTableFetchViewLoadStateHidden = -1,   /* fetchHeaderView나 fetchFooterView를 보여주지 않는 상태 */
    ZBTableFetchViewLoadStateNormal,
    ZBTableFetchViewLoadStateWait,          /* 다른 fetch요청을 처리하고 있어서 대기하는 상태, fetchMore 중일 때 fetchHeaderView의 상태. fetchRecent일 때 fetchFooterView의 상태. */
    ZBTableFetchViewLoadStatePulling,       /* fetchHeader를 끌어 내리거나, fetchFooter를 끌어 올릴 때의 상태. */
    ZBTableFetchViewLoadStateUpdating,      /* 현재 데이터를 요청해서 아직 응답을 받지 못한 상태. */
    ZBTableFetchViewLoadStateFail,          /* 데이터 요청후 실패 응답을 수신한 경우. */
    ZBTableFetchViewLoadStateNoSign,
    ZBTableFetchViewLoadStateEndFooter      /* 목록의 맨 마지막 일 경우 */
};


/* customView가 ZBTableView에 추가될 때 위치형태를 정의 */
typedef NS_ENUM(NSInteger, ZBTableFetchViewCustomAttachType)
{
    ZBTableFetchViewCustomAttachTypeNoAttach,
    ZBTableFetchViewCustomAttachTypeTop,
    ZBTableFetchViewCustomAttachTypeBottom
};


@interface ZBTableFetchView : UIView
@property (nonatomic, strong) void (^retryBlock)(ZBTableFetchView *aView);
@property (nonatomic, strong) NSDate *lastUpdateDate;
@property (nonatomic, strong) UIView *customView;
@property (nonatomic, assign) ZBTableFetchViewCustomAttachType customViewAttachType; /* customView가 화면에 출력되는 상태, headerView일 경우 기본 Bottom으로, footerView일 경우에는 기본 Top으로 설정된다. 이 기능은 ZBTableView에서만 사용하는 것을 권장한다. */
@property (nonatomic, assign) ZBTableFetchViewLoadState state;
@property (nonatomic, assign) BOOL enableSeparator;      /*하단의 separator line의 추가 여부, 기본은 추가됨. */

- (id)initWithHeaderWithFrame:(CGRect)aRect;
- (id)initWithFooterWithFrame:(CGRect)aRect;

@end


@interface ZBTableFetchHeaderView : ZBTableFetchView
- (void)tableViewDidScroll:(UITableView *)aTableView;
@end


@interface ZBTableFetchFooterView : ZBTableFetchView
- (void)tableViewDidScroll:(UITableView *)aTableView;
@end
