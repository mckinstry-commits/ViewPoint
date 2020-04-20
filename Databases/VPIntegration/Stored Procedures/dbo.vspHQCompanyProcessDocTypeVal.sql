SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspHQCompanyProcessDocTypeVal] 
/************************************************************************
* Created:	JG	3/16/2012
* Modified: 
*
* Usage:
* Checks the existence of Mod/Company/DocType usage.
*
* Inputs:
*
* Outputs:
*	@msg			Error message
*
* Return code:
*	0 = success, 1 = error w/messsge
*
**************************************************************************/
(@mod CHAR(2), @co bCompany = null, @doctype VARCHAR(10) = null,  @process VARCHAR(20) = NULL, @msg varchar(512) output)

as

set nocount on 

declare @rcode INTEGER, @procdoctype VARCHAR(10), @procprocess VARCHAR(20)

select @rcode = 0

if @process is null
begin
	select @msg = 'Missing Process!',@rcode = 1
	goto vspexit
end

if @mod is null
begin
	select @msg = 'Missing Module!',@rcode = 1
	goto vspexit
end
	
if @co is null
begin
	select @msg = 'Missing Company!',@rcode = 1
	goto vspexit
end

if @doctype is null
begin
	select @msg = 'Missing Document Type!',@rcode = 1
	goto vspexit
end

SELECT @procdoctype = DocType
FROM dbo.WFProcess 
WHERE Process = @process 
	AND @doctype <> CASE WHEN dbo.vpfIsNullOrEmpty(DocType) = 0 THEN DocType ELSE @doctype END
	
IF @@ROWCOUNT > 0
BEGIN
	select @msg = 'The Workflow Process is set to ' + @procdoctype + '. Cannot change document type!',@rcode = 1
	goto vspexit
END

SELECT @procprocess = Process
FROM dbo.HQCompanyProcess
WHERE [Mod] = @mod 
	AND HQCo = @co 
	AND DocType = @doctype

IF @@ROWCOUNT > 0
BEGIN
	select @msg = 'Module/Company/Document Type combination is already defined for Process: ' + @procprocess + '!',@rcode = 1
	goto vspexit
END	

vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHQCompanyProcessDocTypeVal] TO [public]
GO
