SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[vspPMPCOImpactTypeVal]
/************************************
*Created by:	GP 04/05/2011
*Modified by:	
*
*Purpose:	Check if SL or PO detail exists before unchecking on PM PCOs form.
*************************************/
(@PMCo bCompany, @Project bProject, @PCOType bPCOType, @PCO bPCO, 
@ImpactCheckboxValue bYN, @ImpactType char(2), @msg varchar(255) output)
as
set nocount on

declare @rcode int
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

if @ImpactType is null
begin
	select @msg = 'Missing Impact Type.', @rcode = 1
	goto vspexit
end	
else if @ImpactType not in ('SL','PO')
begin
	select @msg = 'Impact Type must be SL or PO.', @rcode = 1
	goto vspexit
end

if @ImpactCheckboxValue = 'N'
begin
	if @ImpactType = 'SL' and exists (select top 1 1 from dbo.PMOL where PMCo=@PMCo and Project=@Project and PCOType=@PCOType and PCO=@PCO and SubCO is not null)
	begin
		select @msg = 'Subcontract Change Order record exists in PCO detail. You must remove before unchecking impact type SL.', @rcode = 1
		goto vspexit
	end

	if @ImpactType = 'PO' and exists (select top 1 1 from dbo.PMOL where PMCo=@PMCo and Project=@Project and PCOType=@PCOType and PCO=@PCO and POCONum is not null)
	begin
		select @msg = 'PO Change Order record exists in PCO detail. You must remove before unchecking impact type PO.', @rcode = 1
		goto vspexit
	end
end



vspexit:
	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspPMPCOImpactTypeVal] TO [public]
GO
