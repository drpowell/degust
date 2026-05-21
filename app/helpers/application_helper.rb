module ApplicationHelper
    def app_name
        ENV['DEGUST_NAME'] || 'Degust'
    end

    def csrf_meta_tags
      super
    rescue ArgumentError => e
      if e.message == "invalid base64"
        request.reset_session
        super
      else
        raise e
      end
    end
end
