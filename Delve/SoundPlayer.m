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
#import <AudioToolbox/AudioServices.h>

@interface SoundPlayer()

@property (strong, atomic) NSMutableSet *activeSounds;
@property (strong, atomic) AVAudioPlayer *bgmPlayer;
@property (strong, atomic) NSString *bgmName;

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
	//		S: Large Anvil & Steel Hammer .wav by Benboncan | License: Attribution
	//		S: locking a door_02.wav by Dymewiz | License: Attribution
	
	
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
	
	//using soundID because AVAudioPlayer is a bit too heavyweight for sound-effects like these
	SystemSoundID soundID;
	OSStatus error = AudioServicesCreateSystemSoundID((__bridge CFURLRef)fileURL, &soundID);
	if (error == kAudioSessionNoError)
	{
		//set kAudioServicesPropertyIsUISound to 0 since this isn't a UI sound
		UInt32 flag = 0;
		AudioServicesSetProperty(kAudioServicesPropertyIsUISound, sizeof(UInt32), &soundID, sizeof(UInt32), &flag);
		
		//play sound
		AudioServicesPlaySystemSound(soundID);
		
	}
	else
		NSLog(@"Sound %@ failed with error #%d.", soundCategoryName, (int)error);
}

-(void) playBGM:(NSString *)songFilename
{
	//TODO: get bgm (menu, floor 1-3, floor 4-6, floor 7-9, maybe a short song for defeat and for victory)
	//all songs from incompetech
	//floor 0-2 song
	//	floors in this range: start, bandits, first robots
	//	"simplex" tense music
	//floor 3-5 song
	//	floors in this range: zealots, forest, research lab
	//	"dreams become real" calm piano piece
	//floor 6-8 song
	//	floors in this range: broken ship, raider expedition, highborn fort
	//	"failing defense" warlike battle theme, good since this is mostly fighting soldiers
	//floor 9 song
	//	floors in this range: true ship
	//	"the way out" it has an appropriate name, okay
	//defeat fanfare
	//	"steel and seething"
	//victory fanfare?
	//	"feather waltz"
	//menu music
	//	"hypnothis"
	
	
	if (self.bgmName != nil && [self.bgmName isEqualToString:songFilename])
		return; //don't do anything
	
	NSString *filePath = [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], songFilename];
	NSURL *fileURL = [NSURL fileURLWithPath:filePath];
	
	if (self.bgmPlayer != nil)
		[self.bgmPlayer stop];
	self.bgmPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:nil];
	
	self.bgmPlayer.numberOfLoops = -1;
	self.bgmPlayer.volume = 0.4;
	
	[self.bgmPlayer play];
}


@end