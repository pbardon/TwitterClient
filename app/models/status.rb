require 'twitter_session'
require 'open-uri'

def internet_connection?
  begin
    true if open("http://www.google.com/")
  rescue => e
    puts e
    false
  end
end

class Status < ActiveRecord::Base
  attr_accessible(
                  :body,
                  :twitter_status_id,
                  :twitter_user_id
                  )
  belongs_to(
              :user,
              foreign_key: :twitter_user_id,
              primary_key: :twitter_user_id
              )
  validates(
              :body,
              :twitter_status_id,
              :twitter
            )

  validates :twitter_status_id, uniqueness: true

  def self.fetch_by_twitter_id!(twitter_user_id)
    fetched_statuses_params = TwitterSession.get(
      "statuses/user_timeline",
      { user_id: twitter_user_id }
    )

    fetched_statuses = fetched_statuses_params.map do |status_params|
      parse_json(status_params)
    end

    old_ids = Status
      .where(twitter_user_id: twitter_user_id)
      .pluck(:twitter_status_id)

    new_statuses = []
    fetched_statuses.each do |status|
      next if old_ids.include?(status.twitter_status_id)
      status.save!
      new_statuses << status
    end

    new_statuses
  end

  def self.get_by_twitter_user_id(twitter_user_id)
    if internet_connection?
      fetch_by_twitter_id(twitter_user_id)
    end

    where(twitter_user_id: twitter_user_id)
  end

  def parse_json(twitter_status_params)
    Status.new(
    body: twitter_status_params["text"],
    twitter_status_id: twitter_status_params["id_str"],
    twitter_user_id: twitter_status_params["user"]["id_str"]
    )
  end

  def self.post(body)
    status_params =TwitterSession.post(
    "statuses/update",
    {status: body}
    )

    Status.parse_json(status_params).save!
  end
  
end
