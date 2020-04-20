SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspSLUpdateSLWIHist    ******/
CREATE proc [dbo].[vspSLUpdateSLWIHist]
/***********************************************************
* CREATED BY: TJL 02/23/09 - Issue #129889, SL Claims and Certifications
* MODIFIED By : GF 06/25/2010 - issue #135813 expanded SL to varchar(30)
*				GF 11/15/2012 TK-19330 SL Claim clean up
*
* USAGE:
* 	Called 'bspSLUpdateAP' and 'vspSLUpdateAPUnapp' to copy SL Worksheet Item values
*	into SL Worksheet Item history table
*
*  INPUT PARAMETERS
*	    @co			SL/AP Co#
*   	@slusername	Worksheet UserName on header record
*   	@sl			SubContract
*		@slitem		SubContract Item
*
* OUTPUT PARAMETERS
*   	@msg      	error message if error occurs
*
* RETURN VALUE
*   0         success
*   1         Failure
***********************************************************/
(@co bCompany = null, @slusername bVPUserName = null, @sl VARCHAR(30) = null, @slitem bItem, @msg varchar(60) output)

as

set nocount on

declare @rcode INT
----TK-19330
SET @rcode = 0

if @co is null
	begin
	select @msg = 'Missing SL Company.', @rcode = 1
	goto vspexit
	end
if @slusername is null
	begin
	select @msg = 'Missing UserName on record.', @rcode = 1
	goto vspexit
	end
if @sl is null
	begin
	select @msg = 'Missing SubContract.', @rcode = 1
	goto vspexit
	end
if @slitem is null
	begin
	select @msg = 'Missing SubContract Item.', @rcode = 1
	goto vspexit
	end

----TK-19330 Insert record into SLWHHist table
insert into vSLWIHist (i.SLCo, i.UserName, i.SL, i.SLItem, i.ItemType, i.[Description], i.PhaseGroup, i.Phase, i.UM, i.CurUnits, i.CurUnitCost, 
	i.CurCost, i.PrevWCUnits, i.PrevWCCost, i.WCUnits, i.WCCost, i.WCRetPct, i.WCRetAmt, i.PrevSM, i.Purchased, i.Installed, i.SMRetPct, i.SMRetAmt, 
	i.LineDesc,	i.VendorGroup, i.Supplier, i.BillMonth, i.BillNumber, i.BillChangedYN, i.WCPctComplete, i.WCToDate, i.WCToDateUnits, i.Notes, 
	i.ReasonCode, i.SLKeyID)
select i.SLCo, i.UserName, i.SL, i.SLItem, i.ItemType, i.[Description], i.PhaseGroup, i.Phase, i.UM, i.CurUnits, i.CurUnitCost, 
	i.CurCost, i.PrevWCUnits, i.PrevWCCost, i.WCUnits, i.WCCost, i.WCRetPct, i.WCRetAmt, i.PrevSM, i.Purchased, i.Installed, i.SMRetPct, i.SMRetAmt, 
	i.LineDesc,	i.VendorGroup, i.Supplier, i.BillMonth, i.BillNumber, i.BillChangedYN, i.WCPctComplete, i.WCToDate, i.WCToDateUnits, i.Notes, 
	i.ReasonCode, h.KeyID
from bSLWI i with (nolock)
join bSLWH h with (nolock) on h.SLCo = i.SLCo and h.UserName = i.UserName and h.SL = i.SL
where i.SLCo = @co and i.UserName = @slusername and i.SL = @sl and i.SLItem = @slitem
if @@rowcount = 0
	begin
	select @msg = 'SL Worksheet Item was not saved to History table.', @rcode = 1
	goto vspexit
	end

vspexit:

return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspSLUpdateSLWIHist] TO [public]
GO
