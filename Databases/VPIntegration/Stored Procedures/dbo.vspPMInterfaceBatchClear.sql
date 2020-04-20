SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



/****** Object:  Stored Procedure dbo.bspPMInterfaceBatchClear    Script Date: 8/28/99 9:36:24 AM ******/
CREATE proc [dbo].[vspPMInterfaceBatchClear]
/*************************************
* Created By:	TRL 05/12/2011 'TK-04412
* Modified By:	GF 10/29/2011 TK-09503 need to delete line 1 with zero value item
*				GF 03/08/2012 TK-13086 145859 allow for different jobs to SL/SCO to inteface
*				GF 04/30/2012 TK-14595 #146332 change to check HQBC for stuck PM interface batches
*               DW 07/13/12 - TK-16355 - Modified the 'BatchClear' stored procedures to delete from the batch tables instead of the batch views.
*
* USAGE:
* used by PMInterface to clear any batches that had been validated but not posted.
*
* Pass in :
*
* PMCo, Mth, POBatchId, POCBBatchId, SLBatchId, SLCBBatchId,
* MOBatchId, MSBatchId
*
* Returns
*	Error message and return code
*******************************/
(@pmco bCompany, @project bJob, @mth bMonth, 
 @pobatchid bBatchID, @pocbbatchid bBatchID, @slbatchid bBatchID,
 @slcbbatchid bBatchID, @mobatchid bBatchID, @msbatchid bBatchID,
 @errmsg varchar(255) output)
AS
SET NOCOUNT ON


declare @rcode int, @batchco bCompany, @batchid bBatchID, @status tinyint,
		@user bVPUserName, @slseq int, @sl VARCHAR(30),@slitem bItem

select @rcode = 0, @batchco = 0, @status = 0, @user = SUSER_SNAME()



-- POHB Batches
select @batchco=p.BatchCo, @status=h.[Status]
from dbo.PMBC p 
inner join dbo.HQBC h ON p.BatchCo=h.Co and p.Mth=h.Mth and p.BatchId=h.BatchId and p.BatchTable=h.TableName
WHERE p.Co=@pmco and Project=@project 
	and p.Mth=@mth 
	and p.BatchTable='POHB' 
	and p.BatchId = @pobatchid
	----TK-14595
	AND h.Status <> 4
if @@rowcount > 0
begin
	if @status < 4 --0(Open), 1(Inprogress), 2(Errors), 3(Valid)
	begin
		-- execute POBatchClear
		exec @rcode = dbo.bspPOBatchClear @batchco, @mth, @pobatchid, @errmsg output
		if @rcode <> 0
		begin
			select @errmsg = isnull(@errmsg,'') + ' - Cannot cancel POHB batch.', @rcode = 1
			goto vspexit
		end
	end

	if @status = 6 --Cancelled
	begin
		delete dbo.bHQBE 
		where Co=@batchco and Mth=@mth and BatchId=@pobatchid
	end
	
	-- clear PM batch table (bPMBC)
	delete dbo.bPMBC 
	where Co=@pmco and Project=@project and Mth=@mth and BatchTable='POHB'and BatchId=@pobatchid and BatchCo=@batchco
end


-- POCB Batches
select @batchco=BatchCo, @status=h.[Status]
from dbo.PMBC p
inner join dbo.HQBC h ON p.BatchCo=h.Co and p.Mth=h.Mth and p.BatchId=h.BatchId and p.BatchTable=h.TableName
WHERE p.Co=@pmco and Project=@project 
	and p.Mth=@mth 
	and p.BatchTable='POCB'
	and p.BatchId = @pocbbatchid
	----TK-14595
	AND h.Status <> 4
