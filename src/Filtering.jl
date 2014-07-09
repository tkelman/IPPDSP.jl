# ippf  variable to hold the the IPP function name
# sr    single rate
# mr    multirate
# Tt    datatype of filter taps (coefficients)
# Tx    datatype of signal

module WindowType
    const bartleTt       = 0 
    const ippWinBlackman = 1
    const ippWinHamming  = 2
    const ippWinHann     = 3
    const ippWinRect     = 4
end

export  conv,
        xcorr,
        autocorr,
        autocorrb,
        autocorru,
        FIRFilter,
        filt,
        FIRInit
        

        

# These are common to most of the ipps FIR Filter functions 
# I haven't included functions that require integer scaling
# It takes difference parameters. Hope I haven't painted
# myself into a wall.
FIRFilterTypes =    [   ( :IPP32f,      :IPP32f,    "_32f"       ),
                        ( :IPP32fc,     :IPP32fc,   "_32fc"      ),
                        ( :IPP64f,      :IPP64f,    "_64f"       ),
                        ( :IPP64fc,     :IPP64fc,   "_64fc"      ),
                        ( :IPP32f,      :Int16,     "32f_16s"    ),
                        ( :IPP64f,      :Int16,     "64f_16s"    ),
                        ( :IPP64f,      :IPP32f,    "64f_32f"    ),
                        ( :IPP64f,      :Int32,     "64f_32s"    ),
                        ( :IPP64fc,     :IPP16sc,   "64fc_16sc"  ),
                        ( :IPP64fc,     :IPP32sc,   "64fc_32sc"  ),
                        ( :IPP64fc,     :IPP32fc,   "64fc_32fc"  )   ]




for ( julia_fun, ippf_prefix, types ) in    [   (   :conv,      "ippsConv", [   ( :IPP32f, "32f"     ),
                                                                                ( :IPP64f, "64f"     ),
                                                                                ( :Int16,   "16s_Sfs" ) ] ) ]
    julia_fun! = symbol(string(julia_fun, '!'))

    for ( T, ipp_suffix ) in types

        ippf  = string( ippf_prefix, '_', ipp_suffix )
        
        if eval(T)<:Integer # integer versions require a scaling factor
            @eval begin
                function $(julia_fun!)( y::Array{$T}, x1::Array{$T}, x2::Array{$T}, scale::Integer  )
                    ny  = length( y )
                    nx1 = length( x1 )
                    nx2 = length( x2 )
                    ny == nx1+nx2-1 || throw( DimensionMismatch( "length(y) must be length(x1)+length(x2)-1" ))
                    if ny > 3
                        @ippscall( $ippf, ( Ptr{$T},    IppInt,     Ptr{$T},    IppInt,     Ptr{$T},    IppInt  ),
                                            x1,         nx1,        x2,         nx2,        y,          scale   )
                    end
                    return y
                end
            
                $(julia_fun)(  x1::Array{$T}, x2::Array{$T}, scale::Integer ) = $(julia_fun!)( similar(x1, length(x1) + length(x2) - 1), x1, x2, scale )
            
            end
        else
            @eval begin
                function $(julia_fun!)( y::Array{$T}, x1::Array{$T}, x2::Array{$T}  )
                    ny  = length( y )
                    nx1 = length( x1 )
                    nx2 = length( x2 )
                    ny == nx1+nx2-1 || throw( DimensionMismatch( "length(y) must be length(x1)+length(x2)-1" ))
                    if ny > 3
                        @ippscall( $ippf, ( Ptr{$T},    IppInt,     Ptr{$T},    IppInt,     Ptr{$T} ),
                                            x1,         nx1,        x2,         nx2,        y       )
                    end
                    return y
                end
             
                $(julia_fun)(  x1::Array{$T}, x2::Array{$T} ) = $(julia_fun!)( similar(x1, length(x1) + length(x2) - 1), x1, x2 )
            end
        end
    end
end




################################################################################
#               ____ ____ ____ ____ ____ _    ____ ___ _ ____ _  _             #
#               |    |  | |__/ |__/ |___ |    |__|  |  | |  | |\ |             #
#               |___ |__| |  \ |  \ |___ |___ |  |  |  | |__| | \|             #
################################################################################                                           

