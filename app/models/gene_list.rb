class GeneList < ApplicationRecord
    belongs_to :user, optional: true
    belongs_to :de_setting

end
