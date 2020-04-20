SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****************************************/
CREATE  proc [dbo].[vspPMJCCMUpdateJCCICheck]
/****************************************
 * Created By:	GF 05/24/2005
 * Modified By: GF 06/30/2009 - issue #132326
 *
 *
 * Called from PMContract before rec update to check JCCM fields to update to JCCI fields. Returns message
 * with changes if applicable. Following fields are currently check: Department, TaxCode, BillType, RetainagePct.
 * If the new values differ from old values, message is returned prompting user if the corresponding JCCI fields
 * should be updated.
 *
 *
 * Pass:
 * JCCo				JC Company
 * Contract			JC Contract
 * Department		Department assigned to contract
 * TaxCode			TaxCode assigned to contract
 * BillType			BillType assigned to contract
 * RetainagePct		RetainagePct assigned to contract
 * StartMth			Start Month
 *
 *
 * Returns:
 * updateyn flag
 * Message with list of JCCM changes
 *
 *
 **************************************/
(@jcco bCompany, @contract bContract, @department bDept, @taxcode bTaxCode, @billtype char(1),
 @retainagepct bPct, @startmth bMonth, @update varchar(1) output, @msg varchar(1000) = null output)
as
set nocount on

declare @rcode int, @jccm_department bDept, @jccm_taxcode bTaxCode, @jccm_billtype char(1),
		@jccm_retainagepct bPct, @jccm_startmth bMonth, @chrlf varchar(2)


select @rcode = 0, @update = 'N', @chrlf = char(13) + char(10)
select @msg = 'You have changed the following contract master fields.'  + @chrlf
select @msg = @msg + 'Would you like to update any existing contract items having the old value to the new value?' + @chrlf + @chrlf


-- -- -- if no contract items exist in bJCCI exit SP
if not exists(select top 1 1 from JCCI with (nolock) where JCCo=@jcco and Contract=@contract)
	begin
	goto bspexit
	end

-- -- -- get old JCCM contract data
select @jccm_department=Department, @jccm_taxcode=TaxCode, @jccm_billtype=DefaultBillType,
		@jccm_retainagepct=RetainagePCT, @jccm_startmth=StartMonth
from JCCM with (nolock) where JCCo=@jcco and Contract=@contract
if @@rowcount = 0 goto bspexit

-- -- -- no prompt needed if qualified fields not changed.
if isnull(@jccm_department,'') = isnull(@department,'') and isnull(@jccm_taxcode,'') = isnull(@taxcode,'')
	and isnull(@jccm_billtype,'') = isnull(@billtype,'') and isnull(@jccm_retainagepct,0) = isnull(@retainagepct,0)
	and isnull(@jccm_startmth,'') = isnull(@startmth,'')
	begin
	goto bspexit
	end


-- -- -- check each jccm field for a change
-- -- -- department
if isnull(@jccm_department,'') <> isnull(@department,'')
	begin
	select @msg = @msg + 'Department: Old Value: ' + isnull(@jccm_department,'') + space(10) + ' New Value: ' + isnull(@department,'') + @chrlf
	select @rcode = 1, @update = 'Y'
	end


-- -- -- Tax Code
if isnull(@jccm_taxcode,'') <> isnull(@taxcode,'')
	begin
	select @msg = @msg + 'TaxCode: Old Value: ' + isnull(@jccm_taxcode,'') + space(10) + ' New Value: ' + isnull(@taxcode,'') + @chrlf
	select @rcode = 1, @update = 'Y'
	end

-- -- -- Bill Type
if isnull(@jccm_billtype,'') <> isnull(@billtype,'')
	begin
	select @msg = @msg + 'BillType: Old Value: ' + isnull(@jccm_billtype,'') + space(10) + ' New Value: ' + isnull(@billtype,'') + @chrlf
	select @rcode = 1, @update = 'Y'
	end

-- -- -- retainage percent
if (isnull(@jccm_retainagepct,0) <> isnull(@retainagepct,0))
	begin
	select @msg = @msg + 'RetainagePct: Old Value:' + convert(varchar(15),isnull(@jccm_retainagepct,0)*100) + space(10) + ' New Value: ' + convert(varchar(15),isnull(@retainagepct,0)*100) + @chrlf
	select @rcode = 1, @update = 'Y'
	end

-- -- -- start month
if isnull(@jccm_startmth,'') <> isnull(@startmth,'')
	begin
	declare @oldstartmth varchar(20)
	select @oldstartmth = convert(varchar(2), DATEPART(month, isnull(@jccm_startmth,''))) + '/' + substring(convert(varchar(4),DATEPART(year, isnull(@jccm_startmth,''))),3,4)
	declare @newstartmth varchar(20)
	select @newstartmth = convert(varchar(2), DATEPART(month, isnull(@startmth,''))) + '/' + substring(convert(varchar(4),DATEPART(year, isnull(@startmth,''))),3,4)
	select @msg = @msg + 'Start Month: Old Value: ' + @oldstartmth + space(10) + ' New Value: ' + @newstartmth + @chrlf
	select @rcode = 1, @update = 'Y'
	end


bspexit:
  	if @rcode <> 0 
		select @msg = isnull(@msg,'')
	else
		select @msg = ''
	return @rcode




GO
GRANT EXECUTE ON  [dbo].[vspPMJCCMUpdateJCCICheck] TO [public]
GO