for ( julia_fun, ippf_prefix, types ) in    [   (   :xcorr,      "ippsCrossCorr", [     ( :IPP32f,             "32f"       ),
                                                                                        ( :IPP64f,             "64f"       ),
                                                                                        ( :(IPP32fc),  "32fc"      ),
                                                                                        ( :(IPP64fc),  "64fc"      ),
                                                                                        ( :Int16,               "16s_Sfs"   ) ] ) ]

    julia_fun! = symbol(string(julia_fun, '!'))

    for ( T, ipp_suffix ) in types

        ippf  = string( ippf_prefix, '_', ipp_suffix )
        
        if eval(T)==Int16 # scaled version
            @eval begin
                function $(julia_fun!)( y::Array{$T}, x1::Array{$T}, x2::Array{$T}; scale::Integer = 0, lowlag::Integer = 0)
                    ny  = length( y )
                    nx1 = length( x1 )
                    nx2 = length( x2 )
                    ny > 1 && nx1 > 1 && nx2 > 1 || throw() # TODO: Check constrainTx                    
                    if ny > 3
                        @ippscall( $ippf, ( Ptr{$T},    IppInt,     Ptr{$T},    IppInt,     Ptr{$T},    IppInt, IppInt,  IppInt ),
                                            x1,         nx1,        x2,         nx2,        y,          ny,     lowlag,  scale  )
                    end
                    return y
                end
            
                $(julia_fun)(  x1::Array{$T}, x2::Array{$T}; args... ) = $(julia_fun!)( similar(x1, length(x1) + length(x2) - 1), x1, x2; args... )
            
            end
        else
            @eval begin
                function $(julia_fun!)( y::Array{$T}, x1::Array{$T}, x2::Array{$T}; lowlag::Integer = 0)
                    ny  = length( y )
                    nx1 = length( x1 )
                    nx2 = length( x2 )
                    ny > 1 && nx1 > 1 && nx2 > 1 || throw() # TODO: Check constrainTx                    
                    if ny > 3
                        @ippscall( $ippf, ( Ptr{$T},    IppInt,     Ptr{$T},    IppInt,     Ptr{$T},    IppInt, IppInt  ),
                                            x1,         nx1,        x2,         nx2,        y,          ny,     lowlag  )
                    end
                    return y
                end
            
                $(julia_fun)(  x1::Array{$T}, x2::Array{$T}; args... ) = $(julia_fun!)( similar(x1, length(x1) + length(x2) - 1), x1, x2; args... )
            end
        end
    end
end

for ( julia_fun, ippf_prefix )  in  [   (   :autocorr,  "ippsAutoCorr"          ),      
                                        (   :autocorrb, "ippsAutoCorr_NormA"    ),    
                                        (   :autocorru, "ippsAutoCorr_NormB"    )   ]
                                            
    julia_fun! = symbol(string(julia_fun, '!'))

    for ( T, ippf_suffix ) in [ (   :Int16,                 "16s_Sfs"   ),
                                (   :IPP32f,               "32f"       ), 
                                (   :IPP64f,               "64f"       ),
                                (   :(IPP16fc),    "16fc"      ),
                                (   :(IPP32fc),    "32fc"      ),
                                (   :(IPP64fc),    "64fc"      ) ]

        ippf  = string( ippf_prefix, '_', ippf_suffix )
        
        if eval(T) == Int16
            @eval begin
                function $(julia_fun!)( y::Array{$T}, x::Array{$T}; scale::Integer = 0 )
                    ny = length( y )
                    nx = length( x )
                    ny == nx || throw( DimensionMismatch("length(y) != length(x) ") )
                    if ny > 0
                        @ippscall( $ippf, ( Ptr{$T},    IppInt, Ptr{$T},    IppInt, IppInt  ), 
                                            x,          nx,     y,          ny,     scale   )
                    end
            
                    return y
                end
            
                $(julia_fun)(  x::Array{$T}; args... ) = $(julia_fun!)( similar(x, length(x)*2-1), x; args... )

            end
        else
            @eval begin
                function $(julia_fun!)( y::Array{$T}, x::Array{$T}  )
                    ny = length( y )
                    nx = length( x )
                    ny == nx|| throw( DimensionMismatch("length(y) != length(x) ") ) #todo: check this
                    if ny > 0
                        @ippscall( $ippf, ( Ptr{$T},    IppInt, Ptr{$T},    IppInt  ), 
                                            x,          nx,     y,          ny      )
                    end
            
                    return y
                end
                
                $(julia_fun)(  x::Array{$T} ) = $(julia_fun!)( similar(x), x )

            end            
        end
    end
