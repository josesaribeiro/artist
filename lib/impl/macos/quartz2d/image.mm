/*=============================================================================
   Copyright (c) 2016-2020 Joel de Guzman

   Distributed under the MIT License [ https://opensource.org/licenses/MIT ]
=============================================================================*/
#include <artist/image.hpp>
#include <Quartz/Quartz.h>
#include <string>
#include <stdexcept>

namespace cycfi::artist
{
   namespace
   {
      NSBitmapImageRep* get_bitmap(NSImage* image)
      {
         for (NSImageRep* rep in [image representations])
            if ([rep isKindOfClass : [NSBitmapImageRep class]])
               return (NSBitmapImageRep*)rep;
         return nullptr;
      }

      uint32_t* get_pixels(NSImage* image)
      {
         if (auto bitmap = get_bitmap(image))
            return (uint32_t*) [bitmap bitmapData];
         return nullptr;
      }
   }

   image::image(extent size)
   {
      auto img_ = [[NSImage alloc] initWithSize : NSMakeSize(size.x, size.y)];
      _impl = (__bridge_retained image_impl_ptr) img_;
   }

   image::image(fs::path const& path_)
   {
      auto fs_path = find_file(path_);
      auto path = [NSString stringWithUTF8String : fs_path.c_str() ];
      auto img_ = [[NSImage alloc] initWithContentsOfFile : path];
      _impl = (__bridge_retained image_impl_ptr) img_;
   }

   image::~image()
   {
      CFBridgingRelease(_impl);
   }

   image_impl_ptr image::impl() const
   {
      return _impl;
   }

   extent image::size() const
   {
      auto size_ = [(__bridge NSImage*) _impl size];
      return { float(size_.width), float(size_.height) };
   }

   void image::save_png(std::string_view path_) const
   {
      auto path = [NSString stringWithUTF8String : std::string{path_}.c_str() ];
      auto image = (__bridge NSImage*) _impl;
      auto ref = [image CGImageForProposedRect : nullptr
                                       context : nullptr
                                         hints : nullptr];
      auto* rep = [[NSBitmapImageRep alloc] initWithCGImage : ref];
      [rep setSize:[image size]];

      auto* data = [rep representationUsingType : NSBitmapImageFileTypePNG
                                     properties : @{}];
      [data writeToFile : path atomically : YES];
   }

   uint32_t* image::pixels()
   {
      return get_pixels((__bridge NSImage*) _impl);
   }

   uint32_t const* image::pixels() const
   {
      return get_pixels((__bridge NSImage*) _impl);
   }

   extent image::bitmap_size() const
   {
      auto bm = get_bitmap((__bridge NSImage*) _impl);
      auto pixels_wide = [bm pixelsWide];
      auto pixels_high = [bm pixelsHigh];
      return { float(pixels_wide), float(pixels_high) };
   }

   offscreen_image::offscreen_image(image& pict)
    : _image(pict)
   {
      [((__bridge NSImage*) _image.impl()) lockFocusFlipped : YES];
   }

    offscreen_image::~offscreen_image()
   {
      [((__bridge NSImage*) _image.impl()) unlockFocus];
   }

   canvas_impl* offscreen_image::context() const
   {
      return (canvas_impl*) NSGraphicsContext.currentContext.CGContext;
   }
}

