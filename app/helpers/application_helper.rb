module ApplicationHelper
  def start_remote_event_proxy
    "RemoteEventProxy.start('" +
        escape_javascript(url_for(:controller => :event, :action => :poll, :uuid => @this_page_uuid)) +
        "', '" +
        escape_javascript(url_for(:controller => :event, :action => :subscribe, :uuid => @this_page_uuid)) +
      "');"
  end
end