end




################################################################################
#     ____ _ ____    ____ _ _    ___ ____ ____    ____ ___ ____ ___ ____       #
#     |___ | |__/    |___ | |     |  |___ |__/    [__   |  |__|  |  |___       #
#     |    | |  \    |    | |___  |  |___ |  \    ___]  |  |  |  |  |___       #
################################################################################  
#   Name:         ippsFIRRequiredStateSize, ippsFIRMRRequiredStateSize,
#                 ippsFIRInit, ippsFIRMRInit
#   Purpose:      ippsFIRRequiredStateSize - calculates the size of the FIR State
#                                                                    structure;
#                 ippsFIRInit - initialize FIR state - set taps and delay line
#                 using external memory buffer;
#   Parameters:
#       pTaps       - pointer to the filter coefficients;
#       tapsLen     - number of coefficients;
#       pDlyLine    - pointer to the delay line values, can be NULL;
#       ppState     - pointer to the FIR state created or NULL;
#       upFactor    - multi-rate up factor;
#       upPhase     - multi-rate up phase;
#       downFactor  - multi-rate down factor;
#       downPhase   - multi-rate down phase;
#       pStateSize  - pointer where to store the calculated FIR State structure
#                                                              size (in bytes);
#    Return:
#       status      - status value returned, its value are
#          ippStsNullPtrErr       - pointer(s) to the data is NULL
#          ippStsFIRLenErr        - tapsLen <= 0
#          ippStsFIRMRFactorErr   - factor <= 0
#          ippStsFIRMRPhaseErr    - phase < 0 || factor <= phase
#          ippStsNoErr            - otherwise

# IppStatus ippsFIRMRRequiredStateSize_64fc(int tapsLen, int upFactor, int downFactor, int* pBufferSize);

for ( julia_fun, ippf_prefix1, ippf_prefix2 )  in  [ (   :FIRRequiredStateSize,  "ippsFIR",  "GetStateSize"  ) ]
    for ( T_taps, T_sig, ippf_suffix ) in FIRFilterTypes
            
        # Single rate version
        ippfsr = string( ippf_prefix1, ippf_prefix2, ippf_suffix )
        @eval begin
            function $(julia_fun)( ::Type{$T_taps}, ::Type{$T_sig}, tapslen::Integer  )
                buffersize = IppInt[0]  # the function will fill this value
                tapslen > 0 || throw( ) # todo: check this
                @ippscall( $ippfsr, ( IppInt,     Ptr{IppInt} ),
                                      tapslen,    buffersize    )

                return buffersize[1]
            end
        end
        
        # Multirate version
        ippfmr = string( ippf_prefix1, "MR", ippf_prefix2, ippf_suffix )
        @eval begin
            function $(julia_fun)( ::Type{$T_taps}, ::Type{$T_sig}, tapslen::Integer, upFactor::Integer, downFactor::Integer )
                buffersize = IppInt[0]  # the function will fill this value
                tapslen > 0 || throw( ) # todo: check this
                @ippscall( $ippfmr, ( IppInt,   IppInt,    IppInt,      Ptr{IppInt} ),
                                      tapslen,  upFactor,  downFactor,  buffersize    )

                return buffersize[1]
            end
            $(julia_fun)( ::Type{$T_taps}, ::Type{$T_sig}, tapslen::Integer, resamp_ratio::Rational ) = $(julia_fun)( $T_taps, $T_sig, tapslen, num(resamp_ratio), den(resamp_ratio) )
        end        
    end
