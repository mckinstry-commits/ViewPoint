SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE proc [dbo].[vspDDFormValShared]
  /***********************************************************
   * CREATED BY: tl 12/21/4
   * MODIFIED By : CC	07/14/09 - #129922 - Added link for form header to culture text
   *
   * USAGE: Used to verify forms 
   * Used on Forms: RPFD, RPFR, RPRTForms, RPRTFrmRptParamDflt
   *
   * INPUT PARAMETERS
  
   *   Form         Form to validate
   * INPUT PARAMETERS
   *   @FormTable         Main table from DDFHShared
   *   @msg        error message if something went wrong
   * RETURN VALUE
   *   0 Success
   *   1 fail
   ************************************************************************/
  	(@Form varchar(30) = null, @FormTable varchar(30) output , @culture INT = NULL, @msg varchar(60) output)
  as
  set nocount on
  declare @rcode int
  select @rcode = 0
  
  
  if @Form is null
  	begin
  	select @msg = 'Missing Form!', @rcode = 1
  	goto vspexit
  	end
  
  select @FormTable=ViewName, @msg = ISNULL(CultureText.CultureText, DDFHShared.Title)
  from dbo.DDFHShared
  LEFT OUTER JOIN DDCTShared AS CultureText ON CultureText.CultureID = @culture AND CultureText.TextID = DDFHShared.TitleID
  where Form = @Form
  if @@rowcount = 0
  	begin
  	select @msg = 'Form not on file!', @rcode = 1
  	end
  
  vspexit:
  	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspDDFormValShared] TO [public]
GO
