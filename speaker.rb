require "open3"
require "dotenv/load"
require "aws-sdk-polly"
require "zircon"

class Speaker
  def initialize(region:, access_key_id:, secret_access_key:)
    @client = Aws::Polly::Client.new(
      region: region,
      access_key_id: access_key_id,
      secret_access_key: secret_access_key
    )
  end

# Visit https://aws.amazon.com/polly/ for more voice_id supported

  def speak(message)
    response = @client.synthesize_speech({
      output_format: "mp3",
      text_type: "text",
      voice_id: "Mizuki",
      text: message
    })
    Open3.capture3(speaking_command, stdin_data: response.audio_stream)
  end

  def write(from:, message:)
    puts "#{from} >> #{message}"
  end

  private
  def speaking_command
    "./mpg123.exe -q -"
  end
end

class Irc
  def initialize(twitch_username:, twitch_token:, aws_region:, aws_access_key_id:, aws_secret_access_key:)
    @irc = Zircon.new(
      server: "irc.chat.twitch.tv",
      port: "6667",
      channel: "##{twitch_username}",
      username: twitch_username,
      password: twitch_token
    )
    @speaker = Speaker.new(
      region: aws_region,
      access_key_id: aws_access_key_id,
      secret_access_key: aws_secret_access_key
    )
  end

  def on_message
    @irc.on_message do |message|
      if !(message.nil?) && !(message.from.nil?) && !(message.body.nil?)
        @speaker.write(from: message.from, message: message.body)
        if !(message.from.include? "tmi.twitch.tv")
          @speaker.speak(message.body.force_encoding("UTF-8"))
        end
      end
    end
  end

  def run!
    @irc.run!
  end

  def quit
    @irc.quit
  end
end

# configuration

twitch_username = ENV.fetch("TWITCH_USERNAME")
twitch_token = ENV.fetch("TWITCH_OAUTH_TOKEN")
aws_region = ENV.fetch("AWS_REGION", "ap-northeast-1")
aws_access_key_id = ENV.fetch("AWS_ACCESS_KEY_ID")
aws_secret_access_key = ENV.fetch("AWS_SECRET_ACCESS_KEY")

begin
  puts "STARTING APPLICATION.."
  irc = Irc.new(
    twitch_username: twitch_username,
    twitch_token: twitch_token,
    aws_region: aws_region,
    aws_access_key_id: aws_access_key_id,
    aws_secret_access_key: aws_secret_access_key
  )
  irc.on_message
  irc.run!
rescue Interrupt
  puts "CLOSING APPLICATION.."
  irc.quit
end