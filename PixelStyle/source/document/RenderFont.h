//
//  RenderFont.h
//  PhotoArt
//
//  Created by a on 4/23/14.
//
//

#ifndef __PhotoArt__RenderFont__
#define __PhotoArt__RenderFont__


class FTTextureFont;
//class   FTBitmapFont;
//    FTPixmapFont *m_pTextureFont;
//    FTTextureFont *m_pTextureFont;
class FTPolygonFont;
class FTOutlineFont;

class CRenderFont
{
public:
    CRenderFont();
    virtual ~CRenderFont();
    
    
    bool Init(string strFontName, int nSize, int nCharMap);
    
    int GetCharMap();
    
    string GetFontName();
    
    int GetSize();
    
    void SetSize(int nSize);
    
    void SetOutset(float fValue);
    
    FTFont *GetNormalFont(){return m_pTextureFont;};//m_pOutlineFont;}//m_pPolygonFont;}//
    FTFont *GetEdgeFont(bool bFilled) {if(bFilled) return m_pPolygonFont;  return m_pOutlineFont;};
    
    void RenderText(char *cText);
    
protected:
    string m_strFontName;
    int     m_nCharMap;
    float   m_fOutSet;
    
    FTTextureFont *m_pTextureFont;
    //   FTBitmapFont *m_pTextureFont;
    //    FTPixmapFont *m_pTextureFont;
    //    FTTextureFont *m_pTextureFont;
    FTPolygonFont *m_pPolygonFont;
    FTOutlineFont *m_pOutlineFont;
    
    void ClearFontInfo();
    
};

#endif /* defined(__PhotoArt__RenderFont__) */
