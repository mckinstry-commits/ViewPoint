SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMIncompleteBatchCheck    Script Date: 10/31/2005 ******/
CREATE proc [dbo].[bspPMIncompleteBatchCheck]
/*************************************
* Created By:	GF 10/31/2005 for 6.x was a query statement in 5.x
* Modified By:
*
*
*
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
*
*
* Returns
* Error message and return code
*
*******************************/
(@pmco bCompany, @project bJob, @mth bMonth,
 @pobatchid bBatchID output, @postatus tinyint output,
 @slbatchid bBatchID output, @slstatus tinyint output,
 @mobatchid bBatchID output, @mostatus tinyint output,
 @pocbbatchid bBatchID output, @pocbstatus tinyint output,
 @slcbbatchid bBatchID output, @slcbstatus tinyint output,
 @msg varchar(255) output)
as
set nocount on

declare @rcode int, @opencursor int, @batchtable varchar(4), @batchid bBatchID, @status tinyint

select @rcode = 0, @opencursor = 0, @pobatchid = 0, @slbatchid = 0, @mobatchid = 0,
		@pocbbatchid = 0, @slcbbatchid = 0, @postatus = 0, @slstatus = 0, @mostatus = 0,
		@pocbstatus = 0, @slcbstatus = 0

-- -- -- create cursor on PMBC and HQBC to get any batches that are stuck from PM Interface.
declare pm_batches cursor LOCAL FAST_FORWARD
for select p.BatchTable, p.BatchId, h.Status
from PMBC p join HQBC h on p.BatchCo=h.Co and p.Mth=h.Mth and p.BatchId=h.BatchId
where p.Co=@pmco and p.Project=@project and p.Mth=@mth

open pm_batches
set @opencursor = 1
  
pm_batches_loop:
fetch next from pm_batches into @batchtable, @batchid, @status

if @@fetch_status = -1 goto bspexit
if @@fetch_status <> 0 goto pm_batches_loop

-- -- -- if status is 5 or 6 clear out of PMBC
if @status = 5 or @status = 6
	begin
	delete from PMBC where Co=@pmco and Project=@project and Mth=@mth and BatchId=@batchid
	goto pm_batches_loop
	end

-- -- -- load values into return parameters
if @batchtable = 'POHB'
	begin
	select @pobatchid=@batchid, @postatus=@status
	end
if @batchtable = 'POCB'
	begin
	select @pocbbatchid=@batchid, @pocbstatus=@status
	end
if @batchtable = 'SLHB'
	begin
	select @slbatchid=@batchid, @slstatus=@status
	end
if @batchtable = 'SLCB'
	begin
	select @slcbbatchid=@batchid, @slcbstatus=@status
	end
if @batchtable = 'INMB'
	begin
	select @mobatchid=@batchid, @mostatus=@status
	end



goto pm_batches_loop





bspexit:
	if @opencursor = 1
		begin
		close pm_batches
		deallocate pm_batches
		set @opencursor = 0
		end

	if @rcode<>0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMIncompleteBatchCheck] TO [public]
GO
