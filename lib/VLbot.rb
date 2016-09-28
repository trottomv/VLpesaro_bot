require 'dotenv'
require 'telegram/bot'
require 'twitter'
require 'sqlite3'
require 'feed-normalizer'
require_relative 'twitter_reader'

class VLpesarobot
	attr_reader :logger

 def initialize
	 Dotenv.load
	 @logger = Logger.new('log/production.log')
 end

	def run!
		feed = FeedNormalizer::FeedNormalizer.parse open('http://www.gazzetta.it/rss/basket.xml')
		token = ENV['TELEGRAM_TOKEN']
		Telegram::Bot::Client.run(token) do |bot|
		bot.listen do |message|
			case message.text
			when '/start'
		    db = SQLite3::Database.open ENV['PATH_DB']
		    db.execute "INSERT INTO chatid VALUES ('#{message.from.first_name}', '#{message.from.last_name}', '#{message.from.username}', '#{message.chat.id}', '#{Time.now}')"
				bot.api.send_message(chat_id: message.chat.id, text: "Ciao #{message.from.first_name}, benvenuto!!
Io sono il Bot 'VL Pesaro [unofficial]', da ora riceverai tutte le notizie della 'Victoria Libertas Pallacanestro Pesaro'

Questo bot NON e' associato a U.S.Victoria Libertas Pallacanestro s.s.r.l. che e' una societa' registrata.

Digita /help per ricevere aiuto su come utilizzare questo bot.")
			when '/stop'
				db = SQLite3::Database.open ENV['PATH_DB']
				db.execute "DELETE FROM chatid WHERE ID = '#{message.chat.id}'"
				bot.api.send_message(chat_id: message.chat.id, text: "Arrivederci a presto #{message.from.first_name}, grazie per aver utilizzato @VLpesaro_bot")
			when '/meteo'
				bot.api.send_message(chat_id: message.chat.id, text: "http://trottomv.dtdns.net/meteo#{Time.now.strftime("%Y%m%d")}.png")
			when '/basketnews'
				bot.api.send_message(chat_id: message.chat.id, text: "#{feed.entries.first.url}")
			when '/help'
				bot.api.send_message(chat_id: message.chat.id, text: "Ciao #{message.from.first_name} cerchi aiuto? Io sono il bot VL Pesaro [unofficial].

Ecco i comandi per interagire con me:

/start  - iscrizione
/stop - cancellazione
/meteo - info meteo Pesaro
/basketnews  - l'ultima notizia del Basket italiano da gazzetta .it
/help - info aiuto

Questo bot NON e' associato a U.S.Victoria Libertas Pallacanestro s.s.r.l. che e' una societa' registrata.
")
			end
		end
		end
	end

	def allid
		db = SQLite3::Database.open ENV['PATH_DB']
		db.execute "SELECT DISTINCT ID FROM chatid"
	end

	def telegram_client
    @telegram_client ||= Telegram::Bot::Client.new(ENV['TELEGRAM_TOKEN'])
  end

	def twitter_handlers
		ENV['TWITTER_HANDLERS'].split(',').map(&:strip)
	end

	def send_message(chat_id, text)
    begin
      telegram_client.api.send_message(chat_id: chat_id, text: text)
    rescue Telegram::Bot::Exceptions::ResponseError => exception
      logger.error "#{exception.message} (#send_message chat_id: #{chat_id}, text: #{text})"
    end
  end

	def send_last_tweets(minutes: 60)
		allid.each do |eachid|
	    twitter_handlers.each do |handler|
	      TwitterReader.new(handler).tweets_for_last_minutes(minutes).each do |tweet|
					send_message("#{eachid}".tr("\[\]\"", ""), tweet.url)
				end
      end
    end
  end

end
