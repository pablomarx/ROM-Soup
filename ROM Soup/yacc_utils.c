//
//  yacc_utils.c
//  ROM Soup
//
//  Created by Steve White on 12/24/13.
//  Copyright (c) 2013 Steve White. All rights reserved.
//

#include <stdio.h>
#include "NewtParser.h"

/*------------------------------------------------------------------------*/
/** パーサエラー
 *
 * @param s			[in] エラーメッセージ文字列
 *
 * @return			なし
 */

void yyerror(char * s)
{
	if (s[0] && s[1] == ':')
		NPSErrorStr(*s, s + 2);
	else
		NPSErrorStr('E', s);
}