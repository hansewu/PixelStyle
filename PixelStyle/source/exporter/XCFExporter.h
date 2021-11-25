#import "Globals.h"
#import "AbstractExporter.h"

/*!
	@class		XCFExporter
	@abstract	Exports to the XCF file format.
	@discussion	The XCF file format is the GIMP's native file format. XCF stands
				for "eXperimental Comupting Facility".
				<br><br>
				<b>License:</b> GNU General Public License<br>
				<b>Copyright:</b> Copyright (c) 2002 Mark Pazolli
*/

@interface XCFExporter : AbstractExporter {
	
	// The version of this document
	int m_nVersion;
	
	// The document that is being exported
	id m_idDocument;
	
	// These hold 64 bytes of temporary information for us 
	int m_aTempIntString[16];
	char m_aTempString[64];
	
	// Used for saving a floating layer
	int m_nFloatingFiller;
	
}

@end
