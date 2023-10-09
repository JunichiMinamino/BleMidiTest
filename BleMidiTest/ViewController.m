//
//  ViewController.m
//  BleMidiTest
//
//  Created by LoopSessions on 2022/05/06.
//

#import <CoreAudioKit/CoreAudioKit.h>
#import "ViewController.h"
#import "PGMidi.h"

@interface ViewController () <PGMidiDelegate, PGMidiSourceDelegate>
{
	PGMidi *_midi;
	
	UILabel *_labelCount;
	UIScrollView *_scrollViewReceive;
	UILabel *_labelReceive;
}
@end

@implementation ViewController

- (id)init
{
	self = [super init];
	if (self != nil) {
	}
	return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	self.view.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1.0];
	
	////////////////
	_midi = [[PGMidi alloc] init];
	_midi.networkEnabled = YES;
	_midi.delegate = self;
	for (PGMidiSource *source in _midi.sources) {
		[source addDelegate:self];
	}
	_midi.virtualDestinationEnabled = YES;
	_midi.virtualSourceEnabled = YES;
	////////////////
	
	CGFloat fWidth = [[UIScreen mainScreen] bounds].size.width;
	CGFloat fHeight = [[UIScreen mainScreen] bounds].size.height;
	
	NSArray *arSubTitle = @[@"Connect", @"Send", @"Receive"];
	float fSubTitleY[] = {80.0, 80.0 + 130.0, 80.0 + 130.0 * 2 + 70.0};
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
		fSubTitleY[2] = 80.0 + 130.0 * 2;
	}
	UILabel *labelSubTitle[3];
	for (int i = 0; i < 3; i++) {
		labelSubTitle[i] = [[UILabel alloc] init];
		labelSubTitle[i].frame = CGRectMake(20.0, fSubTitleY[i], fWidth - 20.0, 40.0);
		labelSubTitle[i].text = arSubTitle[i];
		labelSubTitle[i].font = [UIFont systemFontOfSize:18.0];
		[self.view addSubview:labelSubTitle[i]];
	}

	NSArray *arTitleConnect = @[@"Central", @"Peripheral"];
	UIButton *buttonConnect[2];
	for (int i = 0; i < 2; i++) {
		buttonConnect[i] = [UIButton buttonWithType:UIButtonTypeCustom];
		buttonConnect[i].tag = 1000 + i;
		[buttonConnect[i] setFrame:CGRectMake(20.0 + 140.0 * i, 80.0 + 50.0, 120.0, 60.0)];
		[buttonConnect[i] setTitle:arTitleConnect[i] forState:UIControlStateNormal];
		buttonConnect[i].backgroundColor = [UIColor lightGrayColor];
		[buttonConnect[i] addTarget:self action:@selector(buttonConnectAct:) forControlEvents:UIControlEventTouchUpInside];
		[self.view addSubview:buttonConnect[i]];
		buttonConnect[i].layer.borderColor = [[UIColor blackColor] CGColor];
		buttonConnect[i].layer.borderWidth = 1.0;
		buttonConnect[i].layer.cornerRadius = 6.0;
		buttonConnect[i].clipsToBounds = YES;
	}

	NSArray *arTitleSend = @[@"C", @"D", @"E", @"F", @"G", @"A", @"B", @"C"];
	UIButton *buttonSend[8];
	for (int i = 0; i < 8; i++) {
		buttonSend[i] = [UIButton buttonWithType:UIButtonTypeCustom];
		buttonSend[i].tag = 2000 + i;
		if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
			[buttonSend[i] setFrame:CGRectMake(20.0 + 80.0 * i, 80.0 + 130.0 + 50.0, 70.0, 60.0)];
		} else {
			[buttonSend[i] setFrame:CGRectMake(20.0 + 80.0 * (i % 4), 80.0 + 130.0 + 50.0 + 70.0 * (i / 4), 70.0, 60.0)];
		}
		[buttonSend[i] setTitle:arTitleSend[i] forState:UIControlStateNormal];
		buttonSend[i].backgroundColor = [UIColor lightGrayColor];
		[buttonSend[i] addTarget:self action:@selector(buttonSendDownAct:) forControlEvents:UIControlEventTouchDown];
		[buttonSend[i] addTarget:self action:@selector(buttonSendUpAct:) forControlEvents:UIControlEventTouchUpInside];
		[buttonSend[i] addTarget:self action:@selector(buttonSendUpAct:) forControlEvents:UIControlEventTouchUpOutside];
		[self.view addSubview:buttonSend[i]];
		buttonSend[i].layer.borderColor = [[UIColor blackColor] CGColor];
		buttonSend[i].layer.borderWidth = 1.0;
		buttonSend[i].layer.cornerRadius = 6.0;
		buttonSend[i].clipsToBounds = YES;
	}
	
	UIButton *buttonClearReceive = [UIButton buttonWithType:UIButtonTypeCustom];
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
		[buttonClearReceive setFrame:CGRectMake(20.0 + 80.0 * 7, 80.0 + 130.0 * 2, 70.0, 40.0)];
	} else {
		[buttonClearReceive setFrame:CGRectMake(20.0 + 80.0 * 3, 80.0 + 130.0 * 2 + 70.0, 70.0, 40.0)];
	}
	[buttonClearReceive setTitle:@"Clear" forState:UIControlStateNormal];
	buttonClearReceive.backgroundColor = [UIColor lightGrayColor];
	[buttonClearReceive addTarget:self action:@selector(buttonClearReceiveAct:) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:buttonClearReceive];
	buttonClearReceive.layer.borderColor = [[UIColor blackColor] CGColor];
	buttonClearReceive.layer.borderWidth = 1.0;
	buttonClearReceive.layer.cornerRadius = 6.0;
	buttonClearReceive.clipsToBounds = YES;

	_labelCount = [[UILabel alloc] init];
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
		[_labelCount setFrame:CGRectMake(10.0, 80.0 + 130.0 * 2 + 50.0, fWidth - 20.0, 30.0)];
	} else {
		[_labelCount setFrame:CGRectMake(10.0, 80.0 + 130.0 * 2 + 70.0 + 50.0, fWidth - 20.0, 30.0)];
		_labelCount.font = [UIFont systemFontOfSize:11.0];
	}
	[_labelCount setBackgroundColor:[UIColor whiteColor]];
	_labelCount.numberOfLines = 0;
	[self.view addSubview:_labelCount];

	_scrollViewReceive = [[UIScrollView alloc] init];
	float fScrollViewReceiveY = 80.0 + 130.0 * 2 + 70.0 + 50.0 + 35.0;
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
		fScrollViewReceiveY = 80.0 + 130.0 * 2 + 50.0 + 35.0;
	}
	[_scrollViewReceive setFrame:CGRectMake(10.0, fScrollViewReceiveY, fWidth - 20.0, fHeight - (fScrollViewReceiveY + 35.0))];
	_scrollViewReceive.backgroundColor = [UIColor whiteColor];
	_scrollViewReceive.contentSize = CGSizeMake(_scrollViewReceive.frame.size.width, _scrollViewReceive.frame.size.height);
	[self.view addSubview:_scrollViewReceive];

	_labelReceive = [[UILabel alloc] init];
	[_labelReceive setFrame:CGRectMake(0.0, 0.0, _scrollViewReceive.frame.size.width, _scrollViewReceive.frame.size.height)];
	[_labelReceive setBackgroundColor:[UIColor whiteColor]];
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
		_labelReceive.font = [UIFont systemFontOfSize:18.0];
	}
	_labelReceive.numberOfLines = 0;
	[_labelReceive sizeToFit];
	[_scrollViewReceive addSubview:_labelReceive];

}

