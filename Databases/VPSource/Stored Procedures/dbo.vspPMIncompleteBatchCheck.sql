SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMIncompleteBatchCheck    Script Date: 10/31/2005 ******/
CREATE proc [dbo].[vspPMIncompleteBatchCheck]
/*************************************
* Created By:	GF 10/31/2005 for 6.x was a query statement in 5.x
* Modified By:
*
* USAGE:
* used by PMInterface to check and see if a post in progress batch exists
* for the company, project and month. Need to return the PO, SL, or MO
* batchid and batch status
*
* Pass in :
* PMCo
* Project
* Mth
*
* Returns
* SL, SLCB, PO, POBC, MO batches and status
*
* Error message and return code
*******************************/
(@pmco bCompany, @project bJob, @mth bMonth,
 @pobatchid bBatchID output, @postatus tinyint output,
 @pocbbatchid bBatchID output, @pocbstatus tinyint output,
 @slbatchid bBatchID output, @slstatus tinyint output,
 @slcbbatchid bBatchID output, @slcbstatus tinyint output,
 @mobatchid bBatchID output, @mostatus tinyint output,
 @msg varchar(255) output)
AS
SET NOCOUNT ON

declare @rcode int, @opencursor int, @batchtable varchar(4), @batchid bBatchID,
		@status TINYINT

select @rcode = 0, @opencursor = 0, @pobatchid = 0, @slbatchid = 0, @mobatchid = 0,
		@pocbbatchid = 0, @slcbbatchid = 0, @postatus = 0, @slstatus = 0, @mostatus = 0,
		@pocbstatus = 0, @slcbstatus = 0

-- create cursor on PMBC and HQBC to get any batches that are stuck from PM Interface.
declare pm_batches cursor LOCAL FAST_FORWARD
for select p.BatchTable, p.BatchId, h.[Status]
from dbo.PMBC p 
inner join dbo.HQBC h on p.BatchCo=h.Co and p.Mth=h.Mth and p.BatchId=h.BatchId
where p.Co=@pmco and p.Mth=@mth 

open pm_batches
set @opencursor = 1
  
pm_batches_loop:
	fetch next from pm_batches into @batchtable, @batchid, @status

	if @@fetch_status = -1 goto vspexit
	if @@fetch_status <> 0 goto pm_batches_loop

	-- if status is 5 or 6 clear out of PMBC
	if @status = 5/*posted*/ or @status = 6/*cancelled*/
	begin
		delete from PMBC where Co=@pmco and Project=@project and Mth=@mth and BatchId=@batchid
		goto pm_batches_loop
	end

	-- load values into return parameters
	---- PO batches TK-05548
	if @batchtable = 'POHB' ----AND @ChangeOrderHeaderBatch = 'N'
		BEGIN
		SELECT @pobatchid=@batchid, @postatus=@status
		END
	--IF @batchtable = 'POHB' AND @ChangeOrderHeaderBatch = 'Y'
	--	BEGIN
	--	SELECT @POHBChangeBatchId = @batchid, @POHBChangeStatus = @status
	--	END
	if @batchtable = 'POCB'
		begin              
		select @pocbbatchid=@batchid, @pocbstatus=@status
		END
	
	---- SL batches TK-05548
	if @batchtable = 'SLHB' ----AND @ChangeOrderHeaderBatch = 'N'
		BEGIN
		SELECT @slbatchid=@batchid, @slstatus=@status
		END
	--IF @batchtable = 'SLHB' AND @ChangeOrderHeaderBatch = 'Y'
	--	BEGIN
	--	SELECT @SLHBChangeBatchId = @batchid, @SLHBChangeStatus = @status
	--	END
	if @batchtable = 'SLCB'
		BEGIN
		SELECT @slcbbatchid=@batchid, @slcbstatus=@status
		END
		
	---- MO batches
	if @batchtable = 'INMB'
		BEGIN
		SELECT @mobatchid=@batchid, @mostatus=@status
		END


goto pm_batches_loop

vspexit:
	if @opencursor = 1
	begin
		close pm_batches
		deallocate pm_batches
		set @opencursor = 0
	end

	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMIncompleteBatchCheck] TO [public]
GO
