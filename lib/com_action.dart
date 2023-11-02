import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:sprintf/sprintf.dart';

import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:path_provider/path_provider.dart';


class ComActionPage extends StatelessWidget {
  const ComActionPage({Key? key, required this.address}) : super(key: key);
  final String address;
  @override
  Widget build(BuildContext context){
    return Scaffold(
      body: ComActionView( address: address ),
    );
  }
}


class ComActionView extends StatefulWidget {
  const ComActionView({Key? key, required this.address}) : super(key: key);

  final String address;

  @override
  State<ComActionView> createState() => ComActionPageState();
}

class TransCmd {
  SendPort? sendport;
  String? comaddress;
  
  TransCmd(this.sendport, this.comaddress);
}

enum CBCmdType {
  Port, Data, Error
}
class CallbackCmd {
  SendPort? sendport;
  String? data;
  CBCmdType cmdtype;
  
  CallbackCmd(this.sendport, this.data, this.cmdtype);
}

const int DotLen = 8;
const int DotWidth = 1;
const int ImgWidth = 400;
const int ImgHeight = DotLen * 9 * 2;

class ComActionPageState extends State<ComActionView> {

  String transmsg="";
  static late SendPort callbackSendPort; 
  String disppage = "";
  int vcnt = 0;
  int linecnt = 0;
  String valstr = "";
  String linestr = "";

  List<int> comvals = [0,0,0,0,0,0,0,0,0];
  late Pointer<Int32> sencervals;
  late DynamicLibrary  dylib ;

  late String outputpath;
  late Pointer<Utf8> outpathbuff;

  late Function openImage;
  late Function putData;
  late Function getImage;

  Image? dispimg;

  int draw_x = 0;
  int draw_y = 0;

  @override
  void initState(){
    super.initState();

    dylib = DynamicLibrary.open("MBCS2UTF8.dll");

    openImage = dylib.lookupFunction<
        Void Function(Int32, Int32),
        void Function(int, int)
        >("openImage");
    putData = dylib.lookupFunction<
        Void Function(Int32, Int32, Int32, Int32, Int32, Pointer<Int32>),
        void Function(int, int, int, int, int, Pointer<Int32>)
        >("putData");
    getImage = dylib.lookupFunction<
        Void Function(Pointer<Utf8>),
        void Function(Pointer<Utf8>)
        >("getImage");

    sencervals = malloc.allocate<Int32>(9);

    trans();
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    final directory = await getApplicationDocumentsDirectory();
    outputpath =  "${directory.path}/output.jpg";
    outpathbuff = outputpath.toNativeUtf8();

    openImage( ImgWidth, ImgHeight );
    //getImage(outpathbuff);
    //dispimg = Image.file(File( outputpath));
  }


