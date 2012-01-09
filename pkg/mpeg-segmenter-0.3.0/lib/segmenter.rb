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

$LOAD_PATH << File.dirname(__FILE__) unless $LOAD_PATH.include?(File.dirname(__FILE__))

require 'mpegts/mpegts_constants'
require 'mpegts/mpegts_file'
require 'mpegts/mpegts_segment'
require 'mpegts/httpls/httpls_m3u8'
require 'mpegts/httpls/httpls_segmenter'
require 'mpegts/cli/mpeg-segmenter'
require 'mpegts/cli/m3u8-playlist-generator'

module MPEGTS
    Version         = '0.3.0'
    Revision        = '0'
    RevisionDate    = "2011-12-30"
    
    InfoLog         = true
    WarnLog         = true
    ErrorLog        = true
    DebugLog        = true
end
