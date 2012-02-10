class Device < ActiveRecord::Base
  class NoDaemonException < ::Exception; end
end
