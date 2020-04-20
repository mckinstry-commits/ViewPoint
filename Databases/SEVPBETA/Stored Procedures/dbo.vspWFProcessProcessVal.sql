SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE  proc [dbo].[vspWFProcessProcessVal]
/***********************************************************
* CREATED BY:	JG	3/12/2012
* MODIFIED BY:	JG	3/13/2012 - TK-00000 - Modified based on DocType changes.
*				GP	6/20/2012 - TK-15929 Added check for active flag
*				
*				
* USAGE:
*	Used to validate WF Process Process valid.
*
*
* RETURN VALUE
*   0         Success
*   1         Failure
*****************************************************/ 

(@Process varchar(20), @DocType VARCHAR(10), @msg varchar(255) output)
as
set nocount on

declare @rcode int, @Active bYN
set @rcode = 0


--VALIDATION
if @Process is null
begin
	select @msg = 'Missing Process.'
	return 1
end



SELECT TOP 1 @msg = [Description], @Active = Active
FROM WFProcess
WHERE Process = @Process
	AND ((dbo.vpfIsNullOrEmpty(@DocType) |
		dbo.vpfIsNullOrEmpty(DocType) = 1)
	OR @DocType = DocType)

IF @@ROWCOUNT = 0
BEGIN
	select @msg = 'The process entered is an invalid WF Process.'
	return 1
END

IF @Active = 'N'
BEGIN
	SELECT @msg = 'The process entered is inactive.'
	RETURN 1
END



GO
GRANT EXECUTE ON  [dbo].[vspWFProcessProcessVal] TO [public]
GO
