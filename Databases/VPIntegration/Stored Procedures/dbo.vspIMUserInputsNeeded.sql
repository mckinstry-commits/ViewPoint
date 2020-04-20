SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[vspIMUserInputsNeeded]
   /************************************************************************
   * CREATED:   RT 03/08/2006
   * MODIFIED:    
   *
   * Purpose of Stored Procedure
   *
   *    Tells whether any identifiers are set to prompt on import.
   *    
   *           
   * Notes about Stored Procedure
   * 
   * returns 0 for yes, 1 for no
   *  
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
   (@Template varchar(10), @msg varchar(60) output)
   
   as
   set nocount on
   
    declare @rcode int
    select @rcode = 1
   
   	if @Template is null
   	begin
   		select @msg = 'Missing Template.', @rcode = 1
   		goto bspexit
   	end
   	
	if exists(select 1 from IMTD with (nolock) where ImportTemplate = @Template and ImportPromptYN = 'Y')
    	select @rcode = 0
	else
		select @rcode = 1

   bspexit:
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspIMUserInputsNeeded] TO [public]
GO
