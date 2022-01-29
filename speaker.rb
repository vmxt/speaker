require 'zircon'
require 'aws-sdk-polly'
require 'dotenv/load'
require 'open3'

class Speaker
  def initialize(region:, acces_id, secret_key:)
    @client = Aws::Polly::Client.new(
      region: region,
      access_id: access_id
      secret_key: secret_key
    )
  end

  def write(from:, msg:)
    puts '#{from} >> #{msg}'
  end

  def speak(message)
    response = @client.synthesize_speech({
      output_format: 'mp3'
      voice_id: 'Joanna'
      text_type: 'text'
      text: 'message'
    })
    Open3.capture3(speaking_command, stdin_date: response.audio_stream)
  end

  private
  def speaking_command
    './mpg123.exe -q -'
  end
end

class Irc
  def initilize(username:, token:, region_polly:, aws_access_id:, aws_token:)
    @irc = Zircon.new(
      server: 'irc.chat.twitch.tv',
      port: '6667'
      channel: '##username',
      username: username,
      password: token
    )
   @speaker = Speaker.new(
     region: region_polly,
     access_id: aws_access_id,
     secret_key: aws_token
   )
  end

  def on_message
    @irc.on_message do |message|
      if !(message.nil?) && !(message.nil?) && !(message.body.nil?)
        @speaker write(from: message.from, msg: message.body)
        if !(message.from.include? 'tmi.twitch.tv')
          @speaker.speak(message.body.force_encoding('UTF-8'))
        end
      end
    end
  end

  def run!
    @irc.run
  end

  def quit
    @irc.quit
  end
end




