SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    proc [dbo].[vspDDFormPropTabLookup]
  /***********************************************************
   * CREATED BY:  MJ 
   * MODIFIED By : 
   *
   * USAGE: Used to find newly created tab page for form properties form.
   * Used on Forms: frmFormProperties
   *
   * INPUT PARAMETERS
  
   *   Form        Form new tab was added to
   *   @msg        error message if something went wrong
   * RETURN VALUE
   *   0 Success
   *   1 fail
   ************************************************************************/
  	(@form varchar(30) = null, @errmsg varchar(60) output)
  as
  set nocount on
  declare @rcode int
  select @rcode = 0
  
   

begin
	--SELECT LoadSeq from DDFTShared where Form = @form and Tab =
	 SELECT MAX(Tab) FROM DDFTShared WHERE Form  = @form
End

 if @@rowcount = 0
  	begin
  	select @errmsg = 'Could not find new tab!', @rcode = 1
  	end
  
  vspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDFormPropTabLookup] TO [public]
GO
