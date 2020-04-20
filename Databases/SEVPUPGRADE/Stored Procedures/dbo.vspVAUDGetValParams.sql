SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO









CREATE     proc [dbo].[vspVAUDGetValParams]
/********************************
* Created: 	JRK 7/12/07
* Modified:	
*
* Get sql parameters for a stored proc.
* Used by the UD Custom Field wizard but it could be used for any stored proc.
*
* Input:
*	@valproc is the name of a stored proc.  Not null.	
*
* Output:
*	@msg will be '' if success or an error msg.
*	
* Return code:
*	0 = success, 1 = failure
*
*********************************/
(@valproc varchar(60) = null, @msg varchar(512) output)
as
	
set nocount on
	
declare @rcode int
	
select @rcode = 0, @msg = ''

if @valproc is null
begin
	select @rcode = 1
	select @msg = 'Parameter @valproc is missing!'
	goto bspexit
end

exec sp_sproc_columns @procedure_name = @valproc
if @@rowcount = 0
begin
	select @rcode = 1
	select @msg = 'No parameters for stored procedure ' + @valproc + ' or no such stored procedure.'
	goto bspexit
end


bspexit:
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspVAUDGetValParams] TO [public]
GO
