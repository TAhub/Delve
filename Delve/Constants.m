//
//  Constants.m
//  Delve
//
//  Created by Theodore Abshire on 2/22/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

#import "Constants.h"
#import "Assert.h"
#import <AVFoundation/AVAudioPlayer.h>

#pragma mark image modification

UIImage *mergeImages(NSArray *images, CGPoint anchorPoint, NSArray *yAdds)
{
	return mergeImagesWithAlphas(images, anchorPoint, yAdds, nil);
}

UIImage *mergeImagesWithAlphas(NSArray *images, CGPoint anchorPoint, NSArray *yAdds, NSArray *alphas)
{
	assert(images != nil);
	assert(yAdds != nil);
	CGRect boundsRect = CGRectMake(0, 0, 0, 0);
	
	//add the images, keeping the bounds in track
	UIView *combinedView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, GAMEPLAY_TILE_SIZE * 2, GAMEPLAY_TILE_SIZE * 2)];
	for (int i = 0; i < images.count; i++)
	{
		UIImage *image = images[i];
		assert(image != nil);
		int yAdd = ((NSNumber *)yAdds[i]).intValue;
		
		UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
		[combinedView addSubview:imageView];
		
		CGRect imageRect = CGRectMake(0, yAdd, image.size.width, image.size.height);
		boundsRect = CGRectUnion(boundsRect, imageRect);
	}
	
	//center the images
	for (int i = 0; i < images.count; i++)
	{
		UIImageView *imageView = combinedView.subviews[i];
		int yAdd = ((NSNumber *)yAdds[i]).intValue;
		
		//the anchorAt point is where the views should converge
		//ie 0.5, 0.5 means they should all be centered
		//0, 0 means they should all be drawn in the upper-left
		imageView.frame = CGRectMake((boundsRect.size.width - imageView.frame.size.width) * anchorPoint.x, (boundsRect.size.height - imageView.frame.size.height) * anchorPoint.y + yAdd, imageView.frame.size.width, imageView.frame.size.height);
		
		if (alphas != nil)
			imageView.alpha = ((NSNumber *)alphas[i]).floatValue;
	}
	
	UIGraphicsBeginImageContext(boundsRect.size);
	[combinedView.layer renderInContext:UIGraphicsGetCurrentContext()];
	UIImage *combinedImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return combinedImage;
}

UIImage *solidColorImage(UIImage *image, UIColor *color)
{
	assert(image != nil);
	assert(color != nil);
	
	CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
	
	//get the color space and context
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	u_int32_t bitmapInfo = kCGImageAlphaPremultipliedLast;
	CGContextRef bitmapContext = CGBitmapContextCreate(nil, (int)image.size.width, (int)image.size.height, 8, 0, colorSpace, bitmapInfo);
	
	//draw and fill it
	CGContextClipToMask(bitmapContext, rect, image.CGImage);
	CGContextSetFillColorWithColor(bitmapContext, color.CGColor);
	CGContextFillRect(bitmapContext, rect);
	
	CGImageRef snapshot = CGBitmapContextCreateImage(bitmapContext);
	return [UIImage imageWithCGImage:snapshot];
}

UIImage *colorImage(UIImage *image, UIColor *color)
{
	//get the color mask image
	UIImage *colorImage = solidColorImage(image, color);
	
	//get other stuff
	CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
	UIGraphicsBeginImageContext(image.size);
	
	//draw the image
	[image drawInRect:rect];
	
	//draw the color mask
	[colorImage drawAtPoint:CGPointZero blendMode:kCGBlendModeMultiply alpha:1.0];
	
	//get the new image
	UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return newImage;
	
}

#pragma mark plist accessors

