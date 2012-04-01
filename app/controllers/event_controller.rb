require 'pp'
class EventController < ApplicationController
  MAX_SUBSCRIBED_PAGES = 10
  MAX_POLL_TIME = 5 # 30 second poll time
  append_before_filter :find_or_create_subscription, :only => [ :subscribe ]
  append_after_filter :write_back_session, :only => [ :subscribe ]

  def debug
    if params[:clear]
      session[:subscribed_pages] = {}
    end
    render :text => session.pretty_inspect + "\n\n\n" + params[:uuid], :content_type => "text/plain"
  end

  def subscribe
    @subscription[:subscription] = hashify_subscription_params(params)
    @subscribed_pages[@this_page_uuid] = @subscription

    render :json => true
  end

  def poll
    changes = []
    start_poll = Time.now
    find_subscription
    Rails.logger.debug("Polling: Subscribed: " + (@subscription ? @subscription[:subscription].pretty_inspect : 'nil'))

    count = 0 # TODO DEBUG
    while Time.now - start_poll < MAX_POLL_TIME
      if @subscription && @subscription[:subscription] && !@subscription[:subscription]["device"].blank?
        changes += update_device_state
      end
      break unless changes.empty?
      count += 1 # TODO DEBUG
      sleep 1
      find_subscription
    end

    Rails.logger.debug("Polling: Changes: " + changes.pretty_inspect)
    render :json => changes
  end

  private
  def update_device_state
    changes = []
    subs = @subscription[:subscription]["device"]
    state = (@subscription[:known_state]["device"] ||= {})
    if subs[:add] || subs[:remove] || subs[:state_changed] == :all
      all_devices = []
      Device.uncached do
        all_devices = Device.all # TODO: all for this user
      end

      # New devices
      all_devices.each { |d|
        if !state[d.id]
          changes.push({
            :namespace => "device",
            :event => :add,
            :options => d.to_h
          })
          state[d.id] = d.to_h
        end
      }

      # Removed devices
      removed_devices = state.keys - all_devices.map { |d| d.id }
      removed_devices.each { |d_id| state.delete(d_id) }

      changes += removed_devices.map { |d_id| { :namespace => "device", :event => :remove, :options => { :id => d_id } } }
    end
    if subs[:state_changed] && subs[:state_changed] != :all
      devices = []
      Device.uncached do
        devices = subs[:state_changed].map { |i| Device.find_by_id(i.to_i) }.compact
      end
      devices.each { |d|
        state[d.id] ||= {}
        if state[d.id][:state] != d.state
          changes.push({
            :namespace => "device",
            :event => :state_changed,
            :options => d.to_h
          })
          state[d.id] = d.to_h
        end
      }
    end
    changes
  end
  def find_or_create_subscription
    @this_page_uuid = params[:uuid]
    @subscribed_pages = session[:subscribed_pages].is_a?(Hash) ? session[:subscribed_pages] : {}
    if !@subscribed_pages[@this_page_uuid]
      @subscribed_pages[@this_page_uuid] = {
          :uuid => @this_page_uuid,
          :known_state => {},
          :subscription => nil,
          :last_accessed => Time.now
      }
      if @subscribed_pages.keys.count > MAX_SUBSCRIBED_PAGES
        sorted_sessions = @subscribed_pages.values.sort { |s1, s2| s2[:last_accessed].to_i <=> s1[:last_accessed].to_i }
        @subscribed_pages = sorted_sessions[0...MAX_SUBSCRIBED_PAGES].inject(Hash.new) { |h, s|
          h[s[:uuid]] = s
          h
        }
      end
    end
    @subscription = @subscribed_pages[@this_page_uuid]
    @subscription[:last_accessed] = Time.now if @subscription
  end
  def find_subscription
    ActiveRecord::SessionStore::Session.uncached do
      session = ActiveRecord::SessionStore::Session.find_by_session_id(request.session_options[:id])
    end
    @this_page_uuid = params[:uuid]
    @subscribed_pages = session[:subscribed_pages].is_a?(Hash) ? session[:subscribed_pages] : {}
    @subscription = @subscribed_pages[@this_page_uuid]
    @subscription[:last_accessed] = Time.now if @subscription
  end
  def write_back_session
    session[:subscribed_pages] = @subscribed_pages
  end
  def hashify_subscription_params(params)
    [ "device" ].inject(Hash.new) do |h, namespace|
      event_txt = params[namespace]
      if event_txt.blank?
        h[namespace] = {}
      else
        h[namespace] = event_txt.split(/;/).inject(Hash.new) { |h2, subscription_txt|
          event, filter = subscription_txt.split(/ /, 2)
          next if h2[event.to_sym] == :all
          h2[event.to_sym] ||= []
          if filter.blank?
            h2[event.to_sym] = :all
          else
            h2[event.to_sym].push filter
          end
          h2
        }
      end
      h
    end
  end
end
