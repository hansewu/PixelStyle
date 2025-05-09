struct _GimpRGB
{
  gdouble r, g, b, a;
};

typedef struct _GimpRGB  GimpRGB;

typedef gdouble (* BlendRepeatFunc) (gdouble);

typedef struct
{
    int nCount;
    float *fArrPositions;
    GimpRGB *ArrayColors;
}GIMP_OTHER_COLORS;

typedef struct
{
  void				*gradient;
  gboolean          reverse;
  gdouble           offset;
  gdouble           sx, sy;
  GimpGradientType  gradient_type;
  GimpRGB           fg, bg;
  gdouble           dist;
  gdouble           vec[2];
  BlendRepeatFunc   repeat_func;
    GIMP_OTHER_COLORS other_colors;
} RenderBlendData;

typedef struct
{
	unsigned char *data;
	int width;
	int height;
	IntRect rect;
	int spp;
} PutPixelData;
