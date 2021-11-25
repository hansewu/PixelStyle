#import "UtilitiesManager.h"
#import "PegasusUtility.h"
#import "ToolboxUtility.h"
#import "OptionsUtility.h"
#import "InfoUtility.h"
#import "PSController.h"
#import "PSHistogramUtility.h"
#import "EffectUtility.h"
#import "PSChannelsUtility.h"

@implementation UtilitiesManager

- (id)init
{
	if(![super init])
		return NULL;
	m_mdPegasusUtilities = [[NSMutableDictionary alloc] init];
	m_mdToolboxUtilities = [[NSMutableDictionary alloc] init];
	m_mdBrushUtilities = [[NSMutableDictionary alloc] init];
    m_mdMyBrushUtilities = [[NSMutableDictionary alloc] init];
	m_mdOptionsUtilities = [[NSMutableDictionary alloc] init];
	m_mdTextureUtilities = [[NSMutableDictionary alloc] init];
	m_mdInfoUtilities = [[NSMutableDictionary alloc] init];
	m_mdStatusUtilities = [[NSMutableDictionary alloc] init];
    m_mdHistogramUtilities = [[NSMutableDictionary alloc] init];
    m_mdEffectUtilities = [[NSMutableDictionary alloc] init];
    m_mdSmartFilterUtilities = [[NSMutableDictionary alloc] init];
    m_mdHelpInfoUtilities = [[NSMutableDictionary alloc] init];
    m_mdChannelsUtilities = [[NSMutableDictionary alloc] init];
    
	return self;
}

- (void)awakeFromNib
{	
	// Make sure we are informed when the application shuts down
	[m_idController registerForTermination:self];
}

- (void)terminate
{
	[m_mdPegasusUtilities autorelease];
	[m_mdToolboxUtilities autorelease];
	[m_mdBrushUtilities autorelease];
    [m_mdMyBrushUtilities autorelease];
	[m_mdOptionsUtilities autorelease];
	[m_mdTextureUtilities autorelease];
	[m_mdInfoUtilities autorelease];
	[m_mdStatusUtilities autorelease];
    [m_mdHistogramUtilities autorelease];
    [m_mdEffectUtilities autorelease];
    [m_mdSmartFilterUtilities autorelease];
	
	// Force such information to be written to the hard disk
	[gUserDefaults synchronize];
}

- (void)shutdownFor:(id)doc
{
	NSNumber *key = [NSNumber numberWithLong:(long)doc];

	[m_mdPegasusUtilities removeObjectForKey:key];
	[m_mdToolboxUtilities  removeObjectForKey:key];
	
	[[self brushUtilityFor:doc] shutdown];
	[m_mdBrushUtilities  removeObjectForKey:key];
    
    [[self myBrushUtilityFor:doc] shutdown];
    [m_mdMyBrushUtilities removeObjectForKey:key];
	
	[[self optionsUtilityFor:doc] shutdown];
	[m_mdOptionsUtilities  removeObjectForKey:key];
	
	[[self textureUtilityFor:doc] shutdown];
	[m_mdTextureUtilities  removeObjectForKey:key];
	
	[[self infoUtilityFor:doc] shutdown];
	[m_mdInfoUtilities  removeObjectForKey:key];
    
    [[self histogramUtilityFor:doc] shutdown];
    [m_mdHistogramUtilities  removeObjectForKey:key];
    
    [m_mdEffectUtilities  removeObjectForKey:key];
    [m_mdSmartFilterUtilities removeObjectForKey:key];
}

- (void)activate:(id)sender
{
	[(PegasusUtility *)[self pegasusUtilityFor:sender] activate];
	[(ToolboxUtility *)[self toolboxUtilityFor:sender] activate];
	[(OptionsUtility *)[self optionsUtilityFor:sender] activate];
	[(InfoUtility *)[self infoUtilityFor:sender] activate];
    [(PSHistogramUtility *)[self histogramUtilityFor:sender] activate];
//    [(EffectUtility *)[self effectUtilityFor:sender] activate];
    
    [(PSChannelsUtility *)[self channelsUtilityFor:sender] activate];
}

#pragma mark - get Utility

- (id)pegasusUtilityFor:(id)doc
{
	return [m_mdPegasusUtilities objectForKey:[NSNumber numberWithLong:(long)doc]];
}

- (id)transparentUtility
{
	return m_idTransparentUtility;
}

