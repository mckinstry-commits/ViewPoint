SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  PROCEDURE [dbo].[vspValidateReportSecurity]  
/**************************************************
*  Returns the Access of Report for given User for given company
* Inputs:
*	@co				Selected Company
*   @reportpath		Relative path of SSRS Report 
*	@user			User name
*
*	Outputs:
*	@access		Access level 0 = Allowed, 1 = None, 2 = denied
*	@errmsg		Message
*
* Return code:
*	@rcode	0 = success, 1 = failure
*
****************************************************/    
  (@co bCompany = null, @reportpath varchar(512) = null,@user varchar(512) = null,@access tinyint output, @errmsg varchar(512) output)     
as        
        
set nocount on      
declare @rcode int, @reportID int 
   
if @co is null
	begin
	select @errmsg = 'Missing required input parameter: Company ', @rcode = 1
	goto vspexit
	end
	
-- initialize return params       
select @rcode = 0, @access = 0       
    
if @user = 'viewpointcs' goto vspexit	-- Viewpoint login has full access
    
-- Get Report ID from ReportPath     
select @reportID=ReportID    
from dbo.RPRTShared (nolock)    
where FileName='?ItemPath=' + REPLACE((REPLACE(@reportpath,'/','%2f')),'+',' ')    
      
select @access = Access        
from dbo.vRPRS (nolock)        
where Co = @co and ReportID = @reportID and SecurityGroup = -1 and VPUserName = @user

if @access = 0 goto vspexit		-- full access
if @access = 2	-- access denied
	begin
	select @errmsg = @user + ' has been denied access to Report '
	goto vspexit
	end

vspexit:
	if @rcode <> 0 select @errmsg = @errmsg + char(13) + char(10) + '[vspValidateReportSecurity]'
	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspValidateReportSecurity] TO [public]
GO
