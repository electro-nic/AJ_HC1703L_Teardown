# Augentix-HC1703L-PTZ-IPCam-Teardown
PTZ IPCam based on SOC Augentix HC1703L teardown

This is a cheap Pan Tilt IP Camera (supposedly 1080p) available on Aliexpress, Gearbest and Temu for €5~15. I bought 5 of them for less than €20 in an attempt to hack them as the reason they are so cheap is due to them being locked to paid cloud services.
As no documentation was eaesily available on the Augentix SOC, a good start to me was to attach a 3.3V UART on the [two + one pads](https://github.com/Jalecom/Augentix-HC1703L-PTZ-IPCam-Teardown/blob/main/Pictures/IMG_8248.jpeg) close to the HC1703 where 57'600bps signal are present.
The camera behaviour appear very similar to the Goke GK7102 Cloud IP Cameras and many of the hack are working on the HC1703 too. See [ant-thomas zsgx1hacks](https://github.com/ant-thomas/zsgx1hacks)

## Debug Scripts and Files

By default, the startup script ```/tmp/start.sh``` will try to load and run some [commands](https://github.com/Jalecom/Augentix-HC1703L-PTZ-IPCam-Teardown/blob/main/tmp/start.sh)

## Files running from SD Card

To run debug scripts create a file ```debug_cmd.sh``` on an SD card and you will be able to execute bash commands from it.
Note the SD card is mounted in /mnt and the camera looks for /mnt/debug_cmd.sh

## Security

The security of these devices is terrible.
* DO NOT expose these cameras to the internet.

