SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*****************************************/
CREATE  proc [dbo].[vspPMInterfaceBatchVal]
/*****************************************
* CREATED BY:	TRL 04/19/2011 TK-04412
* MODIFIED By:	GF 05/23/2011 TK-05437
*				GF 12/20/2011 TK-10927 @changeordernumber not null for interface type Purchase order change
*				GF TK-12748 #145870 added validation for inactive phase when ACO Item force phase flag is yes
*			    JayR TK-16099 Removed unused @vali... variable because it overlapped existing @vali... variable.
*
* USAGE:
* used by PMInterface to interface a project or change order from PM to other mods as specified
*
* Pass in :
*	PMCo, Project, Mth, Options, ACO, INCo
*
* Output
*  POBatchid, SLBatchid, MOBatchid, MSBatchid, errmsg
*
* Returns
*	Error message and return code
*******************************/
(@pmco bCompany, @project bJob = NULL, @interfacetype varchar(50) = NULL,
 @id varchar(50) = NULL, @changeordernumber INT = NULL, @aco bACO = NULL,
 @mth bMonth = NULL, @apco bCompany = NULL, @inco bCompany = NULL,
 @pobatchid int output, @postatus int output, @pocbbatchid int output, @pocbstatus int output,
 @slbatchid int output, @slstatus int output, @slcbbatchid int output, @slcbstatus int output,
 @mobatchid int output, @mostatus int output, @msbatchid int output, @interfacestatus int output,
 @errmsg varchar(1000) output)
AS
SET NOCOUNT ON


declare @rcode int,@porcode int,@slrcode int,@morcode int,@msrcode int, 
		@glco bCompany, @errtext varchar(255), @errorinterfacetext varchar(255),
		@inactive_check varchar(2255), @ValidCnt INT, @RetMsg VARCHAR(255),
		/*Approved Change Order varialbles*/
		@ApprovedAmt bDollar, @ACOItem bACOItem,@IntExt char(1), @InactiveCheck varchar(2000) 


select @rcode = 0,@porcode = 0,@slrcode = 0,@morcode = 0,@msrcode = 0 

SET @msbatchid = -1

If IsNull(@interfacetype,'') = ''
begin
	select @errmsg = 'Missing interface type',@rcode = 1
	goto vspexit
end
	
--get GL Company
select @glco=GLCo
from dbo.JCCO
where JCCo=@pmco

--1. Validates JC Company
--2. Validates Job Status and Contract
--3. Validates JCCo and Job allowing posting opens (Post Closed Jobs or Post Soft Closed Jobs)
--4. Validates Job "PR State" and "Liability Templated", which are required values for interfacing Projects
--5. Validates all Job/Phase/CostTypes are active for ACO's, SL's, PO's, MO's and Quotes
--6. Validate that Contract StartMonth is not less than the Batch Month
exec @rcode = dbo.vspPMInterfaceProjectVal @pmco, @project, @interfacetype, @id, @apco, @mth, @errmsg output
If @rcode = 1 
begin
	goto vspexit
end

---- if project update we are done with validation for now
IF @interfacetype = 'Project Update' GOTO vspexit

/*Start Interfacing Original Records*/
--Interface Original records for Purchase Orders
if @interfacetype = 'Purchase Order - Original'
begin
	 -- validate data to be interfaced and insert it into the batch tables
	exec @porcode = dbo.vspPMInterfacePO @pmco, @project, @id, @mth, @glco,
						@pobatchid output, @postatus output, @errorinterfacetext output

	if @postatus = 0 and @porcode = 0 and @pobatchid <> 0
	begin
		-- if batch tables were successfully created, validate the batch
		exec @porcode = dbo.bspPOHBVal @apco, @mth, @pobatchid, 'PM Intface', @RetMsg output
		select @postatus = [Status]
		from dbo.HQBC 
		where Co=@apco and Mth=@mth and BatchId=@pobatchid
		--if @postatus <> 3 /*Valid*/
		--begin
		--	select @errtext = 'POHB Batch Status is not 3 for PO Batch: ' + convert(varchar(6),@pobatchid)
		--	exec @rcode = dbo.bspHQBEInsert @apco, @mth, @pobatchid, @errtext, @errmsg output
		--	select @porcode = 1
		--end
	end
