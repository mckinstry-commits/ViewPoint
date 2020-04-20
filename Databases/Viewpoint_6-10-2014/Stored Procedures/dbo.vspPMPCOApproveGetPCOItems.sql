SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/************************************
*Created by:	TRL TK-03300 03/24/11
*Modified by:	GP TK-03300 3/31/2011 - added defaults for ApprovalDate and CompletionDate
*				GP TK-04872 5/9/2011 - added default CCOOption 'None'
*				GP TK-06322 6/23/2011 - added sum(i.ChangeDays) to vPMPCOApprove insert
*				GF TK-07900 Revenue re-direct item deducted from approved amount
*				GP TFS 40724 Added ability to add multiple PCOs intially and add in additional PCOs to an existing ApprovalID
*				GP TFS 40724 ApprovalID param needed null value or error thrown with SQL 2012
*
*
*Purpose:  This forms loads Unapproved PCO Items for ACO approval
*from PM Pending Change Orders and PM Change Ordrer Request
*
*used bspPMPCOApproveItemVal for input logic into vPMACOApprove (VP 6.3.0)
*
*Parameters:
*@PMCo 
*@VPUserName, Viewpoint User Name 
*@Source, calling form
*@ApprovalID
*@COR, required when calling form is PM Change Order Request
*@Contract, required for both forms
*@Project, required
*@PCOType, required
*@PCO, required 
*@ErrMsg output
*************************************/
CREATE PROC [dbo].[vspPMPCOApproveGetPCOItems]
(@PMCo bCompany = null, @VPUserName varchar(60), @Source varchar(10)= null,
@COR smallint = null, @Contract bContract = null,
@Project bProject = null,@PCOType bPCOType = null, @PCO bPCO = null, @SelectedPCOs VARCHAR(500), 
@ApprovalID smallint = null output, @ErrMsg varchar(255) output)
as

set nocount on

declare @rcode int, @DeleteApprovalID smallint, @InUseVPUserName varchar(60), @InUseCOR smallint, 
	@InUseContract bContract, @InUsePCOType bPCOType, @InUsePCO bPCO, @PCOKeyID BIGINT

select @rcode = 0, @DeleteApprovalID = null,@InUseCOR = null, @InUseContract = null,@InUsePCOType = null, @InUsePCO = null

if @PMCo is null
begin
	select @ErrMsg = 'Missing PM Company.', @rcode = 1
	goto vspexit
end

if isnull(@VPUserName, '') = '' 
begin
	select @ErrMsg = 'Missing Viewpoint Username.', @rcode = 1
	goto vspexit
end

if isnull(@Source, '') = '' 
begin
	select @ErrMsg = 'Missing Form Source.', @rcode = 1
	goto vspexit
end

--Verify PCO
if @Source = 'PCO' AND @SelectedPCOs IS NULL
begin
	if isnull(@Project, '') = '' 
	begin
		select @ErrMsg = 'Missing Project.', @rcode = 1
		goto vspexit
	end
	
	if isnull(@PCOType, '') = '' 
	begin
		select @ErrMsg = 'Missing PCO Type.', @rcode = 1
		goto vspexit
	end
	
	if isnull(@PCO, '') = ''
	begin
		select @ErrMsg = 'Missing PCO.', @rcode = 1
		goto vspexit
	end
end

--Verify COR
if @Source = 'COR'
begin
	if isnull(@COR, '') = ''
	begin
		select @ErrMsg = 'Missing Change Order Request.', @rcode = 1
		goto vspexit
	end
	
	if isnull(@Contract,'') = '' 
	begin
		select @ErrMsg = 'Missing Contract.', @rcode = 1
		goto vspexit
	end
end

--Only get new ApprovalID and clear old records if we are not adding PCOs to existing Approval session
IF ISNULL(@ApprovalID,0) = 0
BEGIN
	--Get next Approval ID
	select @ApprovalID = isnull(max(ApprovalID), 0) + 1 
	from dbo.PMPCOApprove
	where PMCo = @PMCo

	--Make sure all records are clear before adding any
	exec @rcode = vspPMPCOApproveDelete @PMCo, @VPUserName, @ApprovalID, @ErrMsg output
	if @rcode = 1	goto vspexit
END

