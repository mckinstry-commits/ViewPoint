SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspARExcludeInvGridFill    Script Date: 11/3/05 ******/
CREATE proc [dbo].[vspARExcludeFCClearAll]
/****************************************************************
* CREATED BY	: TJL 11/08/05 - Issue #28323, 6x recode
* 
*
* USAGE:
* 	Reset ExcludeFC column to 'N' for this Customer where set to 'Y'
*
* INPUT PARAMETERS
*	@arco		-	AR Company
*	@custgroup	-	Customer Group
*	@customer	-	Customer
*
* OUTPUT PARAMETERS
*   @errmsg
*
*****************************************************************/
(@arco bCompany = null, @custgroup bGroup = null, @customer bCustomer = null,
	@errmsg varchar(256) output)

as
set nocount on

declare @rcode int
select @rcode=0
  
if @arco is null
	begin
  	select @errmsg = 'AR Company is missing.', @rcode = 1
  	goto vspexit
  	end
if @custgroup is null
  	begin
  	select @errmsg = 'AR Customer Group is missing.', @rcode = 1
  	goto vspexit
  	end
if @customer is null
  	begin
  	select @errmsg = 'AR Customer is missing.', @rcode = 1
  	goto vspexit
  	end

update bARTH
set ExcludeFC = 'N'
where ARCo = @arco and CustGroup = @custgroup and Customer = @customer
  	and Mth = AppliedMth and ARTrans = AppliedTrans
  	and ARTransType in ('I', 'F', 'R')

vspexit:
if @rcode <> 0 select @errmsg = @errmsg		--+ char(13) + char(10) + char(13) + char(10) + '[vspARExcludeFCClearAll]'
  
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspARExcludeFCClearAll] TO [public]
GO
