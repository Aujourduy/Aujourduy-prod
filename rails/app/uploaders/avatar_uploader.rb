class AvatarUploader < CarrierWave::Uploader::Base
  include Cloudinary::CarrierWave

  # Optimisations Cloudinary (comme dans ton cahier)
  process resize_to_fill: [400, 400, :face, gravity: :face]
  process quality: :auto
  process fetch_format: :auto

  # Version miniature (optionnel)
  version :thumb do
    process resize_to_fill: [100, 100, :face, gravity: :face]
  end

  def extension_allowlist
    %w[jpg jpeg png webp]
  end

  def size_range
    0..5.megabytes
  end
end