--PM Pending Change Orders
if @Source = 'PCO'
begin
	--@SelectedPCOs will be null when only approving one PCO record, get the PCO KeyID
	IF @SelectedPCOs IS NULL
	BEGIN
		SELECT @SelectedPCOs = KeyID FROM dbo.PMOP WHERE PMCo = @PMCo and Project = @Project and PCOType = @PCOType and PCO = @PCO
	END

	WHILE @SelectedPCOs <> ''
	BEGIN
		--Get next KeyID
		SET @PCOKeyID = SUBSTRING(@SelectedPCOs, 0, CHARINDEX(',', @SelectedPCOs, 0))
		--Since @SelectedPCOs is not empty yet but nothing was found, assume last KeyID from @SelectedPCOs
		IF @PCOKeyID = 0
		BEGIN
			SET @PCOKeyID = @SelectedPCOs
		END
		--Remove used KeyID and comma from @SelectedPCOs
		SET @SelectedPCOs = SUBSTRING(@SelectedPCOs, LEN(@PCOKeyID) + 2, LEN(@SelectedPCOs))		
		--Get PCO information from PMOP by KeyID
		SELECT @PMCo = PMCo, @Project = Project, @PCOType = PCOType, @PCO = PCO 
		FROM dbo.PMOP 
		WHERE KeyID = @PCOKeyID

		--Check to see if anyone is approving PCO on a Change Order Request
		select @InUseVPUserName = Username, @InUseCOR = COR, @InUseContract = [Contract]
		from dbo.PMPCOApprove 
		where PMCo = @PMCo and Project = @Project and PCOType = @PCOType and PCO = @PCO 
			and	[Contract] is not null and COR is not null
		If @@rowcount <> 0 
		begin
			select @ErrMsg = 'PCO Type: '+ Ltrim(Rtrim(@PCOType)) + ', PCO: '+ Ltrim(Rtrim(@PCO))
			+ ' on Contract: ' + @InUseContract +', COR: ' + convert(varchar, @InUseCOR)
			+ ', is being approved by: '+ @InUseVPUserName, @rcode=1
			goto vspexit
		end
		
		--Check to see if anyone is approving PCO anywhere in PCO's, COR's, etc.,
		select @InUseVPUserName = Username
		from dbo.PMPCOApprove 
		where PMCo = @PMCo and Project = @Project and PCOType = @PCOType and PCO = @PCO 
		and Username <> @VPUserName
		If @@rowcount <> 0 
		begin
			select @ErrMsg = 'PCO Type: '+ Ltrim(Rtrim(@PCOType)) + ', PCO: '+ Ltrim(Rtrim(@PCO ))
			+ ', is being approved by: '+ @InUseVPUserName, @rcode=1
			goto vspexit
		end

		--Insert rows into vPMPCOApprove	
		insert into dbo.vPMPCOApprove (PMCo, ApprovalID, Project, PCOType, PCO, Username, [Contract], ApprovalDate, CompletionDate, CCOOption, AdditionalDays)
		select p.PMCo, @ApprovalID, p.Project, p.PCOType, p.PCO, @VPUserName, @Contract, dbo.vfDateOnly(), dateadd(day, isnull(sum(i.ChangeDays),0), m.ProjCloseDate), 'None', sum(i.ChangeDays)
		from dbo.PMOP p
		join dbo.PMOI i on i.PMCo=p.PMCo and i.Project=p.Project and i.PCOType=p.PCOType and i.PCO=p.PCO
		join dbo.JCCM m on m.JCCo=p.PMCo and m.[Contract]=p.[Contract]
		where p.PMCo=@PMCo and p.Project=@Project and p.PCOType=@PCOType and p.PCO=@PCO 
		group by p.PMCo, p.Project, p.PCOType, p.PCO, m.ProjCloseDate

		--Insert rows into vPMPCOApproveItem
		--Get PCO Items that aren't on a ACO, regardless of whether ACO is approved or not
		insert into dbo.vPMPCOApproveItem (PMCo, ApprovalID, Project, PCOType, PCO, PCOItem, Approve,
					ACOItemDesc, ContractItem, ApprovedAmount, AdditionalDays, UM, Units)
		select @PMCo, @ApprovalID, @Project, @PCOType, @PCO, i.PCOItem, 'N', i.[Description], i.ContractItem,
					----TK-07900
					[ApprovedAmt] = CASE WHEN i.FixedAmountYN = 'Y' THEN i.FixedAmount - ISNULL(AddOnAmt,0)
									ELSE i.PendingAmount - ISNULL(AddOnAmt,0)
									END,
					ChangeDays, UM,Units
		from dbo.PMOI i
		left join dbo.PMOP p on p.PMCo=i.PMCo and p.Project=i.Project and p.PCOType=i.PCOType and p.PCO=i.PCO
		left join (select z.PMCo,z.Project,z.PCOType,z.PCO, z.PCOItem,AddOnAmt = sum(isnull(z.AddOnAmount,0))
			   from dbo.PMOA z
			   join dbo.PMPA y on y.PMCo=z.PMCo and y.Project=z.Project and y.AddOn=z.AddOn
			   where z.PMCo=@PMCo and z.Project=@Project and z.PCOType=@PCOType and z.PCO=@PCO
			   and y.RevRedirect = 'Y'
			   group by z.PMCo,z.Project,z.PCOType,z.PCO, z.PCOItem,y.RevRedirect)
			as addons on addons.PMCo=i.PMCo and addons.Project=i.Project and addons.PCOType=i.PCOType
				and addons.PCO=i.PCO and addons.PCOItem=i.PCOItem
		where i.PMCo=@PMCo and i.Project=@Project and i.PCOType=@PCOType and i.PCO=@PCO and i.[Contract]=@Contract
		and i.ACO is null and i.ACOItem is null and i.Approved = 'N'
	
	END --end while @SelectedPCOs <> ''	
