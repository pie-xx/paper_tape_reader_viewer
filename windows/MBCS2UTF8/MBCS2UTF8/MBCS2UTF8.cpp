#include "pch.h"

#include "pch.h"

#ifdef _DEBUG
#pragma comment(lib, "opencv_world460d.lib")
#else
#pragma comment(lib, "opencv_world460.lib")
#endif

#include <opencv2/opencv.hpp>
#include <opencv2/core/core.hpp>
using namespace cv;

#include <iostream>
#include <string>
#include <fstream>
#include <filesystem>
#include <io.h>
#include <stdio.h>

#include <codecvt>
#include <cstdlib>
#include <iomanip>
#include <iostream>
#include <locale>

#include <system_error>
#include <vector>
#include <Windows.h>

#include "MBCS2UTF8.h"

int wchar2utf8(char* inpath, char* outpath, int outpathsize) {

    int utf8_count = WideCharToMultiByte(CP_UTF8, 0, (wchar_t*)inpath, -1, NULL, 0, NULL, NULL);
    if (utf8_count < outpathsize) {
        WideCharToMultiByte(CP_UTF8, 0, (wchar_t*)inpath, -1, outpath, utf8_count, NULL, NULL);
        utf8_count = 0;
    }

    return utf8_count;
}


int mbcs2utf8(char* inpath, char* outpath, int outpathsize ) {
    // MBCS から UTF-16（wchar_t）に変換
    int wchars_count = MultiByteToWideChar(CP_ACP, 0, inpath, -1, NULL, 0);
    wchar_t* wchars = new wchar_t[wchars_count];
    MultiByteToWideChar(CP_ACP, 0, inpath, -1, wchars, wchars_count);

    int utf8_count = WideCharToMultiByte(CP_UTF8, 0, wchars, -1, NULL, 0, NULL, NULL);
    if (utf8_count < outpathsize) {
        WideCharToMultiByte(CP_UTF8, 0, wchars, -1, outpath, utf8_count, NULL, NULL);
        utf8_count = 0;
    }
    delete[] wchars;
    return utf8_count;
}

std::string ConvertMBCSToUTF8(const std::string& mbcsStr) {
    // MBCS から UTF-16（wchar_t）に変換
    int wchars_count = MultiByteToWideChar(CP_ACP, 0, mbcsStr.c_str(), -1, NULL, 0);
    wchar_t* wchars = new wchar_t[wchars_count];
    MultiByteToWideChar(CP_ACP, 0, mbcsStr.c_str(), -1, wchars, wchars_count);

    // UTF-16 から UTF-8 に変換
    int utf8_count = WideCharToMultiByte(CP_UTF8, 0, wchars, -1, NULL, 0, NULL, NULL);
    char* utf8_str = new char[utf8_count];
    WideCharToMultiByte(CP_UTF8, 0, wchars, -1, utf8_str, utf8_count, NULL, NULL);

    std::string utf8Result = utf8_str;

    delete[] wchars;
    delete[] utf8_str;

    return utf8Result;
}

/*
    UTF8文字列をwstringに変換する
*/
std::wstring Utf8ToWString
(
    std::string oUTF8Str
)
{
    // バッファサイズの取得
    int iBufferSize = ::MultiByteToWideChar(CP_UTF8, 0, oUTF8Str.c_str()
        , -1, (wchar_t*)NULL, 0);

    // バッファの取得
    wchar_t* wpBufWString = (wchar_t*)new wchar_t[iBufferSize];

    // UTF8 → wstring
    ::MultiByteToWideChar(CP_UTF8, 0, oUTF8Str.c_str(), -1, wpBufWString
        , iBufferSize);

    // wstringの生成
    std::wstring oRet(wpBufWString, wpBufWString + iBufferSize - 1);

    // バッファの破棄
    delete[] wpBufWString;

    // 変換結果を返す
    return(oRet);
}


void wimwrite(char* outpath, Mat img) {
    setlocale(LC_ALL, "japanese");

    std::vector<uchar> buff2; //buffer for coding
    std::vector<int> param = std::vector<int>(2);
    param[0] = 1;
    param[1] = 95; //default(95) 0-100

    imencode(".jpg", img, buff2, param);

    std::wstring  u16 = Utf8ToWString(outpath);
    FILE* fp2;
    _wfopen_s(&fp2, u16.data(), L"wb");

    if (fp2 == NULL) {
        std::cout << "BWoutput cant open" << std::endl;
        return;
    }
    fwrite(buff2.data(), buff2.size(), 1, fp2);
    fclose(fp2);
}


static Mat img;

int openImage(int width, int height) {
    img = Mat::zeros(height, width, CV_8UC3);
    cv::rectangle(img, cv::Point(0, 0), cv::Point(width, height),
        cv::Scalar(0, 0, 255), cv::FILLED, cv::LINE_4);
    return 1;
}

int putData(int x, int y, int dotlen, int dotwidth, int valsize, int* vals) {
    for (int n = 0; n < valsize; ++n) {
        cv::rectangle(img, cv::Point(x, y + dotlen * n), cv::Point(x+dotwidth, y + dotlen*(n+1)),
            cv::Scalar(vals[n], vals[n], vals[n]), cv::FILLED, cv::LINE_4);
    }
    return 1;
}

int getImage(char* filename) {
    wimwrite(filename, img);
    return 1;
}