UIColor *loadColor(NSString *colorCode)
{
	assert(colorCode != nil);
	assert(colorCode.length == 6);
	
	NSString *rString = [colorCode substringToIndex:2];
	NSString *gString = [[colorCode substringFromIndex:2] substringToIndex:2];
	NSString *bString = [colorCode substringFromIndex:4];
	int r = (int)strtol([rString UTF8String], NULL, 16);
	int g = (int)strtol([gString UTF8String], NULL, 16);
	int b = (int)strtol([bString UTF8String], NULL, 16);
	
	return [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:1];
}
UIColor *loadColorFromName(NSString *name)
{
	NSDictionary *p = loadEntries(@"Colors");
	id e = p[name];
	assert(e != nil);
	assert([e isKindOfClass:[NSString class]]);
	return loadColor(e);
}
NSDictionary *loadEntries(NSString *category)
{
	NSString *p = [[NSBundle mainBundle] pathForResource:category ofType:@"plist"];
	NSDictionary *d = [[NSDictionary alloc] initWithContentsOfFile:p];
	assert(d != nil);
	return d;
}

//plist caching
NSString *entryName = nil;
NSString *categoryName = nil;
NSDictionary *categoryCache = nil;
NSDictionary *entryCache = nil;

//turn the caching off when you go multithreaded
BOOL cachingEnabled = true;

NSDictionary *loadEntry(NSString *category, NSString *entry)
{
	if (cachingEnabled)
	{
		if (![category isEqualToString:categoryName])
		{
			categoryName = nil;
			entryName = nil;
		}
		if (![entry isEqualToString:entryName])
			entryName = nil;
		
		if (categoryName == nil)
		{
			categoryCache = loadEntries(category);
			categoryName = category;
		}
		if (entryName == nil)
		{
			id e = categoryCache[entry];
			assert(e != nil);
			assert([e isKindOfClass:[NSDictionary class]]);
			entryCache = e;
			entryName = entry;
		}
		return entryCache;
	}
	else
	{
		NSDictionary *d = loadEntries(category);
		id e = d[entry];
		assert(e != nil);
		assert([e isKindOfClass:[NSDictionary class]]);
		return e;
	}
}
NSArray *loadArrayEntry(NSString *category, NSString *entry)
{
	NSDictionary *p = loadEntries(category);
	id a = p[entry];
	assert(a != nil);
	assert([a isKindOfClass:[NSArray class]]);
	return a;
}
NSObject *loadValue(NSString *category, NSString *entry, NSString *value)
{
	NSDictionary *e = loadEntry(category, entry);
	id v = e[value];
	assert(v != nil);
	return v;
}
UIColor *loadValueColor(NSString *category, NSString *entry, NSString *value)
{
	return loadColor(loadValueString(category, entry, value));
}
NSNumber *loadValueNumber(NSString *category, NSString *entry, NSString *value)
{
	NSObject *v = loadValue(category, entry, value);
	assert([v isKindOfClass:[NSNumber class]]);
	return (NSNumber *)v;
}
NSString *loadValueString(NSString *category, NSString *entry, NSString *value)
{
	NSObject *v = loadValue(category, entry, value);
	assert([v isKindOfClass:[NSString class]]);
	return (NSString *)v;
}
NSArray *loadValueArray(NSString *category, NSString *entry, NSString *value)
{
	NSObject *v = loadValue(category, entry, value);
	assert([v isKindOfClass:[NSArray class]]);
	return (NSArray *)v;
}
BOOL loadValueBool(NSString *category, NSString *entry, NSString *value)
{
	//this can't use the normal loadValue because it throws an exception on nil
	NSDictionary *e = loadEntry(category, entry);
	return e[value] != nil;
}

#pragma mark misc

void shuffleArray(NSMutableArray *array)
{
	for (int i = 0; i < array.count; i++)
	{
		int rand = arc4random_uniform((u_int32_t)array.count);
		[array exchangeObjectAtIndex:rand withObjectAtIndex:0];
	}
}

