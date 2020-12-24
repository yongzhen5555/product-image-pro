module SlackHelper
  include BaseHelper
  def slack_notify_product(message)
    notifier = Slack::Notifier.new "#{ENV['SLACK_NOTIFICATION_URL']}" do
      defaults channel: "#product-sync-notifications"
    end

    notifier.ping message
  end
end