- (id)toolboxUtilityFor:(id)doc
{
	return [m_mdToolboxUtilities objectForKey: [NSNumber numberWithLong:(long)doc]];
}

- (id)brushUtilityFor:(id)doc
{
	return [m_mdBrushUtilities objectForKey:[NSNumber numberWithLong:(long)doc]];
}

- (id)myBrushUtilityFor:(id)doc
{
    return [m_mdMyBrushUtilities objectForKey:[NSNumber numberWithLong:(long)doc]];
}

- (id)textureUtilityFor:(id)doc
{
	return [m_mdTextureUtilities objectForKey:[NSNumber numberWithLong:(long)doc]];
}

- (id)optionsUtilityFor:(id)doc
{
	return [m_mdOptionsUtilities objectForKey: [NSNumber numberWithLong:(long)doc]];
}

- (id)infoUtilityFor:(id)doc
{
	return [m_mdInfoUtilities objectForKey:[NSNumber numberWithLong:(long)doc]];
}

- (id)statusUtilityFor:(id)doc
{
	return [m_mdStatusUtilities objectForKey:[NSNumber numberWithLong:(long)doc]];
}

- (id)histogramUtilityFor:(id)doc
{
    return [m_mdHistogramUtilities objectForKey:[NSNumber numberWithLong:(long)doc]];
}

-(id)effectUtilityFor:(id)doc
{
    return [m_mdEffectUtilities objectForKey:[NSNumber numberWithLong:(long)doc]];
}

- (id)smartFilterUtilityFor:(id)doc
{
    return [m_mdSmartFilterUtilities objectForKey:[NSNumber numberWithLong:(long)doc]];
}

- (id)helpInfoUtilityFor:(id)doc
{
    return [m_mdHelpInfoUtilities objectForKey:[NSNumber numberWithLong:(long)doc]];
}

- (id)channelsUtilityFor:(id)doc
{
    return [m_mdChannelsUtilities objectForKey:[NSNumber numberWithLong:(long)doc]];
}

#pragma mark - set Utility

- (void)setPegasusUtility:(id)util for:(id)doc
{
	[m_mdPegasusUtilities setObject:util forKey:[NSNumber numberWithLong:(long)doc]];
}

- (void)setToolboxUtility:(id)util for:(id)doc
{
	[m_mdToolboxUtilities setObject:util forKey:[NSNumber numberWithLong:(long)doc]];
}

- (void)setBrushUtility:(id)util for:(id)doc
{
	[m_mdBrushUtilities setObject:util forKey:[NSNumber numberWithLong:(long)doc]];
}

- (void)setMyBrushUtility:(id)util for:(id)doc
{
    [m_mdMyBrushUtilities setObject:util forKey:[NSNumber numberWithLong:(long)doc]];
}

- (void)setTextureUtility:(id)util for:(id)doc
{
	[m_mdTextureUtilities setObject:util forKey:[NSNumber numberWithLong:(long)doc]];
}

- (void)setOptionsUtility:(id)util for:(id)doc
{
	[m_mdOptionsUtilities setObject:util forKey:[NSNumber numberWithLong:(long)doc]];
}

- (void)setInfoUtility:(id)util for:(id)doc
{
	[m_mdInfoUtilities setObject:util forKey:[NSNumber numberWithLong:(long)doc]];
}

- (void)setStatusUtility:(id)util for:(id)doc
{
	[m_mdStatusUtilities setObject:util forKey:[NSNumber numberWithLong:(long)doc]];
}

- (void)setHistogramUtility:(id)util for:(id)doc
{
    [m_mdHistogramUtilities setObject:util forKey:[NSNumber numberWithLong:(long)doc]];
}

- (void)setEffectUtility:(id)util for:(id)doc
{
    [m_mdEffectUtilities setObject:util forKey:[NSNumber numberWithLong:(long)doc]];
}


- (void)setSmartFilterUtility:(id)util for:(id)doc
{
    [m_mdSmartFilterUtilities setObject:util forKey:[NSNumber numberWithLong:(long)doc]];
}


- (void)setHelpInfoUtility:(id)util for:(id)doc
{
    [m_mdHelpInfoUtilities setObject:util forKey:[NSNumber numberWithLong:(long)doc]];
}

- (void)setChannelsUtility:(id)util for:(id)doc
{
    [m_mdChannelsUtilities setObject:util forKey:[NSNumber numberWithLong:(long)doc]];
}

@end
