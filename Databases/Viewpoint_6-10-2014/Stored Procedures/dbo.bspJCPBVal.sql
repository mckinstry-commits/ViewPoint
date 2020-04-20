SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJCPBVal    Script Date: 8/28/99 9:36:21 AM ******/
CREATE     procedure [dbo].[bspJCPBVal]
/***********************************************************
* Created By:	LM	03/05/97
* Modified By:	GF	10/11/2000
*				GF	03/18/2002	- Added HQCC clear and add for close control
*				SR	07/09/02	- Issue 17738 passing @PhaseGroup to bspJCVPHASE & bspJCVCOSTTYPE
*				GF	05/21/2003	- issue #21312 @errorstart was null, so no error messages in HQBE
*				TV				- 23061 added isnulls
*				GF	03/27/2009	- issue #129898 projection worksheet detail
*				GF	08/13/2009	- issue #135076 validation for JCPD action needed minor change
*				CHS	01/12/2009	- issue #136309
*
* USAGE:
* Validates each entry in bJCPB for a selected batch - must be called
* prior to posting the batch.
*
* After initial Batch and JC checks, bHQBC Status set to 1 (validation in progress)
* bHQBE (Batch Errors) entries are deleted.
*
* Creates a cursor on bJCPB to validate each entry individually.
*

* Errors in batch added to bHQBE using bspHQBEInsert
*
* bHQBC Status updated to 2 if errors found, or 3 if OK to post
* INPUT PARAMETERS
*   JCCo        JC Co
*   Month       Month of batch
*   BatchId     Batch ID to validate
* OUTPUT PARAMETERS
*   @errmsg     if something went wrong
* RETURN VALUE
*   0   success
*   1   fail
*****************************************************/
(@co bCompany, @mth bMonth, @batchid bBatchID, @errmsg varchar(255) output)
as
set nocount on

declare @rcode int, @opencursor tinyint, @errortext varchar(255), @status tinyint, 
		@errorstart varchar(50), @ctstring varchar(5), @job bJob, @phasegroup bGroup,
		@phase bPhase, @costtype bJCCType, @batchseq bigint

declare @detseq bigint, @transtype varchar(1), @budgetcode varchar(10), @emco bCompany,
		@equipment bEquip, @prco bCompany, @craft bCraft, @class bClass, @description bItemDesc,
		@fromdate bDate, @todate bDate, @um bUM, @units bUnits, @unithours bHrs, @hours bHrs,
		@rate bUnitCost, @unitCost bUnitCost, @amount bDollar, @oldtranstype varchar(1),
		@oldbudgetcode varchar(10), @oldemco bCompany, @oldequipment bEquip, @oldprco bCompany,
		@oldcraft bCraft, @oldclass bClass, @olddescription bItemDesc, @oldfromdate bDate,
		@oldtodate bDate, @oldum bUM, @oldunits bUnits, @oldunithours bHrs, @oldhours bHrs,
		@oldRate bUnitCost, @oldunitcost bUnitCost, @oldamount bDollar, @openjcpd_cursor int,
		@employee bEmployee, @oldemployee bEmployee, @detmth bMonth, @olddetmth bMonth,
		@quantity bUnits, @oldquantity bUnits, @valempl varchar(15)

select @rcode = 0, @opencursor = 0, @openjcpd_cursor = 0

-- validate HQ Batch
exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, 'JC Projctn', 'JCPB', @errmsg output, @status output
if @rcode <> 0
	begin
	select @errmsg = @errmsg, @rcode = 1
	goto bspexit
	end

if @status < 0 or @status > 3
	begin
	select @errmsg = 'Invalid Batch status!', @rcode = 1
	goto bspexit
	end

-- set HQ Batch status to 1 (validation in progress)
update bHQBC set Status = 1
where Co=@co and Mth=@mth and BatchId=@batchid
if @@rowcount = 0
	begin
	select @errmsg = 'Unable to update HQ Batch Control status!', @rcode = 1
	goto bspexit
	end

-- clear HQ Batch Errors
delete bHQBE where Co=@co and Mth=@mth and BatchId=@batchid

-- clear and refresh HQCC entries
delete bHQCC where Co = @co and Mth = @mth and BatchId = @batchid

insert into bHQCC(Co, Mth, BatchId, GLCo)
select distinct Co, Mth, BatchId, Co from bJCPB
where Co=@co and Mth=@mth and BatchId=@batchid


---- declare cursor on JC Detail Batch for validation
declare bcJCPB cursor for select BatchSeq, Job, PhaseGroup, Phase, CostType
from bJCPB where Co=@co and Mth=@mth and BatchId=@batchid

---- open cursor
open bcJCPB
set @opencursor = 1

---- get next 
JCPB_loop:
fetch next from bcJCPB into @batchseq, @job, @phasegroup, @phase, @costtype

if (@@fetch_status <> 0) goto JCPB_end


select @errorstart = 'Job: ' + isnull(@job,'')

