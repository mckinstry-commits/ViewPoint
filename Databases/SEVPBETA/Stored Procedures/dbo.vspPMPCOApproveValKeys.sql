SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE proc [dbo].[vspPMPCOApproveValKeys]
/************************************
*Created by:	GP 3/26/2011
*Modified by:	GF 10/05/2011 TK-00000
*
*
*Purpose:	Validates the key fields Project, PCOType, and PCO
*			for PMPCOApprove.
*************************************/
(@PMCo bCompany, @ApprovalID smallint, @Project bProject, @PCOType bPCOType, @PCO bPCO, 
 @Field varchar(10), @PCOAttachId UNIQUEIDENTIFIER = NULL OUTPUT, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @DeleteApprovalID smallint
select @rcode = 0

--VALIDATION
if @PMCo is null
begin
	select @msg = 'Missing PM Company.', @rcode = 1
	goto vspexit
end

if @ApprovalID is null
begin
	select @msg = 'Missing Approval ID.', @rcode = 1
	goto vspexit
end

--Project Val
if upper(@Field) = 'PROJECT'
begin
	if @Project is null
	begin
		select @msg = 'Missing Project.', @rcode = 1
		goto vspexit
	end
	
	if not exists (select top 1 1 from dbo.PMPCOApprove where PMCo = @PMCo and ApprovalID = @ApprovalID and Project = @Project)
	begin
		select @msg = 'No change order approval records exist for this Project.', @rcode = 1
		goto vspexit	
	end
	else
	begin
		--validate project
		exec @rcode = dbo.vspPMProjectVal @PMCo, @Project, '0;1;2;3', null, null, null, null, null, null, null, null, null,
		null, null, null, null, null, null, null, null, null, null, null, @msg output
		if @rcode = 1	goto vspexit		
	end
end

--PCOType Val
if upper(@Field) = 'PCOTYPE'
begin	
	if @Project is null
	begin
		select @msg = 'Missing Project.', @rcode = 1
		goto vspexit
	end	

	if @PCOType is null
	begin
		select @msg = 'Missing PCO Type.', @rcode = 1
		goto vspexit
	end	
	
	if not exists (select top 1 1 from dbo.PMPCOApprove where PMCo = @PMCo and ApprovalID = @ApprovalID and Project = @Project and PCOType = @PCOType)
	begin
		select @msg = 'No change order approval records exist for this PCO Type.', @rcode = 1
		goto vspexit
	end	
	else	
	begin
		--validate pco type
		exec @rcode = dbo.vspPMDocTypeValForPCO @PCOType, null, null, null, null, null, null, null, null, null,
		null, null, null, null, null, null, null, null, null, null, null, @msg output
		if @rcode = 1	goto vspexit			
	end	
end

--PCO Val
if upper(@Field) = 'PCO'
begin
	if @Project is null
	begin
		select @msg = 'Missing Project.', @rcode = 1
		goto vspexit
	end	

	if @PCOType is null
	begin
		select @msg = 'Missing PCO Type.', @rcode = 1
		goto vspexit
	end	

	if @PCO is null
	begin
		select @msg = 'Missing PCO.', @rcode = 1
		goto vspexit
	end	
	
	if not exists (select top 1 1 from dbo.PMPCOApprove where PMCo = @PMCo and ApprovalID = @ApprovalID and Project = @Project and PCOType = @PCOType and PCO = @PCO)
	begin
		select @msg = 'No change order approval records exist for this PCO.', @rcode = 1
		goto vspexit	
	end
	else
	begin
		--validate pco
		--exec @rcode = dbo.bspPMPCOVal @PMCo, @Project, @PCOType, @PCO, null, @msg output
		--if @rcode = 1	goto vspexit
		----TK-00000
		SELECT @PCOAttachId = UniqueAttchID
		FROM dbo.PMOP
		WHERE PMCo=@PMCo
			AND Project = @Project
			AND PCOType = @PCOType
			AND PCO = @PCO
		IF @@ROWCOUNT = 0
			BEGIN
			SET @msg = 'Invalid PCO'
			SET @rcode = 1
			GOTO vspexit
			END
	end	
end



vspexit:
	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspPMPCOApproveValKeys] TO [public]
GO
