class UserFile < ApplicationRecord
    has_many :de_settings

    def from_tempfile(f)
      self.name = f.original_filename
      self.content_type = f.content_type
      self.size = f.size
      self.md5 = Digest::MD5.file(f.path).to_s
      self.location = Rails.root.join('uploads', self.md5)

      if !File.exists?(self.location)
        FileUtils.cp f.tempfile, self.location
      else
        if File.size(location) != self.size
          raise "Uploaded file already exists, but different size!"
        end
      end
      p self
    end
end
