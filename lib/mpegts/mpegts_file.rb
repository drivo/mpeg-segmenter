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
  class MpegTsFile
    def initialize(tsFilePath)
        raise "File \"#{tsFilePath}\" doesn't exist!" if !File.exist?(tsFilePath)

        @filePath = tsFilePath
        @fileSize = File.size(filePath)

        raise "File \"#{tsFilePath}\" contains an incorrent size (it must be multiple of 188 bytes)." if self.size%MPEGTS::MPEGTSConstants::TS_PACKET_SIZE != 0
      
        @segmentCount = File.size(filePath) / MPEGTS::MPEGTSConstants::TS_PACKET_SIZE

        @currentSegment = 0

        # It's better to pre-open the file
        # otherwise the time to browse the segment
        # increases hugely
        #@file = File.open(@filePath, "r:binary")
        @file = File.open(@filePath, "rb")
    end

    # Getters
    def filePath; @filePath; end
    def segmentCount; @segmentCount; end
    def size; @fileSize ; end
    def currentSegment; @currentSegment; end

    def eachSegment(&b)
        @currentSegment = 0;

        0.upto(@segmentCount-1) {
            b.call(nextSegment)
        }
    end

    def nextSegment()
        if(@currentSegment == @segmentCount)
            # We reached the end of file
            return nil
        end

        segment = getSegment(@currentSegment)
        @currentSegment += 1

        return segment
    end

    def getSegment(segmentNumber)
        if((segmentNumber < 0) || (segmentNumber >= @segmentCount))
            return nil
        end

        @file.seek(MPEGTS::MPEGTSConstants::TS_PACKET_SIZE * segmentNumber, IO::SEEK_SET)
        data = @file.read(MPEGTS::MPEGTSConstants::TS_PACKET_SIZE)

        MPEGTSSegment.new(data.bytes.to_a, segmentNumber)
    end

  end
end
