class DeviceController < ApplicationController
  before_filter :find_device, :except => [ :index, :new ]
  before_filter :assign_daemon, :only => [ :on, :off, :dim_to ]
  def show
    if request.xhr? || request.format == "json"
      return render :json => {
        :name => @device.name,
        :address => @device.address,
        :state => @device.state
      }
    end
  end

  def index
    @devices = Device.all
    @device_subset_name = "device"
    if request.xhr?
      return render :json => @devices.map { |d| d.id }
    end
  end

  def new
    render '_device_form', :locals => {
        :action => :new
    }
  end

  def on
    @device.on
    return render :json => true if request.xhr?
    redirect_to :controller => :device, :action => :index
  end
  def off
    @device.off
    return render :json => true if request.xhr?
    redirect_to :controller => :device, :action => :index
  end
  def all_on
    # TODO: all_on
  end
  def all_off
    # TODO: all_off
  end
  def create
    # TODO: create
    render :text => "TODO: create device"
  end
  def dim_to
    dim_level = params[:level].to_i
    @device.dim_to(dim_level)
    return render :json => true if request.xhr?
    redirect_to :controller => :device, :action => :index
  end

  private
  def assign_daemon
    daemon = Robotomate::Daemon.all_daemons[@device.daemon_name.to_sym]
    raise "Daemon not found" unless daemon # TODO: Real exception
    @device.set_daemon(daemon)
  end
  def find_device
    begin
      @device = Device.find(params[:id])
      return true
    rescue
      @device = nil
      redirect_to(:controller => :device, :action => :index)
      return false
    end
  end
end
