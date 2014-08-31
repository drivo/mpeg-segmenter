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
  class Segmenter
      def initialize(input_file, output_file, output_path, segment_duration = 10, base_url = nil, resource_name = "stream")
        if(!File.directory?(output_path))
            raise "Output directory path #{output_path} is not valid!"
        end

        if(!File.exist?(input_file))
            raise "Input file #{input_file} doesn't exist!"
        end

        if(!segment_duration.instance_of?(Fixnum))
            raise "Invalid duration value (#{segment_duration}). It must be an integer value."
        end

        if(!(segment_duration > 1))
            raise "Invalid duration value (#{segment_duration}). It must greater than 1 second."
        end

        begin
            @tsFile = MPEGTS::MpegTsFile.new(input_file)
            @m3u8file = HTTPLiveStreaming::M3u8.new(output_path + resource_name + ".m3u8", segment_duration, base_url + resource_name)
        rescue => exception
            raise exception
        end
        
        puts "Input transport streaming file: \"" + @tsFile.filePath + "\""
        puts "Transport streaming size: " + @tsFile.size.to_s
        puts "Number of transport segments: " + @tsFile.segmentCount.to_s
        
        @durationInSeconds = segment_duration;
        @inputFile = input_file;
        @destinationFile = output_file;
      end
    
      def process
        duration_per_segment = @durationInSeconds #seconds
        file_count = 1;
        last_segment_copied = 0
        last_association_table = temp_last_association_table = 0
        #last_program_table = 0
        segment_count = 0
        program_pids = Array.new
        absolute_time = 0

        #time1 = Time.now.to_i
        reference_time = nil
        @tsFile.eachSegment() { |i|
            #  if((@tsFile.currentSegment%1000) == 0)
            #    puts "%0.0f%%" % (segment_count.to_f/@tsFile.segmentCount.to_f * 100.0)
            #    puts "Current segment: " + @tsFile.currentSegment.to_s
            #  end

            if((segment_count-1) == temp_last_association_table)
                # Check if this association table is adiacent to program table
                if(program_pids.include?(i.pid))
                    #      puts "Sequence: " + (i.sequence + 1).to_s
                    #      puts "Program map PID found: mark position"
                    # mark position for block copying
                    last_association_table = temp_last_association_table
                    #      puts "-----------------"
                end
            end

            if(i.pid == 0)
                temp_last_association_table = segment_count
                program_pids = i.program_PIDs
                #    puts "PID: Program Association Table"
                #    puts "Sequence: " + (i.sequence + 1).to_s
                #    puts "Program PIDS: " + i.program_PIDs.to_s
                #    puts "-----------------"
            end

            #  if(i.pid == 1)
            #    puts "PID: Conditional Access Table"
            #    puts "Sequence: " + (i.sequence + 1).to_s
            #    puts "-----------------"
            #  end
            #  if(i.pid == 2)
            #    puts "PID: Transport Stream Description Table"
            #    puts "Sequence: " + (i.sequence + 1).to_s
            #    puts "-----------------"
            #  end
            #  if(i.pid == 0x1FFF)
            #    puts "PID: Null Packet"
            #    puts "Sequence: " + (i.sequence + 1).to_s
            #    puts "-----------------"
            #  end
            #  if((i.pid >= 3) && (i.pid <= 0xF))
            #    puts "PID: RESERVED Packet"
            #    puts "Sequence: " + (i.sequence + 1).to_s
            #  end

            # Is the Presentation Time Stamp (PTS) defined within the TS packet?
            if(i.pts_defined)

                #    puts "PID: " + i.pid.to_s
                #    puts "Sequence: " + (i.sequence + 1).to_s
                #    puts "Continuity counter: " + i.continuity_counter.to_s
                #    puts "Adaptation Field Control: " + i.adaptation_field_control.to_s + " (" + ADAPTATION_STRING_MAP[i.adaptation_field_control] + ")"
                #    puts "PES/PSI Start Indicator: " + i.payload_unit_start_indicator.to_s
                #    puts "Adaptation Field Size: " + i.adaptationFieldSize.to_s
                #    puts "PES packet found: " + i.pesPacketFound.to_s
                #    puts "Video stream: " + i.is_video_stream.to_s
                #    puts "Audio stream: " + i.is_audio_stream.to_s
                #    puts "Stream number: " + i.stream_number.to_s

               if(reference_time.nil?)
                   # The first time we get a PTS, we need to setup the reference_time
                    reference_time = i.pts2seconds
                end

                absolute_time = i.pts2seconds - reference_time
                #puts "PTS value: " + i.pts.to_s
                #puts "PTS relative value (in seconds): " + "%0.4f" % i.pts2seconds.to_s
                #puts "PTS absolute value (in seconds): " + "%0.4f" % (absolute_time).to_s
                #puts "PTS type: " + (i.pts).class.to_s

                if(absolute_time >= duration_per_segment)
                    reference_time =  i.pts2seconds
                    @m3u8file.insertMedia
                    copy_segments_to_file( @inputFile,                    # Input .TS file
                         last_segment_copied,          # From segment
                         last_association_table,       # To segment
                         @destinationFile % file_count  # Output .TS segment file
                    )
                    last_segment_copied = last_association_table
                    file_count += 1
                end
                #    puts "-----------------"
            end
            segment_count += 1;
            #puts "%02x" % i.data[0]
        }

        if(segment_count > last_segment_copied)

            if(absolute_time.round > 0)
                # Last segment is greater than 0.5 seconds
                @m3u8file.insertMedia(absolute_time.round)

                copy_segments_to_file( @inputFile,                    # Input .TS file
                    last_segment_copied,          # From segment
                    segment_count,                # To segment
                    @destinationFile % file_count  # Output .TS segment file
                )
            else
                # Last segment is next to 0 seconds
                # We only need to merge it to the previous segment
                append_segments_to_file( @inputFile,                    # Input .TS file
                    last_segment_copied,          # From segment
                    segment_count,                # To segment
                    @destinationFile % (file_count-1)  # Output .TS segment file
                )
            end
        end

        #time2 = Time.now.to_i;
        #puts "Time elapsed: " + (time2-time1).to_s + " seconds"
        puts "Segmetation completed. Created #{file_count} segments of #{@durationInSeconds} seconds each."
        #segment = @tsFile.nextSegment
        #puts segment.data.class
        #puts "%02x" % segment.data[0]

        @m3u8file.close

      end
      
      def copy_segments_to_file(source, from, to, destination)
          print "Creating file '" + destination + "'..."
          #  puts "Writing to file '" + destination + "'..."
          #  puts "From segment: " +  from.to_s
          #  puts "To segment: " +  to.to_s
          #  puts "Data start: " +  (from * TS_PACKET_SIZE).to_s
          #  puts "Data end: " +  ((from * TS_PACKET_SIZE) + ((to-from) * TS_PACKET_SIZE) - 1).to_s
          #  puts "Data size: " +  ((to-from) * TS_PACKET_SIZE).to_s
          #  puts "-----------------------------"
          data = IO.read(source, (to-from) * MPEGTS::MPEGTSConstants::TS_PACKET_SIZE, from * MPEGTS::MPEGTSConstants::TS_PACKET_SIZE)

          #  destination_file = File.open(destination, "w:binary")
          destination_file = File.open(destination, "wb")
          destination_file.write(data)
          destination_file.close

          print "done.\n"
      end

      def append_segments_to_file(source, from, to, destination)
          print "Creating file '" + destination + "'..."
          #  puts "Writing to file '" + destination + "'..."
          #  puts "From segment: " +  from.to_s
          #  puts "To segment: " +  to.to_s
          #  puts "Data start: " +  (from * TS_PACKET_SIZE).to_s
          #  puts "Data end: " +  ((from * TS_PACKET_SIZE) + ((to-from) * TS_PACKET_SIZE) - 1).to_s
          #  puts "Data size: " +  ((to-from) * TS_PACKET_SIZE).to_s
          #  puts "-----------------------------"
          data = IO.read(source, (to-from) * TS_PACKET_SIZE, from * TS_PACKET_SIZE)

          #  destination_file = File.open(destination, "w:binary")
          destination_file = File.open(destination, "wb+")
          destination_file.seek(0, IO::SEEK_END)   # Go to the end of file
          destination_file.write(data)
          destination_file.close

          print "done.\n"
      end      
  end
end