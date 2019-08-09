/**
 *  Tank Loop Reverb based on the Progenitor Reverberator
 *
 *  Copyright (C) 1977-1978 David Griesinger
 *  Copyright (C) 2006-2014 Teru Kamogashira
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#ifndef _FV3_PROGENITOR2_HPP
#define _FV3_PROGENITOR2_HPP

#include "freeverb/progenitor.hpp"
#include "freeverb/fv3_defs.h"

#define FV3_PROGENITOR2_NUM_IALLPASS 10
#define FV3_PROGENITOR2_NUM_CALLPASS 4
#define FV3_PROGENITOR2_OUT_INDEX 20

namespace fv3
{

#define _fv3_float_t float
#define _FV3_(name) name ## _f
#include "freeverb/progenitor2_t.hpp"
#undef _FV3_
#undef _fv3_float_t

#define _fv3_float_t double
#define _FV3_(name) name ## _
#include "freeverb/progenitor2_t.hpp"
#undef _FV3_
#undef _fv3_float_t

#define _fv3_float_t long double
#define _FV3_(name) name ## _l
#include "freeverb/progenitor2_t.hpp"
#undef _FV3_
#undef _fv3_float_t

};

#endif
