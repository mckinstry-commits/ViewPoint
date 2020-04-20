SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspVAUDGetCustomComboboxes]
  /* Gets all the custom combo boxes entered in DDCBc (custom table)
    Created:  7/13/07 JRK
    Inputs:
		None
    Returns:
		selected list of combobox names and descriptions (ComboType, Description)
		@msg 
  */
  	(@msg varchar(60) output)
  as
  set nocount on
  declare @rcode int
  select @rcode = 0
  
  select ComboType, [Description] from DDCBc with (nolock)
  
  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspVAUDGetCustomComboboxes] TO [public]
GO
