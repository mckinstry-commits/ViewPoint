SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspPMPCOApprove    Script Date: 8/28/99 9:35:15 AM ******/
CREATE proc [dbo].[bspPMPCOApprove]
/***********************************************************
* CREATED BY: bc 7/6/98
* MODIFIED BY: bc 03/10/99 took PCOType out of 2 validation statements.  issue 3663
*              LM 5/12/99  added insert to jcch where pco addons have a phase/costtype
*		         bc 6/24/99  added PCOItem to the where clause for JCCH when @calling_form =1 and
*			                 checked to make sure that the PMPA PhaseGroup, Phase, CostType are not equal to null
*              bc 01/03/00 added code to spin through the add ons (PMPA) and add any necessary phases to JCJP
*                          prior to inserting a record into JCCH
*              GF 04/27/2000 pulled out as much of the validation as possible to another SP, also
*                            added transaction process, so that if a error occurs will rollback.
*                            call SP to update PMSL and generate subco numbers.
*              DANF 12/1/2000 remove notes from being updated to JCCH for SQL2000
*			   TV 03/30/01   Change in days has been moved to line level, But must update PMOH to keep running total
*              GF 04/09/2001 - issue #12910 not allowing duplication when approving items.
*              GF 06/14/2001 - issue #13763 setting contract equal project in PMOH. Should be contract from JCJM.
*				 GF 03/01/2002 - more changes for duplicate not allowing duplication when approving items.
*					SR 07/09/02 - issue 17738 pass @phasegroup to bspJCVPHASE
*				SR 08/21/02 - issue 18312 - use Default Final status from PMCO if there is one else use from PMSC
*				GF 09/12/2003 - issue #22450 - unable to approve PCO. Problem was format passed to bspHQFormatMultiPart
*								was not correct. When Inputmask is 'R' need to use length + 'R' + 'N' for format to work
*				GF 01/19/2003 - issue #16548 - use PMOP.IntExt flag when inserting bPMOH record.
*					GF 08/17/2005 - issue #28843 - send uniqueattchid from PMOP to PMOH
*				GF 03/13/2006 - issue #120504 - if @sequence is null, call bspPMPCOApprove to get next aco sequence.
*					GF 07/24/2006 - issue #121954 - copy user memos from PMOP to PMOH if column names match.
*					GF 04/29/2008 - issue #22100 - redirect addon addon revenue
*					GF 07/14/2008 - issue #128966 changed flag passed to vspPMPCOAddonRevItem to 'X' when approving PCO.
*					GF 10/30/2008 - issue #130772 changed data type for description to bItemDesc
*					GF 11/28/2008 - issue #131100 expanded phase description
*					GF 01/10/2008 - issue #129669 proportionally distribute add-on phase cost types
*					GF 02/17/2009 - issue #132308 need to make sure that the next item does not already exist.
*				GF 04/28/2009 - issue #133415 expanded @approver to 30 characters
*				GF 04/13/2011 - TK-03898 error if PCO is external and ACO is internal and PCO items have amounts
*				GPT 04/26/2011 - TK-04428 TK-06039 Added auto create of POCO on PCO approval.
*				GF 08/25/2011 TK-07949 added code to make sure the IntExt Flag is 'E' with contract impact.
*				TL 11/17/2011 TK-09994 add parameter @ReadyForAccounting
*				TL  01/11/2012 TK-11599 changed Status code update, Gets Status code from PMCO, then from Existing PCO' Document categorys
*				DAN SO 03/12/2012 - TK-13118 - Added @CreateChangeOrders and @CreateSingleChangeOrder
*				DAN SO 03/13/2012 - TK-13139 - Check @CreateChangeOrders - IF 'N' bypass Change Order creation
*
*
*
*
* USAGE:
*   Approves PM Pending Change Order/Item
*   An error is returned if any of the following occurs
* 	no company passed
*	no project passed
*	no matching ACO passed
*	no item passed when the items form is the approved form's calling
*
* INPUT PARAMETERS
*   @pmco - JC Company to validate against
*   @project - project to validate against
*   @pco - original value of the pending change order
*   @aco - form input value
*   @pco_type - PCO type needed complete 'where' statements
*   @aco_item - New user input for the Pending PCOItem
*   Header Description - the description of the ACO
*   Item Description - the description of the ACO Item
*   Approved Date - form input value
*   Approved By - brought in utilizing mBtkForm.User
*   Sequence - form input value
*   UM - form input value
*   Units - form input value
*   Approved Amount - form input value
*   Contract Item - form input value
*   New Completion Date - form input value
*   Change Days - form input value
*   calling Form - form input value (hidden)  1 = header form, 2 = items form
*   Header Status - new or existing apporved change order
*   @pco_item - Original pending item being approved from the items form (late addition to address an issue)
*	@CreateChangeOrders - should ANY change orders be created?
*	@CreateSingleChangeOrder - should .............?
*
*
*
* OUTPUT PARAMETER
*   	@msg - error message if error occurs
*
* RETURN VALUE
*   0 - Success
*   1 - Failure
*****************************************************/
(@pmco bCompany = 0, @project bJob = null, @pco_type bDocType = null, @pco bPCO = null,
 @aco bPCO = null, @h_desc bItemDesc = null, @approved_date bDate = null, @addtl_days smallint = null,
 @sequence int = null, @new_date bDate = null, @approver varchar(30) = null, @aco_item bPCOItem = null,
 @i_desc bItemDesc = null, @item_date bDate = null, @approved_amt bDollar = null, @contract_item bContractItem = null,
 @um bUM = null, @units bUnits = null, @calling_form tinyint = null, @header_status varchar(10) = null,
 @pco_item bPCOItem = null, @ReadyForAccounting bYN = null, 
 -- TK-13118 --
 @CreateChangeOrders bYN = NULL, @CreateSingleChangeOrder bYN = NULL, 
 @msg varchar(1000) output)