if @@rowcount > 0 
BEGIN

	---- TK-09503 update purge flag so we can delete line 1
	UPDATE dbo.vPOItemLine SET PurgeYN = 'Y'
	FROM dbo.vPOItemLine l
	INNER JOIN dbo.bPOIT i ON i.KeyID = l.POITKeyID
	INNER JOIN dbo.bPMBC c ON c.BatchCo = i.POCo AND c.PO = i.PO AND c.POItem = i.POItem
	where c.Co=@pmco and c.Project=@project 
		AND c.Mth=@mth 
		AND c.BatchId=@pocbbatchid 
		AND c.BatchTable='POCB'
		AND c.PO IS NOT NULL
		AND c.POItem IS NOT NULL
		AND l.POItemLine = 1
		
	---- TK-09503 remove POItemLines added via this process zero value items and lines
	DELETE dbo.vPOItemLine
	FROM dbo.vPOItemLine l
	INNER JOIN dbo.bPOIT i ON i.KeyID = l.POITKeyID
	INNER JOIN dbo.bPMBC c ON c.BatchCo = i.POCo AND c.PO = i.PO AND c.POItem = i.POItem
	where c.Co=@pmco and c.Project=@project 
		AND c.Mth=@mth 
		AND c.BatchId=@pocbbatchid 
		AND c.BatchTable='POCB'
		AND c.PO IS NOT NULL
		AND c.POItem IS NOT NULL
		AND l.POItemLine = 1
		
	---- remove POIT rows added via this process zero value items
	DELETE dbo.bPOIT
	FROM dbo.bPOIT i
	INNER JOIN dbo.bPMBC c ON c.BatchCo = i.POCo AND c.PO = i.PO AND c.POItem = i.POItem
	where c.Co=@pmco and c.Project=@project 
		AND c.Mth=@mth 
		AND c.BatchId=@pocbbatchid 
		AND c.BatchTable='POCB'
		AND c.PO IS NOT NULL
		AND c.POItem IS NOT NULL

	if @status < 4 --0(Open), 1(Inprogress), 2(Errors), 3(Valid)
	begin
		-- execute POBatchClear
		exec @rcode = dbo.bspPOBatchClear @batchco, @mth, @pocbbatchid, @errmsg output
		if @rcode <> 0
		begin
			select @errmsg = isnull(@errmsg,'') + ' - Cannot cancel POCB batch.', @rcode = 1
			goto vspexit
		end
	end

	if @status = 6 --Cancelled
	begin
		delete dbo.bHQBE 
		where Co=@batchco and Mth=@mth and BatchId=@pocbbatchid
	end
	-- clear PM batch table (bPMBC)
	delete dbo.bPMBC 
	where Co=@pmco and Project=@project and Mth=@mth and BatchTable='POCB'and BatchId=@pocbbatchid and BatchCo=@batchco

	update dbo.bPMMF 
	set IntFlag=Null
	where PMCo=@pmco and Project=@project and PO is not null and InterfaceDate is null and IntFlag='I'
end

	
-- SLHB Batches
select @batchco=p.BatchCo, @status=h.[Status]
from dbo.PMBC p 
inner join dbo.HQBC h ON p.BatchCo=h.Co and p.Mth=h.Mth and p.BatchId=h.BatchId and p.BatchTable=h.TableName
WHERE p.Co=@pmco and Project=@project
	and p.Mth=@mth 
	and p.BatchTable='SLHB'
	and p.BatchId = @slbatchid
	----TK-14595
	AND h.Status <> 4
if @@rowcount > 0
begin
	if @status < 4 --0(Open), 1(Inprogress), 2(Errors), 3(Valid)
	begin
		-- execute SLBatchClear
		exec @rcode = dbo.bspSLBatchClear @batchco, @mth, @slbatchid, @errmsg output
		if @rcode <> 0
		begin
			select @errmsg = isnull(@errmsg,'') + ' - Cannot cancel SLHB batch.', @rcode = 1
			goto vspexit
		end
	end

	if @status = 6 --Cancelled
	begin
		delete dbo.bHQBE
		where Co=@batchco and Mth=@mth and BatchId=@slbatchid
	end
	
	-- clear PM batch table (bPMBC)
	delete dbo.bPMBC 
	where Co=@pmco and Project=@project and Mth=@mth and BatchTable='SLHB'and BatchId=@slbatchid and BatchCo=@batchco
end


-- SLCB Batches
select @batchco=p.BatchCo, @status=h.[Status]
from dbo.PMBC p 
inner join dbo.HQBC h ON p.BatchCo=h.Co and p.Mth=h.Mth and p.BatchId=h.BatchId and p.BatchTable=h.TableName
where p.Co=@pmco and Project=@project
	and p.Mth=@mth 
	and p.BatchTable='SLCB' 
	and p.BatchId = @slcbbatchid
	----TK-14595
	AND h.Status <> 4
