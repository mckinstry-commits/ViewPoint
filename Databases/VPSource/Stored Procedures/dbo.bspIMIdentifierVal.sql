SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    proc [dbo].[bspIMIdentifierVal]
   /***********************************************************
    * CREATED BY: GR   09/27/99
    * MODIFIED By : danf 10/22/03 Added output of Datatype.
    *
    * USAGE:
    * validates identifier of Template/RecordType
    *
    * INPUT PARAMETERS
    *
    *   identifier
    *   template
    *   recordtype
    *
    * OUTPUT PARAMETERS
    *    Error Message if error occurs
    * RETURN VALUE
    *   0 Success
    *   1 fail
    ************************************************************************/
   	(@identifier int, @template varchar(10), @recordtype varchar(30), @datatype varchar(30) output, @msg varchar(60) output)
   
   as
   set nocount on
   declare @rcode int, @validcnt int
   select @rcode = 0
   
   if @identifier is null
   	begin
   	select @msg = 'Missing Identifier!', @rcode = 1
   	goto bspexit
   	end
   
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
   
   select @validcnt=Count(*) from IMTD
   	where ImportTemplate=@template and RecordType=@recordtype and Identifier=@identifier
   if @validcnt=0
     begin
       select @msg = 'Template/RecordType/Identifier not on file!', @rcode = 1
       goto bspexit
     end
   
   select @msg=ColDesc, @datatype=Datatype from IMTD where ImportTemplate=@template and RecordType=@recordtype and Identifier=@identifier
   
   bspexit:
   	if @rcode<>0 select @msg=isnull(@msg,'ID Val') + char(13) + char(10) + '[bspIMIdentifierVal]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspIMIdentifierVal] TO [public]
GO
