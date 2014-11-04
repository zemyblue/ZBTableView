//
//  ViewController.m
//  ZBTableView
//
//  Created by zemyblue on 2014. 10. 15..
//  Copyright (c) 2014년 zemyblue. All rights reserved.
//

#import "ViewController.h"
#import "ZBTableView.h"

@interface ViewController () <ZBTableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) ZBTableView *tableView;
@property (nonatomic, assign) NSUInteger numberOfRow;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.numberOfRow = 20;
    
    [self setTitle:@"ZBTableView Demo"];
    
    self.tableView = [[ZBTableView alloc] initWithFrame:self.view.bounds];
    [self.tableView setDelegate:self];
    [self.tableView setDataSource:self];
    [self.view addSubview:self.tableView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark UITableViewDataSource


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.numberOfRow;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"cellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    cell.textLabel.text = [NSString stringWithFormat:@"cell %ld", indexPath.row + 1];
    
    return cell;
}


#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark ZBTableViewDataSource


- (void)fetchRecentWithCompletion:(void (^)(NSError *aError))aCompletion
{
    // delay for test
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        weakSelf.numberOfRow = 20;
        [weakSelf.tableView reloadData];
        aCompletion(nil);
    });
}


- (void)fetchMoreWithCompletion:(void (^)(NSError *aError))aCompletion
{
    // delay for test
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        weakSelf.numberOfRow += 20;
        [weakSelf.tableView reloadData];
        aCompletion(nil);
    });
}


@end
