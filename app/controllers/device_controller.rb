class DeviceController < ApplicationController
  before_filter :find_device, :except => [ :index, :new ]
  before_filter :assign_daemon, :only => [ :on, :off ]
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
  end

  def edit
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


  def dim_select
    if request.xhr?
      render :partial => :dim_select, :layout => false
    else
      redirect_to :controller => :device, :action => :index
    end
  end

  private
  def assign_daemon
    daemon = Robotomate::Daemon.all_daemons[:Ez_Srve_121]
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
