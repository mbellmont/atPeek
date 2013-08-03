/*
 
 atPeek - iPhone app browsing tool
 Copyright (C) 2008  atPurpose
 
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>
 
 */

#if !defined(_UTILITIES_H_)
#define _UTILITIES_H_
 
#define BASE_10_KB  1000.0
#define BASE_2_KB   1024.0

#define ZERO_DIGIT  0
#define ONE_DIGIT   1
#define TWO_DIGIT   2

char *utf8StringFor(double number, double base, int precision);

NSString *runCommandUsingNSTask(NSString *arguments);
NSString *runCommandUsingPopen(NSString *arguments);

#endif
