class User < ApplicationRecord
  has_many :de_settings
  has_many :visited

  # Create (or recreate) upload token
  def create_upload_token
    while true
      tok = Digest::MD5.hexdigest(Random.rand.to_s)
      used = User.where(:upload_token => tok).count
      break if used==0
    end
    self.upload_token = tok
  end

  def delete_upload_token
    self.upload_token = nil
  end

  def self.create_with_omniauth(auth)
    create! do |user|
      user.provider = auth['provider']
      user.uid = auth['uid']
      if auth['info']
         user.name = auth['info']['name'] || ""
      end
    end
  end

  def fill_missing_omniauth(auth)
    if auth['info']
      if (name.nil? || name=='')
        self.name = auth['info']['name']
      end
      self.extra = auth['info'].to_json
      save
    end
  end
end