as
set nocount on

declare @rcode int, @final_status bStatus, @issue bIssue, @today bDate, @addon int,
        @phasegroup bGroup, @phase bPhase, @addon_item bContractItem, @costtype bJCCType, @retmsg varchar(150),
        @retcode int, @pmslacoitem bPCOItem, @dupsfound tinyint, @opencursor tinyint,
        @bcpcoitem bPCOItem, @bcaco bPCO, @bcacoitem bPCOItem, @bcfixedamountyn bYN, @bcfixedamount bDollar,
        @bcpendingamt bDollar, @bcstatus varchar(10), @jcco bCompany,
        @JCJPexists char(1), @pphase bPhase, @desc bItemDesc, @pcontract bContract, @pitem bContractItem,
        @dept bDept, @projminpct bPct, @acoapprdate bDate, @approvedamt bDollar, @tmpitem bPCOItem,
        @nextitem int, @inputlength varchar(10), @inputmask varchar(30), @intext char(1),
		@contract bContract, @validcnt int, @tries smallint, @uniqueattchid uniqueidentifier,
		@keystring varchar(255), @addedby bVPUserName, @adddate bDate, @tablename varchar(30),
		@formname varchar(30), @docname varchar(255), @hqat_desc bDesc, @origfilename varchar(255),
		@guid uniqueidentifier, @pmoh_pmop_ud_flag bYN, @columnname varchar(120), @joins varchar(2000),
		@where varchar(1000), @ieflag varchar(1), @xacoitem bPCOItem, @minseqitem int,
		@fixeditems varchar(max), @counter int,
		----TK-07949
		@ContractType char(1)

select @rcode = 0, @jcco = @pmco, @dupsfound = 0, @opencursor = 0, @pmoh_pmop_ud_flag = 'N'

SET @today = dbo.vfDateOnly()

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
     	select @msg = 'Missing PCO!', @rcode = 1
     	goto bspexit
     	end
    
    if @pco_type is null
     	begin
     	select @msg = 'Missing PCO Type!', @rcode = 1
     	goto bspexit
     	end
    
    if @pco is null
     	begin
     	select @msg = 'Lost track of original PCO!', @rcode = 1
     	goto bspexit
     	end

if @aco_item = '' select @aco_item = null
if @contract_item = '' select @contract_item = null

if @aco_item is null and @calling_form = 2
     	begin
     	select @msg = 'Missing PCO Item!', @rcode = 1
     	goto bspexit
     	end

if @contract_item is null and @calling_form = 2
        begin
        select @msg = 'Missing contract item for pending change order item!', @rcode = 1
        goto bspexit
        end
        


------ set contract
select @contract = Contract
from bJCJM where JCCo=@pmco and Job=@project
if @@rowcount <> 1
        begin
        select @msg = 'Unable to retrieve contract from Job Master !', @rcode = 1
        goto bspexit
        end

exec @retcode = bspPMPCOApprovalCheck @pmco,@project,@pco_type,@pco,@aco_item,@retmsg output
if @retcode <> 0
        begin
        select @msg = @retmsg, @rcode = 1
        goto bspexit
        end

