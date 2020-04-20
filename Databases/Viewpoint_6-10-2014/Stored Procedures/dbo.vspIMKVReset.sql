SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspIMKVReset]
   /***********************************************************
    * CREATED BY: RT   03/07/06
    * MODIFIED BY :
    *
    * USAGE:
    *   Deletes current IMKV contents and inserts new values for given importid.
    *
    * INPUT PARAMETERS
	*   ImportId
    *   Template
    *
    * OUTPUT PARAMETERS
    *    Error Message if error occurs
	*
    * RETURN VALUE
    *   0 Success
    *   1 fail
    ************************************************************************/
   	(@importid varchar(20), @template varchar(10), @msg varchar(60) output)
   
   as
   set nocount on
   declare @rcode int, @validcnt int
   select @rcode = 0
      
   if @importid is null
       begin
       select @msg = 'Missing Import ID!', @rcode = 1
       goto bspexit
       end
   if @template is null
       begin
       select @msg = 'Missing Template!', @rcode = 1
       goto bspexit
       end
      
	delete from IMKV where ImportId = @importid

	insert into IMKV select @importid,ImportTemplate,RecordType,Identifier,null,UpdateKeyYN 
    from IMTD where ImportTemplate = @template and ImportPromptYN = 'Y'

   bspexit:
   	if @rcode<>0 select @msg=isnull(@msg,'Error') + char(13) + char(10) + '[vspIMKVReset]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspIMKVReset] TO [public]
GO
