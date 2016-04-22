//
//  SoundPlayer.m
//  Delve
//
//  Created by Theodore Abshire on 4/21/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

#import "SoundPlayer.h"
#import "Constants.h"
#import <AVFoundation/AVAudioPlayer.h>

@interface SoundPlayer()

@property (strong, atomic) NSMutableSet *activeSounds;


@end


@implementation SoundPlayer

+(id) sharedPlayer
{
	static SoundPlayer *shared = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken,
	^(){
		shared = [[self alloc] init];
	});
	return shared;
}

-(id)init
{
	if (self = [super init])
	{
		//TODO: init the array
		_activeSounds = [NSMutableSet new];
	}
	return self;
}


-(void) playSound:(NSString *)soundCategoryName
{
	//TODO: get bgm (menu, floor 1-3, floor 4-6, floor 7-9, maybe a short song for defeat and for victory)
	
	
	//TODO: put all the liscense info here
	//NOTE: all sounds from freesound.org
	//		S: frumdum.wav by spectorjay | License: Sampling+
	//		S: Nuclear Alarm by plasterbrain | License: Creative Commons 0
	//		S: Moaning Chair.aif by Housed1J | License: Creative Commons 0
	//		S: Bubbles2.wav by kwahmah_02 | License: Attribution
	//		S: Radio.wav by ZvinbergsA | License: Creative Commons 0
	//		S: bow01.wav by Erdie | License: Attribution
	//		S: Match Ignition 8 by HunteR4708 | License: Creative Commons 0
	//		S: GrowlSnarl.wav by Jamius | License: Attribution
	//		S: Short-Fireball-Woosh.flac by wjl | License: Creative Commons 0
	//		S: Pop sound by deraj | License: Creative Commons 0
	//		S: huh.wav by EiK | License: Creative Commons 0
	//		S: Explosion00.wav by jeremysykes | License: Creative Commons 0
	//		S: Squelch_4.wav by Adam_N | License: Creative Commons 0
	//		S: BoneClicks&GoreSquelches_17.aif by vincentoliver | License: Attribution
	//		S: robotspeaking4 by dotY21 | License: Creative Commons 0
	//		S: Robot2_11.wav by LittleRobotSoundFactory | License: Attribution
	//		S: GirlShock01.wav by Otakua | License: Attribution
	//		S: GirlShock02.wav by Otakua | License: Attribution
	//		S: Shocked gasp.wav by GentlemanWalrus | License: Creative Commons 0
	//		S: hit lid with sledge hammer.wav by dcolvin | License: Attribution
	//		S: Sword Slice 14.wav by Black Snow | License: Attribution
	//		S: whoosh fire by sfx4animation | License: Attribution Noncommercial
	//		S: SwordClash05 by 32cheeseman32 | License: Attribution
	//		S: Sword_Clash (48).wav by JohnBuhr | License: Creative Commons 0
	//		S: swoosh wind 09.flac by qubodup | License: Creative Commons 0
	//		S: swoosh39.wav by kwahmah_02 | License: Attribution
	//		S: 01904 air swoosh.wav by Robinhood76 | License: Attribution Noncommercial
	
	
	//unsupported formats I've noticed so far:
	//	.flac
	//	.ogg
	
	
	if (soundCategoryName.length == 0)
		return;
	
	NSLog(@"Playing sound %@", soundCategoryName);
	
	//pick randomly from the sound array
	NSArray *soundArray = loadArrayEntry(@"Sounds", soundCategoryName);
	if (soundArray.count == 0)
		return;
	NSString *pick = soundArray[arc4random_uniform((u_int32_t)soundArray.count)];
	NSString *filePath = [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], pick];
	NSURL *fileURL = [NSURL fileURLWithPath:filePath];
	
	NSError *error;
	AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:&error];
	
	if (error != nil)
	{
		NSLog(@"SOUND ERROR: %@", [error description]);
		return;
	}
	
	
	player.numberOfLoops = 0;
	
	player.volume = 0.3f;
	
	[player play];
	
	//store the player into an array so it's not garbage-collected
	[self.activeSounds addObject:player];
	
	//add a timer to remove the sound
	[NSTimer timerWithTimeInterval:player.duration + 0.1f target:self selector:@selector(soundPlayed:) userInfo:nil repeats:NO];
}

-(void)soundPlayed:(NSTimer *)timer
{
	for (AVAudioPlayer *sound in self.activeSounds)
		if (!sound.playing)
			[self.activeSounds removeObject:sound];
}


@end