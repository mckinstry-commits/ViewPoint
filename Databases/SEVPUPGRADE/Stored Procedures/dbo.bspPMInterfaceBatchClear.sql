SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMInterfaceBatchClear    Script Date: 8/28/99 9:36:24 AM ******/
   CREATE proc [dbo].[bspPMInterfaceBatchClear]
   /*************************************
    * Created By:  LM  07/10/1998
    * Modified By: LM  01/01/2000 Added clearing of any slit records created and not actually interfaced
    *                             they are kept track of in PMBC.
    *              GF 09/05/2000 Not clearing SLIA and SLCA batches
    *              GF 03/01/2001 update IntFlag for regular items added from change order
    *				GF 02/28/2002 - Added clear for MO and MS Quotes
    *				GF 12/05/2003 - #23212 - check error messages, wrap concatenated values with isnull
    *				GF 12/01/2004 - issue #26332 when status 6 for batch's, make sure HQBE is cleared.
    *				gf 01/04/2005 - #26666 UPDATE PMMF.IntFalg for original items added from change order.
    *				DC 06/29/10 - #135813 - expand subcontract number
    *
    *
    *
    * USAGE:
    * used by PMInterface to clear any batches that had been validated but not posted.
    *
    * Pass in :
    *
    *	PMCo, Project, Mth, POBatchId, POCBBatchId, SLBatchId, SLCBBatchId, MOBatchId, MSBatchId
    *
    *
    *
    * Returns
    *	Error message and return code
    *
    *******************************/
   (@pmco bCompany, @project bJob, @mth bMonth, @pobatchid bBatchID, @pocbbatchid bBatchID,
    @slbatchid bBatchID, @slcbbatchid bBatchID, @mobatchid bBatchID, @msbatchid bBatchID,
    @errmsg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @batchco bCompany, @status tinyint, @slseq int, @sl VARCHAR(30),  --bSL, DC #135813
		@slitem bItem, @user bVPUserName, @batchid bBatchID
   
   select @rcode = 0, @batchco = 0, @status = 0, @user = SUSER_SNAME()
   
   -- -- -- POHB Batches
   select @batchco=p.BatchCo, @status=h.Status
   from bPMBC p with (nolock) 
   JOIN bHQBC h with (nolock) ON p.BatchCo=h.Co and p.Mth=h.Mth and p.BatchId=h.BatchId and p.BatchTable=h.TableName
   WHERE p.Co=@pmco and p.Project=@project and p.Mth=@mth and p.BatchTable='POHB' and p.BatchId = @pobatchid
   if @@rowcount > 0
   	begin
   	if @status < 4
   		begin
   		-- -- -- execute POBatchClear
   		exec @rcode = dbo.bspPOBatchClear @batchco, @mth, @pobatchid, @errmsg output
   		if @rcode <> 0
   			begin
   			select @errmsg = isnull(@errmsg,'') + ' - Cannot cancel POHB batch.', @rcode = 1
   			goto bspexit
   			end
   		end
   
   	if @status = 6
   		begin
   		delete bHQBE where Co=@batchco and Mth=@mth and BatchId=@pobatchid
   		end
   
   	-- -- -- clear PM batch table (bPMBC)
   	delete bPMBC where Co=@pmco and Project=@project and Mth=@mth and BatchTable='POHB'
   	and BatchId=@pobatchid and BatchCo=@batchco
   	end
     
   -- -- -- POCB Batches
   select @batchco=BatchCo, @status=h.Status
   from bPMBC p with (nolock) 
   JOIN bHQBC h with (nolock) ON p.BatchCo=h.Co and p.Mth=h.Mth and p.BatchId=h.BatchId and p.BatchTable=h.TableName
   WHERE p.Co=@pmco and p.Project=@project and p.Mth=@mth and p.BatchTable='POCB'  and p.BatchId = @pocbbatchid
   if @@rowcount > 0 
   	begin
   	if @status < 4
   		begin
         	-- -- -- execute POBatchClear
   		exec @rcode = dbo.bspPOBatchClear @batchco, @mth, @pocbbatchid, @errmsg output
   		if @rcode <> 0
   			begin
   			select @errmsg = isnull(@errmsg,'') + ' - Cannot cancel POCB batch.', @rcode = 1
   			goto bspexit
   			end
   		end
   
   	if @status = 6
   		begin
   		delete bHQBE where Co=@batchco and Mth=@mth and BatchId=@pocbbatchid
   		end
   
   	-- -- -- clear PM batch table (bPMBC)
     	delete bPMBC where Co=@pmco and Project=@project and Mth=@mth and BatchTable='POCB'
     	and BatchId=@pocbbatchid and BatchCo=@batchco
   
   	-- -- -- update bPMMF.IntFlag
   	update bPMMF set IntFlag=Null
   	where PMCo=@pmco and Project=@project and PO is not null and InterfaceDate is null and IntFlag='I'
     	end
           
   -- -- -- SLHB Batches
   select @batchco=p.BatchCo, @status=h.Status
   from bPMBC p with (nolock) 
   JOIN bHQBC h with (nolock) ON p.BatchCo=h.Co and p.Mth=h.Mth and p.BatchId=h.BatchId and p.BatchTable=h.TableName
   WHERE p.Co=@pmco and p.Project=@project and p.Mth=@mth and p.BatchTable='SLHB' and p.BatchId = @slbatchid
   if @@rowcount > 0
   	begin
   	if @status < 4
   		begin
   		-- -- -- execute SLBatchClear
   		exec @rcode = dbo.bspSLBatchClear @batchco, @mth, @slbatchid, @errmsg output
   		if @rcode <> 0
   			begin
   			select @errmsg = isnull(@errmsg,'') + ' - Cannot cancel SLHB batch.', @rcode = 1
   			goto bspexit
   			end
   		end
   
   	if @status = 6
   		begin
   		delete bHQBE where Co=@batchco and Mth=@mth and BatchId=@slbatchid
   		end
   
   	-- -- -- clear PM batch table (bPMBC)
     	delete bPMBC where Co=@pmco and Project=@project and Mth=@mth and BatchTable='SLHB'
     	and BatchId=@slbatchid and BatchCo=@batchco
     	end
   
   
   -- -- -- SLCB Batches
   select @batchco=p.BatchCo, @status=h.Status
   from bPMBC p with (nolock) 
   JOIN bHQBC h with (nolock) ON p.BatchCo=h.Co and p.Mth=h.Mth and p.BatchId=h.BatchId and p.BatchTable=h.TableName
   WHERE p.Co=@pmco and p.Project=@project and p.Mth=@mth and p.BatchTable='SLCB' and p.BatchId = @slcbbatchid
   if @@rowcount > 0
   	begin
   	if @status < 4
   		begin
   		-- -- -- execute SLBatchClear
   		exec @rcode = dbo.bspSLBatchClear @batchco, @mth, @slcbbatchid, @errmsg output
   		if @rcode <> 0
   			begin
   			select @errmsg = isnull(@errmsg,'') + ' - Cannot cancel SLCB batch.', @rcode = 1
   			goto bspexit
   			end
   		end
   
   	if @status = 6
   		begin
   		delete bHQBE where Co=@batchco and Mth=@mth and BatchId=@slcbbatchid
   		end
   
   	-- -- -- spin through bPMBC for SLSeq and remove SLIT rows for items added via change orders
    select @slseq=min(SLSeq) from bPMBC where Co=@pmco and Project=@project and Mth=@mth 
   	and BatchId=@slcbbatchid and BatchTable='SLCB' and BatchCo=@batchco and SL is not null
   	while @slseq is not null
   	begin
   		-- -- -- get SL and SLitem from bPMBC
   		select @sl=SL, @slitem=SLItem 
   		from bPMBC where Co=@pmco and Project=@project and Mth=@mth and BatchId=@slcbbatchid
   		and BatchTable='SLCB' and BatchCo=@batchco and SLSeq=@slseq
   		-- -- -- delete SL and SLItem from bSLIT
   		delete bSLIT where SLCo=@batchco and SL=@sl and SLItem=@slitem
   	-- -- -- get next SLSeq
   	select @slseq=min(SLSeq) from bPMBC where Co=@pmco and Project=@project and Mth=@mth
   	and BatchId=@slcbbatchid and BatchTable='SLCB' and SL is not null and SLSeq>@slseq
   	if @@rowcount = 0 set @slseq = null
   	end
   
   	-- -- -- clear PM batch table (bPMBC)
     	delete bPMBC where Co=@pmco and Project=@project and Mth=@mth and BatchTable='SLCB'
     	and BatchId=@slcbbatchid and BatchCo=@batchco
   
   	-- -- -- update bPMSL.IntFlag
   	update bPMSL set IntFlag=Null
   	where PMCo=@pmco and Project=@project and SL is not null and InterfaceDate is null and IntFlag='I'
     	end      
   
   -- -- -- INMB Batches
   select @batchco=BatchCo, @status=h.Status
   from bPMBC p with (nolock) 
   JOIN bHQBC h with (nolock) ON p.BatchCo=h.Co and p.Mth=h.Mth and p.BatchId=h.BatchId and p.BatchTable=h.TableName
   WHERE p.Co=@pmco and p.Project=@project and p.Mth=@mth and p.BatchTable='INMB' and p.BatchId = @mobatchid
   if @@rowcount = 1 
   	begin
   	if @status < 4
   		begin
   		-- -- -- execute INBatchClear
   		exec @rcode = dbo.bspINBatchClear @batchco, @mth, @mobatchid, @errmsg output
   		if @rcode <> 0
   			begin
   			select @errmsg = isnull(@errmsg,'') + ' - Cannot cancel INMB batch ', @rcode = 1
   			goto bspexit
   			end
   		end
   
   	if @status = 6
   		begin
   		delete bHQBE where Co=@batchco and Mth=@mth and BatchId=@mobatchid
   		end
   
   	-- -- -- clear PM batch table (bPMBC)
     	delete bPMBC where Co=@pmco and Project=@project and Mth=@mth and BatchTable='INMB'
     	and BatchId=@mobatchid and BatchCo=@batchco
     	end
   
   
   -- -- -- MS Quotes - no batch delete from bPMBE table
   delete bPMBE where Co=@pmco and Project=@project and Mth=@mth
   
   
   
   bspexit:
   	if @rcode<>0 select @errmsg = isnull(@errmsg,'')
      	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMInterfaceBatchClear] TO [public]
GO
