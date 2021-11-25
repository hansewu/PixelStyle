#import "PSWarning.h"
#import "PSController.h"
#import "PSPrefs.h"
#import "PSWindowContent.h"
#import "PSDocument.h"
#import "WarningsUtility.h"

@implementation PSWarning

- (id)init
{
	self = [super init];
	if(self){
		m_mdDocumentQueues = [[NSMutableDictionary dictionary] retain];
		m_maAppQueue = [[NSMutableArray array] retain];
        m_mdDocumentTempSaveInfo = [[NSMutableDictionary alloc] init];

	}
	return self;
}

- (void)dealloc
{
	[m_mdDocumentQueues release];
	[m_maAppQueue release];
    [m_mdDocumentTempSaveInfo release];
	[super dealloc];
}

- (void)addMessage:(NSString *)message level:(int)level
{
	[m_maAppQueue addObject: [NSDictionary dictionaryWithObjectsAndKeys: message, @"message", [NSNumber numberWithInt:level], @"importance", nil]];
	[self triggerQueue: NULL];
}

- (void)triggerQueue:(id)key
{
	NSMutableArray* queue;
	if(!key){
		queue = m_maAppQueue;
	}else{
		queue = [m_mdDocumentQueues objectForKey:[NSNumber numberWithLong:(long)key]];
	}
	// First check to see if we have any messages
	if(queue && [queue count] > 0){
		// This is the app modal queue
		if(!key){
			while([queue count] > 0){
				NSDictionary *thisWarning = [queue objectAtIndex:0];
				if([[thisWarning objectForKey:@"importance"] intValue] <= [[PSController m_idPSPrefs] warningLevel]){
					NSRunAlertPanel(NULL, [thisWarning objectForKey:@"message"], NULL, NULL, NULL);
				}
				[queue removeObjectAtIndex:0];
			}
		}else {
			// First we need to see if the app has a warning object that
			// is ready to be used (at init it's not all hooked up)
			if([(PSDocument *)key warnings] && [[key warnings] activeWarningImportance] == -1){
				// Next, pop the object out of the queue and pass to the warnings
				NSDictionary *thisWarning = [queue objectAtIndex:0];
				[[key warnings] setWarning: [thisWarning objectForKey:@"message"] ofImportance: [[thisWarning objectForKey:@"importance"] intValue]];
				 [queue removeObjectAtIndex:0];
			}
		}
	}
}

- (void)addMessage:(NSString *)message forDocument:(id)document level:(int)level
{	
	NSMutableArray* thisDocQueue = [m_mdDocumentQueues objectForKey:[NSNumber numberWithLong:(long)document]];
	if(!thisDocQueue){
		thisDocQueue = [NSMutableArray array];
		[m_mdDocumentQueues setObject: thisDocQueue forKey: [NSNumber numberWithLong:(long)document]];
	}
	[thisDocQueue addObject: [NSDictionary dictionaryWithObjectsAndKeys: message, @"message", [NSNumber numberWithInt: level], @"importance", nil]];
	[self triggerQueue: document];
}

- (void)showAlertInfo:(nullable NSString*)message infoText:(nullable NSString*)infoText
{
    NSAlert *alert = [NSAlert alertWithMessageText:message defaultButton:NSLocalizedString(@"OK", nil) alternateButton:nil otherButton:nil informativeTextWithFormat:@"%@", infoText];
    [alert setAlertStyle:NSWarningAlertStyle];
    [alert runModal];
    
}

- (void)addCrashInfo:(nullable NSDictionary*)info forKey:(int)key
{
    NSString *docKey = [NSString stringWithFormat:@"%d",key];
    [m_mdDocumentTempSaveInfo setObject:info forKey:docKey]; //[NSNumber numberWithInt:key]
    [gUserDefaults setValue:m_mdDocumentTempSaveInfo forKey:@"LAST_CRASH_FILE_PATH"];
}

- (void)removeCrashInfoForKey:(int)key
{
    NSString *docKey = [NSString stringWithFormat:@"%d",key];
    [m_mdDocumentTempSaveInfo removeObjectForKey:docKey];
    [gUserDefaults setValue:m_mdDocumentTempSaveInfo forKey:@"LAST_CRASH_FILE_PATH"];
}

@end
