//
//  CharacterServices.m
//  Delve
//
//  Created by Theodore Abshire on 3/8/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

#import "CharacterServices.h"
#import "Creature.h"

void drawArmorsOf(Creature *cr, int layer, NSMutableArray *spriteArray, NSMutableArray *yAdds, NSString *gS)
{
	NSArray *raceYAdds = loadValueBool(@"Races", cr.race, @"armor slot y offsets") ? loadValueArray(@"Races", cr.race, @"armor slot y offsets") : nil;
	
	for (int i = 0; i < cr.armors.count; i++)
	{
		NSString *armor = cr.armors[i];
		if (armor.length > 0 && loadValueBool(@"Armors", armor, @"sprite"))
		{
			//lock to layer
			BOOL rightLayer = false;
			switch(layer)
			{
				case 0: //below layer
					rightLayer = loadValueBool(@"Armors", armor, @"sprite back");
					break;
				case 1: //below hair layer
					rightLayer = !loadValueBool(@"Armors", armor, @"sprite over hair");
					break;
				case 2: //over hair layer
					rightLayer = loadValueBool(@"Armors", armor, @"sprite over hair");
					break;
			}
			
			if (rightLayer)
			{
				int yAdd = raceYAdds == nil ? 0 : ((NSNumber *)raceYAdds[i]).intValue;
				
				NSString *spriteName = loadValueString(@"Armors", armor, @"sprite");
				if (layer == 0)
					spriteName = [NSString stringWithFormat:@"%@_back", spriteName];
				if (loadValueBool(@"Armors", armor, @"sprite gender"))
					spriteName = [NSString stringWithFormat:@"%@%@", spriteName, gS];
				if (cr.gender && loadValueBool(@"Armors", armor, @"female y add"))
					yAdd += loadValueNumber(@"Armors", armor, @"female y add").intValue;
				
				//draw armor sprite
				UIImage *sprite = [UIImage imageNamed:spriteName];
				UIImage *coloredSprite = colorImage(sprite, loadColorFromName(loadValueString(@"Armors", armor, @"color")));
				[spriteArray addObject:coloredSprite];
				[yAdds addObject:@(yAdd)];
			}
		}
	}
}

void makeCreatureSpriteInView(Creature *cr, UIView *view)
{
	//TODO: all boots are (so far) modeled after raider feet
	//but raider feet seem to be spaced 1 px further apart than human feet
	//which is, uh, a problem
	
	for (UIView *subView in view.subviews)
		[subView removeFromSuperview];
	
	if (cr.dead)
		return;
	
	//get info
	NSArray *colorations = loadValueArray(@"Races", cr.race, @"colorations");
	NSDictionary *coloration = colorations[cr.coloration];
	UIColor *skinColor = loadColorFromName((NSString *)coloration[@"skin"]);
	UIColor *hairColor = loadValueBool(@"Races", cr.race, @"hair styles") ? loadColorFromName((NSString *)coloration[@"hair"]) : nil;
	NSString *genderSuffix = loadValueBool(@"Races", cr.race, @"has gender") ? (cr.gender ? @"_f" : @"_m") : @"";
	
	NSMutableArray *images = [NSMutableArray new];
	NSMutableArray *yAdds = [NSMutableArray new];
	
	//	[self drawArmorsOf:cr withLayer:0 inArray:images withYAdds:yAdds genderSuffix:genderSuffix];
	drawArmorsOf(cr, 0, images, yAdds, genderSuffix);
	
	NSString *bodySprite = [NSString stringWithFormat:@"%@%@", loadValueString(@"Races", cr.race, @"sprite"), genderSuffix];
	[images addObject:colorImage([UIImage imageNamed:bodySprite], skinColor)];
	[yAdds addObject:@(0)];
	
	//	[self drawArmorsOf:cr withLayer:1 inArray:images withYAdds:yAdds genderSuffix:genderSuffix];
	drawArmorsOf(cr, 1, images, yAdds, genderSuffix);
	
	if (hairColor != nil)
	{
		NSString *hairSprite = [NSString stringWithFormat:@"%@_hair%i%@", loadValueString(@"Races", cr.race, @"sprite"), cr.hairStyle+1, genderSuffix];
		[images addObject:colorImage([UIImage imageNamed:hairSprite], hairColor)];
		[yAdds addObject:@(0)];
	}
	
	//	[self drawArmorsOf:cr withLayer:2 inArray:images withYAdds:yAdds genderSuffix:genderSuffix];
	drawArmorsOf(cr, 2, images, yAdds, genderSuffix);
	
	UIImageView *imageView = [[UIImageView alloc] initWithImage:mergeImages(images, CGPointMake(0.5f, 1.0f), yAdds)];
	imageView.frame = CGRectMake(GAMEPLAY_TILE_SIZE / 2 - imageView.frame.size.width / 2, GAMEPLAY_TILE_SIZE - imageView.frame.size.height, imageView.frame.size.width, imageView.frame.size.height);
	[view addSubview:imageView];
	
	//stealth effect
	if (cr.stealthed > 0)
		view.alpha = 0.5f; //TODO: this should probably be a constant
	else
		view.alpha = 1;
}

void makeInfoLabelInView(Creature *cr, UIView *view)
{
	for (UIView *subView in view.subviews)
		[subView removeFromSuperview];
	UILabel *statLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
	statLabel.text = [NSString stringWithFormat:@"H%i/%i  D%i/%i  B%i/%i  K%i/%i", cr.health, cr.maxHealth, cr.dodges, cr.maxDodges, cr.blocks, cr.maxBlocks, cr.hacks, cr.maxHacks];
	statLabel.textColor = loadColorFromName(@"ui text");
	//TODO: display blocks, dodges, and hacks as rows of icons
	[statLabel sizeToFit];
	[view addSubview:statLabel];
	
	UILabel *statLabel2 = [[UILabel alloc] initWithFrame:CGRectMake(0, statLabel.frame.size.height, 0, 0)];
	statLabel2.text = [NSString stringWithFormat:@"%i%% dam", cr.damageBonus];
	//TODO: display resistances as rows of icons
	//in this order: blunt, cut, burn, shock
	[statLabel2 sizeToFit];
	statLabel2.textColor = loadColorFromName(@"ui text");
	[view addSubview:statLabel2];
}