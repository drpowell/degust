def my_system(cmd)
    system(cmd) || raise("Unable to run command : #{cmd}")
end

namespace :degust do
  desc "Find old and unused sessions"
  task :unused, [:dest, :modify] => :environment do |t, args|
    dest = nil
    modify = false
    if args[:dest].nil?
      puts "No destination specified.  Not modifying db"
      puts "  Specify : rake degust:unused[directory]\n\n"
    elsif !File.directory?(args[:dest])
      puts "Destination directory does not exist"
    else
      dest = args[:dest]
    end

    if args[:modify]=='modify'
      modify = true
    else
      puts "  Not changing.  To really change db & files.  Specify : rake degust:unused[directory,modify]\n\n"
    end

    puts "Total sessions : #{DeSetting.count}.  Total files : #{UserFile.count}"
    old = DeSetting.where('settings IS NULL AND updated_at < :old', :old => Time.now - 30.days)
    puts "Old sessions : #{old.length}.  examples : #{old.take(5).map &:secure_id}"
    if modify
      old.destroy_all
    end

    orphan_visited = Visited.left_joins(:de_setting).where(de_settings: {id: nil})
    puts "Orphan visited : #{orphan_visited.length}"
    if modify
      orphan_visited.destroy_all
    end

    orphan_userfiles = UserFile.includes(:de_settings).where(:de_settings => { :user_file_id => nil })
    puts "Orphan UserFiles : #{orphan_userfiles.length}.  examples : #{orphan_userfiles.take(5).map &:location}"
    if modify
      orphan_userfiles.destroy_all
    end

    db_files = UserFile.all.map {|u| u.location}.each_with_object(nil).to_h
    unused_files = Dir["uploads/*"].select {|f| !db_files.key?(f)}
    size = 0
    unused_files.each {|f| size += File.size(f) if f}
    puts "Unused files : #{unused_files.length}.  Total size : #{size}.  examples : #{unused_files.take(5)}"

    if !dest.nil?
      FileUtils.mv unused_files, dest, :verbose => true, :noop => !modify
    end
  end

end