end



################################################################################
#      ____ _ ____    ____ _ _    ___ ____ ____    ___ _   _ ___  ____         #
#      |___ | |__/    |___ | |     |  |___ |__/     |   \_/  |__] |___         #
#      |    | |  \    |    | |___  |  |___ |  \     |    |   |    |___         #
################################################################################  


# IPP assings a pointer to state
# This points to an invisuble-to-us struct in buffer
# Intel's documentation is weak in this area, but we allocate the buffer, they
# instantsiat a stuct inside that buffer, and use state to point the location of
# that state

# Both the singe-rate and multirate states are the same, but are in different
# types to help with dispatching

# Single rate state
type FIRSRState
    pointer::Ptr{Void}
    buffer::Vector{Uint8} 
end

# Multirate state
type FIRMRState
    pointer::Ptr{Void}
    buffer::Vector{Uint8} 
end

# FIRFilter type, its type signature includes the FIRState type, which is how functions taking
# FIRFilter as a parapter get diuspatched to the correct single-rate or multirate IPP functions
type FIRFilter{Tt, Tx, Ts}
    taps::Vector{Tt}
    delayLine::Vector{Tx}
    state::Ts
    upFactor::Int
    downFactor::Int
    upPhase::Int
    downPhase::Int    
end

# Single rate constructor
function FIRFilter{Tx, Tt}( ::Type{Tx}, taps::Vector{Tt} )
    tapsLen   = length( taps )
    pointer   = convert( Ptr{Uint8}, 0 )
    bufLen    = FIRRequiredStateSize( Tt, Tx, tapsLen )
    delayLine = zeros( Tx, tapsLen )
    buffer    = zeros( Uint8, bufLen )                        
    state     = FIRSRState( pointer, buffer )
    FIRInit!( state, taps, delayLine )        
    FIRFilter( taps, delayLine, state, 1, 1, 0, 0 )
end    

# Multirate constructor
function FIRFilter{ Tx, Tt }( ::Type{Tx}, taps::Array{Tt, 1}, upFactor, downFactor, upPhase = 0, downPhase = 0 )
    tapsLen   = length( taps )
    pointer   = convert( Ptr{Uint8}, 0 )
    bufLen    = FIRRequiredStateSize( Tt, Tx, tapsLen )
    delayLine = zeros( Tx, tapsLen )
    buffer    = zeros( Uint8, bufLen )                        
    state     = FIRMRState( pointer, buffer )
    FIRInit!( state, taps, delayLine, upFactor, downFactor, upPhase, downPhase )        
    FIRFilter( taps, delayLine, state, upFactor, downFactor, upPhase, downPhase )        
end  

FIRFilter{ Tx, Tt }( ::Type{Tx}, taps::Array{Tt, 1}, resampleRatio::Rational, upPhase = 0, downPhase = 0 ) = FIRFilter( Tx, taps, num(resampleRatio), den(resampleRatio), upPhase, downPhase )


