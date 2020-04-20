SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspPMPCOApproveACOSeqNumVal]
/************************************
*Created by:	GP 3/31/2011
*Modified by:
*
*Purpose:	Validates ACO Seq Number for
*			PMPCOSApprove.
*************************************/
(@PMCo bCompany, @Project bProject, @ACO bACO, @ACOSeq int, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @FoundACO bACO
select @rcode = 0

--VALIDATION
if @PMCo is null
begin
	select @msg = 'Missing PM Company.', @rcode = 1
	goto vspexit
end

if @Project is null
begin
	select @msg = 'Missing Project.', @rcode = 1
	goto vspexit
end

if @ACO is null
begin
	select @msg = 'Missing ACO.', @rcode = 1
	goto vspexit
end

if @ACOSeq is null
begin
	select @msg = 'Missing Report Sequence Number.', @rcode = 1
	goto vspexit
end

--Check if ACOSeq already exists
select top 1 @FoundACO = ACO from dbo.PMOH where PMCo = @PMCo and Project = @Project and ACOSequence = @ACOSeq
if @FoundACO is not null and @FoundACO <> @ACO
begin
	select @msg = 'Report Sequence already assigned to ACO: ' + @FoundACO + '.', @rcode = 1
	goto vspexit
end



vspexit:
	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspPMPCOApproveACOSeqNumVal] TO [public]
GO
