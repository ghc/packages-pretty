{-# OPTIONS -fno-implicit-prelude #-}
-----------------------------------------------------------------------------
-- |
-- Module      :  Data.Bits
-- Copyright   :  (c) The University of Glasgow 2001
-- License     :  BSD-style (see the file libraries/base/LICENSE)
-- 
-- Maintainer  :  libraries@haskell.org
-- Stability   :  experimental
-- Portability :  portable
--
--  This module defines bitwise operations for signed and unsigned
--  integers.  Instances of the class 'Bits' for the 'Int' and
--  'Integer' types are available from this module, and instances for
--  explicitly sized integral types are available from the
--  "Int" and "Word" modules.
--
-----------------------------------------------------------------------------

module Data.Bits ( 
  -- * The 'Bits' class
  Bits(
    (.&.), (.|.), xor, -- :: a -> a -> a
    complement,        -- :: a -> a
    shift,             -- :: a -> Int -> a
    rotate,            -- :: a -> Int -> a
    bit,               -- :: Int -> a
    setBit,            -- :: a -> Int -> a
    clearBit,          -- :: a -> Int -> a
    complementBit,     -- :: a -> Int -> a
    testBit,           -- :: a -> Int -> Bool
    bitSize,           -- :: a -> Int
    isSigned,          -- :: a -> Bool

    -- * Shifts and rotates
    -- $shifts
    shiftL, shiftR,    -- :: Bits a => a -> Int -> a
    rotateL, rotateR   -- :: Bits a => a -> Int -> a
  )

  -- instance Bits Int
  -- instance Bits Integer
 ) where

-- Defines the @Bits@ class containing bit-based operations.
-- See library document for details on the semantics of the
-- individual operations.

#ifdef __GLASGOW_HASKELL__
#include "MachDeps.h"
import GHC.Num
import GHC.Real
import GHC.Base
#endif

infixl 8 `shift`, `rotate`, `shiftL`, `shiftR`, `rotateL`, `rotateR`
infixl 7 .&.
infixl 6 `xor`
infixl 5 .|.

{-| 
The 'Bits' class defines bitwise operations over integral types.

* Bits are numbered from 0 with bit 0 being the least
  significant bit.
-}
class Num a => Bits a where
    -- | Bitwise \"and\"
    (.&.) :: a -> a -> a

    -- | Bitwise \"or\"
    (.|.) :: a -> a -> a

    -- | Bitwise \"xor\"
    xor :: a -> a -> a

    {-| Reverse all the bits in the argument -}
    complement        :: a -> a

    {-| Signed shift the argument left by the specified number of bits.
	Right shifts are specified by giving a negative value. -}
    shift             :: a -> Int -> a

    -- An instance can define either this unified shift or shiftL+shiftR,
    -- depending on which is more convenient for the type in question.
    x `shift`   i | i<0  = x `shiftR` (-i)
                  | i==0 = x
                  | i>0  = x `shiftL` i

    {-| Signed rotate the argument left by the specified number of bits.
	Right rotates are specified by giving a negative value.

        'rotate' is well defined only if 'bitSize' is also well defined
        ('bitSize' is undefined for 'Integer', for example).
    -}
    rotate            :: a -> Int -> a

    {-
    -- Rotation can be implemented in terms of two shifts, but care is
    -- needed for negative values.  This suggested implementation assumes
    -- 2's-complement arithmetic.  It is commented out because it would
    -- require an extra context (Ord a) on the signature of 'rotate'.
    x `rotate`  i | i<0 && isSigned x && x<0
                         = let left = i+bitSize x in
                           ((x `shift` i) .&. complement ((-1) `shift` left))
                           .|. (x `shift` left)
                  | i<0  = (x `shift` i) .|. (x `shift` (i+bitSize x))
                  | i==0 = x
                  | i>0  = (x `shift` i) .|. (x `shift` (i-bitSize x))
    -}

    -- | @bit i@ is a value with the @i@th bit set
    bit               :: Int -> a

    -- | @x \`setBit\` i@ is the same as @x .|. bit i@
    setBit            :: a -> Int -> a

    -- | @x \`clearBit\` i@ is the same as @x .&. complement (bit i)@
    clearBit          :: a -> Int -> a

    -- | @x \`complementBit\` i@ is the same as @x \`xor\` bit i@
    complementBit     :: a -> Int -> a

    -- | Return 'True' if the @n@th bit of the argument is 1
    testBit           :: a -> Int -> Bool

    {-| Return the number of bits in the type of the argument.  The actual
        value of the argument is ignored -}
    bitSize           :: a -> Int

    {-| Return 'True' if the argument is a signed type.  The actual
        value of the argument is ignored -}
    isSigned          :: a -> Bool

    bit i               = 1 `shiftL` i
    x `setBit` i        = x .|. bit i
    x `clearBit` i      = x .&. complement (bit i)
    x `complementBit` i = x `xor` bit i
    x `testBit` i       = (x .&. bit i) /= 0

    -- $shifts
    -- These functions might sometimes be more convenient than the unified
    -- versions 'shift' and 'rotate'.
    
    shiftL, shiftR   :: a -> Int -> a
    rotateL, rotateR :: a -> Int -> a
    x `shiftL`  i = x `shift`  i
    x `shiftR`  i = x `shift`  (-i)
    x `rotateL` i = x `rotate` i
    x `rotateR` i = x `rotate` (-i)

#ifdef __GLASGOW_HASKELL__
instance Bits Int where
    (I# x#) .&.   (I# y#)  = I# (word2Int# (int2Word# x# `and#` int2Word# y#))
    (I# x#) .|.   (I# y#)  = I# (word2Int# (int2Word# x# `or#`  int2Word# y#))
    (I# x#) `xor` (I# y#)  = I# (word2Int# (int2Word# x# `xor#` int2Word# y#))
    complement (I# x#)     = I# (word2Int# (int2Word# x# `xor#` int2Word# (-1#)))
    (I# x#) `shift` (I# i#)
        | i# >=# 0#            = I# (x# `iShiftL#` i#)
        | otherwise            = I# (x# `iShiftRA#` negateInt# i#)
    (I# x#) `rotate` (I# i#) =
        I# (word2Int# ((x'# `shiftL#` i'#) `or#`
                       (x'# `shiftRL#` (wsib -# i'#))))
        where
        x'# = int2Word# x#
        i'# = word2Int# (int2Word# i# `and#` int2Word# (wsib -# 1#))
	wsib = WORD_SIZE_IN_BITS#   {- work around preprocessor problem (??) -}
    bitSize  _                 = WORD_SIZE_IN_BITS
    isSigned _                 = True

instance Bits Integer where
   (S# x) .&. (S# y) = S# (word2Int# (int2Word# x `and#` int2Word# y))
   x@(S# _) .&. y = toBig x .&. y
   x .&. y@(S# _) = x .&. toBig y
   (J# s1 d1) .&. (J# s2 d2) = 
	case andInteger# s1 d1 s2 d2 of
	  (# s, d #) -> J# s d
   
   (S# x) .|. (S# y) = S# (word2Int# (int2Word# x `or#` int2Word# y))
   x@(S# _) .|. y = toBig x .|. y
   x .|. y@(S# _) = x .|. toBig y
   (J# s1 d1) .|. (J# s2 d2) = 
	case orInteger# s1 d1 s2 d2 of
	  (# s, d #) -> J# s d
   
   (S# x) `xor` (S# y) = S# (word2Int# (int2Word# x `xor#` int2Word# y))
   x@(S# _) `xor` y = toBig x `xor` y
   x `xor` y@(S# _) = x `xor` toBig y
   (J# s1 d1) `xor` (J# s2 d2) =
	case xorInteger# s1 d1 s2 d2 of
	  (# s, d #) -> J# s d
   
   complement (S# x) = S# (word2Int# (int2Word# x `xor#` int2Word# (0# -# 1#)))
   complement (J# s d) = case complementInteger# s d of (# s, d #) -> J# s d

   shift x i | i >= 0    = x * 2^i
	     | otherwise = x `div` 2^(-i)

   rotate x i = shift x i   -- since an Integer never wraps around

   bitSize _  = error "Bits.bitSize(Integer)"
   isSigned _ = True
#endif

#ifdef __NHC__
instance Bits Int where
    (.&.)             = nhc_primIntAnd
    (.|.)             = nhc_primIntOr
    xor               = nhc_primIntXor
    complement        = nhc_primIntCompl
    shiftL            = nhc_primIntLsh
    shiftR            = nhc_primIntRsh
    bitSize _         = 32
    isSigned _        = True

foreign import ccall nhc_primIntAnd :: Int -> Int -> Int
foreign import ccall nhc_primIntOr  :: Int -> Int -> Int
foreign import ccall nhc_primIntXor :: Int -> Int -> Int
foreign import ccall nhc_primIntLsh :: Int -> Int -> Int
foreign import ccall nhc_primIntRsh :: Int -> Int -> Int
foreign import ccall nhc_primIntCompl :: Int -> Int

instance Bits Integer where
 -- (.&.) a b          = undefined
 -- (.|.) a b          = undefined
 -- xor a b            = undefined
    complement a       = (-a)
    x `shift` i | i<0  = x `div` (2^(-i))
                | i==0 = x
                | i>0  = x * (2^i)
    x `rotate` i       = x `shift` i	-- an Integer never wraps
    bitSize _          = error "Data.Bits: bitSize :: Integer -> Int"
    isSigned _         = True

#endif

