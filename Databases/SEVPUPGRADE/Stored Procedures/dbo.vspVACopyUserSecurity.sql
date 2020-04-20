SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE    procedure [dbo].[vspVACopyUserSecurity]
  
  /**************************************************
  *
  * Created By:  MJ 04/07/06 
  *
  *	Modified By: JonathanP 05/22/08 - Issue #127459. Now copies attachment type information.
  *			     AL 7/22/07 - Issue #128987 Added joins to shared views.
  *				 AL 12/8/08 - Issue #131035 Added VP QuerySecurity 
  * 			 AL 2/2/08	- Issue #131035 Added VPCanvasTemplateSecurity
  *				 JonathanP 02/25/09 - #132390 - Updated to handle attachment security level column in DDFS
  * USAGE:
  *
  * Copies module, form, tab, and report security for one user from one company to another.
  *
  * INPUT PARAMETERS
  *    FromCo - Company from which to copy user security.
  *	 ToCo   - Company to which user security will be copied.
  *    Username - User for whom security will be copied.
  *	 Replace - "Y" to replace destination company security.
  *
  * RETURN PARAMETERS
  *    Error Message and
  *	 0 for success, or
  *    1 for failure
  *
  *************************************************/
  (@FromCo smallint, @ToCo smallint, @Username bVPUserName, @Replace bYN, @msg varchar(255) = null output)
  
  AS
set nocount on
  
  declare @rcode int
  
  select @rcode = 0
  
  --check for all required parameters
  if @FromCo is null
  begin
  	select @rcode = 1, @msg = 'From Company cannot be null'
  	goto bspexit
  end
  
  if @ToCo is null
  
  begin
  	select @rcode = 1, @msg = 'To Company cannot be null'
  	goto bspexit
  end
  
  if @Username is null
  begin
  	select @rcode = 1, @msg = 'Username cannot be null'
  	goto bspexit
  end
  
  if @FromCo = @ToCo
  begin
 	select @rcode = 1, @msg = 'From Company and To Company cannot be the same.'
 	goto bspexit
  end
 
  if @Replace = 'Y' 
  begin
  --delete current security in the ToCo
  	delete from dbo.vDDTS
  	where VPUserName = @Username and Co = @ToCo
  
  	delete from dbo.vDDFS
  	where VPUserName = @Username and Co = @ToCo
  
  	delete from dbo.vRPRS
  	where VPUserName = @Username and Co = @ToCo
  	
  	delete from dbo.vVAAttachmentTypeSecurity
  	where VPUserName = @Username and Co = @ToCo
  	
  	delete from dbo.VPQuerySecurity
  	where VPUserName = @Username and Co = @ToCo
  end
  
    
  --copy Form Security
  
  	insert into vDDFS(Co,f.Form, SecurityGroup, VPUserName,Access,RecAdd,RecUpdate,RecDelete, AttachmentSecurityLevel)
  	select @ToCo,f.Form,-1,VPUserName,Access,RecAdd,RecUpdate,RecDelete, f.AttachmentSecurityLevel
	 from dbo.vDDFS f (nolock)
	Join dbo.DDFHShared s(nolock)
	on s.Form = f.Form
  	where VPUserName = @Username and Co = @FromCo and SecurityGroup = -1
  	and f.Form not in (select Form from dbo.vDDFS (nolock) where VPUserName = @Username and Co = @ToCo and SecurityGroup = -1)
  	
  --copy Tab Security
  
  	insert into vDDTS(Co,Form,Tab,SecurityGroup,VPUserName,Access)
  	select @ToCo,a.Form,a.Tab,-1,VPUserName,Access
	from dbo.vDDTS a (nolock)
	Join dbo.DDFTShared s (nolock)
	on s.Form = a.Form and s.Tab = a.Tab
  	where a.VPUserName = @Username and a.Co = @FromCo and SecurityGroup = -1
  	and not exists (select 1 from dbo.vDDTS b (nolock) where b.VPUserName = @Username and b.Co = @ToCo
  	and b.Form = a.Form and b.Tab = a.Tab and b.SecurityGroup = -1)
  
  
  --copy Report Security
  
  	insert into dbo.vRPRS(Co,ReportID,SecurityGroup,VPUserName,Access)
  	select @ToCo,ReportID,-1,VPUserName,Access
	from dbo.vRPRS (nolock)
  	where VPUserName = @Username and Co = @FromCo and SecurityGroup = -1
  	and ReportID not in (select ReportID from dbo.vRPRS (nolock) where VPUserName = @Username and Co = @ToCo and SecurityGroup = -1)
  
  
  --copy Attachment Type Security
  
  	insert into dbo.vVAAttachmentTypeSecurity(Co,AttachmentTypeID,SecurityGroup,VPUserName,Access)
  	select @ToCo,AttachmentTypeID,-1,VPUserName,Access
	from dbo.vVAAttachmentTypeSecurity (nolock)
  	where VPUserName = @Username and Co = @FromCo and SecurityGroup = -1
  	and AttachmentTypeID not in (select AttachmentTypeID from dbo.vVAAttachmentTypeSecurity (nolock) where VPUserName = @Username and Co = @ToCo and SecurityGroup = -1)
  
  
  --copy VP Query Security

				insert into dbo.VPQuerySecurity(Co, QueryName, SecurityGroup, VPUserName, Access)
				select @ToCo, QueryName, -1, VPUserName, Access
				from dbo.VPQuerySecurity (nolock)
				where VPUserName = @Username and Co = @FromCo and SecurityGroup = -1
				and QueryName not in (select QueryName from dbo.VPQuerySecurity (nolock) where VPUserName = @Username and Co = @ToCo and SecurityGroup = -1)  
    
  --copy VP Template Security

				insert into dbo.VPCanvasTemplateSecurity(Co, TemplateName, SecurityGroup, VPUserName, Access)
				select @ToCo, TemplateName, -1, VPUserName, Access
				from dbo.VPCanvasTemplateSecurity (nolock)
				where VPUserName = @Username and Co = @FromCo and SecurityGroup = -1
				and TemplateName not in (select TemplateName from dbo.VPCanvasTemplateSecurity (nolock) where VPUserName = @Username and Co = @ToCo and SecurityGroup = -1)
  
  
  bspexit:
  
  return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspVACopyUserSecurity] TO [public]
GO
