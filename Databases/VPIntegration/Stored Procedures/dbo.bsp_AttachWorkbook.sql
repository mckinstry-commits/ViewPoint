SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bsp_AttachWorkbook] 
   /***************************************************
    * Created: GG 05/30/02
    * Modified:
    *
    * Usage:
    *	Links an Excel Workbook with the current SQL database to allow 
    *	heterogenous queries.
    * 	Example: Exec bsp_AttachWorkbook 'c:\temp\orders.xls', 'MyOrders', @msg output
    *			Select * from MyOrders...Worksheet1 
    *
    * Inputs:
    *	@path				Path to Excel Workbook
    *	@remoteserver		Name of linked server to be used for Excel Workbook
    *
    * Output:
    *	@msg				Error message
    *
    * Return Code:
    *	@rcode				0 = success, 1 = failure
    *
    ************************************************************/
       @path nvarchar(4000) = null, @remoteserver nvarchar(128) = null, @msg varchar(255) output
   as
   
   declare @rcode int
   
   set nocount on
   
   select @rcode = 0, @msg = 'Remote server has been linked.'
   
   if @path is null
   	begin
   	select @msg = 'Missing path to Excel Workbook', @rcode = 1
   	goto bspexit
   	end
   if @remoteserver is null
   	begin
   	select @msg = 'Must provide a name for the remote server.', @rcode = 1
   	goto bspexit
   	end
   
   -- adds linked server to allow queries
   exec @rcode = sp_addlinkedserver @server = @remoteserver, @srvproduct = 'Microsoft Excel Workbook',
   	@provider = 'Microsoft.Jet.OLEDB.4.0', @datasrc = @path, @provstr = 'Excel 8.0' 
   if @rcode <> 0
   	begin
   	select @msg = 'Unable to link Excel Workbook ' + @remoteserver + ' at ' + @path
   	goto bspexit
   	end
   
   -- maps logins to linked server
   exec @rcode =  sp_addlinkedsrvlogin @remoteserver, 'false'	-- no login required
   if @rcode = 1
   	begin
   	select @msg = 'Unable to map logins to Excel Workbook ' + @remoteserver + ' at ' + @path
   	goto bspexit
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bsp_AttachWorkbook] TO [public]
GO