void playSound(NSString *soundCategoryName)
{
	//TODO: put all the liscense info here
	
	
	
	//TODO: sound effect choices
	// (store an array of the filenames inside a plist)
	//dodge effect ("dodge")
	//	https://www.freesound.org/people/Robinhood76/sounds/101432/
	//	https://www.freesound.org/people/kwahmah_02/sounds/269294/
	//	https://www.freesound.org/people/qubodup/sounds/59996/
	//block effect ("block")
	//	https://www.freesound.org/people/JohnBuhr/sounds/326794/
	//	https://www.freesound.org/people/32cheeseman32/sounds/180825/
	//burn damage effect ("burn")
	//	https://www.freesound.org/people/sfx4animation/sounds/273663/
	//shock damage effect ("shock")
	//	https://www.freesound.org/people/JoelAudio/sounds/136542/
	//cut damage effect ("cut")
	//	https://www.freesound.org/people/Black%20Snow/sounds/109423/
	//smash damage effect ("smash")
	//	https://www.freesound.org/people/dcolvin/sounds/193896/
	//heal sound effect ("heal")
	//	https://www.freesound.org/people/spectorjay/sounds/37632/
	//death sound male person ("death person male")
	//	https://www.freesound.org/people/GentlemanWalrus/sounds/180005/
	//death sound female person ("death person female")
	//	https://www.freesound.org/people/Otakua/sounds/219891/
	//	https://www.freesound.org/people/Otakua/sounds/219890/
	//death sound machine ("death robot")
	//	https://www.freesound.org/people/LittleRobotSoundFactory/sounds/316308/
	//	https://www.freesound.org/people/dotY21/sounds/309512/
	//death sound beast ("death animal")
	//	https://www.freesound.org/people/vincentoliver/sounds/180490/
	//	https://www.freesound.org/people/Adam_N/sounds/148972/
	//death sound robot ("death guardian")
	//	https://www.freesound.org/people/jeremysykes/sounds/341239/
	// confusion ("huh")
	//	https://www.freesound.org/people/EiK/sounds/240104/
	// pop ("pop")
	//	https://www.freesound.org/people/deraj/sounds/202230/
	//magic bolt throw ("bolt")
	//	https://www.freesound.org/people/wjl/sounds/267887/
	//animal snarl ("snarl")
	//	https://www.freesound.org/people/Jamius/sounds/41526/
	//flamethrower activate ("flamethrower")
	//	https://www.freesound.org/people/HunteR4708/sounds/256799/
	//bow shoot ("bow")
	//	https://www.freesound.org/people/Erdie/sounds/65733/
	//technology activate ("activate")
	//	https://www.freesound.org/people/ZvinbergsA/sounds/273691/
	//poison bubbles ("poison")
	//	https://www.freesound.org/people/kwahmah_02/sounds/261597/
	//metal screech ("screech")
	//	https://www.freesound.org/people/Housed1J/sounds/175410/
	//overtime siren ("siren")
	//	https://www.freesound.org/people/plasterbrain/sounds/242856/
	//anything else I can think of (menu buttons? I dunno)
	
	
	if (soundCategoryName.length == 0)
		return;
	
	NSArray *soundArray = loadArrayEntry(@"Sounds", soundCategoryName);
	NSString *pick = soundArray[arc4random_uniform((u_int32_t)soundArray.count)];
	NSString *filePath = [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], pick];
	NSURL *fileURL = [NSURL fileURLWithPath:filePath];
	
	//TODO: play
	AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:nil];
	player.numberOfLoops = -1;
	
	[player play];
}

#pragma mark tests

