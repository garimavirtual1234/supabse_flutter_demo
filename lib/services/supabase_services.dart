import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_demo/modules/documents/controller/document_controller.dart';
import 'package:supabase_demo/modules/home/controller/home_page_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../modules/home/model/student_model.dart';
import '../route/route_class.dart';


class SupabaseServices {
  final supabase = Supabase.instance.client;
  final User? currentUser = Supabase.instance.client.auth.currentUser;

  createUser(email, password) async {
    final AuthResponse res = await supabase.auth.signUp(
        email: email,
        password: password
    );
    return res;
  }

  signInUser(email, password) async {
    final AuthResponse res = await supabase.auth.signInWithPassword(
        email: email,
        password: password
    );
    return res;
  }

  //insert data into database
  insertData(id, name, phnNo, fName, add) async {
    final User? user = supabase.auth.currentUser;
    await supabase.from("students").insert(
        {
          'id': id,
          'name': name,
          'Phone_number': phnNo,
          "Father's_Name": fName,
          'Address': add,
          'teacherUid': user?.id,
        }
    );
  }


  fetchStudentList() async {
    final User? user = supabase.auth.currentUser;
    final data = await supabase.from('students').select('*').eq(
        'teacherUid', user?.id).order('id',ascending: true);
    print("$data----");
    final list = json.decode(json.encode(data));
    print("$list lll");

    var response = list.map((e) => Student.fromJson(e)).toList();
    print("{$response rrrr}");
    return response;
  }

   searchQuery(query) async{
    final User? user = supabase.auth.currentUser;
    final data = await supabase.from('students').select('*').eq(
        'teacherUid', user?.id).eq('name',query);
    final list = json.decode(json.encode(data));
    var response = list.map((e) => Student.fromJson(e)).toList();
    return response;
    print("${data}-searchdata");
  }
  createStorageForDoc() async {
    final User? user = supabase.auth.currentUser;
    print("${user?.id}--");
    final String result = await supabase.storage.createBucket("${user?.id}");
  }

  uploadFile(file, fileName, filePath) async {
    final User? user = supabase.auth.currentUser;
    try {
      //   final String result = await supabase.storage.emptyBucket("public-documents");
      print("${user?.id} - iddddd");
      final String path = await supabase.storage.from('${user?.id}').upload(
          fileName,
          file,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false)
      ).then((value) async {
        Get.back();
        Get.snackbar("Congrats!", "Upload Successfully");
        return await Get.find<DocumentController>().fetchDocumentsList();

      });
      print(path);
    } on StorageException catch (e)  {
      Get.back();
        Get.snackbar("Fail!", e.message);
      print(e.message);
    }
  }



  fetchListOfFiles() async{

      final User? user = supabase.auth.currentUser;
    List list=[];
      final List<FileObject> objects = await supabase.storage.from("${user?.id}").list();


        objects.forEach((element) async {
          print(element.name);
          if(element.name!=".emptyFolderPlaceholder"){
            list.add(element.name);
          }

        });


      return list;
  }


  openFile(fileName) async {
    final User? user = supabase.auth.currentUser;
     final Uint8List result = await supabase.storage.from("${user?.id}").download(fileName);
     return result;
  }

  deleteFile(fileName) async{
   try{
     final User? user = supabase.auth.currentUser;
     final List<FileObject> objects = await supabase.storage.from("${user?.id}").remove([
       fileName
     ]);
     print(objects);
   }catch(e){
     throw Exception(e);
   }

  }

  logout() async{
    await supabase.auth.signOut();
  }


  signInUsingAppleId() async {
    final authResponse = await supabase.auth.signInWithApple();
    return authResponse;
  }

  signInUsingGoogle()async{
   final auth = await supabase.auth.signInWithOAuth(Provider.google,
   redirectTo: kIsWeb ? null : 'io.supabase.flutterquickstart://login-callback/',
     authScreenLaunchMode: LaunchMode.inAppWebView,
       scopes: 'repo gist notifications'
   ).then((value){
     final Session? session = supabase.auth.currentSession;
     final String? oAuthToken = session?.providerToken;
   });
   ;print("${auth}---google");
   return auth;
  }

}




