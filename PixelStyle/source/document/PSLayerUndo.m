#import "PSLayerUndo.h"
#import "PSLayer.h"
#import "PSContent.h"
#import "PSDocument.h"
#import "PSWhiteboard.h"
#import "PSController.h"
#import "PSPrefs.h"
#import "PSHelpers.h"
#import <sys/stat.h>
#import <sys/mount.h>

extern int tempFileCount;
extern BOOL userWarnedOnDiskSpace;

typedef struct
{
    int sizeAlloced;
    IntRect rect;
    
}SECTION_MEM;

@implementation PSLayerUndo

- (id)initWithDocument:(id)doc forLayer:(id)ilayer
{
	// Setup our local variables
	m_idDocument = doc;
	m_idLayer = ilayer;
	m_ulMemoryCacheSize = (unsigned long)[[PSController m_idPSPrefs] memoryCacheSize];
	
	// Allocate the initial m_psRecords size
	m_psRecords = malloc(kNumberOfUndoRecordsPerMalloc * sizeof(UndoRecord));
	m_nRecordsMaxLen = kNumberOfUndoRecordsPerMalloc;
	m_nRecordsLen = 0;
	
	// Allocate the memory cache
	m_nMemoryCacheLen = m_ulMemoryCacheSize * 1024;
	m_pMemoryCache = malloc(m_nMemoryCacheLen);
	m_nMemoryCachePos = 0;
	
	return self;
}

- (void)dealloc
{
	struct stat sb;
	char *tempFileName;
	int i, j;
	short oldFileNumber;
	
	// Free the disk cache
	for (i = 0; i < m_nRecordsLen; i++)
    {
		if (m_psRecords[i].fileNumber >= 0)
        {
            NSString *filePath = [NSString stringWithFormat:@"%@/psundo-%d", [self getUndoSavePath], m_psRecords[i].fileNumber];
			tempFileName = (char *)[filePath fileSystemRepresentation];
			if (stat(tempFileName, &sb) == 0)
            {
				oldFileNumber = m_psRecords[i].fileNumber;
				for (j = 0; j < m_nRecordsLen; j++)
                {
					if (m_psRecords[j].fileNumber == oldFileNumber)
                    {
						m_psRecords[j].fileNumber = -2;
					}
				}
				unlink(tempFileName);
			}
		}
	}
	
	// Free the memory cache
	if (m_pMemoryCache) free(m_pMemoryCache);
	
	// Free the record of the memory cache
	if (m_psRecords) free(m_psRecords);
	
	// Call the super
	[super dealloc];
}

- (BOOL)checkDiskSpace
{
	struct statfs fs;
	struct stat sb;
	char *tempFileName;
	int i, j;
	unsigned long spaceLeft;
	short oldFileNumber;
	BOOL badstate;
	
	// Determine the disk space remaining
    
	statfs([[self getUndoSavePath] cStringUsingEncoding:NSUTF8StringEncoding], &fs);
	spaceLeft = ((unsigned long long)fs.f_bfree * (unsigned long long)fs.f_bsize) / ((unsigned long long)1024);
	badstate = spaceLeft < (unsigned long)(50 * 1024) || spaceLeft < m_ulMemoryCacheSize * (unsigned long)12;
	
    if (badstate)
    {
	
		// If it is too low display a warning
		if (userWarnedOnDiskSpace == NO) {
			NSRunAlertPanel(LOCALSTR(@"disk space title", @"Disk space low"), LOCALSTR(@"disk space body", @"Your system disk now has limited space, you should quit the app and free more space."), LOCALSTR(@"ok", @"OK"), NULL, NULL);
			userWarnedOnDiskSpace = YES;
		}
		
		// And remove as many of *our* files as necessary to restore 50 MB of system disk space
		for (i = 0; i < m_nRecordsLen && badstate; i++)
        {
			if (m_psRecords[i].fileNumber >= 0)
            {
				oldFileNumber = m_psRecords[i].fileNumber;
                NSString *filePath = [NSString stringWithFormat:@"%@/psundo-%d", [self getUndoSavePath], oldFileNumber];
				tempFileName = (char *)[filePath fileSystemRepresentation];
				if (stat(tempFileName, &sb) == 0)
                {
					for (j = 0; j < m_nRecordsLen; j++)
                    {
						if (m_psRecords[j].fileNumber == oldFileNumber)
                        {
							m_psRecords[j].fileNumber = -2;
						}
					}
					spaceLeft += sb.st_size;
					unlink(tempFileName);
				}
			}
			badstate = spaceLeft < (unsigned long)(50 * 1024) || spaceLeft < m_ulMemoryCacheSize * (unsigned long)12;
		}
		
	}
	
	// In the very worst cases recommend that undo data not be written to disk
	if (spaceLeft < (unsigned long)(16 * 1024) || spaceLeft < m_ulMemoryCacheSize * (unsigned long)3)
		return NO;
		
	return YES;
}

