SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMPCOAddonRevItem    Script Date: 8/28/99 9:33:05 AM ******/
CREATE proc [dbo].[vspPMPCOAddonRevItem]
/***********************************************************
 * CREATED BY:	GF 04/28/2008 - issue #22100 Project Addon Revenue
 * MODIFIED BY:	GF 07/14/2008 - issue #128966 check for @manorappr = 'X' for PCO Header approval
 *				GF 10/30/2008 - issue #130772 expanded description to 60 characters
 *				GF 12/07/2008 - issue #131350 need to reset variables used to get next aco item when more than one revenue item
 *				GF 04/20/2009 - issue #132326 JCCI.StartMonth not null 
 *
 *
 *
 *
 * USAGE:
 *
 *
 * INPUT PARAMETERS
 * PMCO
 * PROJECT
 * PCOType
 * PCO
 * PCOItem
 * ACO
 * ACOItem
 * Addon
 * ManOrAppr	Flag to indicate if approving or manually assigning from ACO side.
 *
 *
 * OUTPUT PARAMETERS
 *
 *
 * RETURN VALUE
 *   0 - Success
 *   1 - Failure
 *****************************************************/
(@pmco bCompany = 0, @project bJob = null, @pcotype bDocType = null, @pco bPCO = null,
 @pcoitem bPCOItem = null, @aco bACO = null, @acoitem bPCOItem = null,
 @manorappr char(1) = 'A', @msg varchar(255) output)
as
set nocount on

declare @rcode int, @contract bContract, @revredirect bYN, @revitem bContractItem,
		@revuseitem char(1), @revstartatitem int, @revwhenapproved bYN, @addon_amount bDollar,
		@intext char(1), @fixedamountyn bYN, @fixedamount bDollar, @pendingamount bDollar,
		@approvedamt bDollar, @revitem_exists bYN, @acoitem_exists bYN, @acoitem_desc bItemDesc,
		@contractitem bContractItem, @addon_acoitem bPCOItem, @inputlength varchar(10),
		@inputmask varchar(30), @tmpitem varchar(10), @retcode int, @next_acoitem integer,
		@dummy varchar(30), @um bUM, @units bUnits, @unitprice bUnitCost,
		@addon int, @opencursor tinyint, @pmoikeyid bigint, @revfixedacoitem bACOItem


select @rcode = 0, @opencursor = 0

if @pmco is null
  	begin
  	select @msg = 'Missing PM Company!', @rcode = 1
  	goto bspexit
  	end

if @project is null
  	begin
  	select @msg = 'Missing Project!', @rcode = 1
  	goto bspexit
  	end

if @aco is null
  	begin
  	select @msg = 'Missing ACO!', @rcode = 1
  	goto bspexit
  	end

------ get the mask for bPCOItem
select @inputmask=InputMask, @inputlength = convert(varchar(10), InputLength)
from DDDTShared with (nolock) where Datatype = 'bACOItem'
if isnull(@inputmask,'') = '' select @inputmask = 'R'
if isnull(@inputlength,'') = '' select @inputlength = '10'
if @inputmask in ('R','L')
   	begin
   	select @inputmask = @inputlength + @inputmask + 'N'
   	end

---- get contract from JCJM
select @contract=Contract
from bJCJM with (nolock) where JCCo=@pmco and Job=@project
if @@rowcount = 0
	begin
	select @msg = 'Invalid contract!', @rcode = 1
	goto bspexit
	end



---- declare cursor on PMPA Project Addons for redirect addons
declare bcPMOA cursor local FAST_FORWARD for select AddOn, isnull(AddOnAmount,0)
from bPMOA where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco and PCOItem=@pcoitem

-- open cursor
open bcPMOA
-- set open cursor flag to true
select @opencursor = 1

PMOA_loop:
fetch next from bcPMOA into @addon, @addon_amount

if @@fetch_status <> 0 goto PMOA_end

select @revitem_exists = 'N', @acoitem_exists = 'N'

