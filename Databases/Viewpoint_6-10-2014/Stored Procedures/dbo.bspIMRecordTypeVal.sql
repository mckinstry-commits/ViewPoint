SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspIMRecordTypeVal    Script Date: 8/28/99 9:34:57 AM ******/
   CREATE   proc [dbo].[bspIMRecordTypeVal]
   /***********************************************************
    * CREATED BY: GR   08/25/99
    * MODIFIED By :
    *
    * USAGE:
    * validates RecordType
    *
    * INPUT PARAMETERS
   
    *   template, recordtype
    *
    * OUTPUT PARAMETERS
    *    form
    *    form description
    *    Error Message if error occurs
    * RETURN VALUE
    *   0 Success
    *   1 fail
    ************************************************************************/
   	(@template varchar(10) = null , @recordtype varchar(30) = null, @form varchar(30) output, @formdesc bDesc output, @msg varchar(255) output)
   
   as
   set nocount on
   declare @rcode int, @validcnt int
   select @rcode = 0
   
   if @template is null
   
   	begin
   	select @msg = 'Missing Template!', @rcode = 1
   	goto bspexit
   	end
   
   
   if @recordtype is null
   
   	begin
   	select @msg = 'Missing RecordType!', @rcode = 1
   	goto bspexit
   	end
   
   select @form=Form, @formdesc=Description from IMTR
   	where ImportTemplate=@template and RecordType=@recordtype
   if @@rowcount=0
     begin
       select @msg = 'No Form associated with this Template/Record Type!', @rcode = 1
       goto bspexit
     end
   else
       select @msg = @formdesc
   
   bspexit:
   	if @rcode<>0 select @msg=isnull(@msg,'Record Type Val') + char(13) + char(10) + '[bspIMRecordTypeVal]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspIMRecordTypeVal] TO [public]
GO
