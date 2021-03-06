# encoding: utf-8

class ProcedureLogoUploader < CarrierWave::Uploader::Base

  def root
    File.join(Rails.root, "public")
  end

  # Choose what kind of storage to use for this uploader:
  if Features.remote_storage
    storage :fog
  else
    storage :file
  end

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    unless Features.remote_storage
      "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
    end
  end

  def cache_dir
    if Rails.env.production?
      '/tmp/tps-cache'
    else
      '/tmp/tps-dev-cache'
    end
  end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  def extension_white_list
    %w(jpg jpeg png)
  end

  def filename
    if original_filename.present? || model.logo_secure_token
      if Features.remote_storage
        filename = "#{model.class.to_s.underscore}-#{secure_token}.#{file.extension.downcase}"
      else
        filename = "logo-#{secure_token}.#{file.extension.downcase}"
      end
    end
    filename
  end

  private

  def secure_token
    model.logo_secure_token ||= generate_secure_token
  end

  def generate_secure_token
    SecureRandom.uuid
  end

end
