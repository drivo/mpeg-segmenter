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

module HTTPLiveStreaming
  class M3u8
      def initialize(filepath, target_duration = nil, base_url = nil, media_sequence = nil)
          @file = File.open(filepath, "w")
          @file.puts("#EXTM3U")
          @file.puts("#EXT-X-TARGETDURATION:%d" % target_duration) if(!target_duration.nil?)
          @file.puts("#EXT-X-MEDIA-SEQUENCE:%d" % media_sequence) if(!media_sequence.nil?)
          @file.flush

          @duration = target_duration
          
          @url_prefix = base_url
          @url_prefix = "segment_" if(base_url.nil?)
          @counter = 1
      end

      def insert(resourceUrl, duration = @duration, description = "")
          @file.puts(sprintf("#EXTINF:%d, %s", duration, description))
          @file.puts(resourceUrl)
      end

      def insertMedia(duration = nil)
          duration = @duration if(duration.nil?)

          insert(@url_prefix + @counter.to_s + ".ts", duration)
          @counter += 1
      end

      def insertPlaylist(url, bandwidth, program_id = 1, resolution_width = nil, resolution_height = nil)
          if(resolution_width.nil? || resolution_height.nil?)
              @file.puts(sprintf("#EXT-X-STREAM-INF:PROGRAM-ID=%d, BANDWIDTH=%d", program_id, bandwidth))
          else
              @file.puts(sprintf("#EXT-X-STREAM-INF:PROGRAM-ID=%d, BANDWIDTH=%d, RESOLUTION=%dx%d", program_id, bandwidth, resolution_width, resolution_height))
          end

          @file.puts(url)
      end

      def close
          @file.puts("#EXT-X-ENDLIST")
          @file.close
      end
  end
end

__END__

** Usage examples **
#
#playlist = M3u8.new("/test-low.m3u8", 15, "fragment_low_")
#playlist.insertMedia
#playlist.insertMedia
#playlist.insertMedia
#playlist.close
#
#playlist = M3u8.new("/test-hi.m3u8", 15, "fragment_hi_")
#playlist.insertMedia
#playlist.insertMedia
#playlist.insertMedia
#playlist.close
#
#playlist = M3u8.new("/test_variants.m3u8")
#playlist.insertPlaylist("test-low.m3u8", 250000, 1, 400, 224)
#playlist.insertPlaylist("test-hi.m3u8", 1240000, 1, 640, 360)
#playlist.close

** Example M3U8 with bandwidth adaptation **
---
##EXTM3U
#EXT-X-STREAM-INF:PROGRAM-ID=1, BANDWIDTH=240000
iphone_3g/stream.m3u8
#EXT-X-STREAM-INF:PROGRAM-ID=1, BANDWIDTH=640000
iphone_wifi/stream.m3u8
#EXT-X-STREAM-INF:PROGRAM-ID=1, BANDWIDTH=1240000
ipad_wifi/stream.m3u8
---

** Example M3U8 with single segmented media **
---
#EXTM3U
#EXT-X-TARGETDURATION:10
#EXT-X-MEDIA-SEQUENCE:0
#EXTINF:10, no desc
fileSequence1.ts
#EXTINF:10, no desc
fileSequence2.ts
#EXTINF:10, no desc
fileSequence3.ts
#EXTINF:10, no desc
fileSequence4.ts
#EXTINF:10, no desc
fileSequence5.ts
#EXTINF:10, no desc
fileSequence6.ts
#EXTINF:10, no desc
fileSequence7.ts
#EXTINF:10, no desc
fileSequence8.ts
#EXTINF:10, no desc
fileSequence9.ts
#EXTINF:10, no desc
fileSequence10.ts
#EXT-X-ENDLIST
---