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
    class MPEGTSSegment
        include MPEGTSConstants
        
        attr_reader :pid
        attr_reader :sequence
        attr_reader :continuity_counter
        attr_reader :adaptation_field_control
        attr_reader :payload_unit_start_indicator
        attr_reader :is_video_stream
        attr_reader :is_audio_stream
        attr_reader :stream_number
        attr_reader :pts
        attr_reader :pts_defined
        attr_reader :program_map_PIDs

        def data; @data; end
      
        def program_PIDs; @program_map_PIDs; end
      
        def initialize(segment, sequence)
            if(segment[0] != TS_PACKET_SYNC_BYTE) then
                puts "Segment '#{sec}' not valid: sync byte 0x47 not found." if ErrorLog
                raise "Segment '#{sec}' not valid: sync byte 0x47 not found."
            end
            
            @data = segment
            @sequence = sequence

            @stream_id = nil
            @stream_number = nil
            @pes_packet_length = 0
            @is_video_stream = false
            @is_audio_stream = false
            @pts_defined = false

            # Parse the Header
            self.parseHeader

            if(self.pesPacketFound)
                self.parsePesPacket
            end

            if(self.programAssociationSectionFound)
                self.parseProgramAssociationSection
            end
        end


        def programAssociationSectionFound
            @pid == 0
        end

        # Parse the Program Association Section in according to 
        # ISO 13818-1 specification:
        #
        #        -----------------------------------
        #        HEADER (3 bytes)
        #          1st byte (MSB -> LSB):
        #            table_id 8 bits
        #
        #          2nd/3rd bytes:
        #             section_syntax_indicator 1
        #             '0' 1
        #             reserved 2
        #             section_length 12
        #        -----------------------------------
        #          4th/5th bytes (MSB -> LSB):
        #             transport_stream_id 16
        #
        #          6th byte:
        #             reserved 2
        #             version_number 5
        #             current_next_indicator 1
        #
        #          7th byte:
        #             section_number 8
        #
        #          8th byte:
        #             last_section_number 8 imsbf
        #
        #          9th (for each program, 4 bytes):
        #             program_number 16 bits
        #             reserved 3 bits
        #             network_pid or program_map_PID 13 bits
        #
        #          Last 4 bytes
        #            CRC32
        def parseProgramAssociationSection
            offset = self.pasSectionOffset
            #puts "PES Section offset: " + offset.to_s if InfoLog

            #First byte of Program Association Section
            @table_id = @data[offset + 0]

            #Second byte
            info = @data[offset + 1]
            @section_syntax_indicator = (info & 0b10000000) != 0
            @section_length = (info & 0b00001111) << 8

            #Third byte
            @section_length = @section_length | @data[offset + 2]
            @number_of_programs = (@section_length - 9) / 4
            #      puts "PES Section length: " + @section_length.to_s
            #      puts "Number of programs: " + @number_of_programs.to_s

            # Fourth/Fifth bytes
            @transport_stream = (@data[offset + 3] << 8) | @data[offset + 4]

            # Sixth byte
            info = @data[offset + 5]
            @version_number = (info & 0b00111110) >> 1
            @current_next_indicator = (info & 0b00000001)

            # Seventh byte
            @section_number = [offset + 6]

            # Eighthth byte
            @last_section_number = [offset + 7]

            @program_map_PIDs = Array.new
            @network_pid = nil
            0.upto(@number_of_programs-1) {
                |i|
                base_offset = offset + 8 + i*4;
                program_number = (@data[base_offset] << 8) | @data[base_offset + 1]

                # First 3 bits are reverved
                pid = ((@data[base_offset + 2] << 8) | @data[base_offset + 3]) & 0b0001111111111111

                if(program_number == 0)
                    # network_pid
                    @network_pid = pid
                else
                    @program_map_PIDs << pid
                end
            }
        end

        # The timer in the MPEG-TS is set to 90kHz
        def pts2seconds
           return pts/TIMER_IN_HZ
        end

        # Parse the Header in according to the following table:
        # 
        #        Transport Packet Header (4 bytes)
        #        -----------------------------------
        #          1st byte (MSB -> LSB):
        #            sync_byte => 8 bits
        #
        #          2nd/3rd bytes:
        #            transport_error_indicator => 1 bits
        #            payload_unit_start_indicator => 1 bits
        #            transport_priority => 1 bits
        #            PID => 13 bits
        #
        #          4th byte:
        #            transport_scrambling_control => 2 bits
        #            adaptation_field_control => 2 bits
        #            continuity_counter => 4 bits
        def parseHeader
            @sync_byte = @data[0]
            @transport_error_indicator = (@data[1] & 0b10000000) != 0
            @payload_unit_start_indicator =  (@data[1] & 0b01000000) != 0
            @transport_priority =  (@data[1] & 0b00100000) != 0
            @pid = ((@data[1] & 0b00011111) << 8) | @data[2]
            @transport_scrambling_control = (@data[3] & 0b11000000) >> 6
            @adaptation_field_control = (@data[3] & 0b00110000) >> 4
            @continuity_counter = (@data[3] & 0b00001111)
        end

        def parsePesPacket
            offset = self.pesPacketOffset

            @stream_id = @data[offset + PES_PACKET_STREAM_ID_OFFSET]
            @pes_packet_length = (@data[offset + PES_PACKET_LENGTH_OFFSET] << 8) | (@data[offset + PES_PACKET_LENGTH_OFFSET + 1])
            @is_video_stream = (@stream_id & PES_PACKET_VIDEO_STREAM_ID_MASK) == PES_PACKET_VIDEO_STREAM_ID
            @is_audio_stream = (@stream_id & PES_PACKET_AUDIO_STREAM_ID_MASK) == PES_PACKET_AUDIO_STREAM_ID


            if(@is_video_stream)
                @stream_number = (@stream_id & PES_PACKET_VIDEO_STREAM_NUMBER_MASK)
            end

            if(@is_audio_stream)
                @stream_number = (@stream_id & PES_PACKET_AUDIO_STREAM_NUMBER_MASK)
            end

            if(@is_video_stream || @is_audio_stream)
