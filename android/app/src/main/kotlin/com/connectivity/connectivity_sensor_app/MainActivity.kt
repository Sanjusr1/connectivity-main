package com.connectivity.connectivity_sensor_app

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.hardware.usb.UsbConstants
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbDeviceConnection
import android.hardware.usb.UsbEndpoint
import android.hardware.usb.UsbInterface
import android.hardware.usb.UsbManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity(), MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    private val usbControlChannelName = "connectivity_sensor_app/usb_control"
    private val usbStreamChannelName = "connectivity_sensor_app/usb_stream"
    private val usbPermissionAction = "com.connectivity.connectivity_sensor_app.USB_PERMISSION"

    private var eventSink: EventChannel.EventSink? = null
    private var readThread: Thread? = null
    private var usbConnection: UsbDeviceConnection? = null
    private var usbInterface: UsbInterface? = null
    private var usbEndpoint: UsbEndpoint? = null
    private var requestedDevice: UsbDevice? = null
    private var pendingStartAfterPermission = false
    private val mainHandler = Handler(Looper.getMainLooper())

    private val permissionReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action != usbPermissionAction) {
                return
            }

            val granted = intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false)
            val device = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                intent.getParcelableExtra(UsbManager.EXTRA_DEVICE, UsbDevice::class.java)
            } else {
                @Suppress("DEPRECATION")
                intent.getParcelableExtra(UsbManager.EXTRA_DEVICE)
            }

            if (granted && device != null && pendingStartAfterPermission) {
                try {
                    openUsbStream(device)
                } catch (error: Exception) {
                    emitError("USB_STREAM_ERROR", error.message ?: "Unable to open USB device after permission.")
                }
            } else if (!granted && pendingStartAfterPermission) {
                emitError("USB_PERMISSION_DENIED", "USB permission was denied.")
            }

            pendingStartAfterPermission = false
            requestedDevice = null
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val filter = IntentFilter(usbPermissionAction)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(permissionReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            @Suppress("DEPRECATION")
            registerReceiver(permissionReceiver, filter)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, usbControlChannelName)
            .setMethodCallHandler(this)
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, usbStreamChannelName)
            .setStreamHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startUsbStream" -> startUsbStream(result)
            "stopUsbStream" -> {
                stopUsbStream()
                result.success("stopped")
            }
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
        stopUsbStream()
    }

    private fun startUsbStream(result: MethodChannel.Result) {
        val usbManager = getSystemService(Context.USB_SERVICE) as UsbManager
        val device = findReadableDevice(usbManager)

        if (device == null) {
            result.error("USB_NOT_FOUND", "No readable USB sensor device was found.", null)
            return
        }

        if (!usbManager.hasPermission(device)) {
            requestedDevice = device
            pendingStartAfterPermission = true
            usbManager.requestPermission(device, createUsbPermissionIntent())
            result.success("permission_requested")
            return
        }

        try {
            openUsbStream(device)
            result.success("streaming")
        } catch (error: Exception) {
            result.error("USB_STREAM_ERROR", error.message, null)
        }
    }

    private fun openUsbStream(device: UsbDevice) {
        stopUsbStream()

        val usbManager = getSystemService(Context.USB_SERVICE) as UsbManager
        val match = findInputInterface(device)
            ?: throw IllegalStateException("No readable USB endpoint was found on the device.")
        val connection = usbManager.openDevice(device)
            ?: throw IllegalStateException("Unable to open the USB device.")

        if (!connection.claimInterface(match.first, true)) {
            connection.close()
            throw IllegalStateException("Unable to claim the USB interface.")
        }

        usbConnection = connection
        usbInterface = match.first
        usbEndpoint = match.second
        startReadLoop(connection, match.second)
    }

    private fun startReadLoop(connection: UsbDeviceConnection, endpoint: UsbEndpoint) {
        readThread = Thread {
            val buffer = ByteArray(4096)
            val packetBuffer = ByteArrayOutputStream()

            try {
                while (!Thread.currentThread().isInterrupted) {
                    val byteCount = connection.bulkTransfer(endpoint, buffer, buffer.size, 250)
                    if (byteCount <= 0) {
                        continue
                    }

                    packetBuffer.write(buffer, 0, byteCount)
                    emitCompletedPackets(packetBuffer)
                }
            } catch (error: Exception) {
                emitError("USB_READ_ERROR", error.message ?: "USB read failed.")
            }
        }.apply {
            name = "usb-sensor-read-loop"
            start()
        }
    }

    private fun emitCompletedPackets(packetBuffer: ByteArrayOutputStream) {
        val bytes = packetBuffer.toByteArray()
        var packetStart = 0

        for (index in bytes.indices) {
            if (bytes[index].toInt() == 10) {
                val packet = bytes.copyOfRange(packetStart, index)
                if (packet.isNotEmpty()) {
                    mainHandler.post { eventSink?.success(packet) }
                }
                packetStart = index + 1
            }
        }

        if (packetStart > 0) {
            packetBuffer.reset()
            if (packetStart < bytes.size) {
                packetBuffer.write(bytes, packetStart, bytes.size - packetStart)
            }
        }
    }

    private fun findReadableDevice(usbManager: UsbManager): UsbDevice? {
        return usbManager.deviceList.values.firstOrNull { device ->
            findInputInterface(device) != null
        }
    }

    private fun findInputInterface(device: UsbDevice): Pair<UsbInterface, UsbEndpoint>? {
        for (interfaceIndex in 0 until device.interfaceCount) {
            val usbInterface = device.getInterface(interfaceIndex)
            for (endpointIndex in 0 until usbInterface.endpointCount) {
                val endpoint = usbInterface.getEndpoint(endpointIndex)
                if (endpoint.direction == UsbConstants.USB_DIR_IN &&
                    (endpoint.type == UsbConstants.USB_ENDPOINT_XFER_BULK ||
                        endpoint.type == UsbConstants.USB_ENDPOINT_XFER_INT)
                ) {
                    return usbInterface to endpoint
                }
            }
        }
        return null
    }

    private fun createUsbPermissionIntent(): PendingIntent {
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        return PendingIntent.getBroadcast(this, 0, Intent(usbPermissionAction), flags)
    }

    private fun emitError(code: String, message: String) {
        mainHandler.post { eventSink?.error(code, message, null) }
    }

    private fun stopUsbStream() {
        readThread?.interrupt()
        readThread = null

        usbConnection?.let { connection ->
            usbInterface?.let { usbInterface ->
                connection.releaseInterface(usbInterface)
            }
            connection.close()
        }

        usbConnection = null
        usbInterface = null
        usbEndpoint = null
    }

    override fun onDestroy() {
        stopUsbStream()
        unregisterReceiver(permissionReceiver)
        super.onDestroy()
    }
}
