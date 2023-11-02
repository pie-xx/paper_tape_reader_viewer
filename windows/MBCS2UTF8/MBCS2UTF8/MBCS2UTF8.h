#pragma once

extern "C" __declspec(dllexport)
int mbcs2utf8(char* inpath, char* outpath, int outpathsize);
extern "C" __declspec(dllexport)
int wchar2utf8(char* inpath, char* outpath, int outpathsize);

extern "C" __declspec(dllexport)
int openImage(int width, int height);
extern "C" __declspec(dllexport)
int putData(int x, int y, int dotlen, int dotwidth, int valsize, int* vals);
extern "C" __declspec(dllexport)
int getImage(char* filename);
