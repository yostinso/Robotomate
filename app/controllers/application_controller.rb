require 'resque'
class ApplicationController < ActionController::Base
  protect_from_forgery
  prepend_before_filter :set_page_uuid

  private
  def set_page_uuid
    @this_page_uuid ||= UUID.new.generate
  end
end