---- validate job
if not exists (select 1 from bJCJM with (nolock) where JCCo = @co and Job = @job)
	begin
	select @errortext = @errorstart + ' - is invalid.'
	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
	if @rcode <> 0 goto bspexit
	goto JCPB_loop
	end

---- validate PhaseGroup
if not exists (select 1 from bHQGP with (nolock) where Grp=@phasegroup)
	begin
	select @errortext = @errorstart + 'Phase Group ' + isnull(convert(varchar(3),@phasegroup),'') + ' - is invalid.'
	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
	if @rcode <> 0 goto bspexit
	goto JCPB_loop
	end

---- look for phase in JCJP - ignore (skip validation) if not there
if not exists (select 1 from bJCJP with (nolock) where JCCo = @co and Job = @job and PhaseGroup = @phasegroup and Phase = @phase)
	begin
	goto JCPB_loop
	end

---- look for cost type in JCCH - ignore (skip validation) if not there
if not exists (select 1 from bJCCH with (nolock) where JCCo = @co and Job = @job and PhaseGroup = @phasegroup and Phase = @phase and CostType = @costtype)
	begin
	goto JCPB_loop
	end

----validate phase
exec @rcode = bspJCVPHASEForJCJP @co, @job, @phase, 'N', @msg=@errmsg output 
if @rcode = 1
	begin
	select @errortext = @errorstart + 'Phase: ' + isnull(@phase,'') + ' - ' + isnull(@errmsg,'')
	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
	if @rcode <> 0 goto bspexit
	goto JCPB_loop
	end

---- validate CostType
select @ctstring=convert(varchar(5),@costtype)
exec @rcode = bspJCVCOSTTYPE @co, @job, @phasegroup, @phase, @ctstring, 'P', @msg=@errmsg output
if @rcode = 1
	begin
	select @errortext = @errorstart + 'Phase: ' + isnull(@phase,'') + 'CostType: ' + isnull(convert(char(3),@costtype),'') + ' - ' + isnull(@errmsg,'')
	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
	if @rcode <> 0 goto bspexit
	goto JCPB_loop
	end


/***********************************************
* create cursor for projection worksheet detail
***********************************************/
---- first check if we have projection detail for the job, phase, costtype
if not exists(select 1 from bJCPD with (nolock) where Co=@co and BatchId=@batchid and Mth=@mth
			and BatchSeq=@batchseq and Job=@job and Phase=@phase and CostType=@costtype)
	begin
	goto JCPB_loop
	end
 
declare bcJCPD cursor LOCAL FAST_FORWARD
for select DetSeq, TransType, BudgetCode, EMCo, Equipment, PRCo, Craft, Class, Employee,
		Description, DetMth, FromDate, ToDate, Quantity, UM, Units, UnitHours, Hours, Rate,
		UnitCost, Amount, OldTransType, OldBudgetCode, OldEMCo, OldEquipment, OldPRCo,
		OldCraft, OldClass, OldEmployee, OldDescription, OldDetMth, OldFromDate, OldToDate,
		OldQuantity, OldUM, OldUnits, OldUnitHours, OldHours, OldRate, OldUnitCost, OldAmount
from bJCPD
where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq and Job = @job
and Phase = @phase and CostType = @costtype

-- open cursor
open bcJCPD
select @openjcpd_cursor = 1

JCPD_loop:
fetch next from bcJCPD into @detseq, @transtype, @budgetcode, @emco, @equipment, @prco,
		@craft, @class, @employee, @description, @detmth, @fromdate, @todate, @quantity,
		@um, @units, @unithours, @hours, @rate, @unitCost, @amount, @oldtranstype,
		@oldbudgetcode, @oldemco, @oldequipment, @oldprco, @oldcraft, @oldclass,
		@oldemployee, @olddescription, @olddetmth, @oldfromdate, @oldtodate, @oldquantity,
		@oldum, @oldunits, @oldunithours, @oldhours, @oldRate, @oldunitcost, @oldamount

if @@fetch_status <> 0 goto JCPD_end

select @errorstart = 'Job: ' + isnull(@job,'') + ', Phase: ' + isnull(@phase,'') + ', CostType: ' + isnull(convert(varchar(3),@costtype),'') + ', Seq: ' + isnull(convert(varchar(8),@detseq),'')

---- validate transaction type
if @transtype not in ('A','C','D')
	begin
	select @errortext = @errorstart + ' -  Invalid transaction type, must be (A),(C), or (D).'
	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
	if @rcode <> 0 goto bspexit
	goto JCPD_loop
	end

----#135076
if isnull(@oldtranstype,'A') <> 'A' and @transtype = 'A'
	begin
	select @errortext = @errorstart + ' -  Invalid transaction type, must be (C) or (D).'
	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
	if @rcode <> 0 goto bspexit
	goto JCPD_loop
	end

---- validate UM
if isnull(@um,'') = ''
	begin
	select @errortext = @errorstart + ' - UM cannot be null.'
	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
	if @rcode <> 0 goto bspexit
	goto JCPD_loop
	end
if not exists (select 1 from bHQUM with (nolock) where UM=@um)
	begin
	select @errortext = @errorstart + ' - UM is invalid.'
	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
	if @rcode <> 0 goto bspexit
	goto JCPD_loop
	end