---- when ACO is not status = 'new' check the ACO IntExt flag to PCO TK-03898
IF @calling_form = 2 AND @pco_item IS NOT NULL
	BEGIN
	IF EXISTS(SELECT TOP 1 1 FROM dbo.PMOI WHERE PMCo=@pmco and Project=@project
				and PCOType=@pco_type and PCO=@pco AND PCOItem=@pco_item
				AND ((FixedAmountYN = 'N' AND PendingAmount <> 0) OR (FixedAmountYN = 'Y' AND FixedAmount <> 0)))
		BEGIN
		IF EXISTS(SELECT TOP 1 1 FROM dbo.PMOH WHERE PMCo=@pmco AND Project=@project AND ACO = @aco AND IntExt = 'I')
			BEGIN
			SELECT @msg = 'Cannot approve pending item. The ACO is flagged as internal and the PCO item has revenue.', @rcode = 1
			GOTO bspexit
			END
		END
	END

------ get the mask for bPCOItem
select @inputmask=InputMask, @inputlength = convert(varchar(10), InputLength)
from DDDTShared with (nolock) where Datatype = 'bPCOItem'
if isnull(@inputmask,'') = '' select @inputmask = 'R'
if isnull(@inputlength,'') = '' select @inputlength = '10'
if @inputmask in ('R','L')
   	begin
   	select @inputmask = @inputlength + @inputmask + 'N'
   	end



---- pseudo cursor to check for like named user memos in PMOP and PMOH to be updated
select @columnname = min(name) from syscolumns where name like 'ud%' and id = object_id('dbo.bPMOP')
while @columnname is not null
begin

	if exists(select * from syscolumns where name = @columnname and id = object_id('dbo.bPMOH'))
		begin
		select @pmoh_pmop_ud_flag = 'Y'
		goto udcheck_done
		end
   
select @columnname = min(name) from syscolumns where name like 'ud%' and id = object_id('dbo.PMOP') and name > @columnname
if @@rowcount = 0 select @columnname = null
end

---- #132308
---- execute stored procedure to get revenue item ranges
set @minseqitem = 0
set @fixeditems = ''
exec @retcode = dbo.vspPMPCOGetAddonRevItemMinValues @pmco, @project, @minseqitem output, @fixeditems output, @msg output
if isnull(@minseqitem,0) = 0 set @minseqitem = null
if isnull(@fixeditems,';') = ';' set @fixeditems = null



udcheck_done:
------ verify that pending items can be approved without creating duplications
if @calling_form = 1
        begin
        -- check for duplicate change order items pending vs approved
        select * from bPMOI a where a.PMCo=@pmco and a.Project=@project and a.PCOType=@pco_type and PCO=@pco
        and ACO is null and exists(select * from bPMOI b where b.PMCo=a.PMCo
        and b.Project=a.Project and b.ACO=@aco and b.ACOItem=a.PCOItem)
        if @@rowcount <> 0
            begin
            select @dupsfound = 1
            -- check if there are any pending items that are not numeric
    		select @tmpitem=ltrim(rtrim(isnull(max(convert(varchar(10),PCOItem)),'0')))
    		from bPMOI WITH (NOLOCK) where PMCo=@pmco and Project=@project and PCOType=@pco_type and PCO=@pco and ACO is null
    		if @@rowcount = 0 goto check_aco_item
    
    		-- check if not numeric
    		if isnumeric(@tmpitem) <> 1
            	begin
            	select @msg = 'Cannot approve pending items - not numeric, approve each pending item separately.', @rcode = 1
            	goto bspexit
           		end
    
    		-- If temp item is zero '0' - then check aco side
    		if @tmpitem = '0' goto check_aco_item
    
    		-- if leading zero's - then item is not numeric
    		if substring(@tmpitem,1,1) = '0'
            	begin
            	select @msg = 'Cannot approve pending items - leading zero, approve each pending item separately.', @rcode = 1
            	goto bspexit
            	end
    
    		-- if decimal - then item is not numeric
    		if @tmpitem like '%.%'
            	begin
            	select @msg = 'Cannot approve pending items - decimal found, approve each pending item separately.', @rcode = 1
      			goto bspexit
            	end
    
    		check_aco_item:
            -- check if last approved item is numeric
    		select @tmpitem=ltrim(rtrim(isnull(max(convert(varchar(10),ACOItem)),'0')))
            from bPMOI WITH (NOLOCK) where PMCo=@pmco and Project=@project and ACO=@aco
    		if @@rowcount = 0 goto get_final_status
    
    		-- check if not numeric
    		if isnumeric(@tmpitem) <> 1
            	begin
            	select @msg = 'Cannot approve pending items - not numeric, approve each pending item separately.', @rcode = 1
            	goto bspexit
           		end
    
    		-- If temp item is zero '0' - then check aco side
    		if @tmpitem = '0' goto check_aco_item
    
    		-- if leading zero's - then item is not numeric
    		if substring(@tmpitem,1,1) = '0'
            	begin
            	select @msg = 'Cannot approve pending items - leading zero, approve each pending item separately.', @rcode = 1
            	goto bspexit
            	end
    
    		-- if decimal - then item is not numeric
    		if @tmpitem like '%.%'
            	begin
            	select @msg = 'Cannot approve pending items - decimal found, approve each pending item separately.', @rcode = 1
            	goto bspexit
            	end
            end
        end
    
    get_final_status:
    ------ retrieve a final status code for approved item
    ------ issue 18312 - use Default Final status from PMCO if there is one else use from PMSC
    select @final_status = FinalStatus from PMCO where PMCo=@pmco and FinalStatus is not null
   --TK-11599
    if @@rowcount = 0 select @final_status = Min(Status) from bPMSC where CodeType='F' and DocCat='PCO'
    
    If IsNull(@final_status,'') = ''
    begin
		select @final_status = Min(Status) from bPMSC where CodeType='F' and ActiveAllYN = 'Y'
	end

