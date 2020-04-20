SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE procedure [dbo].[vspVAWDSettingsGet]
  /************************************************************************
  * CREATED: 	MV 03/29/07 
  * MODIFIED:   CC 05/30/08 - Issue #128451 - Remove server options from Notifier, email sent from Viewpoint server. 
  *
  * Purpose of Stored Procedure:	To get the server settings from bWDSettings
  *									for frmVAWDNotifierServe
  *    
  * 
  *
  * returns 0 if successfull 
  * returns 1 
  *
  *************************************************************************/
       (@FromAddressValue varchar(55) output)   
  as
  set nocount on
  
    declare @rcode int
  
    select @rcode = 0
  -- get From Address value
	select @FromAddressValue = Value from WDSettings where Setting='FromAddress'
 
  return @rcode
  
  
  
 




GO
GRANT EXECUTE ON  [dbo].[vspVAWDSettingsGet] TO [public]
GO