################################################################################
#           ____ _ ____    ____ _ _    ___ ____ ____    _ _  _ _ ___           #
#           |___ | |__/    |___ | |     |  |___ |__/    | |\ | |  |            #
#           |    | |  \    |    | |___  |  |___ |  \    | | \| |  |            #
################################################################################  
#  Documentation is horrible, see this link:
#                hTtps://software.intel.com/en-us/forums/topic/307712
#
#  Name:         ippsFIRRequiredStateSize, ippsFIRMRGeTxtateSize,
#                ippsFIRInit, ippsFIRMRInit
#  Purpose:      ippsFIRRequiredStateSize - calculates the size of the FIR State
#                                                                   structure;
#                ippsFIRInit - initialize FIR state - set taps and delay line
#                using external memory buffer;
#  Parameters:
#      pTaps       - pointer to the filter coefficienTx;
#      tapsLen     - number of coefficienTx;
#      pDlyLine    - pointer to the delay line values, can be NULL;
#      ppState     - pointer to the FIR state created or NULL;
#      upFactor    - multi-rate up factor;
#      upPhase     - multi-rate up phase;
#      downFactor  - multi-rate down factor;
#      downPhase   - multi-rate down phase;
#      pStateSize  - pointer where to store the calculated FIR State structure
#                                                             size (in bytes);
#   Return:
#      status      - status value returned, iTx value are
#         ippSTxNullPtrErr       - pointer(s) to the data is NULL
#         ippSTxFIRLenErr        - tapsLen <= 0
#         ippSTxFIRMRFactorErr   - factor <= 0
#         ippSTxFIRMRPhaseErr    - phase < 0 || factor <= phase
#         ippSTxNoErr            - otherwise
# 
for ( julia_fun, ippf_prefix1, ippf_prefix2 )  in  [ (   :FIRInit,  "ippsFIR",  "Init"  ) ],    ( Tt, Tx, ippf_suffix ) in FIRFilterTypes

    julia_fun! = symbol(string(julia_fun, '!'))
    # Single rate version
    ippfsr     = string( ippf_prefix1, ippf_prefix2, ippf_suffix )
    @eval begin
        
        function $(julia_fun!)( state::FIRSRState, taps::Vector{ $Tt }, delayLine::Vector{ $Tx } )
            ntaps          = length( taps )
            ndelayline     = length( delayLine )
            statePtr       = Array( Ptr{Void}, 1 )         
            @ippscall( $ippfsr, (   Ptr{Void},         Ptr{$Tt},    IppInt,     Ptr{$Tx},      Ptr{Uint8}   ),
                                    pointer(statePtr),  taps,        ntaps,      delayLine,     state.buffer )         
            state.pointer = statePtr[1]
            nothing                                                                                                               
        end
    
    end
                
    # Multirate version
    ippfmr  = string( ippf_prefix1, "MR", ippf_prefix2, ippf_suffix )
    @eval begin
    
        function $(julia_fun!)(  state::FIRMRState, taps::Vector{ $Tt }, delayLine::Vector{ $Tx }, upFactor, downFactor, upPhase, downPhase )
            ntaps          = length( taps )
            ndelayline     = length( delayLine )
            statePtr       = Array( Ptr{Void}, 1 )         
            0 <= upPhase < upFactor && 0 <= downPhase < downFactor || throw()
            @ippscall( $ippfmr, (   Ptr{Void},         Ptr{$Tt}, IppInt, IppInt,    IppInt,  IppInt,     IppInt,    Ptr{$Tx},  Ptr{Uint8}   ),
                                    pointer(statePtr),  taps,     ntaps,  upFactor,  upPhase, downFactor, downPhase, delayLine, state.buffer )
            state.pointer = statePtr[1]
            nothing                                                                                                               
        end
    
    end                    
end

# FIRInit( fir::FIRFilter ) = FIRInit( fir.taps, fir.delayLine, fir.state, fir.buffer )





