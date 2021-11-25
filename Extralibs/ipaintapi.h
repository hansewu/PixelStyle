// iPaintApi.h: interface for the iPaintApi class.
//
//////////////////////////////////////////////////////////////////////

#if !defined(AFX_IPAINTAPI_H__03BA3004_1823_4E30_A95C_D3509CABF653__INCLUDED_)
#define AFX_IPAINTAPI_H__03BA3004_1823_4E30_A95C_D3509CABF653__INCLUDED_



typedef void * HANDLE_PAINT_CANVAS;
typedef void * HANDLE_PAINT_BRUSH;
typedef unsigned int uint32_t;
typedef unsigned short int uint16_t;
typedef unsigned char uint8_t;

//extern void *IPD_GetTileMemory(void *pContext, int nCellX, int nCellY);//data manager 提供此函数
extern void *IPD_GetTileMemory(void *pContext, int nCellX, int nCellY, int nReadOnly);//data manager 提供此函数
extern int GetImageInfo(char *cFileName, int bResource, int *pnWidth, int *pnHeight, unsigned char *pRGBABuf, int bAlphaPremultiplied);


HANDLE_PAINT_CANVAS  IP_CreateCanvas();
void IP_DestroyCanvas(HANDLE_PAINT_CANVAS hCanvas);
void IP_SetContext(HANDLE_PAINT_CANVAS hCanvas, void *pContext);


/*HANDLE_PAINT_CANVAS  IP_OpenCanvas(char *cFile);
int IP_SaveCanvas(HANDLE_PAINT_CANVAS hCanvas, char *cFile);
*/

int IP_GetDirtyCellCount(HANDLE_PAINT_CANVAS hCanvas);
void *IP_GetDirtyCellInfo(HANDLE_PAINT_CANVAS hCanvas, int nIndex, int *pOutX, int *pOutY);
void IP_ClearDirty(HANDLE_PAINT_CANVAS hCanvas);

void IP_BeginOneStroke(HANDLE_PAINT_CANVAS hCanvas);
void IP_EndOneStroke(HANDLE_PAINT_CANVAS hCanvas);
int IP_GetStrokeDirtyCellCount(HANDLE_PAINT_CANVAS hCanvas);
void *IP_GetStrokeDirtyCellInfo(HANDLE_PAINT_CANVAS hCanvas, int nIndex, int *pOutX, int *pOutY);

HANDLE_PAINT_BRUSH  IP_CreateBrush(HANDLE_PAINT_CANVAS hCanvas, char *cBrushFile);
HANDLE_PAINT_BRUSH  IP_CreateBrushFromPackage(HANDLE_PAINT_CANVAS hCanvas, char *cBrushFile);

void IP_SetBrushParam(HANDLE_PAINT_CANVAS hCanvas, HANDLE_PAINT_BRUSH hBrush, int nItem, float fValue);

float IP_GetBrushParam(HANDLE_PAINT_CANVAS hCanvas, HANDLE_PAINT_BRUSH hBrush, int nItem);

void IP_StrokeTo(HANDLE_PAINT_CANVAS hCanvas, HANDLE_PAINT_BRUSH hBrush, uint32_t dwBurshColor, int x, int y, float fPressure, float fIntervalTime);

void IP_DestroyBursh(HANDLE_PAINT_CANVAS hCanvas, HANDLE_PAINT_BRUSH hBrush);

//void IP_SetBackGroundBuffer(HANDLE_PAINT_CANVAS hCanvas, unsigned char *pBuf);
//int IP_CopyOneCellToOneCellBuffer(unsigned char *pCellBuffer, HANDLE_PAINT_CANVAS hCanvas,  int nCellX, int nCellY);

//void IP_SaveForUndo(HANDLE_PAINT_CANVAS hCanvas);

//void IP_Undo(HANDLE_PAINT_CANVAS hCanvas);

//void IP_Redo(HANDLE_PAINT_CANVAS hCanvas);

int IP_SaveEvents(HANDLE_PAINT_CANVAS hCanvas, char *cFileName);

void IP_RGBtoHSVf (float *r_h, float *g_s, float *b_v);

void IP_HSVtoRGBf (float *h_r, float *s_g, float *v_b);

int IP_GetEventCount(HANDLE_PAINT_CANVAS hCanvas);

int IP_GetEvent(HANDLE_PAINT_CANVAS hCanvas, int nIndex, char *cEvent);

void IP_AddEventForSetBackGround(HANDLE_PAINT_CANVAS hCanvas, char *cFileName);

void IP_Init(char *cFileBrushPackage);

void IP_Exit();



#endif // !defined(AFX_IPAINTAPI_H__03BA3004_1823_4E30_A95C_D3509CABF653__INCLUDED_)
