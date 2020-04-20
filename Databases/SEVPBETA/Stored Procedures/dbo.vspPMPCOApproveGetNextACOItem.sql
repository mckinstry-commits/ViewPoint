SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspPMPCOApproveGetNextACOItem]
/************************************
*Created by:	GP 3/25/2011
*Modified by:
*
*Purpose:	Gets the next ACO Item value for
*			PM Change Order Approval form.
*************************************/
(@PMCo bCompany, @Project bProject, @ACO bACO, @ApprovalID smallint, @ACOItem bACOItem output, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @Mask varchar(30), @Length varchar(10), @TempACOItem bACOItem
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

----------------
--GET ACO ITEM--
----------------
--Look at PMPCOApproveItem first
select @TempACOItem = max(cast(i.ACOItem as numeric)) 
from dbo.PMPCOApproveItem i 
join dbo.PMPCOApprove a on a.PMCo=i.PMCo and a.ApprovalID=i.ApprovalID and a.Project=i.Project and a.PCOType=i.PCOType and a.PCO=i.PCO
where a.PMCo = @PMCo and a.ApprovalID = @ApprovalID and a.Project = @Project and a.ACO = @ACO and isnumeric(isnull(i.ACOItem, 1)) = 1
--Increment aco item
if @TempACOItem is not null		set @TempACOItem = @TempACOItem + 1

--Look at PCO Items second
if @TempACOItem is null
begin
	select @TempACOItem = isnull(max(cast(ACOItem as numeric)),0) + 1 
	from dbo.PMOI 
	where PMCo = @PMCo and Project = @Project and ACO = @ACO and isnumeric(isnull(ACOItem, 1)) = 1
end

----------
--FORMAT--
----------
--Get Mask
select @Length = cast(InputLength as varchar(10)), @Mask = InputMask from dbo.DDDT where Datatype = 'bACOItem'
if @Length is null	set @Length = '10'
if @Mask is null	set @Mask = 'R'
if @Mask in ('R','L')	set @Mask = @Length + @Mask + 'N'
--Format ACO Item
exec @rcode = dbo.bspHQFormatMultiPart @TempACOItem, @Mask, @ACOItem output
if @rcode = 1		goto vspexit



vspexit:
	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspPMPCOApproveGetNextACOItem] TO [public]
GO
