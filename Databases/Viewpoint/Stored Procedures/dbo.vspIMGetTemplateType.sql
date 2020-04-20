SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspIMGetTemplateType]
   /***********************************************************
    * CREATED BY: RT   03/07/06
    * MODIFIED BY :
    *
    * USAGE:
    *   Returns FileType for given Template.
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
   	(@template varchar(10), @filetype varchar(1) output, @msg varchar(60) output)
   
   as
   set nocount on
   declare @rcode int, @validcnt int
   select @rcode = 0
      
   if @template is null
       begin
       select @msg = 'Missing Template!', @rcode = 1
       goto bspexit
       end
      
   select @validcnt=Count(*) from IMTD where ImportTemplate=@template
   if @validcnt=0
     begin
       select @msg = 'Template not on file!', @rcode = 1
       goto bspexit
     end
   
   select @filetype=FileType from IMTH where ImportTemplate=@template 
   
   bspexit:
   	if @rcode<>0 select @msg=isnull(@msg,'Error') + char(13) + char(10) + '[vspIMGetTemplateType]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspIMGetTemplateType] TO [public]
GO
