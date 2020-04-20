SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE procedure [dbo].[vspVAWDSettingsSet]
  /************************************************************************
  * CREATED: 	MV 03/29/07 
  * MODIFIED:   CC 05/30/08 - Issue #128451 - Remove server setting from Notifer. 
  *
  * Purpose of Stored Procedure:	To set the server settings to bWDSettings
  *									from frmVAWDNotifierServe
  *    
  * 
  *
  * returns 0 if successfull 
  * returns 1 
  *
  *************************************************************************/
       (@FromAddressValue varchar(55)= null, @msg varchar(250) output)   
  as
  set nocount on
  
    declare @rcode int
  
    select @rcode = 0
  -- update From Address value
	if exists(select 1 from WDSettings where Setting='FromAddress')
		begin
			update WDSettings Set Value = @FromAddressValue Where Setting = 'FromAddress'
			if @@rowcount = 0
			begin
				select @msg = 'Notifer Address did not update.', @rcode =1
			end
		end
	else
		begin
			insert into WDSettings Values('FromAddress',@FromAddressValue)
			if @@rowcount = 0
			begin
				select @msg = 'Notifer Address was not added.', @rcode =1
			end
		end
  
  return @rcode
  
  
  
 




GO
GRANT EXECUTE ON  [dbo].[vspVAWDSettingsSet] TO [public]
GO