void passiveBalanceTest()
{
	int damageBonus = 0;
	int attackBonus = 0;
	int health = 0;
	int smashResistance = 0;
	int cutResistance = 0;
	int shockResistance = 0;
	int burnResistance = 0;
	int dodges = 0;
	int blocks = 0;
	int hacks = 0;
	int metabolism = 0;
	int delayReduction = 0;
	int counter = 0;
	
	for (NSString *treeName in loadEntries(@"SkillTrees").allKeys)
		if (![loadValueString(@"SkillTrees", treeName, @"type") isEqualToString:@"invalid"])
		{
			NSArray *skills = loadValueArray(@"SkillTrees", treeName, @"skills");
			int lDamageBonus = 0;
			int lAttackBonus = 0;
			int lHealth = 0;
			int lSmashResistance = 0;
			int lCutResistance = 0;
			int lShockResistance = 0;
			int lBurnResistance = 0;
			int lDodges = 0;
			int lBlocks = 0;
			int lHacks = 0;
			int lMetabolism = 0;
			int lDelayReduction = 0;
			int lCounter = 0;
			for (int i = 0; i < 4; i++)
			{
				NSDictionary *skill = skills[i];
				if (skill[@"damage bonus"] != nil)
					lDamageBonus += ((NSNumber *)skill[@"damage bonus"]).intValue;
				if (skill[@"attack bonus"] != nil)
					lAttackBonus += ((NSNumber *)skill[@"attack bonus"]).intValue;
				if (skill[@"health"] != nil)
					lHealth += ((NSNumber *)skill[@"health"]).intValue;
				if (skill[@"smash resistance"] != nil)
					lSmashResistance += ((NSNumber *)skill[@"smash resistance"]).intValue;
				if (skill[@"cut resistance"] != nil)
					lCutResistance += ((NSNumber *)skill[@"cut resistance"]).intValue;
				if (skill[@"shock resistance"] != nil)
					lShockResistance += ((NSNumber *)skill[@"shock resistance"]).intValue;
				if (skill[@"burn resistance"] != nil)
					lBurnResistance += ((NSNumber *)skill[@"burn resistance"]).intValue;
				if (skill[@"dodges"] != nil)
					lDodges += ((NSNumber *)skill[@"dodges"]).intValue;
				if (skill[@"blocks"] != nil)
					lBlocks += ((NSNumber *)skill[@"blocks"]).intValue;
				if (skill[@"hacks"] != nil)
					lHacks += ((NSNumber *)skill[@"hacks"]).intValue;
				if (skill[@"metabolism"] != nil)
					lMetabolism += ((NSNumber *)skill[@"metabolism"]).intValue;
				if (skill[@"delay reduction"] != nil)
					lDelayReduction += ((NSNumber *)skill[@"delay reduction"]).intValue;
				if (skill[@"counter"] != nil)
					lCounter += ((NSNumber *)skill[@"counter"]).intValue;
			}
			
			counter += lCounter;
			health += lHealth;
			attackBonus += lAttackBonus;
			damageBonus += lDamageBonus;
			smashResistance += lSmashResistance;
			cutResistance += lCutResistance;
			shockResistance += lShockResistance;
			burnResistance += lBurnResistance;
			dodges += lDodges;
			blocks += lBlocks;
			hacks += lHacks;
			metabolism += lMetabolism;
			delayReduction += lDelayReduction;
			
			//calculate points
			float points = (lHealth / 25.0f) + (lDamageBonus / 25.0f) + (lSmashResistance / 2.0f) + (lCutResistance / 2.0f);
			points += (lShockResistance / 2.0f) + (lBurnResistance / 2.0f) + (lDodges) + (lBlocks) + (lHacks / 3.0f) + (lMetabolism / 30.0f);
			points += lDelayReduction + (lAttackBonus / 35.0f) + (lCounter / 4.0f);
			NSLog(@"Passive points for %@: %f", treeName, points);
		}
	
	NSLog(@"TOTALS:");
	NSLog(@"damage bonus = %i", damageBonus);
	NSLog(@"attack bonus = %i", attackBonus);
	NSLog(@"health = %i", health);
	NSLog(@"smash resistance = %i", smashResistance);
	NSLog(@"cut resistance = %i", cutResistance);
	NSLog(@"shock resistance = %i", shockResistance);
	NSLog(@"burn resistance = %i", burnResistance);
	NSLog(@"dodges = %i", dodges);
	NSLog(@"blocks = %i", blocks);
	NSLog(@"hacks = %i", hacks);
	NSLog(@"metabolism = %i", metabolism);
	NSLog(@"delay reduction = %i", delayReduction);
	NSLog(@"counter = %i", counter);
}

