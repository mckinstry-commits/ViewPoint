SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE proc [dbo].[vspDDFormVal]
  /***********************************************************
   * CREATED BY: kb 12/21/4
   * MODIFIED By : 
   *		CC	07/14/09 - #129922 - Added link for form header to culture text
   *
   * USAGE:
   * validates Form
   *
   * INPUT PARAMETERS
  
   *   Form         Form to validate
   * INPUT PARAMETERS
   *   @FormTable         Main table from DDFH
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
  	goto bspexit
  	end
  
  select @FormTable=ViewName, @msg = ISNULL(CultureText.CultureText, vDDFH.Title)
  from vDDFH
  LEFT OUTER JOIN DDCTShared AS CultureText ON CultureText.CultureID = @culture AND CultureText.TextID = vDDFH.TitleID
  where Form = @Form
  if @@rowcount = 0
  	begin
		select @msg = 'Form not on file!', @rcode = 1
	end
  
  bspexit:
  	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspDDFormVal] TO [public]
GO