---- get PMPA info
select @revredirect=RevRedirect, @revitem=RevItem, @revuseitem=RevUseItem,
		@revstartatitem=RevStartAtItem,  @acoitem_desc=Description,
		@revfixedacoitem=RevFixedACOItem
from bPMPA with (nolock) where PMCo=@pmco and Project=@project and AddOn=@addon
if @@rowcount = 0 goto PMOA_loop

---- is this addon redirected
if @revredirect = 'N' goto PMOA_loop

set @tmpitem = null
set @addon_acoitem = null
set @next_acoitem = null
set @dummy = null

---- must have revenue item if redirecting addon fee
if isnull(@revredirect,'N') = 'Y' and isnull(@revitem,'') = ''
	begin
	select @msg = 'Missing revenue item for add-on: ' + convert(varchar(6), @addon) + '.', @rcode = 1
	goto bspexit
	end

---- if using revenue item
if @revuseitem = 'U'
	begin
	---- verify data length of revenue item will fit in aco item
	if datalength(ltrim(rtrim(@revitem))) > 10
		begin
		select @msg = 'Add-on revenue item length exceeds maximum allowed for ACO Item.', @rcode = 1
		goto bspexit
		end
	---- format aco item from revenue item
	select @tmpitem = ltrim(rtrim(@revitem))
    exec dbo.bspHQFormatMultiPart @tmpitem, @inputmask, @addon_acoitem output
	if isnull(@addon_acoitem,'') = ''
		begin
		select @msg = 'Error occurred formatting revenue item to aco item.', @rcode = 1
		goto bspexit
		end
	end

---- need to create a new ACO Item using the starting ACO Item from PMPA
if @revuseitem = 'S'
	begin
	if isnull(@revstartatitem,0) < 1
		begin
		select @msg = 'Missing starting at ACO Item.', @rcode = 1
		goto bspexit
		end

	---- using starting at number, get max and add one
	select @next_acoitem = max(cast(ACOItem as numeric) + 1)
	from bPMOI with (nolock) where PMCo=@pmco and Project=@project
	and ACO=@aco and cast(ACOItem as numeric) >= @revstartatitem

	---- if null or zero set to 1
	if isnull(@next_acoitem,0) = 0 select @next_acoitem = @revstartatitem
	if @next_acoitem < @revstartatitem select @next_acoitem = @revstartatitem

	------ format @addon_acoitem using appropiate value
	set @dummy = convert(varchar(10),@next_acoitem)
	exec @rcode = dbo.bspHQFormatMultiPart @dummy, @inputmask, @addon_acoitem output

	---- check if exists in PMOI
	if exists(select TOP 1 1 from bPMOI with (nolock) where PMCo=@pmco and Project=@project and ACO=@aco and ACOItem=@addon_acoitem)
		begin
		----select @msg = 'Temp error message: Project: ' + isnull(@project,'') + ' ACO: ' + isnull(@aco,'') + ' ACOItem: ' + char(39) + isnull(@addon_acoitem,'') + char(39) + ' Addon: ' + convert(varchar(10),@addon), @rcode = 1
		select @msg = 'Error occurred trying to get next ACO Item. ACO Item: ' + isnull(@addon_acoitem,''), @rcode = 1
		goto bspexit
		end
	end

---- if using fixed ACO item
if @revuseitem = 'F'
	begin
	if isnull(@revfixedacoitem,'') = ''
		begin
		select @msg = 'Missing ACO item to assign revenue too. Setup in PM Project Addons.', @rcode = 1
		goto bspexit
		end
	select @addon_acoitem = @revfixedacoitem
	end


---- get PMOP info
select @intext=IntExt
from bPMOP with (nolock) where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco
if @@rowcount = 0 goto PMOA_loop
if isnull(@intext,'E') = 'I' goto PMOA_loop

---- get PMOI info for PCO
select @fixedamountyn=FixedAmountYN, @fixedamount=FixedAmount, @pendingamount=PendingAmount
from bPMOI with (nolock) where PMCo=@pmco and Project=@project
and PCOType=@pcotype and PCO=@pco and PCOItem=@pcoitem
if @@rowcount = 0 goto PMOA_loop

