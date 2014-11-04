//
//  ZBTableView.h
//  ZBTableView
//
//  Created by zemyblue on 2014. 10. 19..
//  Copyright (c) 2014년 zemyblue. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ZBTableViewDataSource <UITableViewDataSource>

@optional

- (void)fetchRecentWithCompletion:(void (^)(NSError *aError))aCompletion NS_AVAILABLE_IOS(4_0); ///< 최신 데이터를 요청한다.
- (void)fetchMoreWithCompletion:(void (^)(NSError *aError))aCompletion NS_AVAILABLE_IOS(4_0);   ///< 현재 로드된 데이터에 추가되는 데이터 로딩을 요청한다.

/**
 최신 데이터를 요청하는게 가능 한지 여부를 판단.
 
 @return YES 최신데이터 요청, NO 하지 않음.
 */
- (BOOL)shouldFetchRecent;

/**
 추가 데이터 요청하는게 가능한지 여부를 판단.
 
 @return YES 추가 데이터 요청, NO 하지 않음.
 */
- (BOOL)shouldFetchMore;
@end


/**
 기본 UITableView에 스크롤 시 상/하단 View에 최신데이터 갱신과 추가 데이터를 불러오는 기능을 추가한다.
 목록의 마지막 cell까지 스크롤될 경우 자동으로 다음 목록을 요청한다.
 header에 추가되는 최신데이터 갱신 기능은 fetchRecentWithCompletion: 이 구현되어 있지 않으면 표시되지 않는다.
 마찬가지로 footer의 추가 데이터 불러오는 기능은 fetchMoreWithCompletion: 이 구현되어 있지 않으면 표시되지 않는다.
 */
@interface ZBTableView : UITableView

@property (nonatomic, weak) id<ZBTableViewDataSource> dataSource;
@property (nonatomic, assign) BOOL sticksHeaderToTop;
@property (nonatomic, assign) BOOL sticksFooterToBottom;
@property (nonatomic, assign) BOOL loadedOldestData; ///< 가장 오래된 데이터가 로드된 경우 TRUE로 설정한다. 이를 설정함으로 더이상 footer에서 불러오는 중이 호출되지 않는다.
@property (nonatomic, strong) UIView *(^makeNoDataView)(); ///< 데이터가 없을 경우에 보여주는 View를 생성하는 메소드
@property (nonatomic, assign, getter = isShowsNoDataViewIfNeeded) BOOL showsNoDataViewIfNeeded;
@property (nonatomic, assign) CGPoint contentOffsetWhenLoaded;

- (void)fetchRecent;
- (void)fetchMore;
- (void)fetchMoreAutomatically;

@end


