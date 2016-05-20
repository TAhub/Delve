//
//  HowToPlayViewController.m
//  Delve
//
//  Created by Theodore Abshire on 5/20/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

#import "HowToPlayViewController.h"
#import "Constants.h"

@interface HowToPlayViewController ()

@property (weak, nonatomic) IBOutlet UIView *titlePanel;
@property (weak, nonatomic) IBOutlet UIView *textPanel;
@property (weak, nonatomic) IBOutlet UIView *returnPanel;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton *returnButton;




@end

@implementation HowToPlayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	
	[self formatButton:self.returnButton];
	[self formatPanel:self.titlePanel];
	[self formatPanel:self.textPanel];
	[self formatPanel:self.returnPanel];
	self.titleLabel.textColor = loadColorFromName(@"ui text");
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
