module DeviceHelper
  def form_for_device(url, html_options, &wrapper)
    res = form_tag(url, html_options) do
      if wrapper
        wrapper.call(render :partial => "device/device_form")
      else
        render :partial => "device/device_form"
      end
    end
  end
end