void recipieBalanceTest()
{
	NSArray *recipieNames = loadEntries(@"Recipies").allKeys;
	//TODO: check each non-template recipie and tally up the total ingredient cost of everything
	//and also check each implement and armor in the spawning lists (AKA non-starting items) and tally up their breakdown materials
	//see if they seem to be more or less balanced
	
	NSMutableDictionary *costs = [NSMutableDictionary new];
	NSMutableDictionary *supplies = [NSMutableDictionary new];
	NSMutableDictionary *breakdown = [NSMutableDictionary new];
	
	NSDictionary *lists = loadEntries(@"Lists");
	for (int i = 1; i <= 4; i++)
	{
		NSArray *armorList = lists[[NSString stringWithFormat:@"armors %i", i]];
		for (NSString *armor in armorList)
		{
			NSString *breaksDownInto = loadValueString(@"Armors", armor, @"breaks into");
			supplies[breaksDownInto] = @((supplies[breaksDownInto] != nil ? ((NSNumber *)supplies[breaksDownInto]).intValue : 0) + 1);
			breakdown[armor] = breaksDownInto;
		}
	}
	for (int i = 1; i <= 3; i++)
	{
		NSArray *implementList = lists[[NSString stringWithFormat:@"implements %i", i]];
		for (NSString *implement in implementList)
		{
			NSString *breaksDownInto = loadValueString(@"Implements", implement, @"breaks into");
			supplies[breaksDownInto] = @((supplies[breaksDownInto] != nil ? ((NSNumber *)supplies[breaksDownInto]).intValue : 0) + 1);
			breakdown[implement] = breaksDownInto;
		}
	}
	for (int i = 1; i <= 4; i++)
	{
		NSArray *dropsList = lists[[NSString stringWithFormat:@"drops %i", i]];
		for (NSString *drop in dropsList)
			supplies[drop] = @((supplies[drop] != nil ? ((NSNumber *)supplies[drop]).intValue : 0) + 1);
	}
	
	NSLog(@"Breakdown:");
	for (NSString *name in recipieNames)
		if (![name isEqualToString:@"template"])
		{
			NSString *materialA = loadValueString(@"Recipies", name, @"ingredient a");
			NSString *materialB = @"";
			int materialAamount = loadValueNumber(@"Recipies", name, @"ingredient a amount").intValue;
			costs[materialA] = @((costs[materialA] != nil ? ((NSNumber *)costs[materialA]).intValue : 0) + materialAamount);
			if (loadValueBool(@"Recipies", name, @"ingredient b"))
			{
				materialB = loadValueString(@"Recipies", name, @"ingredient b");
				int materialBamount = loadValueNumber(@"Recipies", name, @"ingredient b amount").intValue;
				costs[materialB] = @((costs[materialB] != nil ? ((NSNumber *)costs[materialB]).intValue : 0) + materialBamount);
			}
			NSString *result = loadValueString(@"Recipies", name, @"result");
			if (breakdown[result] == nil)
				NSLog(@"--%@ has no breakdown", result);
			else
				if (![materialA isEqualToString:breakdown[result]] && ![materialB isEqualToString:breakdown[result]])
					NSLog(@"--ERROR: %@ should cost at least one %@", result, breakdown[result]);
		}
	
	//TODO: check to see if any recipies cost something that the item DOESN'T break down into, and give a warning
	
	NSLog(@"Total costs:");
	for (NSString *key in costs.allKeys)
	{
		NSLog(@"--%@: %i", key, ((NSNumber *)costs[key]).intValue);
	}
	NSLog(@"Total supplies:");
	for (NSString *key in supplies.allKeys)
	{
		NSLog(@"--%@: %i", key, ((NSNumber *)supplies[key]).intValue);
	}
	NSLog(@"Comparison: (low = plentiful supply for the demand, high = low supply for the demand)");
	for (NSString *key in supplies.allKeys)
	{
		int supply = ((NSNumber *)supplies[key]).intValue;
		int demand = ((NSNumber *)costs[key]).intValue;
		float ratio = demand * 1.0f / supply;
		NSLog(@"--%@: %f", key, ratio);
	}
}