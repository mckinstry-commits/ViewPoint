SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspHQUDAddFormNameVal]
  /***********************************************************
   * CREATED BY: mj 10/26/04
   * MODIFIED By :	CC	07/14/09 - #129922 - Added link for form header to culture text
   *				CC  06/08/10 - #139368 - Add override for custom field view
   *
   * USAGE:
   * Validates form by reading from DDFHShared where AllowCustomControls = 'Y'.
   * Returns data about the form.
   *
   * INPUT PARAMETERS
   *   @form			Form to look up.
   * OUTPUT PARAMETERS
   *   @msg				Title of form or error message if something went wrong
   * RETURN VALUE
   *   0 Success
   *   1 fail
   ************************************************************************/
  	(@form varchar(60) = null, @culture INT = NULL, @msg varchar(30) output)
  as
set nocount on
  declare @rcode int
  select @rcode = 0 -- Indicate success by default.
  
	if @form is null
  	begin
  		select @msg = 'Missing Form Title!', @rcode = 1
  		goto bspexit
  	end

	Select Form, ISNULL(CultureText.CultureText, DDFHShared.Title) AS Title, ISNULL(CustomFieldView,ViewName) AS ViewName, CustomFieldTable 
	from DDFHShared 
	LEFT OUTER JOIN DDCTShared AS CultureText ON CultureText.CultureID = @culture AND CultureText.TextID = DDFHShared.TitleID
	where Form = @form and AllowCustomFields='Y'

	if @@rowcount = 0
  		select @msg = 'Form not on file!', @rcode = 1
  
bspexit:
  	return @rcode



GO
GRANT EXECUTE ON  [dbo].[vspHQUDAddFormNameVal] TO [public]
GO
