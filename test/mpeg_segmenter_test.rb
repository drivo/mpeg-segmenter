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

$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'segmenter'
require 'fileutils'

class MpegSegmenterTest < Test::Unit::TestCase
  def initialize(test_method_name)
      super(test_method_name)
      
      @sample_dir = File.join(File.dirname(__FILE__),'samples','thesimpsonstrailer')
      @output_dir = File.join(@sample_dir,'output')    
      
      FileUtils.rm_rf(@output_dir) if File.exists?(@output_dir)
  end
  
  def setup
    Dir.mkdir(@output_dir) if !File.exists?(@output_dir)
  end
  
  def cleanup
    # Clears output directory    
    FileUtils.rm_rf(@output_dir) if File.exists?(@output_dir)
  end  
    
  def test1_segmenter_3g_64k
    assert_boolean(File.exists?(@output_dir), "Playlist cannot be generated if output directory wasn't created.")
    
    argv = Array.new
    argv[0] = File.join(@sample_dir,'thesimpsons_trailer_iphone_3g_64k.ts')
    argv[1] = "10"
    argv[2] = @output_dir
    
    # Executes segmenter
    MPEGTS::MpegSegmenterCLI.execute(argv);  

    assert_equal(File.size(File.join(@output_dir, 'thesimpsons_trailer_iphone_3g_64k.m3u8')), 766)
    assert_equal(File.size(File.join(@output_dir, 'thesimpsons_trailer_iphone_3g_64k1.ts')), 71440)
    assert_equal(File.size(File.join(@output_dir, 'thesimpsons_trailer_iphone_3g_64k14.ts')), 58280)
  end
  
  def test2_segmenter_3g_240k
    assert_boolean(File.exists?(@output_dir), "Playlist cannot be generated if output directory wasn't created.")
    
    argv = Array.new
    argv[0] = File.join(@sample_dir,'thesimpsons_trailer_iphone_3g_240k.ts')
    argv[1] = "10"
    argv[2] = @output_dir
       
    # Executes segmenter
    MPEGTS::MpegSegmenterCLI.execute(argv);  

    assert_equal(File.size(File.join(@output_dir, 'thesimpsons_trailer_iphone_3g_240k.m3u8')), 780)
    assert_equal(File.size(File.join(@output_dir, 'thesimpsons_trailer_iphone_3g_240k1.ts')), 190444)
    assert_equal(File.size(File.join(@output_dir, 'thesimpsons_trailer_iphone_3g_240k14.ts')), 187624)

  end
  
  def test3_m3u8_playlist_generator
    assert_boolean(File.exists?(@output_dir), "Playlist cannot be generated if output directory wasn't created.")
    
    argv = Array.new
    argv[0] = File.join(@output_dir,'thesimpsons_trailer_variants.m3u8')
    
    argv[1] = 'thesimpsons_trailer_iphone_3g_64k.m3u8'
    argv[2] = "64000"
    
    argv[3] = 'thesimpsons_trailer_iphone_3g_240k.m3u8'
    argv[4] = "240000"
    
    # Executes playlist generator
    MPEGTS::M3u8PlaylistGeneratorCLI.execute(argv);
  end
  
end