- (void)writeMemoryCache
{
	FILE *file;
	int fileNo, i;

	// Check we actually have something to write to disk
	if (m_nMemoryCachePos > 0)
    {

		// Check we have sufficient disk space
		if ([self checkDiskSpace])
        {
			
			// Set the file number and increment the tempFileCount
			fileNo = tempFileCount;
			tempFileCount++;
			
			// Open a file for writing the memory cache
            NSString *filePath = [NSString stringWithFormat:@"%@/psundo-%d", [self getUndoSavePath], fileNo];
			file = fopen([filePath fileSystemRepresentation], "w");
			
			// Write the memory cache
			if (file != NULL) fwrite(m_pMemoryCache, sizeof(unsigned char), m_nMemoryCachePos, file);
			if (file == NULL) fileNo = -2;
			
			// Go through each record checking it if it has been written to disk
			for (i = 0; i < m_nRecordsLen; i++)
            {
				if (m_psRecords[i].fileNumber == -1)
                {
					m_psRecords[i].fileNumber = fileNo;
					m_psRecords[i].data = NULL;
				}
			}
			
			// Close the file
			fclose(file);
			
			// Free the memory cache
			free(m_pMemoryCache);
			m_pMemoryCache = NULL;
			m_nMemoryCacheLen = 0;
			m_nMemoryCachePos = 0;
			
			// Write debugging notices
			#ifdef DEBUG
			NSLog(@"Memory converted to the disk cache.");
			#endif
		}
		
	}
	else
    {
		// Free the memory cache
		free(m_pMemoryCache);
		m_pMemoryCache = NULL;
		m_nMemoryCacheLen = 0;
		m_nMemoryCachePos = 0;
	
	}		
}