end 


--Interface Original records for Subcontracts
If @interfacetype = ('Subcontract - Original')
begin
   exec @slrcode = dbo.vspPMInterfaceSL @pmco, @project, @id, @mth, @glco,
					@slbatchid output, @slstatus output, @slcbbatchid output, @slcbstatus output,
					@errorinterfacetext output
 
	if @slstatus = 0 and @slrcode = 0 and @slbatchid <> 0
	begin
		exec @slrcode = dbo.bspSLHBVal @apco, @mth, @slbatchid, 'PM Intface', @RetMsg output
		select @slstatus=[Status]
		from dbo.HQBC 
		where Co=@apco and Mth=@mth and BatchId=@slbatchid
		--if @slstatus <> 3 /*valid*/
		--begin
		--	select @errtext = 'SLHB Batch Status is not 3 for SL Batch: ' + convert(varchar(6),@slbatchid)
		--	exec @rcode = dbo.bspHQBEInsert @apco, @mth, @slbatchid, @errtext, @errmsg output
		--	select @slrcode = 1
		--end
	end

----SELECT @errmsg = 'SLCB BatchID: ' + dbo.vfToString(@slcbbatchid) + ' Status: ' + dbo.vfToString(@slcbstatus) + ' SLRCode: ' + dbo.vfToString(@slrcode)
----SET @rcode = 1
----GOTO vspexit

	if @slcbstatus = 0 and @slrcode = 0 and @slcbbatchid <> 0
	begin
		exec @slrcode = dbo.bspSLCBVal @apco, @mth, @slcbbatchid, 'PM Intface', @RetMsg output
		select @slcbstatus=[Status]
		from dbo.HQBC 
		where Co=@apco and Mth=@mth and BatchId=@slcbbatchid
		
		--if @slcbstatus <> 3 /*valid*/
		--begin
		--	select @errtext = 'SLCB Batch Status is not 3 for SL Batch: ' + convert(varchar(6),@slcbbatchid)
		--	exec @rcode = dbo.bspHQBEInsert @apco, @mth, @slcbbatchid, @errtext, @errmsg output
		--	select @slrcode = 1
		--end
	end
end 	

--Interface change order records for Purchase Orders
If @interfacetype = 'Purchase Order CO'
BEGIN
	----TK-10927
	If @changeordernumber IS NULL
		begin
		select @errmsg = 'Missing POCO Number.',@rcode = 1
		goto vspexit
	end

	exec @porcode = dbo.vspPMInterfacePOCONum @pmco, @project, @mth, @glco, @id, @changeordernumber,
					@pobatchid output,@pocbbatchid output, @postatus output, @pocbstatus output,
					@errorinterfacetext output

	if @postatus = 0 and @porcode = 0 and @pobatchid <> 0
	begin
		exec @porcode = dbo.bspPOHBVal @apco, @mth, @pobatchid, 'PM Intface', @RetMsg output
		select @postatus=[Status]
		from dbo.HQBC
		where Co=@apco and Mth=@mth and BatchId=@pobatchid
		--if @postatus <> 3 /*valid*/
		--begin
		--	select @errtext = 'POHB Batch Status is not 3 for PO Batch: ' + convert(varchar(6),@pobatchid)
		--	exec @rcode = dbo.bspHQBEInsert @apco, @mth, @pobatchid, @errtext, @errmsg output
		--	select @porcode = 1
		--end
	end
 
	if @pocbstatus = 0 AND @pocbbatchid <> 0
	begin
		exec @porcode = dbo.bspPOCBVal @apco, @mth, @pocbbatchid, 'PM Intface', @RetMsg output
		select @pocbstatus=[Status]
		from dbo.HQBC
		where Co=@apco and Mth=@mth and BatchId=@pocbbatchid
		--if @pocbstatus <> 3 /*valid*/
		--begin
		--	select @errtext = 'POCB Batch Status is not 3 for PO Batch: ' + convert(varchar(6),@pocbbatchid)
		--	exec @rcode = dbo.bspHQBEInsert @apco, @mth, @pocbbatchid, @errtext, @errmsg output
		--	select @porcode = 1
		--end
	END
	
