SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspARFCTypeVal    Script Date: 8/28/99 9:34:10 AM ******/
CREATE PROC [dbo].[vspARFCTypeVal]
/*********************************************************************************************
* CREATED BY: TJL   12/15/04
* MODIFIED By : 
* 
*
* USAGE:
*   Validate Finance Charge Type input depending upon the Statement option selected in ARCO
*
* INPUT PARAMETERS
*   @stmttype:		Statement Type - Either Open Item or Balance Forward
*   @fctype:		Finance Charge Type
*   
*           
* OUTPUT PARAMETERS
*   @msg      error message if error occurs.
*
* RETURN VALUE
*   0         Success
*   1         Failure
**********************************************************************************************/
(@stmttype char(1) = null, @fctype char(1) = null, @msg varchar(250) output)
as
set nocount on

declare @rcode int

select @rcode = 0

if @stmttype is null or @stmttype not in ('O', 'B')
	begin
  	select @msg = 'Statement Type must be Open Item or Balance Fwd!', @rcode = 1
  	goto vspexit
  	end
if @fctype is null
	begin
	select @msg = 'Missing Finance Charge Type!', @rcode = 1
	goto vspexit
	end
  
/* Validate FC Type selection relative to Statement Type selection. */
if @stmttype = 'O'
	begin
	if @fctype not in ('A', 'I', 'R', 'N')
		begin
		select @msg = 'FinanceChg Type must be (A, I, R or N) when using Open Item statements!', @rcode = 1
		goto vspexit
		end 
	end
else
	begin
	if @fctype not in ('A', 'N')
		begin
		select @msg = 'FinanceChg Type must be (A or N) when using Balance Forward statements!', @rcode = 1
		goto vspexit
		end
	end

vspexit:
if @rcode <> 0 select @msg = @msg	--+ char(13) + char(10) + '[dbo.vspARFCTypeVal]'
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspARFCTypeVal] TO [public]
GO
