SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspIMImportFormRecTypedVal    Script Date: 9/10/99 10:34:57 AM ******/
   CREATE   proc [dbo].[bspIMImportFormRecTypedVal]
   /***********************************************************
    * CREATED BY: GR   9/10/99
    * MODIFIED By :
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
   	(@importform varchar(30),  @recordtype varchar(30) output, @msg varchar(255) output)
   
   as
   set nocount on
   declare @rcode int, @validcnt int
   select @rcode = 0
   
   if @importform is null
   	begin
   	select @msg = 'Missing Import Form!', @rcode = 1
   	goto bspexit
   	end
   
   
   select @msg=Description, @recordtype=DestTable from DDUF
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
   	if @rcode<>0 select @msg=isnull(@msg,'Rec Type Val') + char(13) + char(10) + '[dbo.bspIMImportFormRecTypedVal]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspIMImportFormRecTypedVal] TO [public]
GO