////////////////////////////////////////////////////////////////
#pragma mark -

- (void)buttonConnectAct:(UIButton *)sender
{
	NSInteger iIndex = sender.tag - 1000;
	
	if (iIndex == 0) {
		// Central
		CABTMIDICentralViewController *pCentralVC = [[CABTMIDICentralViewController alloc] init];
		[self.navigationController pushViewController:pCentralVC animated:YES];
	} else {
		// Peripheral
		CABTMIDILocalPeripheralViewController *pPeripheralVC = [[CABTMIDILocalPeripheralViewController alloc] init];
		[self.navigationController pushViewController:pPeripheralVC animated:YES];
	}
}

- (void)buttonClearReceiveAct:(UIButton *)sender
{
	_labelReceive.text = @"";
	
	[self updateReceiveLabel:@""];
}

////////////////////////////////////////////////////////////////
#pragma mark -

- (void)buttonSendDownAct:(UIButton *)sender
{
	NSInteger iIndex = sender.tag - 2000;
	
	UInt32 iNotes[] = {60, 62, 64, 65, 67, 69, 71, 72};
	
	[self sendMidiDataNoteOnInBackground:0 note:iNotes[iIndex] velocity:127];
	
	sender.backgroundColor = [UIColor grayColor];
}

- (void)buttonSendUpAct:(UIButton *)sender
{
	NSInteger iIndex = sender.tag - 2000;
	
	UInt32 iNotes[] = {60, 62, 64, 65, 67, 69, 71, 72};

	[self sendMidiDataNoteOffInBackground:0 note:iNotes[iIndex] velocity:0];
	
	sender.backgroundColor = [UIColor lightGrayColor];
}