end --end if @Source = 'PCO'

--PM Change Order Request
if @Source = 'COR'
begin
	--Check to see if another person is approving same Contract Change Order
	select @InUseVPUserName = Username
	from dbo.PMPCOApprove 
	where  PMCo = @PMCo and [Contract] = @Contract and COR = @COR and Username <> @VPUserName
	if @@rowcount > 0
	begin
		select @ErrMsg = 'Contract: ' + @Contract +', COR: ' + convert(varchar,@COR  )
		+ ', is being approved by: '+ @InUseVPUserName, @rcode=1
		goto vspexit
	end
	
	--Check to see if a PCO is being approved anywhere else in PCO's, COR's, etc.,
	select @InUseVPUserName = Username, @InUsePCOType = a.PCOType, @InUsePCO = a.PCO
	from dbo.PMPCOApprove a
	inner join dbo.PMChangeOrderRequestPCO b on b.PMCo=a.PMCo and b.Project=a.Project 
		and b.PCOType=a.PCOType and b.PCO=a.PCO 
	where a.PMCo = @PMCo and a.Project = @Project and a.PCOType = @PCOType and a.PCO = @PCO 
		and Username <> @VPUserName
	if @@rowcount <> 0
	begin
		select @ErrMsg =  'PCO Type: '+ Ltrim(Rtrim(@InUsePCOType)) + ', PCO: '+ Ltrim(Rtrim(@InUsePCO))
		+ ' is approved by: '+ @InUseVPUserName, @rcode=1
		goto vspexit
	end
		
	--Insert rows into vPMPCOApprove
	insert into dbo.vPMPCOApprove (PMCo, ApprovalID, Project, PCOType, PCO, Username, [Contract], COR, 
		ApprovalDate, CompletionDate, CCOOption, AdditionalDays)
	select c.PMCo, @ApprovalID, c.Project, c.PCOType, c.PCO, @VPUserName, @Contract, @COR, dbo.vfDateOnly(), dateadd(day, isnull(sum(i.ChangeDays),0), m.ProjCloseDate), 'None', sum(i.ChangeDays)
	from dbo.PMChangeOrderRequestPCO c
	join dbo.PMOI i on i.PMCo=c.PMCo and i.Project=c.Project and i.PCOType=c.PCOType and i.PCO=c.PCO
	join dbo.JCCM m on m.JCCo=c.PMCo and m.[Contract]=c.[Contract]
	where c.PMCo=@PMCo and c.[Contract]=@Contract and c.COR=@COR
	group by c.PMCo, c.Project, c.PCOType, c.PCO, m.ProjCloseDate
	if @@rowcount = 0
	begin 
		select @ErrMsg = 'No PCO records found',@rcode = 1
		goto vspexit
	end
	
	--Insert rows into vPMPCOApproveItem
	--Get PCO Items that aren't on a ACO, regardless of whether ACO is approved or not
	insert into dbo.vPMPCOApproveItem (PMCo, ApprovalID, Project, PCOType, PCO, PCOItem, Approve,
				ACOItemDesc, ContractItem, ApprovedAmount, AdditionalDays, UM, Units)
	select c.PMCo, @ApprovalID, c.Project, c.PCOType, c.PCO, i.PCOItem, 'N', i.[Description], i.ContractItem,
				----TK-07900
				[ApprovedAmt] = CASE WHEN i.FixedAmountYN = 'Y' THEN i.FixedAmount - ISNULL(AddOnAmt,0)
								ELSE i.PendingAmount - ISNULL(AddOnAmt,0)
								END,
				ChangeDays, UM, Units
	from dbo.PMOI i
	inner join dbo.PMChangeOrderRequestPCO c on c.PMCo=i.PMCo and c.Project=i.Project 
		and c.PCOType=i.PCOType and c.PCO=i.PCO 
	left join dbo.PMOP p on p.PMCo=i.PMCo and p.Project=i.Project and p.PCOType=i.PCOType and p.PCO=i.PCO
	left join (select z.PMCo,z.Project,z.PCOType,z.PCO, z.PCOItem,AddOnAmt = sum(isnull(z.AddOnAmount,0))
		   from dbo.PMOA z
		   join dbo.PMPA y on y.PMCo=z.PMCo and y.Project=z.Project and y.AddOn=z.AddOn
		   where z.PMCo=@PMCo and y.RevRedirect = 'Y'
		   Group By z.PMCo,z.Project,z.PCOType,z.PCO, z.PCOItem,y.RevRedirect)
		as addons on addons.PMCo=i.PMCo and addons.Project=i.Project and addons.PCOType=i.PCOType
			and addons.PCO=i.PCO and addons.PCOItem=i.PCOItem
	where i.PMCo = @PMCo and i.[Contract] = @Contract and i.ACO is null and i.ACOItem is null and i.Approved = 'N'
		and c.COR = @COR
end



vspexit:
	return @rcode
	
	
GO
GRANT EXECUTE ON  [dbo].[vspPMPCOApproveGetPCOItems] TO [public]
GO
