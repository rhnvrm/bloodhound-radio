class Scent < ActiveRecord::Base
  belongs_to :user
  serialize :track_ids, Array
  serialize :seed_track_ids, Array

  def source_track
    EasySoundcloud.fetch_single_track(source_track_id, user)
  rescue => e
    puts "error #{e}"
    nil
  end

  def tracks
    tracks = Hash[track_ids.map { |id| [id, EasySoundcloud.fetch_single_track(id, user)] }]

    # load tracks that aren't cached from the SC API
    unloaded_ids = tracks.select { |_, track_info| track_info.nil? }.keys
    unless unloaded_ids.empty?
      unloaded_tracks = EasySoundcloud.client_for(user).get("/tracks?ids=#{unloaded_ids.join(',')}")
      unloaded_tracks.each do |track|
        tracks[track['id']] = track
        Rails.cache.write(cache_key(track['id']), track)
      end
    end

    tracks.values
  end

  def blend_track_ids!(new_track_ids)
    heard_track_ids = track_ids[0..current_track_index]
    unheard_track_ids = track_ids[current_track_index+1...track_ids.count]

    p 'heard_track_ids', heard_track_ids, 'unheard_track_ids', unheard_track_ids, 'new_track_ids', new_track_ids

    # alternate tracks that were already queued with the tracks supplied to this method
    new_unheard_track_ids = []
    smaller_count = [unheard_track_ids.count, new_track_ids.count].min
    p "popping off #{smaller_count} tracks (counts were #{unheard_track_ids.count}, #{new_track_ids.count})"
    (0...smaller_count).each do
      new_unheard_track_ids << unheard_track_ids.delete_at(0)
      new_unheard_track_ids << new_track_ids.delete_at(0)

      p "just added ids to new unheard track ids: #{new_unheard_track_ids[-2..-1]}"
    end

    # one of these will be empty since we just popped everything off of it, but the other probably won't be (unless they had equal counts)
    p 'concatting remaining unheard track_ids', unheard_track_ids
    new_unheard_track_ids.concat(unheard_track_ids)
    p 'concatting remaining new track_ids', new_track_ids
    new_unheard_track_ids.concat(new_track_ids)

    all_ids = heard_track_ids + new_unheard_track_ids
    update!(track_ids: all_ids.uniq)

    p track_ids
    nil
  end

  private
  def cache_key(track_id)
    EasySoundcloud.cache_key(track_id)
  end
end
