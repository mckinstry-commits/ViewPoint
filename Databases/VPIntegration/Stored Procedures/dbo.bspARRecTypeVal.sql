SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspARRecTypeVal    Script Date: 8/28/99 9:32:36 AM ******/
CREATE  PROC [dbo].[bspARRecTypeVal]
/***********************************************************
* CREATED BY: CJW 5/8/97
* MODIFIED By : CJW 5/8/97
*		TJL 01/12/07 - Issue #28228, 6x Recode JBTMBills.  Removed Stored Proc name from error msg
*
* USAGE:
* 	validates Receivable Types in ARRT
*
* INPUT PARAMETERS
*   AR Company
*   Receivable Type to validate
*
* OUTPUT PARAMETERS
*   @msg      Description or error message
* RETURN VALUE
*   0         success
*   1         failure
*****************************************************/
(@arco bCompany = null, @rectype int = null,  @msg varchar(255) output)
as
set nocount on
declare @rcode int
select @rcode = 0
if @arco is null
	begin
	select @msg = 'Missing AR Company!', @rcode = 1
	goto bspexit
	end
if @rectype is null
	begin
	select @msg = 'Missing Receivable Type!', @rcode = 1
	goto bspexit
	end
if @rectype is not null
	begin
 	select @msg = Abbrev from ARRT where RecType = @rectype and ARCo = @arco
 	if @@rowcount = 0
		begin
		select @msg = 'Receivable Type not valid!', @rcode = 1
		goto bspexit
		end
	end
bspexit:
if @rcode<>0 select @msg=@msg			--+ char(13) + char(10) + '[bspARRecTypeVal]'
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspARRecTypeVal] TO [public]
GO
