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
    module MPEGTSConstants
        TS_PACKET_SIZE = 188
        TS_PACKET_SYNC_BYTE = 0x47
        TS_PACKET_HEADER_OFFSET = 0
        TS_PACKET_HEADER_SIZE = 4
        TS_PACKET_PES_PREFIX = 0x000001
        TS_PACKET_ADAPTATION_FIELD_LENGTH_OFFSET = 4

        TS_PACKET_ADAPTATION_FIELD_RESERVED = 0x00
        TS_PACKET_ADAPTATION_FIELD_PAYLOAD_ONLY = 0x01
        TS_PACKET_ADAPTATION_FIELD_ONLY = 0x02
        TS_PACKET_ADAPTATION_FIELD_WITH_PAYLOAD = 0x03

        PES_PACKET_STREAM_ID_OFFSET = 3
        PES_PACKET_LENGTH_OFFSET = 4
        PES_PACKET_STREAM_INFO_OFFSET = 6
        PES_PACKET_PTS_DST_OFFSET = 9

        #        Stream Identifiers (stream_id field in the PES packet):
        #        -----------------------------------
        #        10111100 1 program_stream_map
        #        10111101 2 private_stream_1
        #        10111110 padding_stream
        #        10111111 3 private_stream_2
        #        110x xxxx ISO/IEC 13818-3 or ISO/IEC 11172-3 or ISO/IEC 13818-7 or ISO/IEC 14496-3 audio stream number x xxxx
        #        1110 xxxx ITU-T Rec. H.262 | ISO/IEC 13818-2 or ISO/IEC 11172-2 or ISO/IEC 14496-2 video stream number xxxx
        #        1111 0000 3 ECM_stream
        #        1111 0001 3 EMM_stream
        #        1111 0010 5 ITU-T Rec. H.222.0 | ISO/IEC 13818-1 Annex A or ISO/IEC 13818-6_DSMCC_stream
        #        1111 0011 2 ISO/IEC_13522_stream
        #        1111 0100 6 ITU-T Rec. H.222.1 type A
        #        1111 0101 6 ITU-T Rec. H.222.1 type B
        #        1111 0110 6 ITU-T Rec. H.222.1 type C
        #        1111 0111 6 ITU-T Rec. H.222.1 type D
        #        1111 1000 6 ITU-T Rec. H.222.1 type E
        #        1111 1001 7 ancillary_stream
        #        1111 1010 ISO/IEC14496-1_SL-packetized_stream
        #        1111 1011 ISO/IEC14496-1_FlexMux_stream
        #        1111 1100 ... 1111 1110 reserved data stream
        #        1111 1111 4 program_stream_directory


        PES_PACKET_AUDIO_STREAM_ID_MASK = 0b11100000
        PES_PACKET_AUDIO_STREAM_NUMBER_MASK = 0b00011111
        PES_PACKET_VIDEO_STREAM_ID_MASK = 0b11110000
        PES_PACKET_VIDEO_STREAM_NUMBER_MASK = 0b00001111

        PES_PACKET_AUDIO_STREAM_ID = 0b11000000
        PES_PACKET_VIDEO_STREAM_ID = 0b11100000

        ADAPTATION_STRING_MAP = {
            TS_PACKET_ADAPTATION_FIELD_RESERVED => "TS_PACKET_ADAPTATION_FIELD_RESERVED",
            TS_PACKET_ADAPTATION_FIELD_PAYLOAD_ONLY  => "TS_PACKET_ADAPTATION_FIELD_PAYLOAD_ONLY",
            TS_PACKET_ADAPTATION_FIELD_ONLY => "TS_PACKET_ADAPTATION_FIELD_ONLY",
            TS_PACKET_ADAPTATION_FIELD_WITH_PAYLOAD => "TS_PACKET_ADAPTATION_FIELD_WITH_PAYLOAD"
        }

        PES_PACKET_PTS_ONLY_VALUE     = 0b00000010
        PES_PACKET_PTS_AND_DTS_VALUE  = 0b00000011
        
        # In according to the specification the timer is set to 90 kHz
        TIMER_IN_HZ                   = 90000.0;
    end
    
end