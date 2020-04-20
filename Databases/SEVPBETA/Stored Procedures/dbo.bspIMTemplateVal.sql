SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspIMTemplateVal    Script Date: 8/28/99 9:34:57 AM ******/
   CREATE    proc [dbo].[bspIMTemplateVal]
   /***********************************************************
    * CREATED BY: GR   08/25/99
    * MODIFIED By : MH 12/29/99 - adding @btkroutine and @form output parameters
    *               MH 5/5/00 - adding @filetype, @delim, and @otherdelim output parameters
    *               MH 5/18/01 - adding @rectypecol output parameter
    *
    * USAGE:
    * validates template
    *
    * INPUT PARAMETERS
    *
    *   template
    *
    * OUTPUT PARAMETERS
    *    Default routine
    *    Form
    *    Error Message if error occurs
    * RETURN VALUE
    *   0 Success
    *   1 fail
    ************************************************************************/
   	(@template varchar(10), @btkroutine varchar(30) output, @form varchar(30) output, @filetype varchar(1) output,
           @delim varchar(1) output, @otherdelim varchar(2) output, @importroutine varchar(30) output, @rectypecol int output, 
   		@msg varchar(60) output)
   
   as
   set nocount on
   declare @rcode int, @validcnt int
   select @rcode = 0
   
   if @template is null
   
   	begin
   	select @msg = 'Missing Template!', @rcode = 1
   	goto bspexit
   	end
   
   select @validcnt=Count(*) from IMTH
   	where ImportTemplate=@template
   if @validcnt=0
     begin
       select @msg = 'Template not on file!', @rcode = 1
       goto bspexit
     end
   

   select @filetype = FileType, @delim = Delimiter, @otherdelim = OtherDelim, @rectypecol = RecordTypeCol,
   @msg=Description, @btkroutine = BidtekRoutine, @form = Form, @importroutine = ImportRoutine
   from IMTH with (nolock)
   where ImportTemplate = @template

   bspexit:
   	if @rcode<>0 select @msg=isnull(@msg,'Template Val') + char(13) + char(10) + '[bspIMTemplateVal]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspIMTemplateVal] TO [public]
GO
