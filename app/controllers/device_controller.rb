class DeviceController < ApplicationController
  before_filter :find_device, :except => [ :index, :new, :create ]
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
    if request.xhr?
      return render :json => @devices.map { |d| d.id }
    end
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
    @device_types = DEVICE_TYPES.map { |klass| [ klass.friendly_type, klass.name ] }.sort
    @daemon_names = Robotomate::Daemon.all_daemons.keys.sort
    @device_groups = DeviceGroup.all.map { |dg| [ dg.name, dg.id ] }.sort
    render :_device_form
  end
  def update
    # Requires @device, but then we just call:
    create
  end

  def create_or_update

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
      Rails.logger.debug("find_device: Device not found for '#{params[:id]}', redirecting")
      redirect_to(:controller => :device, :action => :index)
      return false
    end
  end
end