---- retrieve the issue from the pending header record
----TK-07949
select @issue = Issue, @intext = IntExt , @uniqueattchid=UniqueAttchID,
		@ContractType=ContractType
from dbo.bPMOP
where PMCo=@pmco and Project=@project and PCOType=@pco_type and PCO=@pco and ApprovalDate is NULL
---- check if internal or external and we have a contract impact
---- if so the IntExt flag should be 'E' for external
----TK-07949
IF @intext = 'I' AND @ContractType = 'Y'
	BEGIN
	SET @intext = 'E'
	UPDATE dbo.bPMOP SET IntExt = @intext
	WHERE PMCo=@pmco and Project=@project and PCOType=@pco_type and PCO=@pco
	END


-- -- -- set approved date
select @acoapprdate = case @header_status when 'new' then @approved_date else @today end

-- -- -- if no aco sequence number, then get next aco sequence #
if @sequence is null
	begin
    exec @retcode = bspJCMaxACOSeq @pmco, @project, @retmsg output
	if @retcode = 0 
		select @sequence = convert(integer,@retmsg) + 1
	else
		select @sequence = 1
	end


BEGIN TRANSACTION

if @header_status = 'new'
	begin
	------ insert new header
	---- if @uniqueattchid is not null select @guid=NewID()
	insert into bPMOH (PMCo, Project, ACO, Description, ACOSequence, Issue, Contract,
				NewCmplDate, IntExt, ApprovalDate, ApprovedBy, UniqueAttchID)
	values (@pmco, @project, @aco, @h_desc, @sequence, @issue, @contract,
                @new_date, isnull(@intext,'E'), @approved_date, @approver, null) ----@guid)
   ------ copy user memos if any
   if @pmoh_pmop_ud_flag = 'Y'
		begin
		-- build joins and where clause
		select @joins = ' from PMOP join PMOH z on z.PMCo = ' + convert(varchar(3),@pmco) +
   					' and z.Project = ' + CHAR(39) + @project + CHAR(39) +
   					' and z.ACO = ' + CHAR(39) + @aco + CHAR(39)
		select @where = ' where PMOP.PMCo = ' + convert(varchar(3),@pmco) + +
   					' and PMOP.Project = ' + CHAR(39) + @project + CHAR(39) +
   					' and PMOP.PCOType = ' + CHAR(39) + @pco_type + CHAR(39) +
   					' and PMOP.PCO = ' + CHAR(39) + @pco + CHAR(39)
		------ execute user memo update
		exec @rcode = dbo.bspPMPCOApproveUserMemoCopy 'PMOP', 'PMOH', @joins, @where, @msg output
		end

	------ update the contract master
	if @new_date is not null
		begin
		update bJCCM set ProjCloseDate=@new_date, CurrentDays = CurrentDays + isnull(@addtl_days,0)
		where JCCo=@pmco and Contract=@project
		end
	end

