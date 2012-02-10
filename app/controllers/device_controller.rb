class DeviceController < ApplicationController
  def show
  end

  def list
    @devices = Device.all
    @device_subset_name = "device"
  end

  def create
  end

  def edit
  end

end