end


--Interfaced change order records for Subcontracts 
If @interfacetype = 'Subcontract CO'
begin
	exec @slrcode = dbo.vspPMInterfaceSLSubCO @pmco, @project, @mth, @glco, @id, @changeordernumber,
					@slbatchid output, @slcbbatchid output, @slstatus output, @slcbstatus output, 
					@errmsg output

	if @slstatus = 0 and @slrcode = 0 and @slbatchid <> 0
		begin
		exec @slrcode = dbo.bspSLHBVal @apco, @mth, @slbatchid, 'PM Intface', @RetMsg output
		select @slstatus=[Status]
		from dbo.HQBC
		where Co=@apco and Mth=@mth and BatchId=@slbatchid
		--if @slstatus <> 3 /*valid*/
		--begin
		--	select @errtext = 'SLHB Batch Status is not 3 for SL Batch: ' + convert(varchar(6),@slbatchid)
		--	exec @rcode = dbo.bspHQBEInsert @apco, @mth, @slbatchid, @errtext, @errmsg output
		--	select @slrcode = 1
		--end
		
		end


	if @slcbstatus = 0 and @slcbbatchid <> 0
	begin
		exec @slrcode = dbo.bspSLCBVal @apco, @mth, @slcbbatchid, 'PM Intface', @RetMsg output
		select @slcbstatus=[Status]
		from dbo.HQBC
		where Co=@apco and Mth=@mth and BatchId=@slbatchid
		--if @slcbstatus <> 3 /*valid*/
		--begin
		--	select @errtext = 'SLCB Batch Status is not 3 for SL Batch: ' + convert(varchar(6),@slcbbatchid)
		--	exec @rcode = dbo.bspHQBEInsert @apco, @mth, @slcbbatchid, @errtext, @errmsg output
		--	select @slrcode = 1
		--end
	end
end


--Interface Original records for Material Orders
If @interfacetype = ('Material Order')
begin
	exec @morcode = dbo.vspPMInterfaceMO @pmco, @project, @id, @mth, @glco, @inco,
					@mobatchid output, @mostatus output, @errorinterfacetext OUTPUT
 				
	if @mostatus = 0 and @morcode = 0 and @mobatchid <> 0
	begin
		exec @morcode = dbo.bspINMBVal @inco, @mth, @mobatchid, 'PM Intface', @RetMsg output
		select @mostatus=[Status]
		from dbo.HQBC 
		where Co=@inco and Mth=@mth and BatchId=@mobatchid
		--if @mostatus <> 3 /*valid*/
		--begin
		--	select @errtext = 'INMB Batch Status is not 3 for MO Batch: ' + convert(varchar(6),@mobatchid)
		--	exec @rcode = dbo.bspHQBEInsert @inco, @mth, @mobatchid, @errtext, @errmsg output
		--	select @morcode = 1
		--end
	end
end
 
--Interface Original records for MS Quotes
If @interfacetype = ('Quote')
begin
	exec @msrcode = dbo.vspPMInterfaceMS @pmco, @project, @mth, 'Y', @inco, @id,
					@msbatchid output, @errorinterfacetext OUTPUT
end


