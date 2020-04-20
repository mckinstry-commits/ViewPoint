SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspPOPurge    Script Date: 8/28/99 9:35:26 AM ******/
   CREATE     procedure [dbo].[bspPOPurge]
   /************************************************************************
    * Created : kf 5/22/97
    * Modified : kb 8/7/98
    *            GG 7/21/99
    *			  MV 03/20/03 - #20533 set Purge flag in bPOCT
    *			  MV 07/21/04 - #24999 set purge flag in bPOCD
    *			DC 1/12/09 - #25782 Need to create a RQ Entry purge / deletion form 
    *			TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
    *			GF 08/04/2011 - TK-07440 purge POItemLine and update purge flag
    *
    *
    * Called by the PO Purge program to delete a PO and all of its
    * related detail.  Status must be 'closed', and Month Closed must be
    * equal to or earlier than the Last Month Closed in SubLedgers.
    *
    * Input parameters:
    *  @co         PO Company
    *  @mth        Selected month to purge POs through
    *  @po         PO to Purge
    *
    * Output parameters:
    *  @rcode      0 =  successful, 1 = failure
    *
    *************************************************************************/
   
   	@co bCompany, @mth bMonth, @po varchar(30), 
   	@purgerq bYN, --DC #25782
   	@errmsg varchar(255) output
   
   as
   
   declare @rcode int, @status tinyint, @mthclosed bMonth, @inusemth bMonth, @inusebatchid bBatchID
   declare @rqid bRQ  --DC #25782
   
   set nocount on
   
   IF @co is null
    	begin
    	select @errmsg = 'Missing PO Company!', @rcode = 1
    	goto bspexit
    	end
   IF @mth is null
    	begin
    	select @errmsg = 'Missing month!', @rcode = 1
    	goto bspexit
    	end
   IF @po is null
		begin
		select @errmsg = 'Missing Purchase Order!', @rcode = 1
		goto bspexit
		end
   
   -- make some checks before purging
   select @status = Status, @mthclosed = MthClosed, @inusemth = InUseMth, @inusebatchid = InUseBatchId
   from bPOHD where POCo= @co and PO = @po
   IF @@rowcount = 0
		begin
		select @errmsg = 'Invalid PO# ' + @po, @rcode = 1
		goto bspexit
		end
   IF @status <> 2
		begin
		select @errmsg = 'PO# ' + @po + ' must have a (Closed) status!',  @rcode = 1
		goto bspexit
		end
   IF @mthclosed > @mth
		begin
		select @errmsg = 'Closed in a later month!', @rcode =1
		goto bspexit
		end
   IF @inusebatchid is not null
		begin
		select @errmsg = 'PO# ' + @po + ' is currently in use by a Batch (Mth:' + convert(varchar(8),@inusemth)
		   + ' Batch#: ' + convert(varchar(6),@inusebatchid) + ')', @rcode = 1
		goto bspexit
		end
   
	begin transaction
		-- set Purge flag in bPOHD, bPORD, bPOCT to prevent HQ Auditing during delete
		update bPOHD set Purge='Y' where POCo=@co and PO=@po
		IF @@error <> 0 goto purge_error
		update bPORD set Purge='Y' where POCo=@co and PO=@po
		IF @@error <> 0 goto purge_error
			-- #20533
		update bPOCT set PurgeYN='Y' where POCo=@co and PO=@po
		IF @@error <> 0 goto purge_error
		-- #24999
		update bPOCD set PurgeYN='Y' where POCo=@co and PO=@po
		IF @@error <> 0 goto purge_error
		---- TK-07440
		UPDATE dbo.vPOItemLine SET PurgeYN = 'Y'
		WHERE POCo = @co AND PO = @po
		IF @@ERROR <> 0 GOTO purge_error

		-- delete PO from all related tables - must be done in this order
		delete from bPORD where POCo=@co and PO=@po
		IF @@error <> 0 goto purge_error
		delete from bPOCT where POCo=@co and PO=@po
		IF @@error <> 0 goto purge_error
		delete from bPOCD where POCo=@co and PO=@po
		IF @@error <> 0 goto purge_error
		---- TK-07440
		DELETE FROM dbo.vPOItemLine WHERE POCo=@co AND PO=@po
		IF @@ERROR <> 0 GOTO purge_error
		
		delete from bPOIT where POCo=@co and PO=@po
		IF @@error <> 0 goto purge_error
		delete from bPOHD where POCo=@co and PO=@po
		IF @@error <> 0 goto purge_error
	       
		IF @purgerq = 'Y' 
			BEGIN			
			--RQRR
			DELETE FROM bRQRR
			FROM bRQRR r
				INNER JOIN RQRL l on l.RQCo = r.RQCo and l.RQID = r.RQID and l.PO = @po and l.RQLine = r.RQLine
			where l.RQCo = @co
			IF @@error <> 0 goto purge_error
						
			--One RQID
			select RQID
			from RQRL
			Where RQCo = @co and PO = @po
			group by RQID
			IF @@rowcount = 1 --Only one RQID
				BEGIN
				select @rqid = RQID
				from RQRL 
				Where RQCo = @co and PO = @po

				--RQRL
				alter table bRQRL disable trigger btRQRLd
					DELETE from bRQRL
					where RQID = @rqid
						AND PO = @po
						AND RQCo = @co
					IF @@error <> 0 goto purge_error
				alter table bRQRL enable trigger btRQRLd   

				if not exists (select 1 from RQRL Where RQCo = @co and RQID = @rqid)
					--Delete RQRH
					Delete 
					from bRQRH
					Where RQCo = @co and RQID = @rqid
					IF @@error <> 0 goto purge_error
				END
			ELSE  --Multiple RQID's
				BEGIN				 
				alter table bRQRL disable trigger btRQRLd
				   	
				--use a cursor to process all the lines
				DECLARE bcRQRL CURSOR LOCAL FAST_FORWARD FOR
				SELECT RQID
				from RQRL 
				Where RQCo = @co and PO = @po

				OPEN bcRQRL
				FETCH NEXT FROM bcRQRL
				INTO @rqid
												 	
    			WHILE (@@FETCH_STATUS = 0)
    				BEGIN
					--RQRL
					DELETE from bRQRL
					where RQID = @rqid
						AND PO = @po
						AND RQCo = @co
					IF @@error <> 0 goto purge_error

					if not exists (select 1 from RQRL Where RQCo = @co and RQID = @rqid)
						--Delete RQRH
						Delete 
						from bRQRH
						Where RQCo = @co and RQID = @rqid
						IF @@error <> 0 goto purge_error   
						
    	    		FETCH NEXT FROM bcRQRL
    	    		into @rqid						 				    				
    				END
    				    	    	
     			CLOSE bcRQRL
    			DEALLOCATE bcRQRL
				
				alter table bRQRL enable trigger btRQRLd   
   	    	  
				END    	    	    
    	    END
    	        	        	         
	commit transaction
   
   select @rcode = 0
   goto bspexit
   
   purge_error:
       rollback transaction
       select @rcode = 1
   
   bspexit:
   	return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspPOPurge] TO [public]
GO