---- get PMOI info for ACO
select @approvedamt=ApprovedAmt, @contractitem=ContractItem, @um=UM, @units=Units,
		@unitprice=UnitPrice
from bPMOI with (nolock) where PMCo=@pmco and Project=@project and ACO=@aco and ACOItem=@acoitem
if @@rowcount = 0 goto PMOA_loop


---- check if revenue item exists in JCCI
if exists(select top 1 1 from bJCCI with (nolock) where JCCo=@pmco and Contract=@contract and Item=@revitem)
	begin
	select @revitem_exists = 'Y'
	end

---- check if aco item exists in PMOI
if exists(select top 1 1 from bPMOI with (nolock) where PMCo=@pmco and Project=@project
			and ACO=@aco and ACOItem=@addon_acoitem)
	begin
	select @acoitem_exists = 'Y'
	end

----select @msg = @addon_acoitem, @rcode = 1
----rollback transaction
----goto bspexit

---- re-direct add-on amount(fee) to revenue item
BEGIN TRANSACTION

---- insert JCCI record for revenue item if needed
if @revitem_exists = 'N'
	begin
	insert bJCCI (JCCo, Contract, Item, Description, Department, TaxGroup, TaxCode, UM, SIRegion,
			SICode, RetainPCT, OrigContractAmt, OrigContractUnits, OrigUnitPrice, ContractAmt,
			ContractUnits, UnitPrice, BilledAmt, BilledUnits, ReceivedAmt, CurrentRetainAmt,
			BillType, BillGroup, BillDescription, BillOriginalUnits, BillOriginalAmt,
			BillCurrentUnits, BillCurrentAmt, BillUnitPrice, InitSubs, StartMonth, MarkUpRate)
	select @pmco, @contract, @revitem, @acoitem_desc, i.Department, i.TaxGroup, i.TaxCode, 'LS',
			i.SIRegion, i.SICode, i.RetainPCT, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, i.BillType, i.BillGroup,
			i.BillDescription, 0, 0, 0, 0, 0, i.InitSubs, isnull(i.StartMonth,c.StartMonth), i.MarkUpRate
	from bJCCI i
	join bJCCM c with (nolock) on c.JCCo=i.JCCo and c.Contract=i.Contract
	where i.JCCo=@pmco and i.Contract=@contract and i.Item=@contractitem
	if @@rowcount = 0
		begin
		select @msg = 'Error occurred inserting JCCI record for Add-on revenue item.', @rcode = 1
		IF XACT_STATE() <> 0 ROLLBACK TRANSACTION
		goto bspexit
		end
	end


---- insert PMOI record for add-on ACO item if needed
if @acoitem_exists = 'N'
	begin
	insert bPMOI (PMCo, Project, PCOType, PCO, PCOItem, ACO, ACOItem, Description, Status,
			ApprovedDate, UM, Units, UnitPrice, PendingAmount, ApprovedAmt, Issue, Date1,
			Date2, Date3, Contract, ContractItem, Approved, ApprovedBy, ForcePhaseYN,
			FixedAmountYN, BillGroup, ChangeDays, InterfacedDate, ProjectCopy, BudgetNo,
			RFIType, RFI, Notes)
	select @pmco, @project, null, null, null, @aco, @addon_acoitem, @acoitem_desc, i.Status,
			i.ApprovedDate, 'LS', 0, 0, 0, 0, i.Issue, i.Date1, i.Date2, i.Date3,
			@contract, @revitem, i.Approved, i.ApprovedBy, i.ForcePhaseYN,
			'N', i.BillGroup, 0, null, 'N', null, null, null, 'Revenue Item'
	from bPMOI i where i.PMCo=@pmco and i.Project=@project and i.ACO=@aco and i.ACOItem=@acoitem
	if @@rowcount = 0
		begin
		select @msg = 'Error occurred inserting PMOI record for Add-on ACO item.', @rcode = 1
		IF XACT_STATE() <> 0 ROLLBACK TRANSACTION
		goto bspexit
		end

	---- insert row into PM Document History to record that the revenue item was added
	---- and the PCOType, PCO, PCOItem, and the approved amount
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
				FieldType, FieldName, OldValue, NewValue, UserName, Action, PCOItem, ACOItem)
	select @pmco, @project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC),
			'ACO', null, @aco, null, getdate(),
			'A', 'ACOItem', null, @addon_acoitem, SUSER_SNAME(),
			'ACO Revenue Item: ' + isnull(@addon_acoitem,'') + ' has been added from PCO: ' + isnull(@pcotype,'') + '/' + isnull(@pco,'') + '/' + isnull(@pcoitem,'') + ' - amount: ' + convert(varchar(20), isnull(@addon_amount,0)) + '.',
			@pcoitem, @addon_acoitem
	from bPMOI i
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='ACO'
	join bPMCO c with (nolock) on c.PMCo=h.PMCo
	where h.PMCo=@pmco and h.Project=@project and h.DocCategory='ACO'
	and isnull(c.DocHistACO,'N') = 'Y' and @pcoitem is not null and @addon_acoitem is not null
	and i.ACO=@aco and i.ACOItem=@acoitem
	group by i.PMCo, i.Project, i.ACO, i.ACOItem
	end