---- interface approved change orders for JC
If @interfacetype = 'Approved Change Order'
BEGIN
	 --1.  Validate Active Phase/Costs that need to be interfaced that are on Approved ACO's
	begin
		--Check to make sure that if the IntExt flag is set to I, that the contract item amount is 0
		if exists(select ACOItem from dbo.PMOI where PMCo=@pmco and Project=@project and ACO=@id)
		begin
			select @ApprovedAmt = max(ApprovedAmt), @ACOItem=(ACOItem)
			from dbo.PMOI 
			where PMCo = @pmco and Project = @project and ACO = @id
			group by ApprovedAmt, ACOItem
			
			select @IntExt = IntExt
			from dbo.PMOH 
			where PMCo = @pmco and Project = @project and ACO = @id
			if @ApprovedAmt <> 0  and @IntExt = 'I'
			begin
				select @errmsg = 'The change order being interfaced is flagged as internal, but change order item: ' + isnull(@ACOItem,'') 
				+ ' has an approved amount. Approved amount must be zero.',@rcode = 1
				goto vspexit
			end
		end
			
		--need to check for inactive phase/cost types. JCOD insert trigger will not allow
		--#119792 added l.InterfacedDate is null to where clause
		set @InactiveCheck = ''
		
		select @InactiveCheck = @InactiveCheck + 'Phase: ' + h.Phase + ' CostType: ' + convert(varchar(3),h.CostType) + ', '
		from PMOL l
		inner join JCCH h on l.PMCo=h.JCCo and l.Project=h.Job and l.PhaseGroup=h.PhaseGroup and l.Phase=h.Phase and l.CostType=h.CostType
		where l.PMCo=@pmco and l.Project=@project and l.ACO=@id and l.InterfacedDate is null and h.ActiveYN='N'
		----TK-12748
		AND l.SendYN = 'Y'
		if @@rowcount <> 0
		begin
			select @errmsg = 'Inactive phase cost types found for ACO. ' + @InactiveCheck, @rcode = 1
			goto vspexit
		end
	 	
	 	----TK-12748 check for inactive phase and the PMOI force phase flag is yes. The update trigger
	 	----for JCJP will not allow changes to an inactive phase and a trigger error will occur in
	 	----the ACO post.
		set @InactiveCheck = NULL
		select @InactiveCheck = dbo.vfToString(@InactiveCheck) + ' ACO Item: ' + dbo.vfToString(o.ACOItem) + ' Phase: ' + dbo.vfToString(p.Phase) + ','
		FROM dbo.PMOI o
		INNER JOIN dbo.PMOL l ON l.PMCo=o.PMCo and l.Project=o.Project and l.ACO=o.ACO AND l.ACOItem=o.ACOItem
		INNER JOIN dbo.JCJP p on p.JCCo=l.PMCo and p.Job=l.Project and p.PhaseGroup=l.PhaseGroup and p.Phase=l.Phase
		where o.PMCo=@pmco
			AND o.Project=@project
			AND o.ACO=@id
			AND o.ForcePhaseYN = 'Y'
			AND p.ActiveYN = 'N'
			AND l.InterfacedDate IS NULL
			AND p.Item <> o.ContractItem
		if @@rowcount <> 0
			begin
			select @errmsg = 'Phase code is inactive and the ACO item force phase option is checked. Need to set phase active. ' + @InactiveCheck, @rcode = 1
			goto vspexit
			END
		
		/*check for PMOL detail records for a ACO Item and the Item does not exist. We need to delete
		these lines so that the interface post does not error out during post. This is cleanup for
		a prior problem where we could have orphan ACO detail records. #137117*/
		set @ValidCnt = 0
		
		select @ValidCnt = (select count(*)
		from dbo.PMOL l with (nolock)
		where l.PMCo=@pmco and l.Project=@project and l.ACO=@id and l.SendYN='Y' and l.InterfacedDate is null
			and not exists(select 1 from dbo.PMOI i with (nolock) where i.PMCo=l.PMCo and i.Project=l.Project
			and i.ACO=l.ACO and i.ACOItem=l.ACOItem and i.ACOItem is not null))
		if @ValidCnt > 0
		begin
			---- if we have orphans in PMOL, delete
			delete from dbo.PMOL
			from dbo.PMOL l 
			where l.PMCo=@pmco and l.Project=@project and l.ACO=@id and l.SendYN='Y' and l.InterfacedDate is null
				and not exists(select 1 from dbo.PMOI i with (nolock) where i.PMCo=l.PMCo and i.Project=l.Project
				and i.ACO=l.ACO and i.ACOItem=l.ACOItem and i.ACOItem is not null)
			if @@rowcount <> @ValidCnt
			begin
				select @errmsg = 'There is existing PM ACO Item Phase Detail and the ACO Item is missing. Cannot Interface.',@rcode = 1
				goto vspexit
			end
		end
	END
