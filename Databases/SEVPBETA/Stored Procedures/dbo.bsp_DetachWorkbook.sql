SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bsp_DetachWorkbook] 
   /***************************************************
    * Created: GG 05/30/02
    * Modified:
    *
    * Usage:
    *	Unlinks an Excel Workbook from the current SQL database 
    *
    * Inputs:
    *	@remoteserver		Name of linked server used for Excel Workbook
    *
    * Output:
    *	@msg				Error message
    *
    * Return Code:
    *	@rcode				0 = success, 1 = failure
    *
    ************************************************************/
       @remoteserver nvarchar(128) = null, @msg varchar(255) output
   as
   
   declare @rcode int
   
   set nocount on
   
   select @rcode = 0, @msg = 'Remote server has been removed.'
   
   if @remoteserver is null
   	begin
   	select @msg = 'Must provide linked server name.', @rcode = 1
   	goto bspexit
   	end
   
   -- drop linked server and all associated logins
   exec @rcode = sp_dropserver @remoteserver, 'droplogins'
   if @rcode <> 0 
   	begin
   	select @msg = 'Unable to drop linked server.'
   	goto bspexit
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bsp_DetachWorkbook] TO [public]
GO
