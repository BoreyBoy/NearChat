//
//  CTMsgProgressCell.m
//  NearChat
//
//  Created by BOREY on 14-3-26.
//  Copyright (c) 2014年 ctrip. All rights reserved.
//

#import "CTMsgProgressCell.h"

@implementation CTMsgProgressCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
