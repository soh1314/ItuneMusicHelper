//
//  TableViewCell.h
//  YJZMusicPlayer
//
//  Created by 颜镜圳 on 16/5/13.
//  Copyright © 2016年 颜镜圳. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *musicImageView;
@property (weak, nonatomic) IBOutlet UILabel *musicTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *musicSingerLabel;

@end
