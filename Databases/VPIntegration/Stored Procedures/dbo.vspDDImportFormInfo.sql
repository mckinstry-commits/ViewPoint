SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[vspDDImportFormInfo]
   /***********************************************************
    * CREATED BY: GR   08/24/99
    * MODIFIED By : danf 08/24/01  Add modification for JCProgress
	*				danf 07/31/07 6.x recode
    *
    * USAGE:
    * validates importform and returns description and the destination table
    *
    * INPUT PARAMETERS
   
    *   Form         ImportForm
    *
    * OUTPUT PARAMETERS
    *    Description
    *    Destination Table
    * RETURN VALUE
    *   0 Success
    *   1 fail
    ************************************************************************/
   	(@importform char(30) = null, @descrip bDesc output, @tablename varchar(30) output,
       @formtype tinyint output, @source bSource output, @msg varchar(60) output)
   
   as
   set nocount on
   declare @rcode int, @name varchar(30)
   select @rcode = 0
   
   if @importform is null
   
   	begin
   	select @msg = 'Missing Import Form!', @rcode = 1
   	goto bspexit
   	end
   
   
   select @descrip = Title, @tablename = CustomFieldTable, @formtype=FormType from DDFH with (nolock)
   	where Form = @importform
   
   
   
   if @@rowcount=0
       begin
       select @msg='Form does not exists in Form Header', @rcode=1
       goto bspexit
       end
   else
       begin
       If @importform = 'JCProgress' select @formtype = 2
   
       select @name=CustomFieldTable from DDFH with (nolock) where Form=@importform and FormType=2
       select @source=Source from HQBC with (nolock) where TableName=@name
       end

   bspexit:

   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDImportFormInfo] TO [public]
GO