------ Update/Approve change orders
------ If the calling form is the Header (1), then all the items and lines on that PCO are to be updated.
    if @calling_form <> 1 goto Item_Approval
    
    -- if no duplicates found then goto cursor creation
    if @dupsfound = 0 goto Create_PMOI_Cursor
    
    select @nextitem = 0
    -- get maximum ACO Item
	---- #132308
    select @tmpitem=ltrim(rtrim(isnull(max(convert(varchar(10),i.ACOItem)),'0')))
    from bPMOI i with (nolock) where PMCo=@pmco and Project=@project and ACO=@aco
	and convert(int,i.ACOItem) < isnull(@minseqitem,99999999)
	and charindex(';' + i.ACOItem + ';', isnull(@fixeditems,'~~~~~~~~~~')) = 0 
    if @@rowcount = 0 goto Create_PMOI_Cursor
    
    ---- check if not numeric
    if isnumeric(@tmpitem) <> 1
    	begin
		IF XACT_STATE() <> 0 ROLLBACK TRANSACTION
    	select @msg = 'Not numeric, unable to create ACO Item.', @rcode = 1
    	goto bspexit
		end
    
    ---- If temp item is zero '0' - then get next sequential item
    if @tmpitem = '0' goto Create_PMOI_Cursor
    
    ---- if leading zero's - then item is not numeric
    if substring(@tmpitem,1,1) = '0'
    	begin
		IF XACT_STATE() <> 0 ROLLBACK TRANSACTION
        select @msg = 'Leading zero, unable to create ACO Item.', @rcode = 1
        goto bspexit
        end
    
    ---- if decimal - then item is not numeric
    if @tmpitem like '%.%'
        begin
		IF XACT_STATE() <> 0 ROLLBACK TRANSACTION
        select @msg = 'Decimal found, unable to create ACO Item.', @rcode = 1
        goto bspexit
        end
    
    -- aco item is numeric, load into next item to be used for incrementation
    select @nextitem = convert(int,@tmpitem)
    
    
    
    
    -- declare cursor on PMOI Pending CO items for approval
    Create_PMOI_Cursor:
    declare bcPMOI cursor local FAST_FORWARD
    for select PCOItem, ACOItem, FixedAmountYN, isnull(FixedAmount,0), isnull(PendingAmount,0), Status
    from bPMOI where PMCo=@pmco and Project=@project and PCOType=@pco_type and PCO=@pco and Approved<>'Y'
    
    -- open cursor
    open bcPMOI
    -- set open cursor flag to true
    select @opencursor = 1
    
    PMOI_loop:
    fetch next from bcPMOI into @bcpcoitem, @xacoitem, @bcfixedamountyn, @bcfixedamount, @bcpendingamt, @bcstatus

    if @@fetch_status <> 0 goto PMOI_end
    
	---- first run add-on calculations so that distribution phase cost types are ready to go
	if isnull(@xacoitem,'') <> ''
		begin
		exec @retcode = dbo.vspPMOACalcs @pmco, @project, @pco_type, @pco, @bcpcoitem
		end
		
	---- update PMOA and set all addon.status flags to 'Y'
    update dbo.bPMOA set Status = 'Y'
    where PMCo=@pmco and Project=@project and PCOType=@pco_type
    and PCO=@pco and PCOItem=@bcpcoitem and Status <> 'Y'
    
    -- set approved amount
    select @approvedamt = case @bcfixedamountyn when 'Y' then @bcfixedamount else @bcpendingamt end
	---- get IntExt flag from PMOH
	select @ieflag=IntExt from bPMOH where PMCo=@pmco and Project=@project and ACO=@aco
	if isnull(@ieflag,'E') = 'I' select @approvedamt = 0
    -- set approved status
    select @bcstatus = isnull(@final_status,@bcstatus), @bcacoitem = null
    
    -- if there are no duplicates then set ACOItem=PCOItem else increment next item
    if @dupsfound = 0
		begin
        select @bcacoitem = @bcpcoitem
		end
    else
    	begin
		---- #132308
		set @counter = 0
		while @counter < 3
			begin
    		-- increment next item
    		select @nextitem = @nextitem + 1
    		select @tmpitem = convert(varchar(10),@nextitem)
    		exec bspHQFormatMultiPart @tmpitem, @inputmask, @bcacoitem output
			if isnull(@bcacoitem,'') = ''
    			begin
				IF XACT_STATE() <> 0 ROLLBACK TRANSACTION
				select @msg = 'Error getting next item, unable to create ACO Item.', @rcode = 1
				goto bspexit
    			end
			---- check if exists
			if not exists(select top 1 1 from bPMOI with (nolock) where PMCo=@pmco and Project=@project and ACO=@aco and ACOItem=@bcacoitem)
				begin
				set @counter = 3
				end
			else
				begin
				IF XACT_STATE() <> 0 ROLLBACK TRANSACTION
				select @msg = 'Error getting next item, unable to create ACO Item.', @rcode = 1
				goto bspexit
				end
			end
    	end
    
    if isnull(@bcacoitem,'') = ''
    	begin
    	select @msg = 'Error approving PCO Item: ' + isnull(@bcpcoitem,'') + ' ACOItem: ' + isnull(@bcacoitem,'Null')
    	goto Approval_Done
    	end
    
    
    -- update PMOI pending values into the approved PMOI positions
    update bPMOI set ACO=@aco, ACOItem=@bcacoitem, Approved='Y', ApprovedDate=@acoapprdate,
    ApprovedBy = @approver, Status=@bcstatus, ApprovedAmt=@approvedamt
    where PMCo=@pmco and Project=@project and PCOType=@pco_type and PCO=@pco and PCOItem=@bcpcoitem
        
    -- update any pending lines into their respective approved positions
    update bPMOL set ACO=@aco, ACOItem=@bcacoitem
    where PMCo=@pmco and Project=@project and PCOType=@pco_type and PCO=@pco and PCOItem=@bcpcoitem
    -- update Material detail
    update bPMMF set ACO=@aco, ACOItem=@bcacoitem
    where PMCo=@pmco and Project=@project and PCOType=@pco_type and PCO=@pco and PCOItem=@bcpcoitem
    -- update subcontract detail
    UPDATE bPMSL SET ACO=@aco, ACOItem=@bcacoitem
	where PMCo=@pmco and Project=@project and PCOType=@pco_type and PCO=@pco and PCOItem=@bcpcoitem
       
	---- now lets create ACO Item from PCO Addons if not an internal change order. #22100, #128966
	if isnull(@ieflag,'E') = 'E'
		begin
        ---- execute SP to create aco item and contract item from addon
        exec @rcode=dbo.vspPMPCOAddonRevItem @pmco, @project, @pco_type, @pco, @bcpcoitem,
					@aco, @bcacoitem, 'X', @msg output
        if @rcode <> 0
            begin
			IF XACT_STATE() <> 0 ROLLBACK TRANSACTION
            goto bspexit
            end
		end

	---- now lets add any add-on phase cost types that are being distributed to #129669
    exec @rcode = dbo.vspPMPCOAddonDistCosts @pmco, @project, @pco_type, @pco, @bcpcoitem,
					@aco, @bcacoitem, @msg output
	if @rcode <> 0
		begin
		IF XACT_STATE() <> 0 ROLLBACK TRANSACTION
		goto bspexit
		end


    ---- loop through all item add-ons and try to add the phase if needed
    select @addon = min(AddOn) from bPMOA
    where PMCo=@pmco and Project=@project and PCOType=@pco_type and PCO=@pco and PCOItem=@bcpcoitem
    while @addon is not null
    begin
        select @phasegroup=PhaseGroup, @phase=Phase, @costtype=CostType, @addon_item=Item
        from PMPA where PMCo=@pmco and Project=@project and AddOn=@addon
        if @phase is null goto get_next_addon1
        if @phase = '' goto get_next_addon1
    
        if @addon_item = '' select @addon_item = null
        if @addon_item is null
            begin
            select @addon_item=ContractItem from bPMOI
            where PMCo=@pmco and Project=@project and PCOType=@pco_type and PCO=@pco and PCOItem=@bcpcoitem
            end
    
        -- validate phase
        exec @rcode=dbo.bspJCVPHASE @jcco, @project, @phase, @phasegroup, 'Y', @pphase output, @desc output,
             @phasegroup output, @pcontract output, @pitem output, @dept output, @projminpct output,
             @JCJPexists output, @msg output
        if @rcode <> 0
            begin
			IF XACT_STATE() <> 0 ROLLBACK TRANSACTION
            goto bspexit
            end
    
        -- if phase does not exist in JCJP then add
        if @JCJPexists <> 'Y'
            begin
            insert into bJCJP (JCCo, Job, PhaseGroup, Phase, Description, Contract, Item, ProjMinPct, ActiveYN, Notes)
            select @jcco, @project, @phasegroup, @phase, @desc, @contract, @addon_item, isnull(@projminpct,0), 'Y',Null
            if @@rowcount = 0
                begin
				IF XACT_STATE() <> 0 ROLLBACK TRANSACTION
                goto bspexit
                end
            end
    
    -- get next add-on
    get_next_addon1:
    select @addon = min(AddOn) from bPMOA
    where PMCo=@pmco and Project=@project and PCOType=@pco_type and PCO=@pco and PCOItem=@bcpcoitem and AddOn>@addon
    end
    

    goto PMOI_loop
    
    
    PMOI_end:
    
    -- Add any Project Addons w/phase-costtype info to JCCH
    insert bJCCH (JCCo,Job,PhaseGroup,Phase,CostType,UM,BillFlag,ItemUnitFlag,PhaseUnitFlag,BuyOutYN,
                LastProjDate,Plugged,ActiveYN,OrigHours,OrigUnits,OrigCost,SourceStatus,InterfaceDate)
    select distinct @pmco, @project, p.PhaseGroup, p.Phase, p.CostType, 'LS', 'C', 'N', 'N','N', null,'N','Y',0,0,0,'Y',null
    from bPMOA a with (Nolock)
    JOIN bPMPA p with (nolock) ON a.PMCo=p.PMCo and a.Project=p.Project and a.AddOn=p.AddOn
    where a.PMCo=@pmco and a.Project=@project and a.PCOType=@pco_type and a.PCO=@pco
    and a.PCOItem=a.PCOItem and p.PhaseGroup is not null and p.Phase is not null
    and p.CostType is not null and not exists(select * from bJCCH where JCCo=@pmco
    and Job=@project and PhaseGroup=p.PhaseGroup and Phase=p.Phase and CostType=p.CostType)


    goto Approval_Done
    