END


-- if errors have occurred need to cleanup
if isnull(@porcode,0) <> 0 or isnull(@slrcode,0) <> 0 or isnull(@morcode,0) <> 0 or @msrcode <> 0
begin
	--POHB/POIB
	if isnull(@pobatchid,0) <> 0
	begin
		delete dbo.POIB where Co=@apco and Mth=@mth and BatchId=@pobatchid
		delete dbo.POHB where Co=@apco and Mth=@mth and BatchId=@pobatchid
		
		exec @rcode = dbo.bspHQBCExitCheck @apco, @mth, @pobatchid, 'PM Intface', 'POHB', @errmsg output
		if @rcode <> 0
		begin
			select @errmsg = isnull(@errmsg,'') + ' - Cannot cancel POHB batch '
		end
	end

	-- POCB
	if isnull(@pocbbatchid,0) <> 0
	begin
		delete dbo.POCB where Co=@apco and Mth=@mth and BatchId=@pocbbatchid
		
		exec @rcode = dbo.bspHQBCExitCheck @apco, @mth, @pocbbatchid, 'PM Intface', 'POCB', @errmsg output
		if @rcode <> 0
		begin
			select @errmsg = isnull(@errmsg,'') + ' - Cannot cancel POCB batch '
		end
	end

	-- SLHB/SLIB
	if isnull(@slbatchid,0) <> 0
	begin
		delete dbo.SLIB where Co=@apco and Mth=@mth and BatchId=@slbatchid
		delete dbo.SLHB where Co=@apco and Mth=@mth and BatchId=@slbatchid
		delete dbo.vSLInExclusionsBatch where Co=@apco and Mth=@mth and BatchId=@slbatchid -- JG TFS# 491
		
		exec @rcode = dbo.bspHQBCExitCheck @apco, @mth, @slbatchid, 'PM Intface', 'SLHB', @errmsg output
		if @rcode <> 0
		begin
			select @errmsg = isnull(@errmsg,'') + ' - Cannot cancel SLHB batch '
		end
	end

	-- SLCB
	if isnull(@slcbbatchid,0) <> 0
	begin
		delete dbo.SLCB where Co=@apco and Mth=@mth and BatchId=@slcbbatchid
		
		exec @rcode = dbo.bspHQBCExitCheck @apco, @mth, @slcbbatchid, 'PM Intface', 'SLCB', @errmsg output
		if @rcode <> 0
		begin
			select @errmsg = isnull(@errmsg,'') + ' - Cannot cancel SLCB batch '
		end
	end

	-- INMB/INIB
	if isnull(@mobatchid,0) <> 0
	begin
		delete dbo.INIB where Co=@inco and Mth=@mth and BatchId=@mobatchid
		delete dbo.INMB where Co=@inco and Mth=@mth and BatchId=@mobatchid
		
		exec @rcode = dbo.bspHQBCExitCheck @inco, @mth, @mobatchid, 'PM Intface', 'INMB', @errmsg output
		if @rcode <> 0
		begin
			select @errmsg = isnull(@errmsg,'') + ' - Cannot cancel INMB batch '
		end
	end

	select @rcode = 1
	select @errmsg = ' Errors exist - cannot interface data. ' ----+ IsNull(@errmsg,'')
	select @interfacestatus=2
end

-- everything is valid
if isnull(@porcode,0) = 0 and isnull(@slrcode,0) = 0 and isnull(@morcode,0) = 0 and isnull(@msrcode,0) = 0
BEGIN
	select @errmsg = 'Interface data validated. ', @interfacestatus = 3
end
  
vspexit:
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPMInterfaceBatchVal] TO [public]
GO
