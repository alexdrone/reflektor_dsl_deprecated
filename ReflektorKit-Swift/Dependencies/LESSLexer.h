//
// LESSParser.h
// Tests
// Forked from https://github.com/tracy-e/ESCssParser
//
//

@import UIKit;

#include <stdio.h>

typedef enum {
    CHARSET_SYM,          //@charset
    IMPORT_SYM,           //@import
    PAGE_SYM,             //@page
    MEDIA_SYM,            //@media
    FONT_FACE_SYM,        //@font-face
    NAMESPACE_SYM,        //@namespace
    IMPORTANT_SYM,        //!{w}important
    
    S,                    //{space}
    STRING,               //{string}
    IDENT,                //{ident}
    HASH,                 //#{name}
    CDO,                  //<!--
    CDC,                  //-->
    INCLUDES,             //~=
    DASHMATCH,            //!=
    
    EMS,                  //{num}em
    EXS,                  //{num}ex
    LENGTH,               //{num}px | cm | mm | in | pt | pc
    ANGLE,                //{num}deg | rad | grad
    TIME,                 //{num}ms | s
    FREQ,                 //{num}Hz | kHz
    DIMEN,                //{num}{ident}
    PERCENTAGE,           //{num}%
    NUMBER,               //{num}
    
    URI,                  //url()
    FUNCTION,             //{ident}(
    
    UNICODERANGE,         //U\+{range} | U\+{h}{1,6}-{h}{1,6}
    UNKNOWN               //.
} LESSToken;

extern __nullable const char* LESSTokenName[];

#ifndef YY_TYPEDEF_YY_SCANNER_T
#define YY_TYPEDEF_YY_SCANNER_T
typedef void* yyscan_t;
#endif

//utilities
__nonnull NSString *LESS_uuid(void);
__nonnull NSString *LESS_stripQuotesFromString(__nonnull NSString *string);
BOOL LESS_stringHasPrefix(__nonnull NSString *string, __nonnull NSArray *prefixes);
__nonnull NSArray *LESS_prefixedOrderedKeys(__nonnull NSArray *keys);
__nonnull NSString *LESS_stringToCamelCase(__nonnull NSString *string);
__nullable NSArray *LESS_getArgumentForValue(__nonnull NSString* stringValue);
__nullable id LESS_parseKeyword(__nonnull NSString *cssValue);

//lexer
int LESSlex(void);
void LESS_parse(__nonnull const char *buffer);
void LESS_scan(__nullable const char *text, int token);

@interface LESSParser : NSObject

- (__nullable NSDictionary*)parseText:(__nonnull NSString*)LESSText;

@end