/*********************************************************/
Item_Approval:
    -- If just an item is being approved, update the existing PMOI record with the new goods
    -- Lines for that item are also updated A new PMOI record is not inserted
	if exists(select 1 from bPMOI with (nolock) where PMCo=@pmco and Project=@project and ACO=@aco and ACOItem=@aco_item)
     	  begin
			IF XACT_STATE() <> 0 ROLLBACK TRANSACTION
     	  select @msg = 'Item ' + isnull(@aco_item,'') + ' has already been approved!  No update.', @rcode = 1
     	  goto bspexit
     	  end

	---- first run add-on calculations so that distribution phase cost types are ready to go
	exec @retcode = dbo.vspPMOACalcs @pmco, @project, @pco_type, @pco, @pco_item

	---- get IntExt flag from PMOH
	select @ieflag=IntExt from bPMOH with (nolock) where PMCo=@pmco and Project=@project and ACO=@aco

	---- update PMOI pending values into the new & approved PMOI record
 	update bPMOI
 	set ACO=@aco, ACOItem=@aco_item, Description=@i_desc, ApprovedDate=@item_date,
 		UM=@um, Units=@units, ApprovedAmt=@approved_amt, ContractItem=@contract_item,
 		Approved='Y', ApprovedBy=@approver, Status=isnull(@final_status, Status)
 	where PMCo=@pmco and Project=@project and PCOType=@pco_type and PCO=@pco
    and PCOItem=@pco_item and Approved<>'Y'
 	if @@rowcount = 0
 		begin
		IF XACT_STATE() <> 0 ROLLBACK TRANSACTION
 		select @msg = 'The original pending item has already been approved!  No update.', @rcode = 1
        goto bspexit
 		end
	
	---- Update The ChangeDays field to keep running total
	if isnull(@addtl_days, 0) <> 0
		begin
		update PMOH
		set ChangeDays = isnull(ChangeDays, 0) + @addtl_days
		where ACO=@aco and Project=@project and PMCo = @pmco
		update PMOI
		set ChangeDays = @addtl_days
		where ACO=@aco and Project=@project and PMCo = @pmco and ACOItem = @aco_item
		end
    
 	-- update any pending lines into their respective approved positions
	update bPMOL set ACO=@aco, ACOItem=@aco_item
 	where PMCo=@pmco and Project=@project and PCOType=@pco_type and PCO=@pco
    and PCOItem=@pco_item and ACOItem is null

	---- update material detail
    update bPMMF set ACO=@aco, ACOItem=@aco_item
 	where PMCo=@pmco and Project=@project and PCOType=@pco_type and PCO=@pco
    and PCOItem=@pco_item and ACOItem is null

	---- update subcontract detail
    update bPMSL set ACO=@aco, ACOItem=@aco_item
 	where PMCo=@pmco and Project=@project and PCOType=@pco_type and PCO=@pco
    and PCOItem=@pco_item and ACOItem is NULL
    
    -- add phase for any add ons of this pco item if it does not already exist in JCJP
    select @addon = min(AddOn) from bPMOA with (nolock)
    where PMCo=@pmco and Project=@project and PCOType=@pco_type and PCO=@pco and PCOItem=@pco_item
    while @addon is not null
      begin
      select @phasegroup=PhaseGroup, @phase=Phase, @costtype=CostType, @addon_item=Item
      from bPMPA with (nolock) where PMCo=@pmco and Project=@project and AddOn=@addon

      if @phase is null goto get_next_addon2
      if @phase = '' goto get_next_addon2

      if @addon_item = '' select @addon_item = null
      if @addon_item is null
        begin
        select @addon_item=ContractItem from bPMOI with (nolock)
        where PMCo=@pmco and Project=@project and PCOType=@pco_type and PCO=@pco and PCOItem=@pco_item
        end
    
      -- validate phase
      exec @rcode=dbo.bspJCVPHASE @jcco, @project, @phase, @phasegroup, 'Y', @pphase output, @desc output,
           @phasegroup output, @pcontract output, @pitem output, @dept output, @projminpct output,
           @JCJPexists output, @msg output
      if @rcode <> 0
         begin
         rollback transaction
         goto bspexit
         end

      -- if phase does not exist in JCJP then add
      if @JCJPexists <> 'Y'
         begin
         insert into bJCJP (JCCo, Job, PhaseGroup, Phase, Description, Contract, Item, ProjMinPct, ActiveYN, Notes)
	     select @jcco, @project, @phasegroup, @phase, @desc, @contract, @addon_item, isnull(@projminpct,0), 'Y', Null
         if @@rowcount = 0
            begin
			IF XACT_STATE() <> 0 ROLLBACK TRANSACTION
            goto bspexit
            end
         end

    -- get next add-on
    get_next_addon2:
    select @addon = min(AddOn) from bPMOA with (nolock)
    where PMCo=@pmco and Project=@project and PCOType=@pco_type and PCO=@pco
    and PCOItem=@pco_item and AddOn > @addon
    end
    
 	-- Add any Project Addons w/phase-costtype info to JCCH
 	insert bJCCH (JCCo,Job,PhaseGroup,Phase,CostType,UM,BillFlag,ItemUnitFlag,PhaseUnitFlag,BuyOutYN,
             LastProjDate,Plugged,ActiveYN,OrigHours,OrigUnits,OrigCost,SourceStatus,
               InterfaceDate)
 	select distinct @pmco, @project, p.PhaseGroup, p.Phase, p.CostType, 'LS', 'C', 'N', 'N', 'N',
                    null,'N','Y',0,0,0,'Y',null
 	from bPMOA a with (nolock)
    JOIN bPMPA p with (nolock) ON a.PMCo=p.PMCo and a.Project=p.Project and a.AddOn=p.AddOn
 	Where a.PMCo=@pmco and a.Project=@project and a.PCOType=@pco_type and a.PCO=@pco and a.PCOItem=@pco_item
 	and p.PhaseGroup is not null and p.Phase is not null and p.CostType is not null
 	and not exists(select * from bJCCH where JCCo=@pmco and Job=@project and PhaseGroup=p.PhaseGroup
 	and Phase=p.Phase and CostType=p.CostType)

	----------------------------------------------
	-- CHECK FLAG BEFORE CREATING CHANGE ORDERS --
	----------------------------------------------
	-- TK-04428 TK-06039
	-- update PMSL separately to update SubCO properly
	-- TK-09994 @ReadyForAccounting
	select @retcode=0, @retmsg=''
	exec @retcode = vspPMPCOApprovePMSL @pmco, @project, @pco_type, @pco, @pco_item, @aco, @aco_item, 'A', @ReadyForAccounting,
					-- TK-13118 --
					@CreateChangeOrders, @CreateSingleChangeOrder,
					@retmsg output
	if @retcode > 0
		begin
		IF XACT_STATE() <> 0 ROLLBACK TRANSACTION
		select @msg = @retmsg, @rcode = @retcode
		goto bspexit
		end
 
	-- TK-04428 TK-06039
	-- Update PMMF and generate the POCONum numbers.
	select @retcode=0, @retmsg=''
	exec @retcode = vspPMPCOApprovePMMF @pmco, @project, @pco_type, @pco, @pco_item, @aco, @aco_item, 'A', @ReadyForAccounting,
						-- TK-13118 --
					@CreateChangeOrders, @CreateSingleChangeOrder,
					@retmsg output
	if @retcode > 0
		begin
		IF XACT_STATE() <> 0 ROLLBACK TRANSACTION
		select @msg = @retmsg, @rcode = @retcode
		goto bspexit
		end


	---- now lets create ACO Item from PCO Addons if not an internal change order
	if isnull(@ieflag,'E') = 'E'
		begin
		---- execute SP to create aco item and contract item from addon
		exec @rcode=dbo.vspPMPCOAddonRevItem @pmco, @project, @pco_type, @pco, 
					@pco_item, @aco, @aco_item, 'A', @msg output
		if @rcode <> 0
			begin
			IF XACT_STATE() <> 0 ROLLBACK TRANSACTION
			goto bspexit
			end
		end

	---- now lets add any add-on phase cost types that are being distributed to #129669
    exec @rcode = dbo.vspPMPCOAddonDistCosts @pmco, @project, @pco_type, @pco,
					@pco_item, @aco, @aco_item, @msg output
	if @rcode <> 0
		begin
		IF XACT_STATE() <> 0 ROLLBACK TRANSACTION
		goto bspexit
		end



Approval_Done:

COMMIT TRANSACTION

bspexit:
    ---- deallocate cursor
    if @opencursor = 1
        begin
        close bcPMOI
        deallocate bcPMOI
        select @opencursor = 0
        end
    
    if @rcode<>0 select @msg=@msg 
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspPMPCOApprove] TO [public]
GO
