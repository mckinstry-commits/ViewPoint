SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  proc [dbo].[vspWFProcessCopyVal]
/***********************************************************
* CREATED BY:	GP	2/29/2012
* MODIFIED BY:	JG	3/09/2012 - TK-13110 - Renamed Type to Document Type.
*				JG	3/13/2012 - TK-00000 - Removed Document Type.
*				
* USAGE:
*	Used in WF Process Copy to validate the Process field.
*
* INPUT PARAMETERS  
*   Process - new Process value
*
* OUTPUT PARAMETERS
*	NewRecordKeyID - KeyID of newly created record
*   msg
*
* RETURN VALUE
*   0         Success
*   1         Failure
*****************************************************/ 

(@Process varchar(20), @msg varchar(255) output)
as
set nocount on

declare @rcode int
set @rcode = 0


--VALIDATION
if @Process is null
begin
	select @msg = 'Missing Process.', @rcode = 1
	return @rcode
end

if exists (select 1 from dbo.vWFProcess where Process = @Process)
begin
	select @msg = 'The record you are copying to already exists.', @rcode = 1
	return @rcode
end
GO
GRANT EXECUTE ON  [dbo].[vspWFProcessCopyVal] TO [public]
GO
