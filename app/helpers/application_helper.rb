module ApplicationHelper
    def app_name
        ENV['DEGUST_NAME'] || 'Degust'
    end
end
