#include "pch.h"

#include <windows.h>
#include <string>

#include "MBCS2UTF8.h"

int mbcs2utf8(char* inpath, char* outpath, int outpathsize ) {
    // MBCS ���� UTF-16�iwchar_t�j�ɕϊ�
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
    // MBCS ���� UTF-16�iwchar_t�j�ɕϊ�
    int wchars_count = MultiByteToWideChar(CP_ACP, 0, mbcsStr.c_str(), -1, NULL, 0);
    wchar_t* wchars = new wchar_t[wchars_count];
    MultiByteToWideChar(CP_ACP, 0, mbcsStr.c_str(), -1, wchars, wchars_count);

    // UTF-16 ���� UTF-8 �ɕϊ�
    int utf8_count = WideCharToMultiByte(CP_UTF8, 0, wchars, -1, NULL, 0, NULL, NULL);
    char* utf8_str = new char[utf8_count];
    WideCharToMultiByte(CP_UTF8, 0, wchars, -1, utf8_str, utf8_count, NULL, NULL);

    std::string utf8Result = utf8_str;

    delete[] wchars;
    delete[] utf8_str;

    return utf8Result;
}
