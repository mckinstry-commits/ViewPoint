SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspIMImportFormVal]
   /***********************************************************
    * CREATED BY:    GR   9/10/99
    * MODIFIED By :  RT 10/15/03, Issue #13558 return batchyn so we know type of import.
    *
    * USAGE:
    * validates ImportForm
    *
    * INPUT PARAMETERS
   
    *   Import Form
    *
    * OUTPUT PARAMETERS
    *    form description
    *    Error Message if error occurs
    * RETURN VALUE
    *   0 Success
    *   1 fail
    ************************************************************************/
   	(@importform varchar(30), @uploadroutine varchar(30) output, @bidtekroutine varchar(30) output,  
   		@importroutine varchar(30) output, @batchyn bYN output, @msg varchar(255) output)
   
   as
   set nocount on
   declare @rcode int, @validcnt int
   select @rcode = 0
   
   if @importform is null
   	begin
   	select @msg = 'Missing Import Form!', @rcode = 1
   	goto bspexit
   	end
   
   
   select @msg=Description, @uploadroutine=UploadRoutine, @bidtekroutine=BidtekRoutine, 
   @importroutine=ImportRoutine, @batchyn=BatchYN
   from DDUF
   	where Form=@importform
   if @@rowcount=0
     begin
       select @msg = 'Not a valid Import Form!', @rcode = 1
       goto bspexit
     end
   
   select @validcnt=Count(*) from DDUD where Form=@importform
   if @validcnt = 0
       begin
           select @msg = 'Form Detail not set up!', @rcode = 1
           goto bspexit
      end
   
   bspexit:
   	if @rcode<>0 select @msg=isnull(@msg,'Form Val)') + char(13) + char(10) + '[dbo.bspIMImportFormVal]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspIMImportFormVal] TO [public]
GO