################################################################################
#      ____ _ ____    ____ _ _    ___ ____ ____    ____ _  _ ____ ____         #
#      |___ | |__/    |___ | |     |  |___ |__/    |___  \/  |___ |            #
#      |    | |  \    |    | |___  |  |___ |  \    |___ _/\_ |___ |___         #
################################################################################
# 
#  Names:         ippsFIR
#  Purpose:       FIR filter. Vector filtering
#  Parameters:
#      pSrcDst     - pointer to the input/output vector in in-place operation
#      pSrc        - pointer to the input vector
#      pDst        - pointer to the output vector
#      numIters    - number iterations (for single-rate equal length data vector)
#      pState      - pointer to the filter state
#      scaleFactor - scale factor value
#  Return:
#      ippSTxContextMatchErr  - wrong state identifier
#      ippSTxNullPtrErr       - pointer(s) to the data is NULL
#      ippSTxSizeErr          - numIters is less or equal zero
#      ippSTxNoErr            - otherwise
#  Note: for Multi-Rate filtering
#          length pSrc = numIters*downFactor
#          length pDst = numIters*upFactor
#               for inplace functions max this values
# 
for ( julia_fun, ippf_prefix )  in  [ (   :filt,  "ippsFIR"  ) ], ( Tt, Tx, ippf_suffix ) in FIRFilterTypes
        
    ippfsr     = string( ippf_prefix, ippf_suffix )
    julia_fun! = symbol(string(julia_fun, '!'))
    
    @eval begin
        function $(julia_fun!)( self::FIRFilter{$Tt, $Tx, FIRSRState}, buffer::Vector{ $Tx }, signal::Vector{ $Tx } )
            sigLen = length( signal )
            outLen = length( buffer )                
            @ippscall( $ippfsr,  (  Ptr{$Tx},       Ptr{$Tx},       IppInt,    Ptr{Void}                    ),
                                    signal,         buffer,         sigLen,    self.state.pointer           )
            buffer                                                                                                               
        end            
        $(julia_fun)( self::FIRFilter{$Tt, $Tx, FIRSRState}, signal::Vector{$Tx} ) = $(julia_fun!)( self, similar( signal ), signal )
    end
    
    ippfmr = string( ippf_prefix, "MR", ippf_suffix )
    @eval begin
        function $(julia_fun!)( self::FIRFilter{ $Tt, $Tx, FIRMRState },
                                buffer::Array{$Tx, 1},
                                signal::Array{$Tx, 1} )
            sigLen = length( signal )
            outLen = length( buffer )
            sigLen * self.upFactor == outLen * self.downFactor || throw()
            iterations  = int( sigLen/self.downFactor )
            @ippscall( $ippfsr,  (  Ptr{$Tx},  Ptr{$Tx},  IppInt,     Ptr{Void}            ),
                                    signal,    buffer,    iterations, self.state.pointer   )
            buffer
        end
    
        function $(julia_fun)( self::FIRFilter{$Tt, $Tx, FIRMRState}, signal::Vector{ $Tx } )
            sigLen = length( signal )
            sigLen % self.downFactor == 0 || throw()
            bufLen = int( sigLen * self.upFactor / self.downFactor )
            buffer = similar( signal, bufLen )
            $(julia_fun!)( self, buffer, signal )
        end
    end
end


#  Names:      ippsFIRGenLowpass_64f, ippsFIRGenHighpass_64f, ippsFIRGenBandpass_64f
#              ippsFIRGenBandstop_64f
#
#  Purpose:    This function computes the lowpass FIR filter coefficients
#              by windowing of ideal (infinite) filter coefficients segment
#
#  Parameters:
#      rfreq             cut off frequency (0 < rfreq < 0.5)
#
#      taps              pointer to the array which specifies
#                        the filter coefficients;
#
#      tapsLen           the number of taps in taps[] array (tapsLen>=5);
#
#      winType           the ippWindowType switch variable,
#                        which specifies the smoothing window type;
#
#      doNormal          if doNormal=0 the functions calculates
#                        non-normalized sequence of filter coefficients,
#                        in other cases the sequence of coefficients
#                        will be normalized.
#  Return:
#   ippStsNullPtrErr     the null pointer to taps[] array pass to function
#   ippStsSizeErr        the length of coefficient's array is less than five
#   ippStsSizeErr        the low or high frequency isn't satisfy
#                                    the condition 0 < rLowFreq < 0.5
#   ippStsNoErr          otherwise
#
#
#  IPPAPI(IppStatus, ippsFIRGenLowpass_64f, (Ipp64f rfreq, Ipp64f* taps, int tapsLen,
#                                              IppWinType winType, IppBool doNormal))
#  
#  IPPAPI(IppStatus, ippsFIRGenHighpass_64f, (Ipp64f rfreq, Ipp64f* taps, int tapsLen,
#                                               IppWinType winType, IppBool doNormal))
#  
#  IPPAPI(IppStatus, ippsFIRGenBandpass_64f, (Ipp64f rLowFreq, Ipp64f rHighFreq, Ipp64f* taps,
#                                       int tapsLen, IppWinType winType, IppBool doNormal))
#  
#  IPPAPI(IppStatus, ippsFIRGenBandstop_64f, (Ipp64f rLowFreq, Ipp64f rHighFreq, Ipp64f* taps,
#                                       int tapsLen, IppWinType winType, IppBool doNormal))
