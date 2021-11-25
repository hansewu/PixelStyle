//
//  RenderFont.cpp
//  PhotoArt
//
//  Created by a on 4/23/14.
//
//

#include "RenderFont.h"


CRenderFont::CRenderFont()
{
    m_pTextureFont = NULL; m_pPolygonFont = NULL; m_pOutlineFont = NULL;
}


CRenderFont::~CRenderFont()
{
        ClearFontInfo();
}
    
    
bool CRenderFont::Init(string strFontName, int nSize, int nCharMap)
{
    if(m_strFontName != strFontName && m_pTextureFont !=NULL)
    {
        ClearFontInfo();
    }
    // cocos2d::ccGLEnableVertexAttribs( 0 );
    
    // glEnableClientState(GL_VERTEX_ARRAY);
    m_pTextureFont = new FTTextureFont(strFontName.c_str());//new FTExtrudeFont(strFontName.c_str());// FTBitmapFont(strFontName.c_str());// FTPixmapFont(strFontName.c_str());//  FTTextureFont(strFontName.c_str());
    //        if(m_pTextureFont->Error())
    //        {
    //            delete m_pTextureFont;
    //            return false;
    //        }
    
    m_pPolygonFont = new FTPolygonFont(strFontName.c_str());
    m_pOutlineFont = new FTOutlineFont(strFontName.c_str());
    
    if(m_pTextureFont->Error() !=0)
    {
        ClearFontInfo();
        return false;
    }
    
    m_pTextureFont->FaceSize(nSize);
    m_pPolygonFont->FaceSize(nSize);
    m_pOutlineFont->FaceSize(nSize);
    
    m_pPolygonFont->Outset(1.0);
    m_pOutlineFont->Outset(1.0);
    m_fOutSet = 1.0;
    
    m_pOutlineFont->UseDisplayList(false);
    
    if(nCharMap != 0)
    {
        m_pTextureFont->CharMap((FT_Encoding)nCharMap);
        m_pPolygonFont->CharMap((FT_Encoding)nCharMap);
        m_pOutlineFont->CharMap((FT_Encoding)nCharMap);
    }
    
    //        if(m_pTextureFont->Error() !=0)
    //        {
    //            ClearFontInfo();
    //            return false;
    //        }
    m_strFontName = strFontName;
    m_nCharMap  = nCharMap;
    
    return true;
}

int CRenderFont::GetCharMap()
{
    return m_nCharMap;
}

string CRenderFont::GetFontName()
{
    return m_strFontName;
}

int GetSize()
{
    if(!m_pTextureFont) return 0;
    
    return m_pTextureFont->FaceSize();
}

void CRenderFont::SetSize(int nSize)
{
    if(!m_pTextureFont) return;
    
    m_pTextureFont->FaceSize(nSize);
    m_pPolygonFont->FaceSize(nSize);
    m_pOutlineFont->FaceSize(nSize);
}

void CRenderFont::SetOutset(float fValue)
{
    if(!m_pTextureFont) return;
    
    
    //Init(m_strFontName, GetSize(), m_nCharMap);
    if(fabs(fValue - m_fOutSet) < 0.0001)
        return;
    
    SetSize(GetSize());
    
    m_pPolygonFont->Outset(fValue);
    m_pOutlineFont->Outset(fValue);
    
    m_fOutSet = fValue;
}


void CRenderFont::RenderText(char *cText)
{
    m_pPolygonFont->Render(cText, -1, FTPoint(1000, 1000));
    // m_pPolygonFont->Render(cText, -1, FTPoint(1000, 1000));
    //m_pOutlineFont->Render(cText, -1, FTPoint(1000, 1000));
}


void CRenderFont::ClearFontInfo()
{
    if(m_pTextureFont !=NULL)
    {
        delete m_pTextureFont; m_pTextureFont = NULL;
        delete m_pPolygonFont; m_pPolygonFont = NULL;
        delete m_pOutlineFont; m_pOutlineFont = NULL;
    }
    
    m_strFontName = "";
    m_nCharMap = 0;
}
