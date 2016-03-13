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
	
	UIImage *merged = mergeImages(images, CGPointMake(0.5f, 1.0f), yAdds);
	
	//colorize the image based on status effects
	if (cr.damageBoosted > 0)
		merged = colorImage(merged, loadColorFromName(@"damage boost"));
	if (cr.immunityBoosted > 0)
		merged = colorImage(merged, loadColorFromName(@"immunity boost"));
	if (cr.skating > 0)
		merged = colorImage(merged, loadColorFromName(@"skate"));
	if (cr.defenseBoosted > 0)
		merged = colorImage(merged, loadColorFromName(@"defense boost"));
	
	if (cr.forceField > 0)
	{
		float ffAlpha = 0.7f; //TODO: this should probably be a constant
		ffAlpha *= MIN(1, cr.forceField * 2.0f / cr.maxHealth) * 0.8f + 0.2f;
		
		UIImage *ffImage = solidColorImage(merged, [UIColor whiteColor]);
		merged = mergeImagesWithAlphas([NSArray arrayWithObjects:merged, ffImage, nil], CGPointMake(0.5f, 1.0f), [NSArray arrayWithObjects:@(0), @(0), nil], [NSArray arrayWithObjects:@(1), @(ffAlpha), nil]);
	}
	
	
	UIImageView *imageView = [[UIImageView alloc] initWithImage:merged];
	imageView.frame = CGRectMake(GAMEPLAY_TILE_SIZE / 2 - imageView.frame.size.width / 2, GAMEPLAY_TILE_SIZE - imageView.frame.size.height, imageView.frame.size.width, imageView.frame.size.height);
	[view addSubview:imageView];
	
	//stealth effect
	if (cr.stealthed > 0)
		view.alpha = 0.5f; //TODO: this should probably be a constant
	else
		view.alpha = 1;
}

CGPoint iconRow(NSString *baseName, UIColor *color, int cur, int max, CGPoint corner, UIView *addTo)
{
	//draw a row of icons, each representing two of something
	
	for (int i = 0; i < max;)
	{
		int pieces = 0;
		int maxPieces = 0;
		if (i == max - 1)
		{
			maxPieces = 1;
			pieces = max == cur ? 1 : 0;
			i += 1;
		}
		else
		{
			maxPieces = 2;
			pieces = MAX(MIN(max - cur - i + 2, 2), 0);
			i += 2;
		}
		NSString *suffix;
		if (maxPieces == 1)
			suffix = pieces == 1 ? @"_half_full" : @"_half_empty";
		else
		{
			switch(pieces)
			{
				case 0: suffix = @"_empty"; break;
				case 1: suffix = @"_halfEmpty"; break;
				case 2: suffix = @"_full"; break;
			}
		}
		
		UIImage *loaded = colorImage([UIImage imageNamed:[NSString stringWithFormat:@"%@%@", baseName, suffix]], color);
		UIImageView *iconView = [[UIImageView alloc] initWithImage:loaded];
		iconView.frame = CGRectMake(corner.x, corner.y, loaded.size.width, loaded.size.height);
		[addTo addSubview:iconView];
		corner.x += loaded.size.width;
	}
	return corner;
}

void makeInfoLabelInView(Creature *cr, UIView *view)
{
	for (UIView *subView in view.subviews)
		[subView removeFromSuperview];
	UILabel *statLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
	statLabel.text = [NSString stringWithFormat:@"H%i/%i ", cr.health, cr.maxHealth];
	statLabel.textColor = loadColorFromName(@"ui text");
	[statLabel sizeToFit];
	[view addSubview:statLabel];
	
	//display blocks, dodges, and hacks as rows of icons
	CGPoint corner = CGPointMake(statLabel.frame.origin.x + statLabel.frame.size.width, statLabel.frame.origin.y);
	corner = iconRow(@"ui_block", loadColorFromName(@"ui block"), cr.blocks, cr.maxBlocks, corner, view);
	corner = iconRow(@"ui_dodge", loadColorFromName(@"ui dodge"), cr.dodges, cr.maxDodges, corner, view);
	iconRow(@"ui_hack", loadColorFromName(@"ui hack"), cr.hacks, cr.maxHacks, corner, view);
	
	//display resistances as rows of icons
	//in this order: smash, cut, burn, shock
	CGPoint corner2 = CGPointMake(0, statLabel.frame.size.height + 10);
	corner2 = iconRow(@"ui_resist", loadColorFromName(@"element smash"), cr.smashResistance, cr.smashResistance, corner2, view);
	corner2 = iconRow(@"ui_resist", loadColorFromName(@"element cut"), cr.cutResistance, cr.cutResistance, corner2, view);
	corner2 = iconRow(@"ui_resist", loadColorFromName(@"element burn"), cr.burnResistance, cr.burnResistance, corner2, view);
	iconRow(@"ui_resist", loadColorFromName(@"element shock"), cr.shockResistance, cr.shockResistance, corner2, view);
}