- (void)sendMidiDataNoteOnInBackground:(UInt32)iIndex note:(UInt32)iNote velocity:(UInt32)iVelocity
{
	const UInt8 noteOn[] = { 0x90 + iIndex, iNote, iVelocity };
	
	[_midi sendBytes:noteOn size:sizeof(noteOn)];
}

- (void)sendMidiDataNoteOffInBackground:(UInt32)iIndex note:(UInt32)iNote velocity:(UInt32)iVelocity
{
	const UInt8 noteOff[] = { 0x80 + iIndex, iNote, iVelocity };
	
	[_midi sendBytes:noteOff size:sizeof(noteOff)];
}

////////////////////////////////////////////////////////////////
#pragma mark - PGMidiDelegate

- (void)midi:(PGMidi *)midi sourceAdded:(PGMidiSource *)source
{
	[source addDelegate:self];
	[self updateCountLabel];
	[self updateReceiveLabel:[NSString stringWithFormat:@"Source added: %@", ToString(source)]];
}

- (void)midi:(PGMidi *)midi sourceRemoved:(PGMidiSource *)source
{
	[self updateCountLabel];
	[self updateReceiveLabel:[NSString stringWithFormat:@"Source removed: %@", ToString(source)]];
}

// Connect USB keyboard
- (void)midi:(PGMidi *)midi destinationAdded:(PGMidiDestination *)destination
{
	[self updateCountLabel];
	[self updateReceiveLabel:[NSString stringWithFormat:@"Desintation added: %@", ToString(destination)]];
}

- (void)midi:(PGMidi *)midi destinationRemoved:(PGMidiDestination *)destination
{
	[self updateCountLabel];
	[self updateReceiveLabel:[NSString stringWithFormat:@"Desintation removed: %@", ToString(destination)]];
}

- (void)updateReceiveLabel:(NSString *)string
{
	NSString *strBak = _labelReceive.text;
	
	if (strBak.length == 0) {
		_labelReceive.text = string;
	} else {
		_labelReceive.text = [NSString stringWithFormat:@"%@\n%@", strBak, string];
	}
	NSLog(@"%@", string);
	
	float fScrollViewWidth = _scrollViewReceive.frame.size.width;
	float fLabelWidth = _labelReceive.frame.size.width;

	_labelReceive.frame = CGRectMake(0.0, 0.0, 1366.0, _labelReceive.frame.size.height + 10.0);
	[_labelReceive sizeToFit];
	
	// adjust width
	if (fLabelWidth < _labelReceive.frame.size.width + 10.0) {
		fLabelWidth = _labelReceive.frame.size.width + 10.0;
	}
	if (fLabelWidth < fScrollViewWidth) {
		fLabelWidth = fScrollViewWidth;
	}
	
	_scrollViewReceive.contentSize = CGSizeMake(fLabelWidth, _labelReceive.frame.size.height + 10.0);
}

- (void)updateCountLabel
{
	NSString *strCount = [NSString stringWithFormat:@"sources=%u destinations=%u", (unsigned)_midi.sources.count, (unsigned)_midi.destinations.count];
	_labelCount.text = strCount;
	NSLog(@"%@", strCount);
}

const char *isToString(BOOL b)
{
	return b ? "yes":"no";
}

NSString *ToString(PGMidiConnection *connection)
{
	return [NSString stringWithFormat:@"< PGMidiConnection: name=%@ isNetwork=%s >", connection.name, isToString(connection.isNetworkSession)];
}

////////////////////////////////////////////////////////////////
#pragma mark - PGMidiSourceDelegate

- (void)callMIDIPacket:(NSInteger)iIndex packet:(const MIDIPacket *)packet
{
//	NSData *dataRet = [NSData dataWithBytes:packet->data length:packet->length];
//	NSLog(@"dataRet %@", dataRet);
	
	NSMutableString *strPacket = [NSMutableString string];
	for (int i=0; i < packet->length; i++) {
		[strPacket appendFormat:@"%X ", packet->data[i]];
	}
	[self updateReceiveLabel:strPacket];
}

- (void)midiSource:(PGMidiSource *)midi midiReceived:(const MIDIPacketList *)packetList
{
	const MIDIPacket *packet = &packetList->packet[0];
	for (int i = 0; i < packetList->numPackets; ++i) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[self callMIDIPacket:i packet:packet];
		});
		
		packet = MIDIPacketNext(packet);
	}
}

@end
