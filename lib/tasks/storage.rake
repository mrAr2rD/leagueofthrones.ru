namespace :storage do
  desc "Purge all orphaned Active Storage blobs (files missing from disk)"
  task purge_orphaned: :environment do
    purged = 0
    ActiveStorage::Blob.find_each do |blob|
      unless blob.service.exist?(blob.key)
        blob.purge
        purged += 1
        puts "Purged: #{blob.filename}"
      end
    end
    puts "Done. Purged #{purged} orphaned blobs."
  end
end
