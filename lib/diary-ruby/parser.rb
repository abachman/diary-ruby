# Parse a plaintext diary entry into a Diary::Entry object

module Diary
  class Parser
    def self.parse(infile)
      header = []
      body = []
      in_header = true
      split_match = /^---+$/

      Diary.debug("PARSE #{ infile.size } BYTES")

      infile.lines.each do |line|
        if in_header
          if split_match =~ line
            in_header = false
            next
          end

          # check for line
          header << line
        else
          body << line
        end
      end

      metadata = {}

      key_match = /^([A-Za-z_-]+):? (.+)$/
      header.each do |h_line|
        if key_match =~ h_line
          key = $1.strip.downcase
          val = $2.strip

          if /tags/i =~ key
            val = val.split(',').map {|v| v.strip}
          end

          metadata[key] = val
        end
      end

      key = Entry.keygen(metadata['day'], metadata['time'])
      Diary.debug "KEY #{ key }"
      Diary.debug "METADATA #{ metadata.inspect }"
      Diary.debug "BODY #{ body.join(" ") }"

      return Entry.new(
        day: metadata['day'],
        time: metadata['time'],
        tags: metadata['tags'],
        body: body.join("\n").strip,
        title: metadata['title'],
        key: key,
      )
    end

    def self.parse_file(file)
      # read
      file.seek(0)
      contents = file.read

      # now parse
      self.parse(contents)
    end
  end
end
