SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   procedure [dbo].[bspIMWEReformat]
   /*******************************************************************************
   * Created By:   GR 11/25/99
   * Modified By:  CC 03/31/08 - Issue #127569 modified to use DDDTShared
   *
   * This SP will get the datatype and datatype info
   *
   * It Returns either STDBTK_SUCCESS or STDBTK_ERROR and a msg in @msg
   *
   * Pass In
   *   Template		Template for this import
   *   Form            Form
   *   Identifier      Identifier
   *   Seq             Seq
   *   RecordSeq       RecordSeq
   *
   * RETURN PARAMS
   *   Datatype      Datatype for the seq
   *   InputType     Input type
   *   Inputmask     Input mask
   *   InputLength   Input length
   *   Prec          Precision
   *   msg           Error Message, or Success message
   *
   * Returns
   *      STDBTK_ERROR on Error, STDBTK_SUCCESS if Successful
   *
   ********************************************************************************/
   
    (@template varchar(10), @recordtype varchar(30), @identifier int,
    @datatype varchar(30) output, @inputtype int output,
    @inputmask varchar(30) output, @inputlength int output, @prec int output, @msg varchar(60) output)
   
    as
    set nocount on
   
    declare @rcode int
   
    select @rcode=0
   
    If @recordtype is null
       begin
       select @msg='Missing Record Type', @rcode=1
       goto bspexit
       end
   
    if @template is null
       begin
       select @msg='Missing Template', @rcode=1
       goto bspexit
       end
   
    --get datatype from IMTD
    select @datatype=Datatype from IMTD where
    ImportTemplate=@template and RecordType=@recordtype
    and Identifier=@identifier
   
   if left(@datatype, 1) = 'b'
   -- if (@@rowcount <> 0 and left(@datatype, 1) = 'b')
       begin
       select @inputtype=InputType, @inputmask=InputMask, @inputlength=InputLength, @prec=Prec
       from DDDTShared
       where Datatype=@datatype
   
       select @prec = isnull(@prec, 0)
   
       end
   
   bspexit:
        if @rcode<>0 select @msg=isnull(@msg,'reformat') + char(13) + char(10) + '[bspIMWEReformat]'
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspIMWEReformat] TO [public]
GO
