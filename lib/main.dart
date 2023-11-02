import 'package:flutter/material.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:charset_converter/charset_converter.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:typed_data';

import 'com_action.dart';

void main() {
  runApp(const MaterialApp( home: MyHomePage(), ));
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  @override
  State<MyHomePage> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<MyHomePage> {
  var availablePorts = [];

  late Pointer<Utf8> outpath;
  late DynamicLibrary  dylib ;
  late Function mbcs2utf8;

  late Map<String,String> portdesc;

  @override
  void initState() {
    super.initState();

    dylib = DynamicLibrary.open("MBCS2UTF8.dll");

    mbcs2utf8 = dylib.lookupFunction<
        Void Function(Pointer<Utf8>, Pointer<Utf8>, Int32),
        void Function(Pointer<Utf8>, Pointer<Utf8>, int)
        >("mbcs2utf8");
    outpath = malloc.allocate<Utf8>(1024);
    initPorts();
  }

  void initPorts() async {
    availablePorts = SerialPort.availablePorts;
    portdesc = {};
    for( var address in availablePorts ){
      final port = SerialPort(address);
      String decoded = await CharsetConverter.decode("Shift_JIS", Uint8List.fromList(port.description?.codeUnits ?? []) );
      print(decoded);
      portdesc[ address ] = decoded;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Serial Port example'),   
        ),
        body: Scrollbar(
          child: ListView(
            children: [
              for (final address in availablePorts)
                Builder(builder: (context) {
                  final port = SerialPort(address);
                  
                  //print(port.description);
                  //mbcs2utf8(port.description?.toNativeUtf8(), outpath, 1024);
                  return ExpansionTile(
                    title: Text("$address - ${portdesc[address]}"),
                    onExpansionChanged: (t){
                      print(address);
                      Navigator.push(
                        this.context, 
                        MaterialPageRoute(
                          builder: (context) => ComActionPage( address: address )
                        )
                      );
                    },
                    /*
                    children: [
                      CardListTile('Description', portdesc[address]),
                      CardListTile('Transport', port.transport.toTransport()),
                      CardListTile('USB Bus', port.busNumber?.toPadded()),
                      CardListTile('USB Device', port.deviceNumber?.toPadded()),
                      CardListTile('Vendor ID', port.vendorId?.toHex()),
                      CardListTile('Product ID', port.productId?.toHex()),
                      CardListTile('Manufacturer', port.manufacturer),
                      CardListTile('Product Name', port.productName),
                      CardListTile('Serial Number', port.serialNumber),
                      CardListTile('MAC Address', port.macAddress),
                    ],
                    */
                  );
                }),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.refresh),
          onPressed: initPorts,
        ),
      ),
    );
  }
}

/*
class CardListTile extends StatelessWidget {
  final String name;
  final String? value;

  CardListTile(this.name, this.value);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(value ?? 'N/A'),
        subtitle: Text(name),
      ),
    );
  }
}

extension IntToString on int {
  String toHex() => '0x${toRadixString(16)}';
  String toPadded([int width = 3]) => toString().padLeft(width, '0');
  String toTransport() {
    switch (this) {
      case SerialPortTransport.usb:
        return 'USB';
      case SerialPortTransport.bluetooth:
        return 'Bluetooth';
      case SerialPortTransport.native:
        return 'Native';
      default:
        return 'Unknown';
    }
  }
}
*/