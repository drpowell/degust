namespace :degust_mongo do
  desc "Copy old mongo data to new rails"
  task :migrate, [:dir] => :environment do |t, vars|
      str = `bsondump #{vars.dir}/degust/users.bson`
      users = []
      str.each_line do |line|
          user = JSON.parse(line)
          if user['twitter']
              user['added'] = User.create!(provider: 'twitter', uid: user['twitter']['id'])
          elsif user['google']
              user['added'] = User.create!(provider: 'google_oauth2', uid: user['google']['id'])
          end
          users.push(user)
      end
      puts "Added users : #{users.length}"

      files = []
      str = `bsondump #{vars.dir}/degust/files.bson`
      str.each_line do |line|
          file = JSON.parse(line)
          name = Pathname.new(file['path']).basename.to_s
          time = DateTime.parse(file['createdAt']['$date'])
          f = UserFile.create!(name: file['name'], content_type: file['mimetype'],
                          created_at: time, updated_at: time,
                          md5: name,
                          location: Rails.root.join('uploads', name),
                          size: file['size'])
          file['added'] = f
          files.push(file)
      end
      puts "Added files : #{files.length}"

      desettings = []
      str = `bsondump #{vars.dir}/degust/desettings.bson`
      str.each_line do |line|
          de = JSON.parse(line)
          next if !de.key?('file')

          time = DateTime.parse(de['createdAt']['$date'])
          owner = nil
          if de["owner"]
              owner = users.select{|u| u["_id"]["$oid"] == de["owner"]["$oid"]}.first['added']
          end
          if de['settings'].nil?
              de['settings'] = {}
          end

          f = files.select{|x| x["_id"]["$oid"] == de["file"]["$oid"]}.first['added']
          xx = DeSetting.create!(settings: de['settings'].to_json,
                            created_at: time, updated_at: time,
                            user_file: f,
                            user: owner
                            )
          xx.secure_id = de["_id"]["$oid"]
          xx.save!
          de['added'] = xx
          desettings.push(de)
      end
      puts "Added de_setting : #{desettings.length}"

      str = `bsondump #{vars.dir}/degust/visiteds.bson`
      str.each_line do |line|
          v = JSON.parse(line)
          de = desettings.select{|x| x["_id"]["$oid"] == v["deSettings"]["$oid"]}.first['added']
          user = users.select{|u| u["_id"]["$oid"] == v["user"]["$oid"]}.first['added']
          time = DateTime.parse(v['last']['$date'])

          Visited.create!(:user => user, :de_setting => de, :last => time)
      end

  end
end
