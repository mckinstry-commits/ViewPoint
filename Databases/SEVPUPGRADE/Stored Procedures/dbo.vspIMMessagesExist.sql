SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspIMMessagesExist]
   /************************************************************************
   * CREATED:   RT 03/08/2006
   * MODIFIED:    
   *
   * Purpose of Stored Procedure
   *
   *    Tells whether error messages exist for the given import.
   *    
   *           
   * Notes about Stored Procedure
   * 
   * returns 0 for no, 1 for yes
   *  
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
   (@importid varchar(20), @msg varchar(60) output)
   
   as
   set nocount on
   
    declare @rcode int
    select @rcode = 1
   
   	if @importid is null
   	begin
   		select @msg = 'Missing ImportId.', @rcode = 1
   		goto bspexit
   	end
   	
	if exists(select 1 from IMWM with (nolock) where ImportId = @importid and isnull(Error,0) <> 9999)
    	select @rcode = 0
	else
		select @rcode = 1

   bspexit:
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspIMMessagesExist] TO [public]
GO
