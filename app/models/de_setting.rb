class DeSetting < ApplicationRecord
    belongs_to :user, optional: true
    belongs_to :user_file
    has_many :visiteds

    before_create :randomize_id
    before_save :update_name

    def settings_as_json
        JSON.parse(settings || '{}')
    end

    def settings_with_defaults
        defs = {'csv_format' => false,
                'replicates' => [],
                'fc_columns' => [],
                'info_columns' => [],
                'analyze_server_side' => true,
                }

        res = settings_as_json
        # Set any defaults
        defs.each do |k,v|
            res[k] = v if !res.key?(k)
        end

        res
    end

    def update_from_json(new_settings)
        if (!DeSetting.check_settings(new_settings))
            return false
        end

        self.settings = new_settings.to_json
        return true
    end

    def last_visit_by(user)
        visiteds.where(:user => user).first
    end

    def is_owner(user)
        !user.nil? && self.user == user
    end

    def is_locked
        settings_as_json['config_locked']
    end

    def can_modify(user)
        is_owner(user) || !is_locked()
    end

    BAD_REGEX = /[\\'"\n]/

    def randomize_id
        if !self.new_record?
            raise "Only use randomize_id for new record"
        end
        begin
            self.secure_id = Digest::MD5.hexdigest(Random.rand.to_s)
        end while DeSetting.where(secure_id: self.secure_id).exists?
    end

    def set_name(name)
        json = settings_as_json
        json['name'] = name
        self.settings = JSON.generate(json)
    end

    def description
        settings_as_json['experimentDescription']
    end

private
    def update_name
        self.name = settings_as_json['name']
    end


    def self.check_array(arr)
        arr.nil? || arr.all? {|x| !BAD_REGEX.match?(x)}
    end

    # Check the passed settings (in json) are valid
    def self.check_settings(settings)
        if (!check_array(settings['fc_columns']) ||
            !check_array(settings['info_columns']) ||
            !check_array(settings['hidden_factors']))
            return false
        end

        settings['filter_rows'].each do |filt|
            if (BAD_REGEX.match?(filt["column"]) || BAD_REGEX.match?(filt["regexp"]))
                return false
            end
        end

        if (settings.key?('ec_column') && BAD_REGEX.match?(settings['ec_column']))
            return false
        end

        settings['replicates'].each do |rep|
            return false if !check_array([rep[0]])
            return false if !check_array(rep[1])
        end

        return true
    end

end
