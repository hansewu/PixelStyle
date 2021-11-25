/* LIBGIMP - The GIMP Library
 * Copyright (C) 1995-1997 Peter Mattis and Spencer Kimball
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

/* For information look into the C source or the html documentation */


/*  RGB and RGBA color types and operations taken from LibGCK  */

typedef enum
{
  GIMP_RGB_COMPOSITE_NONE = 0,
  GIMP_RGB_COMPOSITE_NORMAL,
  GIMP_RGB_COMPOSITE_BEHIND
} GimpRGBCompositeMode;


void      gimp_rgb_set        (GimpRGB       *rgb,
			       gdouble        red,
			       gdouble        green,
			       gdouble        blue);
void      gimp_rgb_set_alpha  (GimpRGB       *rgb,
			       gdouble        alpha);
void      gimp_rgb_set_uchar  (GimpRGB       *rgb,
			       guchar         red,
			       guchar         green,
			       guchar         blue);
void      gimp_rgb_get_uchar  (const GimpRGB *rgb,
			       guchar        *red,
			       guchar        *green,
			       guchar        *blue);

void      gimp_rgb_add        (GimpRGB       *rgb1,
			       const GimpRGB *rgb2);
void      gimp_rgb_subtract   (GimpRGB       *rgb1,
			       const GimpRGB *rgb2);
void      gimp_rgb_multiply   (GimpRGB       *rgb1,
			       gdouble        factor);
gdouble   gimp_rgb_distance   (const GimpRGB *rgb1,
			       const GimpRGB *rgb2);
gdouble   gimp_rgb_max        (const GimpRGB *rgb);
gdouble   gimp_rgb_min        (const GimpRGB *rgb);
void      gimp_rgb_clamp      (GimpRGB       *rgb);
void      gimp_rgb_gamma      (GimpRGB       *rgb,
 			       gdouble        gamma);
gdouble   gimp_rgb_intensity        (const GimpRGB *rgb);
guchar    gimp_rgb_intensity_uchar  (const GimpRGB *rgb);

void      gimp_rgb_composite  (GimpRGB              *color1,
			       const GimpRGB        *color2,
			       GimpRGBCompositeMode  mode);

void      gimp_rgba_set       (GimpRGB       *rgba,
			       gdouble        red,
			       gdouble        green,
			       gdouble        blue,
			       gdouble        alpha);
void      gimp_rgba_set_uchar (GimpRGB       *rgba,
			       guchar         red,
			       guchar         green,
			       guchar         blue,
			       guchar         alpha);
void      gimp_rgba_get_uchar (const GimpRGB *rgba,
			       guchar        *red,
			       guchar        *green,
			       guchar        *blue,
			       guchar        *alpha);

void      gimp_rgba_add       (GimpRGB       *rgba1,
			       const GimpRGB *rgba2);
void      gimp_rgba_subtract  (GimpRGB       *rgba1,
			       const GimpRGB *rgba2);
void      gimp_rgba_multiply  (GimpRGB       *rgba,
			       gdouble        factor);
gdouble   gimp_rgba_distance  (const GimpRGB *rgba1,
			       const GimpRGB *rgba2);


/*  Map RGB to intensity  */

#define INTENSITY_RED   0.30
#define INTENSITY_GREEN 0.59
#define INTENSITY_BLUE  0.11
#define INTENSITY(r,g,b) ((r) * INTENSITY_RED   + \
			  (g) * INTENSITY_GREEN + \
			  (b) * INTENSITY_BLUE  + 0.001)
