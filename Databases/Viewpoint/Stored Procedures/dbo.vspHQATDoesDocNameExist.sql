SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[vspHQATDoesDocNameExist]
   /*******************************************************************************
   * CREATED BY: JonathanP 08/28/07
   * MODIFIED BY:
   *
   * Checks if a given string exists in the doc name column of HQAT.
   *
   * Inputs:
   *			@docNameToCheck - Check if this string exists in HQAT's DocName column.
   *
   * Outputs:
   *     	    @docNameCount - The number of times the given string occurs in the DocName column.
   *
   * Error returns:
   *  1 and error message
   *
   ********************************************************************************/
   (@docNameToCheck varchar(512), @docNameCount int output, @errorMessage varchar(255) output)
   as

	set nocount on
	declare @returnCode int
	select @returnCode=0

	select @docNameCount = count(DocName) from HQAT where DocName = @docNameToCheck	

	return @returnCode

GO
GRANT EXECUTE ON  [dbo].[vspHQATDoesDocNameExist] TO [public]
GO