- (NSString *)getUndoSavePath
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *cachedPath = nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString* bundleID = [[NSBundle mainBundle] bundleIdentifier];
    
    if ([paths count] > 0)
    {
        cachedPath = [paths objectAtIndex:0];
        cachedPath = [cachedPath stringByAppendingPathComponent:bundleID];
        cachedPath = [cachedPath stringByAppendingPathComponent:@"temp"];
    }
    
    if (![fileManager fileExistsAtPath:cachedPath])
    {
        [fileManager createDirectoryAtPath:cachedPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return cachedPath;
}

- (BOOL)loadMemoryCacheWithIndex:(int)index
{
	FILE *file;
	struct stat sb;
	int i, fileNo, spp;
	const char *fileName;
	int *int_ptr;

	// Set up variables
	fileNo = m_psRecords[index].fileNumber;
	spp = [(PSContent *)[m_idDocument contents] spp];

	// If the record is already in the memory cache succeed
	if (fileNo == -1) return YES;
	
	// If the record has an undefined file attached to it fail
	if (fileNo == -2) return NO;

	// Otherwise write the current memory cache to disk
	[self writeMemoryCache];
	
	// Open the file associated with this record
    NSString *filePath = [NSString stringWithFormat:@"%@/psundo-%d", [self getUndoSavePath], fileNo];
	fileName = [filePath fileSystemRepresentation];
	file = fopen(fileName, "r");
	if (file == NULL) return NO;
	
	// Read the whole file asssociated with this record into the memory cache
	fstat(fileno(file), &sb);
	m_nMemoryCacheLen = sb.st_size;
	m_pMemoryCache = malloc(m_nMemoryCacheLen);
	fread(m_pMemoryCache, sizeof(char), m_nMemoryCacheLen, file);
	m_nMemoryCachePos = 0;
	
	// Go through each record looking for a matching file number and signal that record is now in memory
	for (i = 0; i < m_nRecordsLen; i++)
    {
		if (m_psRecords[i].fileNumber == fileNo)
        {
		
			// In case of such a match load the record's data
			m_psRecords[i].data = (unsigned char *)m_pMemoryCache + m_nMemoryCachePos;
			m_psRecords[i].fileNumber = -1;
            
            SECTION_MEM *pSectionMem = (SECTION_MEM *)&m_pMemoryCache[m_nMemoryCachePos];
            m_nMemoryCachePos += pSectionMem->sizeAlloced; //wzq
			//int_ptr = (int *)&m_pMemoryCache[m_nMemoryCachePos];
			//if (int_ptr[2] == -1)
			//	m_nMemoryCachePos += 3 * sizeof(int) + spp;
			//else
			//	m_nMemoryCachePos += 4 * sizeof(int) + int_ptr[2] * int_ptr[3] * spp;
			
		}
	}
	
	// Close the file
	fclose(file);
	
	// Delete the file (we have its contents in memory now)
	unlink(fileName);
	
	// Write debugging notices
	#ifdef DEBUG
	NSLog(@"Disk cache converted to memory.");
	#endif
	
	return YES;
}

- (int)takeSnapshot:(IntRect)rect automatic:(BOOL)automatic
{
    return [self takeSnapshot:rect automatic:automatic bFullLayer:NO date:NULL];
}

- (int)takeFullSnapshot:(IntRect)rect automatic:(BOOL)automatic date:(unsigned char *)data
{
    return [self takeSnapshot:rect automatic:automatic bFullLayer:YES date:data];
}

- (int)takeSnapshot:(IntRect)rect automatic:(BOOL)automatic bFullLayer:(BOOL)bFullLayer date:(unsigned char *)fullLayerData
{
	unsigned char *data, *temp_ptr;
	int i, width, sectionSize, spp;
//	int rectSize, *int_ptr;
	
	// Check the rectangle is valid
    if(!bFullLayer)
    {
        rect = IntConstrainRect(rect, IntMakeRect(0, 0, [(PSLayer *)m_idLayer width], [(PSLayer *)m_idLayer height]));
        if (rect.size.width <= 0) return -1;
        if (rect.size.height <= 0) return -1;
    }
	
	// Set up variables
	spp = [(PSContent *)[m_idDocument contents] spp];
	sectionSize = rect.size.width * rect.size.height * spp;
    if(bFullLayer)
    {
        int sectionSize1 = [(PSLayer *)m_idLayer width] * [(PSLayer *)m_idLayer height] *spp;//redo 时候可能变大
        sectionSize = (sectionSize> sectionSize1)?sectionSize:sectionSize1;
    }
    
    if(!bFullLayer)
        data = [(PSLayer *)m_idLayer getRawData];
    else data = fullLayerData;
    
    if (!data)  return -1;
    
    if(!bFullLayer)
        width = [(PSLayer *)m_idLayer width];
    else width = rect.size.width;
	
	// Allow the undo (if required)
	if (automatic)
    {
        if(!bFullLayer)
            [[[m_idDocument undoManager] prepareWithInvocationTarget:self] restoreSnapshot:m_nRecordsLen automatic:YES];
        else
            [[[m_idDocument undoManager] prepareWithInvocationTarget:self] restoreFullLayerSnapshot:m_nRecordsLen automatic:YES];
    }
	
	// Allocate more space for the m_psRecords if need be
	if (m_nRecordsLen >= m_nRecordsMaxLen)
    {
		m_nRecordsMaxLen += kNumberOfUndoRecordsPerMalloc;
		m_psRecords = realloc(m_psRecords, m_nRecordsMaxLen * sizeof(UndoRecord));
	}
	
	// Check that the memory cache has space to handle this snapshot (otherwise write it to disk and start afresh)
	if (m_nMemoryCachePos + sectionSize + sizeof(SECTION_MEM) > m_nMemoryCacheLen)
    {
		[self writeMemoryCache];
		m_nMemoryCacheLen = MAX(sectionSize + sizeof(SECTION_MEM), m_ulMemoryCacheSize * 1024);
		m_pMemoryCache = malloc(m_nMemoryCacheLen);
		m_nMemoryCachePos = 0;
	}
	
	// Record the details
	temp_ptr = (unsigned char*)m_pMemoryCache + m_nMemoryCachePos;
    
    SECTION_MEM *pSectionMem = (SECTION_MEM *)temp_ptr;

    pSectionMem->rect = rect;
    pSectionMem->sizeAlloced = sectionSize + sizeof(SECTION_MEM);
    
    temp_ptr += sizeof(SECTION_MEM);
    
    if(!bFullLayer)
    {
        for (i = 0; i < rect.size.height; i++)
        {
            memcpy(temp_ptr, data + ((rect.origin.y + i) * width + rect.origin.x) * spp, rect.size.width * spp);
            temp_ptr += rect.size.width * spp;
        }
    }
    else
        memcpy(temp_ptr, data, rect.size.width * rect.size.height * spp);
    
    if(!bFullLayer)
        [(PSLayer *)m_idLayer unLockRawData];
    
	m_psRecords[m_nRecordsLen].fileNumber = -1;
	m_psRecords[m_nRecordsLen].data = (unsigned char*)m_pMemoryCache + m_nMemoryCachePos;
	
	// Increase the memory cache position
	m_nMemoryCachePos += sectionSize + sizeof(SECTION_MEM);
	
	// Increment m_nRecordsLen
	m_nRecordsLen++;
	
	// Check that the memory cache has space to handle this snapshot (otherwise write it to disk and start afresh)
	if (m_nMemoryCachePos >= m_nMemoryCacheLen)
    {
		[self writeMemoryCache];
		m_nMemoryCacheLen = m_ulMemoryCacheSize * 1024;
		m_pMemoryCache = malloc(m_nMemoryCacheLen);
		m_nMemoryCachePos = 0;
	}
	
	return m_nRecordsLen - 1;
}

- (int)takeSnapshot:(IntRect)rect automatic:(BOOL)automatic date:(unsigned char *)data
{
    if (!data)
    {
        return 0;
    }
    unsigned char *temp_ptr;
    int i, width, rectSize, sectionSize, spp;
    //int *int_ptr;
    
    // Check the rectangle is valid
    rect = IntConstrainRect(rect, IntMakeRect(0, 0, [(PSLayer *)m_idLayer width], [(PSLayer *)m_idLayer height]));
    if (rect.size.width <= 0) return -1;
    if (rect.size.height <= 0) return -1;
    
    // Set up variables
    spp = [(PSContent *)[m_idDocument contents] spp];
    sectionSize = rect.size.width * rect.size.height * spp;
    width = [(PSLayer *)m_idLayer width];
    
    // Allow the undo (if required)
    if (automatic) [[[m_idDocument undoManager] prepareWithInvocationTarget:self] restoreSnapshot:m_nRecordsLen automatic:YES];
    
    // Allocate more space for the m_psRecords if need be
    if (m_nRecordsLen >= m_nRecordsMaxLen)
    {
        m_nRecordsMaxLen += kNumberOfUndoRecordsPerMalloc;
        m_psRecords = realloc(m_psRecords, m_nRecordsMaxLen * sizeof(UndoRecord));
    }
    
    // Check that the memory cache has space to handle this snapshot (otherwise write it to disk and start afresh)
    if (m_nMemoryCachePos + sectionSize + sizeof(SECTION_MEM) > m_nMemoryCacheLen)
    {
        [self writeMemoryCache];
        m_nMemoryCacheLen = MAX(sectionSize + sizeof(SECTION_MEM), m_ulMemoryCacheSize * 1024);
        m_pMemoryCache = malloc(m_nMemoryCacheLen);
        m_nMemoryCachePos = 0;
    }
    
    // Record the details
    temp_ptr = (unsigned char*)m_pMemoryCache + m_nMemoryCachePos;
    
    SECTION_MEM *pSectionMem = (SECTION_MEM *)temp_ptr;
    pSectionMem->rect = rect;
    pSectionMem->sizeAlloced = sectionSize + sizeof(SECTION_MEM);
    temp_ptr += sizeof(SECTION_MEM);
/*    int_ptr = (int *)temp_ptr;
    int_ptr[0] = rect.origin.x;
    int_ptr[1] = rect.origin.y;
    if (rect.size.width == 1 && rect.size.height == 1)
    {
        int_ptr[2] = -1;
        rectSize = 3 * sizeof(int);
        temp_ptr += rectSize;
    }
    else
    {
        int_ptr[2] = rect.size.width;
        int_ptr[3] = rect.size.height;
        rectSize = 4 * sizeof(int);
        temp_ptr += rectSize;
    }
  */
    for (i = 0; i < rect.size.height; i++)
    {
        memcpy(temp_ptr, data + ((rect.origin.y + i) * width + rect.origin.x) * spp, rect.size.width * spp);
        temp_ptr += rect.size.width * spp;
    }
    m_psRecords[m_nRecordsLen].fileNumber = -1;
    m_psRecords[m_nRecordsLen].data = (unsigned char*)m_pMemoryCache + m_nMemoryCachePos;
    
    // Increase the memory cache position
    m_nMemoryCachePos += sectionSize + sizeof(SECTION_MEM);
    
    // Increment m_nRecordsLen
    m_nRecordsLen++;
    
    // Check that the memory cache has space to handle this snapshot (otherwise write it to disk and start afresh)
    if (m_nMemoryCachePos >= m_nMemoryCacheLen)
    {
        [self writeMemoryCache];
        m_nMemoryCacheLen = m_ulMemoryCacheSize * 1024;
        m_pMemoryCache = malloc(m_nMemoryCacheLen);
        m_nMemoryCachePos = 0;
    }
    
    return m_nRecordsLen - 1;
}

- (void)restoreFullLayerSnapshot:(int)index automatic:(BOOL)automatic
{
    IntRect rect;
    unsigned char *data, *temp_ptr, *o_temp_ptr = NULL, *odata = NULL;
    int width, recordDataSize = 0, spp, lindex;
   // int *int_ptr, *o_int_ptr = NULL;
    
    // Check the index is valid
#ifdef DEBUG
    if (index < 0) NSLog(@"Invalid index recieved by restoreFullLayerSnapshot:");
    if (index >= m_nRecordsLen) NSLog(@"Invalid index recieved by restoreFullLayerSnapshot:");
#endif
    if (index < 0) return;
    
    // Allow the undo/redo
    if (automatic) [[[m_idDocument undoManager] prepareWithInvocationTarget:self] restoreFullLayerSnapshot:index automatic:YES];
    
    // Load the record we require into memory
    if (![self loadMemoryCacheWithIndex:index]) return;
    
    // Set-up variables
    spp     = [(PSContent *)[m_idDocument contents] spp];
    
    temp_ptr = m_psRecords[index].data;
    
    SECTION_MEM *pInSectionMem = (SECTION_MEM *)temp_ptr;
    SECTION_MEM *pOutSectionMem = NULL;
    //int_ptr = (int *)temp_ptr;
    
    // Set-up variables for old data
    if (automatic)
    {
        recordDataSize = [(PSLayer *)m_idLayer width] * [(PSLayer *)m_idLayer height] * spp + sizeof(SECTION_MEM);
        odata = malloc(recordDataSize);
        o_temp_ptr = odata;
        pOutSectionMem = (SECTION_MEM *)o_temp_ptr;
      //  o_int_ptr = (int *)o_temp_ptr;
    }
    
    // Load rectangle information
    rect = pInSectionMem->rect;
    temp_ptr += sizeof(SECTION_MEM);
  /*  rect.origin.x = int_ptr[0];
    rect.origin.y = int_ptr[1];
    if (int_ptr[2] != -1)
    {
        rect.size.width = int_ptr[2];
        rect.size.height = int_ptr[3];
        temp_ptr += 4 * sizeof(int);
    }
    else
    {
        rect.size.width = 1;
        rect.size.height = 1;
        temp_ptr += 3 * sizeof(int);
    }*/
    
    // Set rectangle information in old data
    if (automatic)
    {
        pOutSectionMem->rect = [(PSLayer *)m_idLayer localRect];
        pOutSectionMem->sizeAlloced = pInSectionMem->sizeAlloced;//recordDataSize;
        o_temp_ptr += sizeof(SECTION_MEM);
     /*   o_int_ptr[0] = [(PSLayer *)m_idLayer xoff];
        o_int_ptr[1] = [(PSLayer *)m_idLayer yoff];
        if ([(PSLayer *)m_idLayer width] == 1 && [(PSLayer *)m_idLayer height] == 1)
        {
            o_int_ptr[2] = -1;
            o_temp_ptr += 3 * sizeof(int);
        }
        else
        {
            o_int_ptr[2] = [(PSLayer *)m_idLayer width];
            o_int_ptr[3] = [(PSLayer *)m_idLayer height];
            o_temp_ptr += 4 * sizeof(int);
        }
      */
        memcpy(o_temp_ptr, [(PSLayer *)m_idLayer getRawData], [(PSLayer *)m_idLayer width] * [(PSLayer *)m_idLayer height] * spp);
        [(PSLayer *)m_idLayer unLockRawData];
        
    }
    
    IMAGE_DATA imageData = [(PSLayer *)m_idLayer initImageAndLockWrite:rect.size.width height:rect.size.height spp:spp alphaPremultiplied:false];
    
    data    = imageData.pBuffer;//[(PSLayer *)m_idLayer getRawData];
    
    if(rect.origin.x != [(PSLayer *)m_idLayer xoff] || rect.origin.y != [(PSLayer *)m_idLayer yoff])
        [(PSLayer *)m_idLayer setOffsets:rect.origin];
    
    width   = rect.size.width;//[(PSLayer *)m_idLayer width];
    
    lindex  = [(PSLayer *)m_idLayer index];
    
    memcpy(data, temp_ptr, rect.size.width * rect.size.height *spp);
    
    [(PSLayer *)m_idLayer unLockRawData];
    
    // Call for an update
    if (automatic) [[m_idDocument helpers] layerSnapshotRestored:lindex rect:IntMakeRect(0,0, rect.size.width, rect.size.height)];
    
    // Move saved image data into the record
    if (automatic)
    {
        memcpy(m_psRecords[index].data, odata, recordDataSize);
        free(odata);
    }
}

- (void)restoreSnapshot:(int)index automatic:(BOOL)automatic
{
	IntRect rect;
	unsigned char *data, *temp_ptr, *o_temp_ptr = NULL, *odata = NULL;
	int i, width, recordDataSize = 0, spp, lindex;
	//int *int_ptr, *o_int_ptr = NULL;
	
	// Check the index is valid
	#ifdef DEBUG
	if (index < 0) NSLog(@"Invalid index recieved by restoreSnapshot:");
	if (index >= m_nRecordsLen) NSLog(@"Invalid index recieved by restoreSnapshot:");
	#endif
	if (index < 0) return;
	
	// Allow the undo/redo
	if (automatic) [[[m_idDocument undoManager] prepareWithInvocationTarget:self] restoreSnapshot:index automatic:YES];
	
	// Load the record we require into memory
	if (![self loadMemoryCacheWithIndex:index]) return;
	
	// Set-up variables
	data    = [(PSLayer *)m_idLayer getRawData];
	width   = [(PSLayer *)m_idLayer width];
	spp     = [(PSContent *)[m_idDocument contents] spp];
	lindex  = [(PSLayer *)m_idLayer index];
	temp_ptr = m_psRecords[index].data;
    
    SECTION_MEM *pInSectionMem = (SECTION_MEM *)temp_ptr;
    SECTION_MEM *pOutSectionMem = NULL;
	//int_ptr = (int *)temp_ptr;
	
	// Set-up variables for old data
	if (automatic)
    {
//		if (int_ptr[2] == -1)
//			recordDataSize = 3 * sizeof(int) + spp;
//		else
//			recordDataSize = 4 * sizeof(int) + int_ptr[2] * int_ptr[3] * spp;
        recordDataSize = pInSectionMem->sizeAlloced;
		odata = malloc(recordDataSize);
		o_temp_ptr = odata;
		pOutSectionMem = (SECTION_MEM *)o_temp_ptr;
	}
	
	// Load rectangle information
    rect = pInSectionMem->rect;
    temp_ptr += sizeof(SECTION_MEM);
/*	rect.origin.x = int_ptr[0];
	rect.origin.y = int_ptr[1];
	if (int_ptr[2] != -1)
    {
		rect.size.width = int_ptr[2];
		rect.size.height = int_ptr[3];
		temp_ptr += 4 * sizeof(int);
	}
	else
    {
		rect.size.width = 1;
		rect.size.height = 1;
		temp_ptr += 3 * sizeof(int);
	}*/
	
	// Set rectangle information in old data
	if (automatic)
    {
        pOutSectionMem->rect = rect;
        pOutSectionMem->sizeAlloced = recordDataSize;
        
        o_temp_ptr += sizeof(SECTION_MEM);
	/*	o_int_ptr[0] = rect.origin.x;
		o_int_ptr[1] = rect.origin.y;
		if (rect.size.width == 1 && rect.size.height == 1)
        {
			o_int_ptr[2] = -1;
			o_temp_ptr += 3 * sizeof(int);
		}
		else
        {
			o_int_ptr[2] = rect.size.width;
			o_int_ptr[3] = rect.size.height;
			o_temp_ptr += 4 * sizeof(int);
		}*/
	}

	// Save the current image data
	if (automatic)
    {
		for (i = 0; i < rect.size.height; i++)
        {
			memcpy(o_temp_ptr, data + ((rect.origin.y + i) * width + rect.origin.x) * spp, rect.size.width * spp);
			o_temp_ptr += rect.size.width * spp;
		}
	}
	
	// Replace the image data with that of the record
	for (i = 0; i < rect.size.height; i++)
    {
		memcpy(data + ((rect.origin.y + i) * width + rect.origin.x) * spp, temp_ptr, rect.size.width * spp);
		temp_ptr += rect.size.width * spp;
	}
   
    [(PSLayer *)m_idLayer unLockRawData];
		
	// Call for an update
	if (automatic) [[m_idDocument helpers] layerSnapshotRestored:lindex rect:rect];

	// Move saved image data into the record
	if (automatic)
    {
        if(recordDataSize > pInSectionMem->sizeAlloced)  //
        {
            unsigned char *pNewMemoryCache = (unsigned char *)malloc(m_nMemoryCacheLen + recordDataSize - pInSectionMem->sizeAlloced);
            
            memcpy(pNewMemoryCache, m_pMemoryCache,  m_nMemoryCachePos);
            
            if(m_nMemoryCacheLen - (m_nMemoryCachePos + pInSectionMem->sizeAlloced) > 0 )
                memcpy(pNewMemoryCache + m_nMemoryCacheLen + recordDataSize, (unsigned char *)m_pMemoryCache + m_nMemoryCachePos + pInSectionMem->sizeAlloced, m_nMemoryCacheLen - (m_nMemoryCachePos + pInSectionMem->sizeAlloced));
            
            free(m_pMemoryCache);
            m_pMemoryCache = (char *)pNewMemoryCache;
            
            m_psRecords[i].data = (unsigned char *)m_pMemoryCache + m_nMemoryCachePos;
        }
        
		memcpy(m_psRecords[index].data, odata, recordDataSize);
		free(odata);
	}
    
}


@end