  static void isoTrans( TransCmd cmd ){
    bool stat_go = true;

    var callBackReceivePort = new ReceivePort();
    print("isoTrans: callBackReceivePort = ${callBackReceivePort.sendPort}");
    cmd.sendport?.send(callBackReceivePort.sendPort);

    var serialPort;
    bool retry = true;
    while( retry ){
      try{
        serialPort = SerialPort(cmd.comaddress ?? "");
        retry = false;
      }catch(e){
        print(e.toString());
        retry = true;
      }
    }
    print("isotrans opened ${cmd.comaddress}");

    // 通信側からのコールバック
    callBackReceivePort.listen(( message ) {
      print("callbackPort.listen $message");
      //callbackPort.close();
      stat_go = false;
      serialPort.close();
      Isolate.current.kill(priority: Isolate.immediate);
    });

    //CallbackCmd answer_port = CallbackCmd(callbackPort.sendPort, null, CBCmdType.Port);
    //cmd.sendport?.send( answer_port );

    print("isotrans start loop");
    try {
      int readcnt = 0;
      if(serialPort.openRead()){
        while( stat_go ){
          if( readcnt > ImgWidth ){
            break;
          }
          List<int> bytes = serialPort.read(1);  // Read up to 100 bytes
          if (bytes.isEmpty) {
            //cmd.sendport?.send("-");
          } else {
            String c =  String.fromCharCodes(bytes) ;
            cmd.sendport?.send(c);
            if( c=="\n"){
              readcnt++;
            }
          }        
        }
      }
    }catch(e){
      cmd.sendport?.send( e.toString() );
      print("isotrans error ${e.toString()}");
    }

    print("isotrans loop break");
    serialPort.close();
    cmd.sendport?.send("answer_end");
    Isolate.current.kill(priority: Isolate.immediate);
  }

/*
isoTrans関数を新しいIsolateで実行し、画像変換処理を実行します。
ReceivePortを使って、メインIsolateと新しいIsolate間の通信を行います。
*/
  void trans() async {

    final ReceivePort receivePort = ReceivePort();
    var multiChannel = receivePort.asBroadcastStream();

    await Isolate.spawn( isoTrans, TransCmd(receivePort.sendPort, widget.address) );



    callbackSendPort = await multiChannel.first;
    print("trans: callbackSendPort = $callbackSendPort");

    // 通信側からのコールバック
    multiChannel.listen(( message )  {

        if( message=="0" ||  message=="1" || message=="2" || message=="3" || message=="4"
         || message=="5" || message=="6" || message=="7" || message=="8" || message=="9" ){
          valstr = valstr + message;
          linestr = linestr + message;
        }
        if( message=="\t"){
          if( vcnt < 9 ) {
            linestr = linestr + message;
            try{
              comvals[vcnt] = int.parse(valstr);
            }catch(e){
              print(valstr);
              print(e.toString());
            }
            vcnt = vcnt + 1;
          }
          valstr = "";
        }
        if( message=="\n" ){
          if( linecnt > 30 ){
            disppage = disppage.substring( disppage.indexOf("\n") + 1 );
          }
          vcnt = 0;

          for( int n=0; n<3; ++n){
            sencervals[n] = comvals[n];
          }
          sencervals[3] = (255 * (comvals[8]/100.0)).toInt();
          for( int n=4; n<9; ++n){
            sencervals[n] = comvals[n-1];
          }

          //disppage = disppage + sprintf(" %03d,%03d,%03d,%03d,%03d,%03d,%03d,%03d,%03d,\n", sencervals );
          linecnt = linecnt + 1;
          linestr = "";

          putData(draw_x, draw_y, DotLen, DotWidth, 9, sencervals);

          draw_x = draw_x + 1;
          if( draw_x == ImgWidth ){
            /*
            draw_x = 0;
            draw_y = draw_y + DotLen * 9;
            if( draw_y >= ImgHeight ){
              draw_x = 0;
              draw_y = 0;
            }
            */
            getImage(outpathbuff);
            Uint8List  imageData = File(outputpath).readAsBytesSync();
            dispimg = Image.memory( imageData ); 
            setState(() {
              
            });
          }

        }
    });

  }

  @override
  Widget build(BuildContext context) {

    var dirsetting = InteractiveViewer(
              maxScale: 64,
              child: Container( child: Center( child: 
                  dispimg ?? Text("No Image $draw_x, $draw_y")
              ),
            ));


    return PopScope(
      onPopInvoked: (bool t) async {
        callbackSendPort.send("message");
        await Future.delayed(Duration(seconds: 2));
        print("onPopInvoked $t $callbackSendPort");
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text(widget.address),
      ),
      body: dirsetting,
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.refresh),
          onPressed: () async{ 
            getImage(outpathbuff);
            Uint8List  imageData = File(outputpath).readAsBytesSync();
            dispimg = Image.memory( imageData ); 
            await precacheImage(dispimg!.image, context);

            setState(() {      

            });
          },
        ),
      ),
    );
  
  }
}
