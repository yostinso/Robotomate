require 'lib/robotomate'
require 'lib/robotomate/daemon/definition'

require 'config/daemons.rb'

DEVICE_TYPES = [
    Device::X10,
    Device::X10::Lamp,
    Device::Insteon,
    Device::Insteon::Lamp,
    Device::Infrared,
    Device::Infrared::Receiver
]

