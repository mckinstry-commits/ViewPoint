SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspIMXDGetFormatInfo]
   /************************************************************************
   * CREATED:    MH     
   * MODIFIED:   mh 5/20/03 Add @rectype, @template, @ident parameters.  Dropped @datatype
   *				parameter.  Moved request for datatype info into this sp.  Issue 21314 
   *			  RT 7/18/03 Issue #21864 - Added isnull() for @inputtype.
   *
   * Purpose of Stored Procedure
   *
   *    Return format info for Import Template data.
   *    
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
       (@rectype varchar(30), @template varchar(10), @ident int, @inputtype int output, @inputmask varchar(30) output, 
   	@inputlength int output, @prec int output, @msg varchar(80) = '' output)
   
   as
   set nocount on
   
       declare @rcode int, @datatype varchar(30)
   
       select @rcode = 0
   
   	select @datatype = Datatype 
   	from IMTD where ImportTemplate = @template and RecordType = @rectype and Identifier = @ident 
   
       select @inputtype=InputType, @inputmask=InputMask, @inputlength=InputLength, @prec=Prec
       from DDDTShared
       where Datatype=@datatype
   
   	select @inputtype = isnull(@inputtype, 0)	--issue #21864
   	select @inputmask = isnull(@inputmask, '')
   	select @inputlength = isnull(@inputlength, 0)
       select @prec = isnull(@prec, 0)
      
   
   bspexit:
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspIMXDGetFormatInfo] TO [public]
GO
