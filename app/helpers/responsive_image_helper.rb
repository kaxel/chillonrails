module ResponsiveImageHelper
  def optimize_image_url(url, width: 1024, quality: 80)
    return url if url.blank?
    
    # If URL already has query parameters, append with &, otherwise use ?
    separator = url.include?('?') ? '&' : '?'
    "#{url}#{separator}w=#{width}&q=#{quality}"
  end
  
  def picture_srcset(url, size_preset = :medium)
    return '' if url.blank?
    
    sizes = {
      small: { w: 640, q: 75 },
      medium: { w: 1024, q: 80 },
      large: { w: 1920, q: 85 }
    }
    
    size = sizes[size_preset] || sizes[:medium]
    
    # Generate 1x and 2x versions for retina displays
    "#{optimize_image_url(url, width: size[:w], quality: size[:q])} 1x, " \
    "#{optimize_image_url(url, width: size[:w] * 2, quality: size[:q])} 2x"
  end
  
  def image_loading_placeholder
    "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 1024 768'%3E%3Crect fill='%23f1f5f9' width='1024' height='768'/%3E%3C/svg%3E"
  end
end