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
  class MpegSegmenterCLI
    def self.execute(argv)
      self.new.execute(argv)
    end
    
    def print_usage
        puts "mpeg-segmenter, MPEG Transport Segmenter v#{MPEGTS::Version}, rev. #{MPEGTS::Revision}"
        puts "Converts MPEG-TS files into HTTP Live Streaming M3U8. Copyright (C) 2011 by Guido D'Albore (guido@bitstorm.it)"
        puts
        puts "Usage:"
        puts "\t" + File.split($0)[1] + " <input-ts-file> <duration-in-seconds> <output-path> [segment-base-URL]"
        puts
    end
    
    def execute(argv)
      if((argv.length < 3) || (argv.length > 4))
          print_usage
          exit!
      else
          input_file = argv[0] # Input .TS filepath
          input_file = input_file.sub("//", "/")
          input_file = input_file.sub("//", "/")
          output_basename = File.basename(input_file, File.extname(input_file))
          duration_in_seconds = argv[1].to_i
          output_folder = argv[2] + "/"
          base_url = argv[3] # it can be "nil"
          base_url = "" if(base_url.nil?)
          output_file = output_folder + output_basename + "%d.ts"
      end

      begin
        segmenter = HTTPLiveStreaming::Segmenter::new(input_file, output_file, output_folder, duration_in_seconds, base_url, output_basename)
        segmenter.process
      rescue => exception
        print_usage
        puts exception
        exit!
      end
    end
  end
  
end