if @@rowcount > 0 
BEGIN

	---- remove SLIT rows added via this process zero value items
	DELETE dbo.bSLIT
	FROM dbo.bSLIT i
	INNER JOIN dbo.bPMBC c ON c.BatchCo = i.SLCo AND c.SL = i.SL AND c.SLItem = i.SLItem
	where c.Co=@pmco
		----TK-13086
		----and c.Project=@project 
		AND c.Mth=@mth 
		AND c.BatchId=@slcbbatchid 
		AND c.BatchTable='SLCB'
		AND c.SL IS NOT NULL
		AND c.SLItem IS NOT NULL


	if @status < 4 --0(Open), 1(Inprogress), 2(Errors), 3(Valid)
	begin
		-- execute SLBatchClear
		exec @rcode = dbo.bspSLBatchClear @batchco, @mth, @slcbbatchid, @errmsg output
		if @rcode <> 0
		begin
			select @errmsg = isnull(@errmsg,'') + ' - Cannot cancel SLCB batch.', @rcode = 1
			goto vspexit
		end
	end

	if @status = 6 --Cancelled
	begin
		delete dbo.bHQBE 
		where Co=@batchco and Mth=@mth and BatchId=@slcbbatchid
	end
		-- spin through bPMBC for SLSeq and remove SLIT rows for items added via change orders
	select @slseq=min(SLSeq)
	from dbo.PMBC 
	where Co=@pmco and Project=@project and Mth=@mth and BatchId=@slcbbatchid and BatchTable='SLCB' 
			and BatchCo=@batchco and SL is not null
	while @slseq is not null
	begin
		-- get SL and SLitem from bPMBC
		select @sl=SL, @slitem=SLItem 
		from dbo.PMBC 
		where Co=@pmco and Project=@project and Mth=@mth and BatchId=@slcbbatchid and BatchTable='SLCB' 
			and BatchCo=@batchco and SLSeq=@slseq
		
		-- delete SL and SLItem from SLIT
		delete dbo.bSLIT
		where SLCo=@batchco and SL=@sl and SLItem=@slitem
		
		-- get next SLSeq
		select @slseq=min(SLSeq)
		from dbo.PMBC 
		where Co=@pmco and Project=@project and Mth=@mth and BatchId=@slcbbatchid and BatchTable='SLCB' 
			and SL is not null and SLSeq>@slseq
		if @@rowcount = 0 set @slseq = null
	end
		
	-- clear PM batch table (bPMBC)
	delete dbo.bPMBC 
	where Co=@pmco and Project=@project and Mth=@mth and BatchTable='SLCB' and BatchId=@slcbbatchid and BatchCo=@batchco
end      

-- INMB Batches
select @batchco=BatchCo, @status=h.[Status]
from dbo.PMBC p 
inner join dbo.HQBC h ON p.BatchCo=h.Co and p.Mth=h.Mth and p.BatchId=h.BatchId and p.BatchTable=h.TableName
where p.Co=@pmco and Project=@project
	and p.Mth=@mth 
	and p.BatchTable='INMB' 
	and p.BatchId = @mobatchid
	AND h.Status <> 4
if @@rowcount > 0 
begin
	if @status < 4
	begin
		-- execute INBatchClear
		exec @rcode = dbo.bspINBatchClear @batchco, @mth, @mobatchid, @errmsg output
		if @rcode <> 0
		begin
			select @errmsg = isnull(@errmsg,'') + ' - Cannot cancel INMB batch ', @rcode = 1
			goto vspexit
		end
	end

	if @status = 6
	begin
		delete dbo.bHQBE 
		where Co=@batchco and Mth=@mth and BatchId=@mobatchid
	end
	-- clear PM batch table (bPMBC)
	delete dbo.bPMBC 
	where Co=@pmco and Project=@project and Mth=@mth and BatchTable='INMB' and BatchId=@mobatchid and BatchCo=@batchco
end
	
-- MS Quotes - no batch delete from bPMBE table
delete dbo.bPMBE 
where Co=@pmco and Project=@project and Mth=@mth
	
vspexit:
	return @rcode



GO
GRANT EXECUTE ON  [dbo].[vspPMInterfaceBatchClear] TO [public]
GO