---- get units and unit price for add-on revenue item
---- need to update approved amount and recalculate unitprice if needed
select @units=Units, @unitprice=UnitPrice, @fixedamountyn=FixedAmountYN,
		@approvedamt=ApprovedAmt, @pmoikeyid=KeyID
from bPMOI where PMCo=@pmco and Project=@project and ACO=@aco and ACOItem=@addon_acoitem
if @@rowcount = 0
	begin
	select @msg = 'Error occurred updating Add-on Amount to ACO Item.', @rcode = 1
	IF XACT_STATE() <> 0 ROLLBACK TRANSACTION
	goto bspexit
	end

---- update Approved Amount in PMOI for the add-on ACO item
if @fixedamountyn = 'N'
	begin
	set @approvedamt = @approvedamt + @addon_amount
	if @units <> 0 select @unitprice = @approvedamt / @units
	update bPMOI set ApprovedAmt = @approvedamt, UnitPrice=@unitprice
	where PMCo=@pmco and Project=@project and ACO=@aco and ACOItem=@addon_acoitem
	end

---- remove tag in notes if needed
update bPMOI set Notes = null
where PMCo=@pmco and Project=@project and ACO=@aco and ACOItem=@addon_acoitem and Notes = 'Revenue Item'

---- now update ACO Item and decrease approved amount by the add-on amount
---- recalculate unit price if we have units
---- only do this when approving, if manual then assume amount is correct #128966
if @manorappr = 'X'
	begin
	select @units=Units, @unitprice=UnitPrice, @fixedamountyn=FixedAmountYN,
			@approvedamt=ApprovedAmt
	from bPMOI where PMCo=@pmco and Project=@project and ACO=@aco and ACOItem=@acoitem
	if @@rowcount <> 0 and @fixedamountyn = 'N'
		begin
		set @approvedamt = @approvedamt - @addon_amount
		if @units <> 0 select @unitprice = @approvedamt / @units
		update bPMOI set ApprovedAmt = @approvedamt, UnitPrice=@unitprice
		where PMCo=@pmco and Project=@project and ACO=@aco and ACOItem=@acoitem
		end
	end

---- update bPMOA set reference to PMOI keyid and approved amount
update bPMOA set RevACOItemId=@pmoikeyid, RevACOItemAmt=@addon_amount
where PMCo=@pmco and Project=@project and PCOType=@pcotype
and PCO=@pco and PCOItem=@pcoitem and AddOn=@addon



COMMIT TRANSACTION


goto PMOA_loop


PMOA_end:
if @opencursor = 1
	begin
	close bcPMOA
	deallocate bcPMOA
	select @opencursor = 0
	end


bspexit:
	if @opencursor = 1
		begin
		close bcPMOA
		deallocate bcPMOA
		select @opencursor = 0
		end
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMPCOAddonRevItem] TO [public]
GO
