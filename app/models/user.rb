class User < ApplicationRecord
  has_many :de_settings
  has_many :visited
  has_many :gene_lists

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
      if auth['info'] && (name.nil? || name=='')
          self.name = auth['info']['name']
          self.extra = auth['info'].to_json
          save
      end
  end
end