---- from and to date validation
if isnull(@fromdate,'') = '' and isnull(@todate,'') <> ''
	begin
	select @errortext = @errorstart + ' - Must have a from date when a to date is entered.'
	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
	if @rcode <> 0 goto bspexit
	goto JCPD_loop
	end

if isnull(@fromdate,'') <> '' and isnull(@todate,'') = ''
	begin
	select @errortext = @errorstart + ' - Must have a to date when a from date is entered.'
	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
	if @rcode <> 0 goto bspexit
	goto JCPD_loop
	end

---- check from and to date range, to date cannot be less than from date
if isnull(@fromdate,'') <> '' and isnull(@todate,'') <> ''
	begin
	if @todate < @fromdate
		begin
		select @errortext = @errorstart + ' - The to date cannot be earlier than the from date.'
		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
		if @rcode <> 0 goto bspexit
		goto JCPD_loop
		end
	end

---- validate budget code
if isnull(@budgetcode,'') <> ''
	begin
	if not exists (select 1 from bPMEC with (nolock) where PMCo = @co and BudgetCode = @budgetcode)
		begin
		select @errortext = @errorstart + ' - Budget code is invalid.'
		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
		if @rcode <> 0 goto bspexit
		goto JCPD_loop
		end
	end

---- validate EM Company and Equipment
if isnull(@emco,'') <> ''
	begin
	if not exists (select 1 from bEMCO with (nolock) where EMCo = @emco)
		begin
		select @errortext = @errorstart + ' - EM Company is invalid.'
		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
		if @rcode <> 0 goto bspexit
		goto JCPD_loop
		end

	---- validate equipment
	if isnull(@equipment,'') <> ''
		begin
		if not exists (select 1 from bEMEM with (nolock) where EMCo = @emco and Equipment=@equipment)
			begin
			select @errortext = @errorstart + ' - EM Equipment is invalid.'
			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			if @rcode <> 0 goto bspexit
			goto JCPD_loop
			end
		end
	end

---- validate PR Company, Craft, Class
if isnull(@prco,'') <> ''
	begin
	if not exists (select 1 from bPRCO with (nolock) where PRCo = @prco)
		begin
		select @errortext = @errorstart + ' - PR Company is invalid.'
		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
		if @rcode <> 0 goto bspexit
		goto JCPD_loop
		end

	---- validate employee
	if isnull(@employee,'') <> ''
		begin
		select @valempl = convert(varchar(15),@employee)
		exec @rcode = bspPREmplVal @prco, @valempl, 'Y', @msg = @errmsg output
		if @rcode <> 0
			begin
			select @errortext = @errorstart + ' - ' + isnull(@errmsg,'')
			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			if @rcode <> 0 goto bspexit
			goto JCPD_loop
			end
		end

	---- validate craft
	if isnull(@craft,'') <> ''
		begin
		if not exists(select 1 from bPRCM with (nolock) where PRCo=@prco and Craft=@craft)
			begin
			select @errortext = @errorstart + ' - PR Craft is invalid.'
			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			if @rcode <> 0 goto bspexit
			goto JCPD_loop
			end

		if isnull(@class,'') <> ''
			begin
			if not exists(select 1 from bPRCC with (nolock) where PRCo=@prco and Craft=@craft and Class=@class)
				begin
				select @errortext = @errorstart + ' - PR Craft/Class is invalid'
				exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				if @rcode <> 0 goto bspexit
				goto JCPD_loop
				end
			end
		end

	if isnull(@craft,'') = '' and isnull(@class,'') <> ''
		begin
		select @errortext = @errorstart + ' - PR Craft must be specified if Class is entered'
		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
		if @rcode <> 0 goto bspexit
		goto JCPD_loop
		end

	if isnull(@craft,'') <> '' and isnull(@class,'') = ''
		begin
		select @errortext = @errorstart + ' - PR Class is missing'
		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
		if @rcode <> 0 goto bspexit
		goto JCPD_loop
		end
	end






goto JCPD_loop

JCPD_end:
if @opencursor = 1
	begin
	close bcJCPD
	deallocate bcJCPD
	set @openjcpd_cursor = 0
	end


goto JCPB_loop



JCPB_end:
if @opencursor = 1
	begin
	close bcJCPB
	deallocate bcJCPB
	set @opencursor = 0
	end



---- check HQ Batch Errors and update HQ Batch Control status
select @status = 3	-- valid - ok to post
if exists(select * from bHQBE where Co=@co and Mth=@mth and BatchId=@batchid)
	begin
	select @status = 2	-- validation errors
	end

update bHQBC set Status = @status
where Co=@co and Mth=@mth and BatchId=@batchid
if @@rowcount <> 1
	begin
	select @errmsg = 'Unable to update HQ Batch Control status!', @rcode = 1
	goto bspexit
	end


bspexit:
	if @opencursor = 1
		begin
		close bcJCPB
		deallocate bcJCPB
		end

	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCPBVal] TO [public]
GO
