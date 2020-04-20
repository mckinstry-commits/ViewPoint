SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.[vspPMPCORFQGet]    Script Date: 09/16/2005 ******/
CREATE  proc [dbo].[vspPMPCORFQGet]
/*************************************
 * Created By:	GF 08/08/2007
 * Modified by:	GF 03/21/2008 - issue #127299 added RFQ Date as output
*
 *
 * called from PMPCOS to get the max(RFQ) from PMRQ table
 *
 * Pass:
 * PMCo			PM Company
 * Project		PM Project
 * PCOType		PM PCO Type
 * PCO			PM PCO
 *
 * Returns:
 * max(RFQ)		maximum PM PCO RFQ from PMRQ
 *
 *
 * Success returns:
 *	0
 *
 * Error returns:
 * 
 *	1 and error message
 **************************************/
(@pmco bCompany, @project bJob, @pcotype bDocType, @pco bPCO,
 @rfq bDocument = null output, @rfqdate bDate = null output)
as
set nocount on

declare @rcode int

select @rcode = 0, @rfq = ''

---- get max(RFQ) from PMRQ
select @rfq = max(RFQ) from PMRQ
where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco
if @@rowcount = 0
	begin
	select @rfq = null
	goto bspexit
	end
---- get RFQ date from PMRQ
select @rfqdate=RFQDate from PMRQ with (nolock)
where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco and RFQ=@rfq



bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMPCORFQGet] TO [public]
GO
