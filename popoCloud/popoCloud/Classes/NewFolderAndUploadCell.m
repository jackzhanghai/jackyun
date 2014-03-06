//
//  NewFolderAndUploadCell.m
//  popoCloud
//
//  Created by ice on 13-11-28.
//
//

#import "NewFolderAndUploadCell.h"

@implementation NewFolderAndUploadCell
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}
-(void)awakeFromNib
{
    [super awakeFromNib];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.line1.backgroundColor = [UIColor colorWithRed:123.0f/255.0f green:199.0f/255.0f blue:1.0f alpha:1.0f];
    self.line2.backgroundColor = [UIColor colorWithRed:248.0f/255.0f green:252.0f/255.0f blue:1.0f alpha:1.0f];
    self.contentView.backgroundColor = [UIColor colorWithRed:205.0f/255.0f green:230.0f/255.0f blue:1.0f alpha:1.0f];
}
- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}
-(IBAction)newFolderAction:(id)sender
{
    if (self.editing) {
        return;
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(createNewFloder)])
    {
        [self.delegate createNewFloder];
    }
}
-(IBAction)uploadAction:(id)sender
{
    if (self.editing) {
        return;
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(uploadPhoto)])
    {
        [self.delegate uploadPhoto];
    }
}
@end
