#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# 
#  Copyright (C) by Guido D'Albore (guido@bitstorm.it)
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#   

# Reference Specifications:
# 
#  * ISO 13818-1 (MPEG-part1)
#  * IETF Draft HTTP Live Streaming

module MPEGTS
  class M3u8PlaylistGeneratorCLI
    def self.execute(argv)
      self.new.execute(argv)
    end
    
    def print_usage
      puts "M3u8 Variant Playlist Generator. Copyright (C) 2011 by Guido D'Albore (guido@bitstorm.it)"
      puts "Usage:"
      puts "\t" + File.split($0)[1] + " <m3u8-output-file> <variant1-url> <variant1-badwidth> <variant2-url> <variant2-badwidth> <variantX-url> <variantX-badwidth> [m3u8-base-URL]"
      puts
      puts "Example (how to generate a variant playlist with 4 different streams):"
      puts "\t" + File.split($0)[1] + " variants.m3u8 low.m3u8 250000 med.m3u8 640000 hi.m3u8 1250000 gold.m3u8 2500000 http://hostname/playlist/"
      puts
    end
    
    def execute(argv)
      if(argv.length < 3)
        print_usage
        exit!
      end

      if((argv.length%2) == 0)
        # Gets last element (base URL)
        base_url = ARGV.pop
      else
        base_url = ""
      end

      filepath = argv[0]
      playlist = HTTPLiveStreaming::M3u8.new(filepath)

      counter = 1

      begin
        while(counter < argv.length)
          playlist.insertPlaylist(base_url + argv[counter], argv[counter + 1].to_i)

          counter += 2
        end

        playlist.close

        puts "Playlist '#{filepath}' created."
      rescue => exception
        print_usage
        puts exception
        exit!
      end      
      
    end
  end
  
end


