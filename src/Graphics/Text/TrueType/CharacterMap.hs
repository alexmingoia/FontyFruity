module Graphics.Text.TrueType.CharacterMap where

import Control.Monad( replicateM )
import Control.Applicative( (<$>), (<*>) )
import Control.Monad( when )
import Data.Binary( Binary( .. ) )
import Data.Binary.Get( Get
                      , getWord8
                      , getWord16be
                      , getWord32be )

import Data.Binary.Put( putWord16be
                      , putWord32be )
import Data.Word( Word8, Word16, Word32 )

import qualified Data.Vector.Unboxed as VU

data TtfEncoding
  = EncodingSymbol
  | EncodingUnicode
  | EncodingShiftJIS
  | EncodingBig5
  | EncodingPRC
  | EncodingWansung
  | EncodingJohab
  deriving (Eq, Show)

instance Binary TtfEncoding where
    put EncodingSymbol = putWord16be 0
    put EncodingUnicode = putWord16be 1
    put EncodingShiftJIS = putWord16be 2
    put EncodingBig5 = putWord16be 3
    put EncodingPRC = putWord16be 4
    put EncodingWansung = putWord16be 5
    put EncodingJohab = putWord16be 6

    get = do
      v <- getWord16be
      case v of
        0 -> return EncodingSymbol
        1 -> return EncodingUnicode
        2 -> return EncodingShiftJIS
        3 -> return EncodingBig5
        4 -> return EncodingPRC
        5 -> return EncodingWansung
        6 -> return EncodingJohab
        _ -> fail "Unknown encoding"

data CharacterMaps = CharacterMaps [Table]

instance Binary CharacterMaps where
  put _ = fail "Unimplemented"
  get = do
    versionNumber <- getWord16be
    when (versionNumber /= 0)
         (fail "Characte map - invalid version number")
    tableCount <- fromIntegral <$> getWord16be
    CharacterMaps <$> replicateM tableCount get

data CharMapOffset = CharMapOffset 
    { _cmoPlatformId :: !Word16
    , _cmoEncodingId :: !TtfEncoding 
    , _cmoOffset     :: !Word32
    }
    deriving (Eq, Show)

instance Binary CharMapOffset where
    get = CharMapOffset <$> getWord16be <*> get <*> getWord32be
    put (CharMapOffset platform encoding offset) =
      putWord16be platform >> put encoding >> putWord32be offset

data Table
    = TableFormat0 !(VU.Vector Word8)
    | TableFormat2 Format2
    deriving (Eq, Show)

getFormat0 :: Get Table
getFormat0 = TableFormat0 <$> do
    count <- fromIntegral <$> getWord16be
    _version <- getWord16be
    VU.replicateM count getWord8

data Format2SubHeader = Format2SubHeader
    { _f2SubCode       :: !Word16
    , _f2EntryCount    :: !Word16
    , _f2IdDelta       :: !Int16
    , _f2IdRangeOffset :: !Word16
    }

instance Binary Format2SubHeader where
    put (Format2SubHeader a b c d) =
        p16 a >> p16 b >> pi16 c >> p16 d
      where
        p16 = putWord16be
        pi16 = p16 . fromIntegral

    get = Format2SubHeader <$> g16 <*> g16 <*> (fromIngegral <$> g16) <*> g16
      where g16 = getWord16be

instance Binary Format2 where
    put _ = fail "Format2.put - unimplemented"
    get = do
      tableSize <- getWord16be
      lang <- getWord16be
      subKeys <- VU.map (`div` 8) <$> VU.replicateM 256 getWord16be
      let maxSubIndex = VU.maximum subKeys

data Format2 = Format2
    { _format2Language   :: !Word16
    , _format2SubKeys    :: !Word16
    , _format2SubHeaders :: !Format2SubHeader
    }

instance Binary Table where
    put _ = fail "Binary.put Table - Unimplemented"
    get = do
        format <- getWord16be
        case format of
            0 -> getFormat0
            n -> fail $ "Unrecognized table format " ++ show n