=begin
    1st byte (MSB -> LSB):
      '10' => 2 bits
      PES_scrambling_control => 2 bits
      PES_priority => 1 bit
      data_alignment_indicator => 1 bit
      copyright => 1 bit
      original_or_copy => 1 bit

    2nd byte:
      PTS_DTS_flags => 2 bits
      ESCR_flag => 1 bit
      ES_rate_flag => 1 bit
      DSM_trick_mode_flag => 1 bit
      additional_copy_info_flag => 1 bit
      PES_CRC_flag => 1 bit
      PES_extension_flag => 1 bit

    3rd byte:
      PES_header_data_length => 8 bits
=end

                # gets first byte
                info = @data[offset + PES_PACKET_STREAM_INFO_OFFSET + 0]
                @pes_scrambling_control = (info & 0b00110000) >> 4
                @pes_priority = (info & 0b00001000) != 0
                @data_alignment_indicator = (info & 0b00000100) != 0
                @copyright = (info & 0b00000010) != 0
                @original_or_copy = info & 0b00000001

                # gets second byte
                info = @data[offset + PES_PACKET_STREAM_INFO_OFFSET + 1]
                @pts_dts_flags = (info & 0b11000000) >> 6
                @escr_flag = (info & 0b00100000) != 0
                @es_rate_flag = (info & 0b00010000) != 0
                @dsm_trick_mode_flag = (info & 0b00001000) != 0
                @additiona_copy_info_flag = (info & 0b00000100) != 0
                @pes_crc_flag = (info & 0b00000010) != 0
                @pes_extension_flag = (info & 0b00000001) != 0

                # gets third byte
                @pes_header_length = @data[offset + PES_PACKET_STREAM_INFO_OFFSET + 2]

                if(   (@pts_dts_flags == PES_PACKET_PTS_ONLY_VALUE) ||
                      (@pts_dts_flags == PES_PACKET_PTS_AND_DTS_VALUE))
=begin
        PTS (presentation time stamp, 90KHz clock) structure:

        1st byte (MSB -> LSB):
          '0010' => 4 bits
          PTS [32..30] => 3 bits
          marker_bit => 1 bit

        2nd / 3rd bytes:
          PTS [29..15] => 15 bits
          marker_bit => 1 bit

        4th/5th bytes:
          PTS [14..0] => 15 bits
          marker_bit => 1 bits
=end
                    # first byte
                    info = @data[offset + PES_PACKET_PTS_DST_OFFSET + 0]
                    @pts = (info & 0b00001110) << 29

                    # second byte (8 bit of data)
                    info = @data[offset + PES_PACKET_PTS_DST_OFFSET + 1]
                    @pts = @pts | (info << 22)

                    # third byte (7 bit of data)
                    info = @data[offset + PES_PACKET_PTS_DST_OFFSET + 2]
                    @pts = @pts | ((info & 0b11111110) << 14)

                    # fourth byte (8 bit of data)
                    info = @data[offset + PES_PACKET_PTS_DST_OFFSET + 3]
                    @pts = @pts | (info << 7)

                    # fifth byte (7 bit of data))
                    info = @data[offset + PES_PACKET_PTS_DST_OFFSET + 4]
                    @pts = @pts | (info >> 1)

                    @pts_defined = true
                    #puts "PTS class type: " + @pts.class.to_s
                end

                #      if(@pts_dts_flags == PES_PACKET_PTS_AND_DTS_VALUE)
                #        # PTS and DTS are declared
                #      end
            end
        end

        def pesPacketOffset
            #    offset 0: packet_start_code_prefix => 24 bits
            #    offset 3: stream_id => 8 bits
            #    offset 4: PES_packet_length => 16 bits

            @stream_id = @data[3]
            return TS_PACKET_HEADER_SIZE + self.adaptationFieldSize;
        end

        def pasSectionOffset
            if(@payload_unit_start_indicator)
                return TS_PACKET_HEADER_SIZE + self.adaptationFieldSize + 1;
            end

            return TS_PACKET_HEADER_SIZE + self.adaptationFieldSize
        end

        def pesPacketFound
            if( ((@adaptation_field_control == TS_PACKET_ADAPTATION_FIELD_PAYLOAD_ONLY)   ||
                 (@adaptation_field_control == TS_PACKET_ADAPTATION_FIELD_WITH_PAYLOAD))  &&
                  @payload_unit_start_indicator)

                offset = self.pesPacketOffset

                byte1 = @data[offset + 0] << 16
                byte2 = @data[offset + 1] << 8
                byte3 = @data[offset + 2]

                pesprefix = (byte1 | byte2 | byte3)

                #puts "Prefix: " + pesprefix.to_s
                return pesprefix == TS_PACKET_PES_PREFIX
            end

            return false
        end

        def adaptationFieldLegth
            if( (@adaptation_field_control == TS_PACKET_ADAPTATION_FIELD_ONLY) ||
                (@adaptation_field_control == TS_PACKET_ADAPTATION_FIELD_WITH_PAYLOAD) )
                # adaptation field present, the length is defined on the first byte after
                # the packet header (4 bytes)

                return @data[TS_PACKET_ADAPTATION_FIELD_LENGTH_OFFSET]
            end

            return 0
        end

        def adaptationFieldSize
            length = self.adaptationFieldLegth

            if(length != 0)
                # +1 is the size of "length" field
                return length + 1
            end

            return 0
        end

        

    end
end