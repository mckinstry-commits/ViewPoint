SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspIMTemplateValidate]
   /***********************************************************
    * CREATED BY: DANF 06/27/2007
    * MODIFIED BY :
    *
    * USAGE:
    *   Validate Import template.
    *
    * INPUT PARAMETERS
    *   Template
    *
    * OUTPUT PARAMETERS
    *    FileType
    *    Error Message if error occurs
    * RETURN VALUE
    *   0 Success
    *   1 fail
    ************************************************************************/
   	(@template varchar(10), @msg varchar(60) output)

   as
   set nocount on
   declare @rcode int, @validcnt int
   select @rcode = 0
      
   if @template is null
       begin
       select @msg = 'Missing Template!', @rcode = 1
       goto bspexit
       end
      
select @validcnt = 1
from IMTH with (nolock)
where ImportTemplate = @template
if @@rowcount<>1
     begin
       select @msg = 'Template not on file!', @rcode = 1
       goto bspexit
     end

   bspexit:
   	if @rcode<>0 select @msg=isnull(@msg,'Error') + char(13) + char(10) + '[vspIMTemplateValidate]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspIMTemplateValidate] TO [public]
GO
