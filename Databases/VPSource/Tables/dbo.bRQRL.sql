CREATE TABLE [dbo].[bRQRL]
(
[RQCo] [dbo].[bCompany] NOT NULL,
[RQID] [dbo].[bRQ] NOT NULL,
[RQLine] [dbo].[bItem] NOT NULL,
[LineType] [tinyint] NOT NULL,
[Route] [tinyint] NOT NULL,
[Quote] [int] NULL,
[QuoteLine] [int] NULL,
[Description] [dbo].[bItemDesc] NULL,
[ExpDate] [dbo].[bDate] NULL,
[ReqDate] [dbo].[bDate] NULL,
[Status] [tinyint] NOT NULL,
[PO] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[POItem] [dbo].[bItem] NULL,
[GLCo] [dbo].[bCompany] NULL,
[GLAcct] [dbo].[bGLAcct] NULL,
[JCCo] [dbo].[bCompany] NULL,
[Job] [dbo].[bJob] NULL,
[PhaseGroup] [dbo].[bGroup] NULL,
[Phase] [dbo].[bPhase] NULL,
[JCCType] [dbo].[bJCCType] NULL,
[INCo] [dbo].[bCompany] NULL,
[Loc] [dbo].[bLoc] NULL,
[MatlGroup] [dbo].[bGroup] NULL,
[Material] [dbo].[bMatl] NULL,
[ShipLoc] [dbo].[bShipLoc] NULL,
[VendorGroup] [dbo].[bGroup] NULL,
[Vendor] [dbo].[bVendor] NULL,
[VendorMatlId] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[EMCo] [dbo].[bCompany] NULL,
[Equip] [dbo].[bEquip] NULL,
[EMGroup] [dbo].[bGroup] NULL,
[WO] [dbo].[bWO] NULL,
[WOItem] [dbo].[bItem] NULL,
[CompType] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Component] [dbo].[bEquip] NULL,
[CostCode] [dbo].[bCostCode] NULL,
[EMCType] [dbo].[bEMCType] NULL,
[UM] [dbo].[bUM] NOT NULL,
[Units] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_bRQRL_Units] DEFAULT ((0)),
[UnitCost] [dbo].[bUnitCost] NULL CONSTRAINT [DF_bRQRL_UnitCost] DEFAULT ((0)),
[ECM] [dbo].[bECM] NULL CONSTRAINT [DF_bRQRL_ECM] DEFAULT ('E'),
[TotalCost] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bRQRL_TotalCost] DEFAULT ((0)),
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[Address] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[Attention] [dbo].[bDesc] NULL,
[City] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[State] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[Zip] [dbo].[bZip] NULL,
[Address2] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[ShipIns] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[Country] [char] (2) COLLATE Latin1_General_BIN NULL,
[ByPassTriggers] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bRQRL_ByPassTriggers] DEFAULT ('N')
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
ALTER TABLE [dbo].[bRQRL] ADD
CONSTRAINT [CK_bRQRL_ECM] CHECK (([ECM]='E' OR [ECM]='C' OR [ECM]='M' OR [ECM] IS NULL))
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
   
   
/****** Object:  Trigger dbo.btRQRLd    Script Date: 3/2/2004 9:59:36 AM ******/
CREATE        trigger [dbo].[btRQRLd] on [dbo].[bRQRL] for DELETE as    
/*-----------------------------------------------------------------
     *  Created: DC 3/2/2004
     *  Modified:  GF 09/08/2004 - issue #25482 - null out RQ# and RQLine in PMMF when status not 5.
     *				DC 1/9/2009 #130129 - Combine RQ and PO into a single module
     *				DC 5/13/2009 #25782 - Need to create a RQ Purge form
     *
     *
     *
     *  Delete trigger for bRQRL.  
     *  Deletes corresponding reviewer records in bRQRR
     *  Inserts into HQ Master Audit entry.
     *
     */----------------------------------------------------------------
	declare @errmsg varchar(255), @validcnt int, @numrows int, @rqco bCompany,
		@quote int, @quoteline int, @msg varchar(255)
    
    IF @@rowcount = 0 return
    set nocount on
    
    --skip trigger if ByPassTrigger = Y
    IF not exists(Select top 1 1 from deleted where ByPassTriggers = 'N') return
   
    --Don't delete record if it exists on a PO or on a Quote.
    /* check RQ PO */
        if exists(select top 1 0 from deleted d where d.PO is not null)
          begin
          select @errmsg = 'Cannot Delete RQ Line. RQ Line is currently on a PO.'
          goto error
          end
   
    /* check RQ Quote */
        if exists(select top 1 0 from deleted d where d.Quote is not null)
          begin
          select @errmsg = 'Cannot Delete RQ Line. RQ Line is currently on a Quote.'
          goto error
          end
    
    -- delete the reviewers for this RQRL record
    delete bRQRR from bRQRR r join deleted d on r.RQCo = d.RQCo and r.RQID = d.RQID and r.RQLine = d.RQLine
    
    -- -- -- update bPMMF where Status <> 5
    update bPMMF set RequisitionNum = null, RQLine = null
    from deleted d join bPMMF m on m.PMCo=d.JCCo and m.Project=d.Job and m.RequisitionNum=d.RQID and m.RQLine=d.RQLine
    where d.Status <> 5
    
    IF @@rowcount <> 1
    	BEGIN
    	--Use a cursor to process all lines
    	DECLARE bcRQRL_delete CURSOR LOCAL FAST_FORWARD FOR
    	SELECT d.RQCo, d.Quote, d.QuoteLine FROM Deleted d
    	
    	OPEN bcRQRL_delete
    	FETCH NEXT FROM bcRQRL_delete INTO @rqco, @quote, @quoteline
    	
    	WHILE (@@FETCH_STATUS = 0)
    		BEGIN
    		--Update the Qoute Status
    		EXEC bspRQSetQuoteLineStatus @rqco, @quote, @quoteline, @msg
    
    		FETCH NEXT FROM bcRQRL_delete INTO @rqco, @quote, @quoteline 
    	    
    		END
    	
    	CLOSE bcRQRL_delete
    	DEALLOCATE bcRQRL_delete
    	END
    ELSE
    	BEGIN
    	SELECT @rqco = d.RQCo, @quote = d.Quote, @quoteline = d.QuoteLine FROM Deleted d
    	--Update the Qoute Status
    	EXEC bspRQSetQuoteLineStatus @rqco, @quote, @quoteline, @msg
    	END
    
    /* Audit RQ Header deletions */
        if exists(select top 1 0 from deleted d join bPOCO a on a.POCo = d.RQCo where a.AuditRQ = 'Y')
          BEGIN
          insert into bHQMA
      	(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	  select 'bRQRL', 'RQ Co#: ' + convert(varchar(3),RQCo) + ' RQID: ' + convert(varchar(10),RQID) + ' RQLine: ' + convert(varchar(20),RQLine),
    	   RQCo, 'D', null, null, null, getdate(), SUSER_SNAME()
    	   from deleted d
        if @@rowcount <> @numrows
    	begin
    	select @errmsg = 'Unable to update HQ Master Audit'
    	goto error
    	end
          END
    
    return
    error:
    	select @errmsg = @errmsg + ' - cannot delete RQ Detail!'
    	RAISERROR(@errmsg, 11, -1);
    	rollback transaction


GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Trigger dbo.btRQRLi    Script Date: 2/25/2004 1:10:56 PM ******/
    CREATE                 trigger [dbo].[btRQRLi] on [dbo].[bRQRL] for INSERT as
    

/*-----------------------------------------------------------------
     *  Created: DC 2/25/04
     *  Modified: DC 1/9/2009 #130129 - Combine RQ and PO into a single module
     *
     *
     * Insert trigger for RQ Lines
     * Rejects insert unless Header record exists
     * Inserts into HQ Master Audit entry. 
     * Inserts Reviewer into bRQRR
     *
     */----------------------------------------------------------------
     declare @numrows int, @validcnt int, @errmsg varchar(255),@quote int,@quoteline int,
    	  	@co bCompany, @rqid bRQ, @rqline bItem, @jcco bCompany, 
    		@job bJob,@emco bCompany, @equip bEquip, @totalcost bDollar, @route int,
    		@rc int, @units int, @msg varchar(255), @inco bCompany, @loc bLoc
    
    
    select @numrows = @@rowcount
    if @numrows = 0 return
    
    SET nocount on
    
    /* check RQ Header */
    SELECT @validcnt = count(1) FROM bRQRH h WITH (NOLOCK)
    	JOIN inserted i ON h.RQCo = i.RQCo and h.RQID = i.RQID
    IF @validcnt <> @numrows
    	BEGIN
    	SELECT @errmsg = 'RQ Header does not exist'
    	GOTO error
    	END
    
    /* check bRQQL if Quote and QuoteLine is not null */
      SELECT @quote = isnull(Quote,0), @quoteline = isnull(QuoteLine,0)
      FROM inserted
    
    if @quote <> 0 or @quoteline <> 0
      BEGIN
    	SELECT @validcnt = count(1)
    	FROM inserted i join bRQQL l WITH (NOLOCK) on i.Quote = l.Quote and i.QuoteLine = l.QuoteLine
      IF @validcnt <> @numrows
    	BEGIN 
    	SELECT @errmsg = 'Quote and Quote line does not exist in bRQQL'
    	GOTO error
    	END
      END
    
    /* add Reviewers **************************************/
    -- use a cursor to process all lines
    declare bcRQRL_insert cursor for
    select i.RQCo, i.RQID, i.RQLine, i.JCCo, i.Job, i.EMCo, i.Equip, i.TotalCost, i.Route,
    i.Quote, i.QuoteLine, i.Units, i.INCo, i.Loc
    from inserted i
    
    OPEN bcRQRL_insert
    FETCH NEXT FROM bcRQRL_insert
    INTO @co, @rqid, @rqline, @jcco, @job, @emco, @equip, @totalcost, @route, @quote, @quoteline,
    @units, @inco, @loc
    
        WHILE (@@FETCH_STATUS = 0)
        	BEGIN 	
    		EXEC @rc = bspRQLineReviewerGet @co, @rqid, @rqline, @jcco, @job, @emco, @equip, @totalcost, @route, @inco, @loc, @msg
    	
    		IF @rc = 1 
    			BEGIN
    			SELECT @errmsg = @msg
    			GOTO error
    			END
    
    		--If the RQ Line is being added to a Quote by the Quote Manager then the
    		--Quote Line needs to be updated (Units and Total cost need to be recalculated
    		IF ISNULL(@quote, -1) <> -1
    			BEGIN
    			UPDATE bRQQL SET Units = Units + @units, TotalCost = TotalCost + @totalcost
    			WHERE RQCo = @co AND Quote = @quote AND QuoteLine = @quoteline
    			END
    
    		--Update the RQ Line status
    		EXEC bspRQSetRQLineStatus @co, @rqid, @rqline, @msg
    		
    		--Update the Qoute Status
    		EXEC bspRQSetQuoteLineStatus @co, @quote, @quoteline, @msg
    
        	FETCH NEXT FROM bcRQRL_insert
        	INTO @co, @rqid, @rqline, @jcco, @job, @emco, @equip, @totalcost, @route, 
    		@quote, @quoteline, @units, @inco, @loc
        	END
    
        CLOSE bcRQRL_insert
        DEALLOCATE bcRQRL_insert
    
    /* add HQ Master Audit entry */
        if exists(select top 1 0 from inserted i join bPOCO a on a.POCo = i.RQCo where a.AuditRQ = 'Y')
          BEGIN
          insert into bHQMA
      	(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	  select 'bRQRL', 'RQCo: ' + convert(varchar(3),RQCo) + ' RQID: ' + convert(varchar(10),RQID) + ' RQLine: ' + convert(varchar(20),RQLine),
    	   RQCo, 'A', null, null, null, getdate(), SUSER_SNAME()
    	   from Inserted i
        if @@rowcount <> @numrows
    	begin
    	select @errmsg = 'Unable to update HQ Master Audit'
	goto error
    	end
          END
    
    return
    
    error:
        SELECT @errmsg = @errmsg +  ' - cannot insert RQ Line!'
        RAISERROR(@errmsg, 11, -1);
        rollback transaction


GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/****** Object:  Trigger dbo.btRQRLu    Script Date: 3/2/2004 12:31:08 PM ******/
    CREATE                      TRIGGER [dbo].[btRQRLu] ON [dbo].[bRQRL] FOR UPDATE AS    
/*-----------------------------------------------------------------
    *Created:  DC  03/02/2004
    *Modified: GWC 09/21/2004
	*			DC	10/11/2007 - #125594 - Changing PO number in PO batch should update RQRL.PO column
	*			DC 03/07/08 - Issue #127387:  Modify PO/RQ  for International addresses
	*			DC 1/9/2009 - #130129 - Combine RQ and PO into a single module
	*			DC 7/1/2009 - #28539 - Improve the filter in RQ Entry
	*			GP 7/27/2011 - TK-07144 changed bPO to varchar(30)
	*
    *
    *Purpose:
    *  - Update trigger for RQ Lines
    *  - Rejects updates to key fields
    *  - Changes status to open and logs change in Reviewer table if Status is not open
    *  - Inserts records into HQ Master Audit entry. 
    */----------------------------------------------------------------
    DECLARE @numrows int, 
    		@validcnt int, 
    		@co bCompany, 
    		@rqid bRQ, 
    		@rqline bItem, 
    		@itotalcost bDollar, 
    		@iroute int,
    		@dtotalcost bDollar, 
    		@droute int,
    		@iquote int,
    		@iquoteline int,
    		@dquote int,
    		@dquoteline int,
    		@dunits bUnits,
    		@iunits bUnits, 
    		@istatus int,
    		@dstatus int,
    		@ilinetype int,
    		@dlinetype int,
    		@iexpdate bDate,
    		@dexpdate bDate,
    		@ireqdate bDate,
    		@dreqdate bDate,
    		@idescription bItemDesc,
    		@ddescription bItemDesc,
    		@ijcco bCompany,
    		@djcco bCompany,
    		@ijob bJob,
    		@djob bJob,
    		@ijcctype bJCCType,
    		@djcctype bJCCType,
    		@iinco bCompany,
    		@dinco bCompany,
    		@iloc bLoc,
    		@dloc bLoc,
    		@ishiploc varchar(10),
    		@dshiploc varchar(10),
    	
    		@ivendorgroup bGroup,
    		@ivendor bVendor,
    		@ivendormatlid varchar(30),
    		@iunitcost bUnitCost,
    		@iemco bCompany,
    		@iwo bWO,
    		@iwoitem bItem,
    		@iemctype bEMCType,
    		@icostcode bCostCode,
    		@iequip bEquip,
    		@iphasegroup bGroup,
    		@iphase bPhase,
    		@imatlgroup bGroup,
    		@imaterial	bMatl,
    		@ium bUM,
    		@icomptype varchar(10),
    		@icomponent bEquip,
    		@iecm bECM,
    		--@inotes varchar(255),
    		@iaddress varchar(60),
    		@iattention bDesc,
    		@icity varchar(30),
    		@istate varchar(4),
    		@izip bZip,
    		@iaddress2 varchar(60),
    		@ishipins varchar(60),
    		@iemgroup bGroup,
    		--@itotalcost bDollar,
    		@iglacct bGLAcct,
    		@iglco bCompany,
    
    		@dvendorgroup bGroup,
    		@dvendor bVendor,
    		@dvendormatlid varchar(30),
    		@dunitcost bUnitCost,
    		@demco bCompany,
    		@dwo bWO,
    		@dwoitem bItem,
    		@demctype bEMCType,
    		@dcostcode bCostCode,
    		@dequip bEquip,
    		@dphasegroup bGroup,
    		@dphase bPhase,
    		@dmatlgroup bGroup,
    		@dmaterial	bMatl,
    		@dum bUM,
    		@dcomptype varchar(10),
    		@dcomponent bEquip,
    		@decm bECM,
    		--@dnotes varchar(255),
    		@daddress varchar(60),
    		@dattention bDesc,
    		@dcity varchar(30),
    		@dstate varchar(4),
    		@dzip bZip,
    		@daddress2 varchar(60),
    		@dshipins varchar(60),
    		@demgroup bGroup,
    		--@dtotalcost bDollar,
    		@dglacct bGLAcct,
    		@dglco bCompany,
   		@ipo varchar(30),
   		@dpo varchar(30),
    		@history varchar(3000),
    		@rc int,
    		@msg varchar(255),
    		@errmsg varchar(255)
    
    
    SELECT @numrows = @@ROWCOUNT
    IF @numrows = 0 RETURN
      
    SET NOCOUNT ON
    
    --Check for key changes
    SELECT @validcnt = COUNT(1) FROM Deleted d, Inserted i
    WHERE d.RQCo = i.RQCo AND d.RQID = i.RQID AND d.RQLine = i.RQLine
      
    --If the counts are different, then keys have been changed, update the error
    --message and exit the trigger, rolling back the changes
    IF @numrows <> @validcnt
    	BEGIN
     	SELECT @errmsg = 'Cannot change RQ Company, RQID or RQLine'
     	GOTO error
     	END --If Keys have been changed
    
	--DC 125594
	--If the PO number is being updated, then allow it and skip down to the EndStatement
   IF EXISTS(SELECT i.PO 
   			FROM Deleted d, Inserted i
   			WHERE d.RQCo = i.RQCo 
   				AND d.RQID = i.RQID 
   				AND d.RQLine = i.RQLine 
   				AND i.PO IS NOT NULL 
   				AND i.PO <> d.PO)
   	BEGIN
    	GOTO EndStatement
   	END 
   	
	--DC #28539
	--If the ByPassTrigger is Y, then allow it and skip down to the EndStatement
   IF EXISTS(SELECT i.PO 
   			FROM Deleted d, Inserted i
   			WHERE d.RQCo = i.RQCo 
   				AND d.RQID = i.RQID 
   				AND d.RQLine = i.RQLine 
   				AND i.ByPassTriggers = 'Y')
   	BEGIN
    	GOTO EndStatement
   	END 
   	

   --If any of the RQ Lines currently have a PO, then they cannot be
   --updated at this time.
   IF EXISTS(SELECT d.PO 
   			FROM Deleted d 
   			JOIN Inserted i on d.RQCo = i.RQCo and d.RQID = i.RQID and d.RQLine = i.RQLine
   			JOIN bPOHD p on p.POCo = d.RQCo and p.PO = d.PO)  --DC #28539
   			--WHERE d.RQCo = i.RQCo 
   			--	AND d.RQID = i.RQID 
   			--	AND d.RQLine = i.RQLine) 
   				--AND i.PO IS NOT NULL   --DC #28539
   				--AND d.PO IS NOT NULL)  --DC #28539
   	BEGIN
    	SELECT @errmsg = 'Cannot update RQ Line. RQ Line is currently on PO'
    	GOTO error
   	END --If RQLine exists on Quote 
   
    --IF EXISTS (SELECT i.Status, d.Status FROM Inserted i INNER JOIN
    --Deleted d ON i.RQCo = d.RQCo AND i.RQID = d.RQID AND i.RQLine = d.RQLine
   
    --WHERE ISNULL(i.Status,-1) <> ISNULL(d.Status,-1))
    --	BEGIN
    --	RETURN
    --	END
   
    
    --If any of the RQ Lines currently have a Quote or Quote Line, then they cannot be
    --updated at this time.
    --IF EXISTS(SELECT d.Quote FROM Deleted d, Inserted i
    --WHERE d.RQCo = i.RQCo AND d.RQID = i.RQID AND d.RQLine = i.RQLine AND
    --i.Quote IS NOT NULL AND d.Quote IS NOT NULL)
    --	BEGIN
    --	GOTO bspexit
    --	END --If RQLine exists on Quote 
    
    --If more than one record is being updated, then the cursor will be used to process
    --all of the rows
    IF @numrows <> 1
    	BEGIN
    	--Use a cursor to process all lines
    	DECLARE bcRQRL_update CURSOR LOCAL FAST_FORWARD FOR
    	SELECT i.RQCo, i.RQID, i.RQLine, i.TotalCost, i.Route, d.Route, d.TotalCost, 
    	i.Quote, i.QuoteLine, d.Quote, d.QuoteLine, d.Units, i.Units, i.Status, d.Status,
    	i.LineType, d.LineType,i.ExpDate, d.ExpDate,i.ReqDate, d.ReqDate, 
    	i.Description, d.Description, i.JCCo, d.JCCo,i.Job, d.Job, i.JCCType, d.JCCType,
    	i.INCo, d.INCo, i.Loc, d.Loc, i.ShipLoc, d.ShipLoc, i.VendorGroup, d.VendorGroup,
    	i.Vendor, d.Vendor, i.VendorMatlId, d.VendorMatlId, i.UnitCost, d.UnitCost,
    	i.EMCo, d.EMCo, i.WO, d.WO, i.WOItem, d.WOItem, i.EMCType, d.EMCType,
    	i.CostCode, d.CostCode, i.Equip, d.Equip, i.PhaseGroup, d.PhaseGroup, i.Phase, d.Phase,
    	i.MatlGroup, d.MatlGroup, i.Material, d.Material, i.UM, d.UM, i.CompType, d.CompType,
    	i.Component, d.Component, i.ECM, d.ECM, i.Address, d.Address,
    	i.Attention, d.Attention, i.City, d.City, i.State, d.State, i.Zip, d.Zip, 
    	i.Address2, d.Address2, i.ShipIns, d.ShipIns, i.EMGroup, d.EMGroup, i.GLAcct, d.GLAcct,
    	i.GLCo, d.GLCo,i.PO, d.PO FROM Inserted i
    	JOIN Deleted d ON i.RQCo = d.RQCo and i.RQID = d.RQID and i.RQLine = d.RQLine
    	 	
    	
    	OPEN bcRQRL_update
    	FETCH NEXT FROM bcRQRL_update
    	into @co, @rqid, @rqline, @itotalcost, @iroute, @droute, @dtotalcost, 
    	@iquote, @iquoteline, @dquote, @dquoteline, @dunits, @iunits, @istatus, @dstatus,
    	@ilinetype, @dlinetype, @iexpdate, @dexpdate, @ireqdate, @dreqdate, 
    	@idescription, @ddescription, @ijcco, @djcco, @ijob, @djob, @ijcctype, @djcctype,
    	@iinco, @dinco, @iloc, @dloc, @ishiploc, @dshiploc, @ivendorgroup, @dvendorgroup,
    	@ivendor, @dvendor, @ivendormatlid, @dvendormatlid, @iunitcost, @dunitcost,
    	@iemco, @demco, @iwo, @dwo, @iwoitem, @dwoitem, @iemctype, @demctype,
    	@icostcode, @dcostcode, @iequip, @dequip, @iphasegroup, @dphasegroup, @iphase, @dphase,
    	@imatlgroup, @dmatlgroup, @imaterial, @dmaterial, @ium, @dum, @icomptype, @dcomptype,
    	@icomponent, @dcomponent, @iecm, @decm, @iaddress, @daddress,
    	@iattention, @dattention, @icity, @dcity, @istate, @dstate, @izip, @dzip, 
    	@iaddress2, @daddress2, @ishipins, @dshipins, @iemgroup, @demgroup, @iglacct, @dglacct,
    	@iglco, @dglco, @ipo, @dpo  
    	
    	WHILE (@@FETCH_STATUS = 0)
    		BEGIN
   		/**************************************
   		If linetype is 5-WorkOrder and Route is
   		changed to Stock then update the WO and 
   		change the PSFlag to S - Stock
   		**************************************/
   		IF @ilinetype = 5 and @iroute = 2 and @droute <> 2
   			BEGIN
   			UPDATE EMWP
   			SET PSFlag = 'S'
   			WHERE EMCo = @iemco
   				and	WorkOrder = @iwo
   				and WOItem = @iwoitem
   				and MatlGroup = @imatlgroup
   				and Material = @imaterial
   			END
   
    		--Add threshold reviewer if Route is Purchase and Total Cost is greater then 
    		--the Threshold amount
    		IF @iroute = 1  --1 = Purchase
    			BEGIN		
    			IF EXISTS(SELECT TOP 1 1 FROM bPOCO WITH (NOLOCK) WHERE Threshold IS NOT NULL AND POCo = @co)
    				BEGIN
    				IF (@itotalcost > (SELECT Threshold FROM bPOCO WITH (NOLOCK) WHERE POCo = @co)) 
    				AND (@dtotalcost <= (SELECT Threshold FROM bPOCO WITH (NOLOCK) WHERE POCo = @co))
    					BEGIN
    					INSERT bRQRR (RQCo, RQID, RQLine, Reviewer, AssignedDate, Status)
    						SELECT @co, @rqid, @rqline, r.ThresholdReviewer, GETDATE(), 0
    						FROM bPOCO r WITH (NOLOCK)
    						WHERE r.POCo = @co AND r.ThresholdReviewer IS NOT NULL
    					END --Total cost is greater than Threshold for the first time
    				END --Threshold has been setup in bPOCO
    	
    				--If the Route has been changed to Purchase, add the Purchase reviewer
    				--that has been setup in RQ Company (if one has been setup)
    				IF @iroute <> @droute
    					BEGIN
    					EXEC @rc = bspRQLineReviewerGet @co, @rqid, @rqline, @ijcco, @ijob, @iemco, @iequip,@itotalcost, @iroute, @iinco, @iloc, @errmsg
    					END

    				END --If Route = Purchase			
    			
    			--If the RQ Line is being removed from a quote (Quote is now null, but used to contain
    			--a value) then the Quote Line needs to be updated (Units and Total cost recalculated)
    			IF @iquote IS NULL AND ISNULL(@iquote, -1) <> ISNULL(@dquote, -1)
    				BEGIN
    				UPDATE bRQQL SET Units = Units - @dunits, TotalCost = TotalCost - @dtotalcost
    				WHERE RQCo = @co AND Quote = @dquote AND QuoteLine = @dquoteline
    				END --If Quote Line has been removed	
    
   			IF @iquote IS NOT NULL AND @dquote IS NULL AND @ium = 'LS'
   				BEGIN
   				UPDATE bRQQL SET TotalCost = TotalCost + @itotalcost
    				WHERE RQCo = @co AND Quote = @iquote AND QuoteLine = @iquoteline
   				END
   
    			--Create the history line of the changes being made to the RQ Line
    			SELECT @history = '' --Initialize the history variable 
    	
    			
    			IF ISNULL(@ilinetype, 0) <> ISNULL(@dlinetype, 0)
    				BEGIN
    				SELECT @history = ISNULL(@history,'') + 'Line Type was changed from "' + 
    				RTRIM(CONVERT(char(30),ISNULL(@dlinetype, ''))) + '" to "' + 
    				RTRIM(CONVERT(char(30),ISNULL(@ilinetype, ''))) + '". '
    				END --If Line Type was changed
    		
    			IF ISNULL(@iroute, 0) <> ISNULL(@droute, 0)
    				BEGIN
    				SELECT @history = ISNULL(@history,'') + 'Route was changed from "' +  
    				RTRIM(CONVERT(char(30),ISNULL(@droute, ''))) + '" to "' + 
    				RTRIM(CONVERT(char(30),ISNULL(@iroute, ''))) + '". '
    				END --If Route was changed
    	
    			IF ISNULL(@iexpdate, '') <> ISNULL(@dexpdate, '')
    				BEGIN
    				SELECT @history = ISNULL(@history,'') + 'Expected Date was changed from "' + 
    				CONVERT(char(12),ISNULL(@dexpdate, '')) + '" to "' + 
    				CONVERT(char(12),ISNULL(@iexpdate, '')) + '". '
    				END --If Expected Date was changed
    	
    			IF ISNULL(@ireqdate, '') <> ISNULL(@dreqdate, '')
    				BEGIN
    				SELECT @history = ISNULL(@history,'') + 'Required Date was changed from "' + 
    				CONVERT(char(12),ISNULL(@dreqdate, '')) + '" to "' + 
    				CONVERT(char(12),ISNULL(@ireqdate, '')) + '". '
    				END --If Required Date was changed
    	
    			IF ISNULL(@idescription, '') <> ISNULL(@ddescription, '')
    				BEGIN
    				SELECT @history = ISNULL(@history,'') + 'Description was changed from "' + 
    				ISNULL(@ddescription, '') + '" to "' + ISNULL(@idescription, '') + '". '
    				END --If Description was changed
    			
    			IF ISNULL(@ijcco, 0) <> ISNULL(@djcco, 0)
    				BEGIN
    				SELECT @history = ISNULL(@history,'') + 'JC Company was changed from "' + 
    				RTRIM(CONVERT(char(30),ISNULL(@djcco, ''))) + '" to "' + 
    				RTRIM(CONVERT(char(30),ISNULL(@ijcco, ''))) + '". '
    				END --If JC Company was changed
    	
    			IF ISNULL(@ijob, '') <> ISNULL(@djob, '')
    				BEGIN
    				SELECT @history = ISNULL(@history,'') + 'Job was changed from "' + 
    				ISNULL(@djob, '') + '" to "' + ISNULL(@ijob, '') + '". '
    				END --If Job was changed
    	
    			IF ISNULL(@ijcctype, 0) <> ISNULL(@djcctype, 0)
    				BEGIN
    				SELECT @history = ISNULL(@history,'') + 'JC Cost Type was changed from "' +  
    				RTRIM(CONVERT(char(30),ISNULL(@djcctype, ''))) + '" to "' + 
    				RTRIM(CONVERT(char(30),ISNULL(@ijcctype, ''))) + '". '
    				END --If JC Cost Type was changed
    	
    			IF ISNULL(@iinco, 0) <> ISNULL(@dinco, 0)
    				BEGIN
    				SELECT @history = ISNULL(@history,'') + 'IN Company was changed from "' +  
    				RTRIM(CONVERT(char(30),ISNULL(@dinco, ''))) + '" to "' + 
    				RTRIM(CONVERT(char(30),ISNULL(@iinco, ''))) + '". '
    				END --If IN Company was changed
    	
    			IF ISNULL(@iloc, '') <> ISNULL(@dloc, '')
    				BEGIN
    				SELECT @history = ISNULL(@history,'') + 'IN Location was changed from "' + 
    				ISNULL(@dloc, '') + '" to "' + ISNULL(@iloc, '') + '". '
    				END --If IN Location was changed
    	
    			IF ISNULL(@ishiploc, '') <> ISNULL(@dshiploc, '')
    				BEGIN
    				SELECT @history = ISNULL(@history,'') + 'Ship Location was changed from "' +  
    				ISNULL(@dshiploc, '') + '" to "' + ISNULL(@ishiploc, '') + '". '
    				END --If Ship Location was changed
    	
    			IF ISNULL(@ivendorgroup, 0) <> ISNULL(@dvendorgroup, 0)
    				BEGIN
    				SELECT @history = ISNULL(@history,'') + 'Vendor Group was changed from "' +  
    				RTRIM(CONVERT(char(30),ISNULL(@dvendorgroup, ''))) + '" to "' + 
    				RTRIM(CONVERT(char(30),ISNULL(@ivendorgroup, ''))) + '". '
    				END --If Vendor Group was changed
    	
    			IF ISNULL(@ivendor, 0) <> ISNULL(@dvendor, 0)
    				BEGIN
    				SELECT @history = ISNULL(@history,'') + 'Vendor was changed from "' +  
    				RTRIM(CONVERT(char(30),ISNULL(@dvendor, ''))) + '" to "' + 
    				RTRIM(CONVERT(char(30),ISNULL(@ivendor, ''))) + '". '
    				END --If Vendor was changed
    	
    			IF ISNULL(@ivendormatlid, '') <> ISNULL(@dvendormatlid, '')
    				BEGIN
    				SELECT @history = ISNULL(@history,'') + 'Vendor Material ID was changed from "' +  
    				ISNULL(@dvendormatlid, '') + '" to "' + ISNULL(@ivendormatlid, '') + '". '
    				END --If Vendor Material ID was changed
    	
    			IF ISNULL(@iunitcost, 0) <> ISNULL(@dunitcost, 0)
    				BEGIN
    				SELECT @history = ISNULL(@history,'') + 'Unit Cost was changed from "' +  
    				RTRIM(CONVERT(char(30),ISNULL(@dunitcost, ''))) + '" to "' + 
    				RTRIM(CONVERT(char(30),ISNULL(@iunitcost, ''))) + '". '
    				END --If Unit Cost was changed
    	
    			IF ISNULL(@iemco, 0) <> ISNULL(@demco, 0)
    				BEGIN
    				SELECT @history = ISNULL(@history,'') + 'EM Company was changed from "' +  
    				RTRIM(CONVERT(char(30),ISNULL(@demco, ''))) + '" to "' + 
    				RTRIM(CONVERT(char(30),ISNULL(@iemco, ''))) + '". '
    				END --If EM Company was changed
    	
    			IF ISNULL(@iwo, '') <> ISNULL(@dwo, '')
    				BEGIN
    				SELECT @history = ISNULL(@history,'') + 'Work Order was changed from "' + 
    				ISNULL(@dwo, '') + '" to "' + ISNULL(@iwo, '') + '". '
    				END --If Work Order was changed
    	
    			IF ISNULL(@iwoitem, 0) <> ISNULL(@dwoitem, 0)
    				BEGIN
    				SELECT @history = ISNULL(@history,'') + 'Work Order Item was changed from "' +  
    				RTRIM(CONVERT(char(30),ISNULL(@dwoitem, ''))) + '" to "' + 
    				RTRIM(CONVERT(char(30),ISNULL(@iwoitem, ''))) + '". '
    				END --If Work Order Item was changed
    	
    			IF ISNULL(@iemctype, 0) <> ISNULL(@demctype, 0)
    				BEGIN
    				SELECT @history = ISNULL(@history,'') + 'EM Cost Type was changed from "' + 
    				RTRIM(CONVERT(char(30),ISNULL(@demctype, ''))) + '" to "' + 
    				RTRIM(CONVERT(char(30),ISNULL(@iemctype, ''))) + '". '
    				END --If EM Cost Type was changed
    	
    			IF ISNULL(@icostcode, '') <> ISNULL(@dcostcode, '')
    				BEGIN
    				SELECT @history = ISNULL(@history,'') + 'Cost Code was changed from "' +  
    				ISNULL(@dcostcode, '') + '" to "' + ISNULL(@icostcode, '') + '". '
    				END --If Cost Code was changed
    	
    			IF ISNULL(@iequip, '') <> ISNULL(@dequip, '')
    				BEGIN
    				SELECT @history = ISNULL(@history,'') + 'Equipment was changed from "' +  
    				ISNULL(@dequip, '') + '" to "' + ISNULL(@iequip, '') + '". '
    				END --If Equipment was changed
    	
    			IF ISNULL(@iphasegroup, 0) <> ISNULL(@dphasegroup, 0)
    				BEGIN
    				SELECT @history = ISNULL(@history,'') + 'Phase Group was changed from "' +  
    				RTRIM(CONVERT(char(30),ISNULL(@dphasegroup, ''))) + '" to "' + 
    				RTRIM(CONVERT(char(30),ISNULL(@iphasegroup, ''))) + '". '
    				END --If Phase Group was changed
    	
    			IF ISNULL(@iphase, '') <> ISNULL(@dphase, '')
    				BEGIN
    				SELECT @history = ISNULL(@history,'') + 'Phase was changed from "' +  
    				ISNULL(@dphase, '') + '" to "' + ISNULL(@iphase, '') + '". '
    				END --If Phase was changed
    	
    			IF ISNULL(@imatlgroup, 0) <> ISNULL(@dmatlgroup, 0)
    				BEGIN
    				SELECT @history = ISNULL(@history,'') + 'Material Group was changed from "' +  
    				RTRIM(CONVERT(char(30),ISNULL(@dmatlgroup, ''))) + '" to "' + 
    				RTRIM(CONVERT(char(30),ISNULL(@imatlgroup, ''))) + '". '
    				END --If Material Group was changed
    	
    			IF ISNULL(@imaterial, '') <> ISNULL(@dmaterial, '')
    				BEGIN
    				SELECT @history = ISNULL(@history,'') + 'Material was changed from "' + 
    				ISNULL(@dmaterial, '') + '" to "' + ISNULL(@imaterial, '') + '". '
    				END --If Material was changed
    	
    			IF ISNULL(@ium, '') <> ISNULL(@dum, '')
    				BEGIN
    				SELECT @history = ISNULL(@history,'') + 'Unit of Measure was changed from "' +  
    				ISNULL(@dum, '') + '" to "' + ISNULL(@ium, '') + '". '
    				END --If Units of Measure was changed
    	
    			IF ISNULL(@iunits, 0) <> ISNULL(@dunits, 0)
    				BEGIN
    				SELECT @history = ISNULL(@history,'') + 'Number of Units was changed from "' +  
    				RTRIM(CONVERT(char(30),ISNULL(@dunits, ''))) + '" to "' + 
    				RTRIM(CONVERT(char(30),ISNULL(@iunits, ''))) + '". '
    				END --If Units was changed
    	
    			IF ISNULL(@icomptype, '') <> ISNULL(@dcomptype, '')
    				BEGIN
    				SELECT @history = ISNULL(@history,'') + 'Component Type was changed from "' +  
    				ISNULL(@dcomptype, '') + '" to "' + ISNULL(@icomptype, '') + '". '
    				END --If Component Type was changed
    	
    			IF ISNULL(@icomponent, '') <> ISNULL(@dcomponent, '')
    				BEGIN
    				SELECT @history = ISNULL(@history,'') + 'Component was changed from "' + 
    				ISNULL(@dcomponent, '') + '" to "' + ISNULL(@icomponent, '') + '". '
    				END --If Component was changed
    	
    			IF ISNULL(@iecm, '') <> ISNULL(@decm, '')
    				BEGIN
    				SELECT @history = ISNULL(@history,'') + 'ECM was changed from "' +  
    				ISNULL(@decm, '') + '" to "' + ISNULL(@iecm, '') + '". '
    				END --If ECM was changed
    	
    			--REMMED out Notes because Notes is a text field which cannot be
    			--manipulated in the insert and delete tables
    			--IF ISNULL(@inotes, '') <> ISNULL(@dnotes, '')
    				--BEGIN
    				--SELECT @history = ISNULL(@history,'') + 'Notes was changed from "' +  
    				--ISNULL(@dnotes, '') + '" to "' + ISNULL(@inotes, '') + '". '
    				--END
    	
    			IF ISNULL(@iaddress, '') <> ISNULL(@daddress, '')
    				BEGIN
    				SELECT @history = ISNULL(@history,'') + 'Address was changed from "' +  
    				ISNULL(@daddress, '') + '" to "' + ISNULL(@iaddress, '') + '". '
    				END --If Address was changed
    	
    			IF ISNULL(@iattention, '') <> ISNULL(@dattention, '')
    				BEGIN
    				SELECT @history = ISNULL(@history,'') + 'Attention was changed from "' +  
    				ISNULL(@dattention, '') + '" to "' + ISNULL(@iattention, '') + '". '
    				END --If Attention was changed
    	
    			IF ISNULL(@icity, '') <> ISNULL(@dcity, '')
    				BEGIN
    				SELECT @history = ISNULL(@history,'') + 'City was changed from "' +  
    				ISNULL(@dcity, '') + '" to "'+ ISNULL(@icity, '') + '". '
    				END --If City was changed
    	
    			IF ISNULL(@istate, '') <> ISNULL(@dstate, '')
    				BEGIN
    				SELECT @history = ISNULL(@history,'') + 'State was changed from "' + 
    				ISNULL(@dstate, '') + '" to "' + ISNULL(@istate, '') + '". '
    				END --If State was changed
    	
    			IF ISNULL(@izip, '') <> ISNULL(@dzip, '')
    				BEGIN
    				SELECT @history = ISNULL(@history,'') + 'Zip was changed from "' +  
    				ISNULL(@dzip, '') + '" to "' + ISNULL(@izip, '') + '". '
    				END --If Zip was changed
    	
    			IF ISNULL(@iaddress2, '') <> ISNULL(@daddress2, '')
    				BEGIN
    				SELECT @history = ISNULL(@history,'') + 'Address 2 was changed from "' +  
    				ISNULL(@daddress2, '') + '" to "' + ISNULL(@iaddress2, '') + '". '
    				END --If Address2 was changed
    	
    			IF ISNULL(@ishipins, '') <> ISNULL(@dshipins, '')
    				BEGIN
    				SELECT @history = ISNULL(@history,'') + 'Ship Insurance was changed from "' +  
    				ISNULL(@dshipins, '') + '" to "' + ISNULL(@ishipins, '') + '". '
    				END --If Ship Insurance was changed
    	
    			IF ISNULL(@iemgroup, 0) <> ISNULL(@demgroup, 0)
    				BEGIN
    				SELECT @history = ISNULL(@history,'') + 'EM Group was changed from "' +  
    				RTRIM(CONVERT(char(30),ISNULL(@demgroup, ''))) + '" to "' + 
    				RTRIM(CONVERT(char(30),ISNULL(@iemgroup, ''))) + '". '
    				END --IF EM Group was changed
    	
    			IF ISNULL(@itotalcost, 0) <> ISNULL(@dtotalcost, 0)
    				BEGIN
    				SELECT @history = ISNULL(@history,'') + 'Total Cost was changed from "' +  
    				RTRIM(CONVERT(char(30),ISNULL(@dtotalcost, ''))) + '" to "' + 
    				RTRIM(CONVERT(char(30),ISNULL(@itotalcost, ''))) + '". '
    				END --If Total Cost was changed
    	
    			IF ISNULL(@iglacct, '') <> ISNULL(@dglacct, '')
    				BEGIN
    				SELECT @history = ISNULL(@history,'') + 'GL Account was changed from "' + 
    				RTRIM(CONVERT(char(30),ISNULL(@dglacct, ''))) + '" to "' + 
    				RTRIM(CONVERT(char(30),ISNULL(@iglacct, ''))) + '". '
    				END --If GL Account was changed
    	
    			IF ISNULL(@iglco, 0) <> ISNULL(@dglco, 0)
    				BEGIN
    				SELECT @history = ISNULL(@history,'') + 'GL Company was changed from "' +  
    				RTRIM(CONVERT(char(30),ISNULL(@dglco, ''))) + '" to "' + 
    				RTRIM(CONVERT(char(30),ISNULL(@iglco, ''))) + '". '
    				END --If GL Company was changed
    	
    			
    			--If changes have been made to the RQLine then update the Reviewer notes
    			--with a log of these changes and update the status for the Reviewer 
    			--and Line where appropriate.
    			IF @history <> '' AND ISNULL(@iquote, -1) = -1
    				BEGIN
    				--Complete the history line to be added to the reviewer notes
    				SELECT @history = 'The following changes were made to the RQ Line on ' +
    				RTRIM(CONVERT(char(30),GETDATE())) + ':  ' + ISNULL(@history, '') + 
    				'Review status has been reset due to these changes.'
    	
    				--Update the Reviewers notes with what changes have been made
    				--and reset the review status to Open so the reviewer can look
    				--over the changes that have been made to the RQ Line
    				UPDATE bRQRR SET Notes = ISNULL(Notes, '') + ISNULL(@history,''), Status = 0 
    				WHERE RQCo = @co AND RQID = @rqid AND RQLine = @rqline AND Status <> 0  
    	
    				--IF @istatus = @dstatus
    					--BEGIN
    					--Update the Line Status 
    					--EXEC bspRQSetRQLineStatus @co, @rqid, @rqline, @msg
    					--END
    
    				--UPDATE bRQRL SET Status = 0 WHERE RQCo = @co AND RQID = @rqid AND
    				--RQLine = @rqline AND Status <> 0
   
    				
    				END -- If History variable contains information
    			
    			IF @istatus = @dstatus
    				BEGIN
    				--Update the status for the RQ Line
    				EXEC bspRQSetRQLineStatus @co, @rqid, @rqline, @msg
    				END
    
    			IF ISNULL(@ipo, -1) <> ISNULL(@dpo, -2)
    				BEGIN
   				IF ISNULL(@iquote, -1) = ISNULL(@dquote, -1)
   	 				BEGIN
   	 				IF ISNULL(@iquote, -1) <> -1
   	 					BEGIN
   	 					--Update the status for the Quote Line
   	 					EXEC bspRQSetQuoteLineStatus @co, @iquote, @iquoteline, @msg
   	 					END
   	 				END
   	 			ELSE
   	 				BEGIN
   	 				IF ISNULL(@iquote, -1) <> -1
   	 					BEGIN
   	 					EXEC bspRQSetQuoteLineStatus @co, @iquote, @iquoteline, @msg
   	 					END					
   	 
   	 				IF ISNULL(@dquote, -1) <> -1
   	 					BEGIN
   	 					EXEC bspRQSetQuoteLineStatus @co, @dquote, @dquoteline, @msg
   	 					END
   	 				END
   				END	 			
    			
    	    	FETCH NEXT FROM bcRQRL_update
    	    	into @co, @rqid, @rqline, @itotalcost, @iroute, @droute, @dtotalcost, @iquote, 
    			@iquoteline, @dquote, @dquoteline, @dunits, @iunits, @istatus, @dstatus,
    			@ilinetype, @dlinetype, @iexpdate, @dexpdate, @ireqdate, @dreqdate, 
    			@idescription, @ddescription, @ijcco, @djcco, @ijob, @djob, @ijcctype, @djcctype,
    			@iinco, @dinco, @iloc, @dloc, @ishiploc, @dshiploc, @ivendorgroup, @dvendorgroup,
    			@ivendor, @dvendor, @ivendormatlid, @dvendormatlid, @iunitcost, @dunitcost,
    			@iemco, @demco, @iwo, @dwo, @iwoitem, @dwoitem, @iemctype, @demctype,
    			@icostcode, @dcostcode, @iequip, @dequip, @iphasegroup, @dphasegroup, @iphase, @dphase,
    			@imatlgroup, @dmatlgroup, @imaterial, @dmaterial, @ium, @dum, @icomptype, @dcomptype,
    			@icomponent, @dcomponent, @iecm, @decm, @iaddress, @daddress,
    			@iattention, @dattention, @icity, @dcity, @istate, @dstate, @izip, @dzip, 
    			@iaddress2, @daddress2, @ishipins, @dshipins, @iemgroup, @demgroup, @iglacct, @dglacct,
    			@iglco, @dglco, @ipo, @dpo   
    	    	END
    	
    	    CLOSE bcRQRL_update
    	    DEALLOCATE bcRQRL_update
    	END --If @@numrows <> 1
    ELSE --@@numrows = 1
   
    	BEGIN 
    	SELECT @co = i.RQCo, @rqid = i.RQID, @rqline = i.RQLine, @itotalcost = i.TotalCost, 
    	@iroute = i.Route, @droute = d.Route, @dtotalcost = d.TotalCost, 
    	@iquote = i.Quote, @iquoteline = i.QuoteLine, @dquote = d.Quote, 
    	@dquoteline = d.QuoteLine, @dunits = d.Units, @iunits = i.Units, @istatus = i.Status,
    	@dstatus = d.Status, @ilinetype = i.LineType, @dlinetype = d.LineType,
    	@iexpdate = i.ExpDate, @dexpdate = d.ExpDate, @ireqdate = i.ReqDate, 
    	@dreqdate = d.ReqDate,@idescription = i.Description, @ddescription = d.Description, 
    	@ijcco = i.JCCo, @djcco = d.JCCo, @ijob = i.Job, @djob = d.Job, @ijcctype = i.JCCType,
    	@djcctype = d.JCCType, @iinco = i.INCo, @dinco = d.INCo, @iloc = i.Loc, @dloc = d.Loc,
    	@ishiploc = i.ShipLoc, @dshiploc = d.ShipLoc, @ivendorgroup = i.VendorGroup, 
    	@dvendorgroup = d.VendorGroup, @ivendor = i.Vendor, @dvendor = d.Vendor, 
    	@ivendormatlid = i.VendorMatlId, @dvendormatlid = d.VendorMatlId, @iunitcost = i.UnitCost, 
    	@dunitcost = d.UnitCost, @iemco = i.EMCo, @demco = d.EMCo, @iwo = i.WO, @dwo = d.WO,
    	@iwoitem = i.WOItem, @dwoitem = d.WOItem, @iemctype = i.EMCType, @demctype = d.EMCType,
    	@icostcode = i.CostCode, @dcostcode = d.CostCode, @iequip = i.Equip, @dequip = d.Equip, 
    	@iphasegroup = i.PhaseGroup, @dphasegroup = d.PhaseGroup, @iphase = i.Phase, 
    	@dphase = d.Phase, @imatlgroup = i.MatlGroup, @dmatlgroup = d.MatlGroup, 
    	@imaterial = i.Material, @dmaterial = d.Material, @ium = i.UM, @dum = d.UM, 
    	@icomptype = i.CompType, @dcomptype = d.CompType, @icomponent = i.Component, 
    	@dcomponent = d.Component, @iecm = i.ECM, @decm = d.ECM, @iaddress = i.Address, 
    	@daddress = d.Address, @iattention = i.Attention, @dattention = d.Attention, 
    	@icity = i.City, @dcity = d.City, @istate = i.State, @dstate = d.State, @izip = i.Zip, 
    	@dzip = d.Zip, @iaddress2 = i.Address2, @daddress2 = d.Address2, @ishipins = i.ShipIns, 
    	@dshipins = d.ShipIns, @iemgroup = i.EMGroup, @demgroup = d.EMGroup, @iglacct = i.GLAcct, 
    	@dglacct = d.GLAcct, @iglco = i.GLCo, @dglco = d.GLCo, @ipo = i.PO, @dpo = d.PO FROM Inserted i
    	JOIN Deleted d ON i.RQCo = d.RQCo and i.RQID = d.RQID and i.RQLine = d.RQLine
    		
   	/**************************************
   	If linetype is 5-WorkOrder and Route is
   	changed to Stock then update the WO and 
   	change the PSFlag to S - Stock
   	**************************************/
   	IF @ilinetype = 5 and @iroute = 2 and @droute <> 2
   		BEGIN
   		UPDATE EMWP
   		SET PSFlag = 'S'
   		WHERE EMCo = @iemco
   			and	WorkOrder = @iwo
   			and WOItem = @iwoitem
   			and MatlGroup = @imatlgroup
   			and Material = @imaterial
   		END
   
    	--Add threshold reviewer if Route is Purchase and Total Cost is greater then 
    	--the Threshold amount
    	IF @iroute = 1  --1 = Purchase
    		BEGIN		
    		IF EXISTS(SELECT TOP 1 1 FROM bPOCO WITH (NOLOCK) WHERE Threshold IS NOT NULL AND POCo = @co)
    			BEGIN
    			IF (@itotalcost > (SELECT Threshold FROM bPOCO WITH (NOLOCK) WHERE POCo = @co)) 
    			AND (@dtotalcost <= (SELECT Threshold FROM bPOCO WITH (NOLOCK) WHERE POCo = @co))
    				BEGIN
    				INSERT bRQRR (RQCo, RQID, RQLine, Reviewer, AssignedDate, Status)
    					SELECT @co, @rqid, @rqline, r.ThresholdReviewer, GETDATE(), 0
    					FROM bPOCO r WITH (NOLOCK)
    					WHERE r.POCo = @co AND r.ThresholdReviewer IS NOT NULL
    				END --Total cost is greater than Threshold for the first time
    			END --Threshold has been setup in bPOCO
    
    			--If the Route has been changed to Purchase, add the Purchase reviewer
    			--that has been setup in RQ Company (if one has been setup)
   
    			IF @iroute <> @droute
    				BEGIN
    				EXEC @rc = bspRQLineReviewerGet @co, @rqid, @rqline, @ijcco, @ijob, @iemco, @iequip,@itotalcost, @iroute, @iinco, @iloc, @errmsg
    	
    				--INSERT bRQRR (RQCo, RQID, RQLine, Reviewer, AssignedDate, Status)
    				--	SELECT @co, @rqid, @rqline, r.PurchaseReviewer, GETDATE(), 0
    				--	FROM bRQCO r WITH (NOLOCK)
    				--	WHERE r.RQCo = @co AND r.PurchaseReviewer IS NOT NULL
    				END
    			
    	/*
    				--If the Status is changing and the route is Purchase, make sure that
    				--Purchase reviewers have approved for purchase if they are required
    				IF @istatus <> @dstatus
    					BEGIN
    						IF @istatus = 4 --User trying to set the RQLine to Approved for Purchase
    							BEGIN
    								SELECT @validcnt = count(1) FROM bRQCO r WITH (NOLOCK)
    								WHERE r.RQCo = @co AND r.ApprforPurchase = 'Y'
    	
    								IF @validcnt = 1
    									BEGIN
    										IF (SELECT count(1) FROM bRQRR WITH (NOLOCK)
    										WHERE RQID = @rqid AND RQLine = @rqline AND
    										RQCo = @co) <> (SELECT count(1) FROM bRQRR
    										WITH (NOLOCK) WHERE RQID = @rqid AND RQLine 
    										= @rqline AND RQCo = @co AND Status = 1)
    											BEGIN
    												SELECT @errmsg = 'Cannot change RQ Line ' +
    												'Status, Purchase Reviewers required. ' +
    												'Route is Purchase, but no Purchase ' +
    												'reviewers have approved for Purchase at ' +
    												'this time.'
    	 											GOTO ERROR
    											END
    									END
    							END 
    					END */
    				END --If Route = Purchase			
    			
    		--If the RQ Line is being removed from a quote (Quote is now null, but used to contain
    		--a value) then the Quote Line needs to be updated (Units and Total cost recalculated)
    		IF @iquote IS NULL AND ISNULL(@iquote, -1) <> ISNULL(@dquote, -1)
    			BEGIN
    			UPDATE bRQQL SET Units = Units - @dunits, TotalCost = TotalCost - @dtotalcost
    			WHERE RQCo = @co AND Quote = @dquote AND QuoteLine = @dquoteline
    			END --If Quote Line has been removed	
    
   		IF @iquote IS NOT NULL AND @dquote IS NULL AND @ium = 'LS'
   			BEGIN
   			UPDATE bRQQL SET TotalCost = TotalCost + @itotalcost
   				WHERE RQCo = @co AND Quote = @iquote AND QuoteLine = @iquoteline
   			END
   
    		--Create the history line of the changes being made to the RQ Line
    		SELECT @history = '' --Initialize the history variable 
    
    		IF ISNULL(@ilinetype, 0) <> ISNULL(@dlinetype, 0)
    			BEGIN
    			SELECT @history = ISNULL(@history,'') + 'Line Type was changed from "' + 
    			RTRIM(CONVERT(char(30),ISNULL(@dlinetype, ''))) + '" to "' + 
    			RTRIM(CONVERT(char(30),ISNULL(@ilinetype, ''))) + '". '
    			END --If Line Type was changed
    	
    		IF ISNULL(@iroute, 0) <> ISNULL(@droute, 0)
    			BEGIN
    			SELECT @history = ISNULL(@history,'') + 'Route was changed from "' +  
    			RTRIM(CONVERT(char(30),ISNULL(@droute, ''))) + '" to "' + 
    			RTRIM(CONVERT(char(30),ISNULL(@iroute, ''))) + '". '
    			END --If Route was changed
    
    		IF ISNULL(@iexpdate, '') <> ISNULL(@dexpdate, '')
    			BEGIN
    			SELECT @history = ISNULL(@history,'') + 'Expected Date was changed from "' + 
    			RTRIM(CONVERT(char(30),ISNULL(@dexpdate, ''))) + '" to "' + 
    			RTRIM(CONVERT(char(30),ISNULL(@iexpdate, ''))) + '". '
    			END --If Expected Date was changed
    
    		IF ISNULL(@ireqdate, '') <> ISNULL(@dreqdate, '')
    			BEGIN
    			SELECT @history = ISNULL(@history,'') + 'Required Date was changed from "' + 
    			RTRIM(CONVERT(char(30),ISNULL(@dreqdate, ''))) + '" to "' + 
    			RTRIM(CONVERT(char(30),ISNULL(@ireqdate, ''))) + '". '
    			END --If Required Date was changed
    
    		IF ISNULL(@idescription, '') <> ISNULL(@ddescription, '')
    			BEGIN
    			SELECT @history = ISNULL(@history,'') + 'Description was changed from "' + 
    			ISNULL(@ddescription, '') + '" to "' + ISNULL(@idescription, '') + '". '
    			END --If Description was changed
    		
    		IF ISNULL(@ijcco, 0) <> ISNULL(@djcco, 0)
    			BEGIN
    			SELECT @history = ISNULL(@history,'') + 'JC Company was changed from "' + 
    			RTRIM(CONVERT(char(30),ISNULL(@djcco, ''))) + '" to "' + 
    			RTRIM(CONVERT(char(30),ISNULL(@ijcco, ''))) + '". '
    			END --If JC Company was changed
    
    		IF ISNULL(@ijob, '') <> ISNULL(@djob, '')
    			BEGIN
    			SELECT @history = ISNULL(@history,'') + 'Job was changed from "' + 
    			ISNULL(@djob, '') + '" to "' + ISNULL(@ijob, '') + '". '
    			END --If Job was changed
    
    		IF ISNULL(@ijcctype, 0) <> ISNULL(@djcctype, 0)
    			BEGIN
    			SELECT @history = ISNULL(@history,'') + 'JC Cost Type was changed from "' +  
    			RTRIM(CONVERT(char(30),ISNULL(@djcctype, ''))) + '" to "' + 
    			RTRIM(CONVERT(char(30),ISNULL(@ijcctype, ''))) + '". '
    			END --If JC Cost Type was changed
    
    		IF ISNULL(@iinco, 0) <> ISNULL(@dinco, 0)
    			BEGIN
    			SELECT @history = ISNULL(@history,'') + 'IN Company was changed from "' +  
    			RTRIM(CONVERT(char(30),ISNULL(@dinco, ''))) + '" to "' + 
    			RTRIM(CONVERT(char(30),ISNULL(@iinco, ''))) + '". '
    			END --If IN Company was changed
    
    		IF ISNULL(@iloc, '') <> ISNULL(@dloc, '')
    			BEGIN
    			SELECT @history = ISNULL(@history,'') + 'IN Location was changed from "' + 
    			ISNULL(@dloc, '') + '" to "' + ISNULL(@iloc, '') + '". '
    			END --If IN Location was changed
    
    		IF ISNULL(@ishiploc, '') <> ISNULL(@dshiploc, '')
    			BEGIN
    			SELECT @history = ISNULL(@history,'') + 'Ship Location was changed from "' +  
    			ISNULL(@dshiploc, '') + '" to "' + ISNULL(@ishiploc, '') + '". '
    			END --If Ship Location was changed
    
    		IF ISNULL(@ivendorgroup, 0) <> ISNULL(@dvendorgroup, 0)
    			BEGIN
    			SELECT @history = ISNULL(@history,'') + 'Vendor Group was changed from "' +  
    			RTRIM(CONVERT(char(30),ISNULL(@dvendorgroup, ''))) + '" to "' + 
    			RTRIM(CONVERT(char(30),ISNULL(@ivendorgroup, ''))) + '". '
    			END --If Vendor Group was changed
    
    		IF ISNULL(@ivendor, 0) <> ISNULL(@dvendor, 0)
    			BEGIN
    			SELECT @history = ISNULL(@history,'') + 'Vendor was changed from "' +  
    			RTRIM(CONVERT(char(30),ISNULL(@dvendor, ''))) + '" to "' + 
    			RTRIM(CONVERT(char(30),ISNULL(@ivendor, ''))) + '". '
    			END --If Vendor was changed
    
    		IF ISNULL(@ivendormatlid, '') <> ISNULL(@dvendormatlid, '')
    			BEGIN
    			SELECT @history = ISNULL(@history,'') + 'Vendor Material ID was changed from "' +  
    			ISNULL(@dvendormatlid, '') + '" to "' + ISNULL(@ivendormatlid, '') + '". '
    			END --If Vendor Material ID was changed
    
    		IF ISNULL(@iunitcost, 0) <> ISNULL(@dunitcost, 0)
    			BEGIN
    			SELECT @history = ISNULL(@history,'') + 'Unit Cost was changed from "' +  
   
    			RTRIM(CONVERT(char(30),ISNULL(@dunitcost, ''))) + '" to "' + 
    			RTRIM(CONVERT(char(30),ISNULL(@iunitcost, ''))) + '". '
    			END --If Unit Cost was changed
    
    		IF ISNULL(@iemco, 0) <> ISNULL(@demco, 0)
    			BEGIN
    			SELECT @history = ISNULL(@history,'') + 'EM Company was changed from "' +  
    			RTRIM(CONVERT(char(30),ISNULL(@demco, ''))) + '" to "' + 
    			RTRIM(CONVERT(char(30),ISNULL(@iemco, ''))) + '". '
    			END --If EM Company was changed
    
    		IF ISNULL(@iwo, '') <> ISNULL(@dwo, '')
    			BEGIN
    			SELECT @history = ISNULL(@history,'') + 'Work Order was changed from "' + 
    			ISNULL(@dwo, '') + '" to "' + ISNULL(@iwo, '') + '". '
    			END --If Work Order was changed
    
    		IF ISNULL(@iwoitem, 0) <> ISNULL(@dwoitem, 0)
    			BEGIN
    			SELECT @history = ISNULL(@history,'') + 'Work Order Item was changed from "' +  
    			RTRIM(CONVERT(char(30),ISNULL(@dwoitem, ''))) + '" to "' + 
    			RTRIM(CONVERT(char(30),ISNULL(@iwoitem, ''))) + '". '
    			END --If Work Order Item was changed
    
    		IF ISNULL(@iemctype, 0) <> ISNULL(@demctype, 0)
    			BEGIN
    			SELECT @history = ISNULL(@history,'') + 'EM Cost Type was changed from "' + 
    			RTRIM(CONVERT(char(30),ISNULL(@demctype, ''))) + '" to "' + 
    			RTRIM(CONVERT(char(30),ISNULL(@iemctype, ''))) + '". '
    			END --If EM Cost Type was changed
    
    		IF ISNULL(@icostcode, '') <> ISNULL(@dcostcode, '')
    			BEGIN
    			SELECT @history = ISNULL(@history,'') + 'Cost Code was changed from "' +  
    			ISNULL(@dcostcode, '') + '" to "' + ISNULL(@icostcode, '') + '". '
    			END --If Cost Code was changed
    
    		IF ISNULL(@iequip, '') <> ISNULL(@dequip, '')
    			BEGIN
    			SELECT @history = ISNULL(@history,'') + 'Equipment was changed from "' +  
    			ISNULL(@dequip, '') + '" to "' + ISNULL(@iequip, '') + '". '
    			END --If Equipment was changed
    
    		IF ISNULL(@iphasegroup, 0) <> ISNULL(@dphasegroup, 0)
    			BEGIN
    			SELECT @history = ISNULL(@history,'') + 'Phase Group was changed from "' +  
    			RTRIM(CONVERT(char(30),ISNULL(@dphasegroup, ''))) + '" to "' + 
    			RTRIM(CONVERT(char(30),ISNULL(@iphasegroup, ''))) + '". '
    			END --If Phase Group was changed
    
    		IF ISNULL(@iphase, '') <> ISNULL(@dphase, '')
    			BEGIN
    			SELECT @history = ISNULL(@history,'') + 'Phase was changed from "' +  
    			ISNULL(@dphase, '') + '" to "' + ISNULL(@iphase, '') + '". '
    			END --If Phase was changed
    
    		IF ISNULL(@imatlgroup, 0) <> ISNULL(@dmatlgroup, 0)
    			BEGIN
    			SELECT @history = ISNULL(@history,'') + 'Material Group was changed from "' +  
    			RTRIM(CONVERT(char(30),ISNULL(@dmatlgroup, ''))) + '" to "' + 
    			RTRIM(CONVERT(char(30),ISNULL(@imatlgroup, ''))) + '". '
    			END --If Material Group was changed
    
    		IF ISNULL(@imaterial, '') <> ISNULL(@dmaterial, '')
    			BEGIN
    			SELECT @history = ISNULL(@history,'') + 'Material was changed from "' + 
    			ISNULL(@dmaterial, '') + '" to "' + ISNULL(@imaterial, '') + '". '
    			END --If Material was changed
    
    		IF ISNULL(@ium, '') <> ISNULL(@dum, '')
    			BEGIN
    			SELECT @history = ISNULL(@history,'') + 'Unit of Measure was changed from "' +  
    			ISNULL(@dum, '') + '" to "' + ISNULL(@ium, '') + '". '
    			END --If Units of Measure was changed
    
    		IF ISNULL(@iunits, 0) <> ISNULL(@dunits, 0)
    			BEGIN
    			SELECT @history = ISNULL(@history,'') + 'Number of Units was changed from "' +  
    			RTRIM(CONVERT(char(30),ISNULL(@dunits, ''))) + '" to "' + 
    			RTRIM(CONVERT(char(30),ISNULL(@iunits, ''))) + '". '
    			END --If Units was changed
    
    		IF ISNULL(@icomptype, '') <> ISNULL(@dcomptype, '')
    			BEGIN
    			SELECT @history = ISNULL(@history,'') + 'Component Type was changed from "' +  
    			ISNULL(@dcomptype, '') + '" to "' + ISNULL(@icomptype, '') + '". '
    			END --If Component Type was changed
    
    		IF ISNULL(@icomponent, '') <> ISNULL(@dcomponent, '')
    			BEGIN
    			SELECT @history = ISNULL(@history,'') + 'Component was changed from "' + 
    			ISNULL(@dcomponent, '') + '" to "' + ISNULL(@icomponent, '') + '". '
    			END --If Component was changed
    
    		IF ISNULL(@iecm, '') <> ISNULL(@decm, '')
    			BEGIN
    			SELECT @history = ISNULL(@history,'') + 'ECM was changed from "' +  
    			ISNULL(@decm, '') + '" to "' + ISNULL(@iecm, '') + '". '
    			END --If ECM was changed
    
    		--REMMED out Notes because Notes is a text field which cannot be
    		--manipulated in the insert and delete tables
    		--IF ISNULL(@inotes, '') <> ISNULL(@dnotes, '')
    			--BEGIN
    			--SELECT @history = ISNULL(@history,'') + 'Notes was changed from "' +  
    			--ISNULL(@dnotes, '') + '" to "' + ISNULL(@inotes, '') + '". '
    			--END
    
    		IF ISNULL(@iaddress, '') <> ISNULL(@daddress, '')
    			BEGIN
    			SELECT @history = ISNULL(@history,'') + 'Address was changed from "' +  
    			ISNULL(@daddress, '') + '" to "' + ISNULL(@iaddress, '') + '". '
    			END --If Address was changed
    
    		IF ISNULL(@iattention, '') <> ISNULL(@dattention, '')
    			BEGIN
    			SELECT @history = ISNULL(@history,'') + 'Attention was changed from "' +  
    			ISNULL(@dattention, '') + '" to "' + ISNULL(@iattention, '') + '". '
    			END --If Attention was changed
    
    		IF ISNULL(@icity, '') <> ISNULL(@dcity, '')
    			BEGIN
    			SELECT @history = ISNULL(@history,'') + 'City was changed from "' +  
    			ISNULL(@dcity, '') + '" to "'+ ISNULL(@icity, '') + '". '
    			END --If City was changed
    
    		IF ISNULL(@istate, '') <> ISNULL(@dstate, '')
    			BEGIN
    			SELECT @history = ISNULL(@history,'') + 'State was changed from "' + 
    			ISNULL(@dstate, '') + '" to "' + ISNULL(@istate, '') + '". '
    			END --If State was changed
   
    
    		IF ISNULL(@izip, '') <> ISNULL(@dzip, '')
    			BEGIN
    			SELECT @history = ISNULL(@history,'') + 'Zip was changed from "' +  
    			ISNULL(@dzip, '') + '" to "' + ISNULL(@izip, '') + '". '
    			END --If Zip was changed
    
    		IF ISNULL(@iaddress2, '') <> ISNULL(@daddress2, '')
    			BEGIN
    			SELECT @history = ISNULL(@history,'') + 'Address 2 was changed from "' +  
    			ISNULL(@daddress2, '') + '" to "' + ISNULL(@iaddress2, '') + '". '
    			END --If Address2 was changed
    
    		IF ISNULL(@ishipins, '') <> ISNULL(@dshipins, '')
    			BEGIN
    			SELECT @history = ISNULL(@history,'') + 'Ship Insurance was changed from "' +  
    			ISNULL(@dshipins, '') + '" to "' + ISNULL(@ishipins, '') + '". '
    			END --If Ship Insurance was changed
    
    		IF ISNULL(@iemgroup, 0) <> ISNULL(@demgroup, 0)
    			BEGIN
    			SELECT @history = ISNULL(@history,'') + 'EM Group was changed from "' +  
    			RTRIM(CONVERT(char(30),ISNULL(@demgroup, ''))) + '" to "' + 
    			RTRIM(CONVERT(char(30),ISNULL(@iemgroup, ''))) + '". '
    			END --IF EM Group was changed
    
    		IF ISNULL(@itotalcost, 0) <> ISNULL(@dtotalcost, 0)
    			BEGIN
    			SELECT @history = ISNULL(@history,'') + 'Total Cost was changed from "' +  
    			RTRIM(CONVERT(char(30),ISNULL(@dtotalcost, ''))) + '" to "' + 
    			RTRIM(CONVERT(char(30),ISNULL(@itotalcost, ''))) + '". '
    			END --If Total Cost was changed
    
    		IF ISNULL(@iglacct, '') <> ISNULL(@dglacct, '')
    			BEGIN
    			SELECT @history = ISNULL(@history,'') + 'GL Account was changed from "' + 
    			RTRIM(CONVERT(char(30),ISNULL(@dglacct, ''))) + '" to "' + 
    			RTRIM(CONVERT(char(30),ISNULL(@iglacct, ''))) + '". '
    			END --If GL Account was changed
    
    		IF ISNULL(@iglco, 0) <> ISNULL(@dglco, 0)
    			BEGIN
    			SELECT @history = ISNULL(@history,'') + 'GL Company was changed from "' +  
    			RTRIM(CONVERT(char(30),ISNULL(@dglco, ''))) + '" to "' + 
    			RTRIM(CONVERT(char(30),ISNULL(@iglco, ''))) + '". '
    			END --If GL Company was changed
    
    		--If changes have been made to the RQLine then update the Reviewer notes
    		--with a log of these changes and update the status for the Reviewer 
    		--and Line where appropriate.
    		IF @history <> '' AND ISNULL(@iquote, -1) = -1
    			BEGIN
    			--Complete the history line to be added to the reviewer notes
    			SELECT @history = 'The following changes were made to the RQ Line on ' +
    			RTRIM(CONVERT(char(30),GETDATE())) + ':  ' + ISNULL(@history, '') + 
    			'Review status has been reset due to these changes.'
    
    			--Update the Reviewers notes with what changes have been made
    			--and reset the review status to Open so the reviewer can look
    			--over the changes that have been made to the RQ Line
    			UPDATE bRQRR SET Notes = ISNULL(Notes, '') + ISNULL(@history,''), Status = 0 
    			WHERE RQCo = @co AND RQID = @rqid AND RQLine = @rqline AND Status <> 0  
    
    			--Update the Line Status
    			--IF @istatus = @dstatus
    			--	BEGIN
    				--Update the Line Status 
    			--	EXEC bspRQSetRQLineStatus @co, @rqid, @rqline, @msg
    			--	END
    			
    			--UPDATE bRQRL SET Status = 0 WHERE RQCo = @co AND RQID = @rqid AND
    			--RQLine = @rqline AND Status <> 0
    			
    			END -- If History variable contains information
    	
    		
    		IF @istatus = @dstatus
    			BEGIN
    			--Update the status for the RQ Line
    			EXEC bspRQSetRQLineStatus @co, @rqid, @rqline, @msg
    			END
    
   
   		IF ISNULL(@ipo, -1) <> ISNULL(@dpo, -2)
   			BEGIN
   	 		IF ISNULL(@iquote, -1) = ISNULL(@dquote, -1)
   	 			BEGIN
   	 			IF ISNULL(@iquote, -1) <> -1
   	 				BEGIN
   	 				--Update the status for the Quote Line
   	 				EXEC bspRQSetQuoteLineStatus @co, @iquote, @iquoteline, @msg
   	 				END
   	 			END
   	 		ELSE
   
   	 			BEGIN
   	 			IF ISNULL(@iquote, -1) <> -1
   	 				BEGIN
   	 				EXEC bspRQSetQuoteLineStatus @co, @iquote, @iquoteline, @msg
   	 				END					
   	 	
   	 			IF ISNULL(@dquote, -1) <> -1
   	 				BEGIN
   	 				EXEC bspRQSetQuoteLineStatus @co, @dquote, @dquoteline, @msg
   	 				END
   	 			END
   	 		END	
   	 
    	END --@@numrows = 1
    
    
    --Add HQ Master Audit entry if the audit flag is set in bPOCO
    IF EXISTS(SELECT TOP 1 0 FROM Inserted i INNER JOIN bPOCO a ON a.POCo = i.RQCo WHERE a.AuditRQ = 'Y')
    	BEGIN 
    	--Insert records into HQMA for changes made to audited fields 
    	IF UPDATE(Quote)
       		insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, 
    		NewValue, DateTime, UserName)
       		select 'bRQRL', 'RQCo: ' + convert(char(3),i.RQCo) + ' RQID: ' + 
    		convert(char(10), i.RQID) + ' RQLine: ' + convert(varchar(20), i.RQLine),
    	 	i.RQCo, 'C', 'Quote', ISNULL(d.Quote,''), ISNULL(i.Quote,''),getdate(), SUSER_SNAME()
     		from inserted i join deleted d on i.RQCo = d.RQCo and i.RQID = d.RQID and i.RQLine = d.RQLine
     		where ISNULL(i.Quote,0) <> ISNULL(d.Quote,0)
       
    	if update(QuoteLine)
       		insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	   	select 'bRQRL', 'RQCo: ' + convert(char(3),i.RQCo) + ' RQID: ' + convert(char(10), i.RQID) + ' RQLine: ' + convert(varchar(20), i.RQLine),
    		i.RQCo, 'C', 'QuoteLine', ISNULL(d.QuoteLine,''), ISNULL(i.QuoteLine,''),getdate(), SUSER_SNAME()
    	 	from inserted i join deleted d on i.RQCo = d.RQCo and i.RQID = d.RQID and i.RQLine = d.RQLine
    	 	where isnull(i.QuoteLine,0) <> isnull(d.QuoteLine,0)
    
    	if update(Route)
    		insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    		select 'bRQRL', 'RQCo: ' + convert(char(3),i.RQCo) + ' RQID: ' + convert(char(10), i.RQID) + ' RQLine: ' + convert(varchar(20), i.RQLine),
    		i.RQCo, 'C', 'Route', isnull(d.Route,''), isnull(i.Route,''),getdate(), SUSER_SNAME()
    		from inserted i join deleted d on i.RQCo = d.RQCo and i.RQID = d.RQID and i.RQLine = d.RQLine
    		where isnull(i.Route,0) <> isnull(d.Route,0)
    
    	if update(ExpDate)
    		insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    		select 'bRQRL', 'RQCo: ' + convert(char(3),i.RQCo) + ' RQID: ' + convert(char(10), i.RQID) + ' RQLine: ' + convert(varchar(20), i.RQLine),
    		i.RQCo, 'C', 'ExpDate', CONVERT(VARCHAR(12),isnull(d.ExpDate,'')), CONVERT(VARCHAR(12),isnull(i.ExpDate,'')),getdate(), SUSER_SNAME()
    		from inserted i join deleted d on i.RQCo = d.RQCo and i.RQID = d.RQID and i.RQLine = d.RQLine
    		where isnull(i.ExpDate,'') <> isnull(d.ExpDate,'')
    
    	IF UPDATE(ReqDate)
    		insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    		select 'bRQRL', 'RQCo: ' + convert(char(3),i.RQCo) + ' RQID: ' + 
    		convert(char(10), i.RQID) + ' RQLine: ' + convert(varchar(20), i.RQLine),
    		i.RQCo, 'C', 'ReqDate', CONVERT(VARCHAR(12),ISNULL(d.ReqDate,'')), 
    		CONVERT(VARCHAR(12),ISNULL(i.ReqDate,'')),getdate(), SUSER_SNAME()
    		from inserted i join deleted d on i.RQCo = d.RQCo and i.RQID = d.RQID 
    		and i.RQLine = d.RQLine
    		where isnull(i.ReqDate,'') <> isnull(d.ReqDate,'')
    
    	if update(PO)
    		insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    		select 'bRQRL', 'RQCo: ' + convert(char(3),i.RQCo) + ' RQID: ' + convert(char(10), i.RQID) + ' RQLine: ' + convert(varchar(20), i.RQLine),
    		i.RQCo, 'C', 'PO', isnull(d.PO,''), isnull(i.PO,''),getdate(), SUSER_SNAME()
    		from inserted i join deleted d on i.RQCo = d.RQCo and i.RQID = d.RQID and i.RQLine = d.RQLine
    		where isnull(i.PO,0) <> isnull(d.PO,0)
    
    	if update(POItem)
    		insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    		select 'bRQRL', 'RQCo: ' + convert(char(3),i.RQCo) + ' RQID: ' + convert(char(10), i.RQID) + ' RQLine: ' + convert(varchar(20), i.RQLine),
    		i.RQCo, 'C', 'POItem', isnull(d.POItem,''), isnull(i.POItem,''),getdate(), SUSER_SNAME()
    		from inserted i join deleted d on i.RQCo = d.RQCo and i.RQID = d.RQID and i.RQLine = d.RQLine
    		where isnull(i.POItem,0) <> isnull(d.POItem,0)
    	
    	if update(Status)
    		insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    		select 'bRQRL', 'RQCo: ' + convert(char(3),i.RQCo) + ' RQID: ' + convert(char(10), i.RQID) + ' RQLine: ' + convert(varchar(20), i.RQLine),
    		i.RQCo, 'C', 'Status', isnull(d.Status,''), isnull(i.Status,''),getdate(), SUSER_SNAME()
    		from inserted i join deleted d on i.RQCo = d.RQCo and i.RQID = d.RQID and i.RQLine = d.RQLine
    		where isnull(i.Status,0) <> isnull(d.Status,0)
    	
    	if update(Description)
    		insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    		select 'bRQRL', 'RQCo: ' + convert(char(3),i.RQCo) + ' RQID: ' + convert(char(10), i.RQID) + ' RQLine: ' + convert(varchar(20), i.RQLine),
    		i.RQCo, 'C', 'Description', isnull(d.Description,''), isnull(i.Description,''),getdate(), SUSER_SNAME()
    		from inserted i join deleted d on i.RQCo = d.RQCo and i.RQID = d.RQID and i.RQLine = d.RQLine
    		where isnull(i.Description,0) <> isnull(d.Description,0)
    	
    	if update(JCCo)
    		insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    		select 'bRQRL', 'RQCo: ' + convert(char(3),i.RQCo) + ' RQID: ' + convert(char(10), i.RQID) + ' RQLine: ' + convert(varchar(20), i.RQLine),
    		i.RQCo, 'C', 'JCCo', isnull(d.JCCo,''), isnull(i.JCCo,''),getdate(), SUSER_SNAME()
    		from inserted i join deleted d on i.RQCo = d.RQCo and i.RQID = d.RQID and i.RQLine = d.RQLine
    		where isnull(i.JCCo,0) <> isnull(d.JCCo,0)
    	
    	if update(Job)
    		insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    		select 'bRQRL', 'RQCo: ' + convert(char(3),i.RQCo) + ' RQID: ' + convert(char(10), i.RQID) + ' RQLine: ' + convert(varchar(20), i.RQLine),
    		i.RQCo, 'C', 'Job', isnull(d.Job,''), isnull(i.Job,''),getdate(), SUSER_SNAME()
    		from inserted i join deleted d on i.RQCo = d.RQCo and i.RQID = d.RQID and i.RQLine = d.RQLine
    		where isnull(i.Job,0) <> isnull(d.Job,0)
    	
    	if update(JCCType)
    		insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    		select 'bRQRL', 'RQCo: ' + convert(char(3),i.RQCo) + ' RQID: ' + convert(char(10), i.RQID) + ' RQLine: ' + convert(varchar(20), i.RQLine),
    		i.RQCo, 'C', 'JCCType', isnull(d.JCCType,''), isnull(i.JCCType,''),getdate(), SUSER_SNAME()
    		from inserted i join deleted d on i.RQCo = d.RQCo and i.RQID = d.RQID and i.RQLine = d.RQLine
    		where isnull(i.JCCType,0) <> isnull(d.JCCType,0)
    	
    	if update(INCo)
    		insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    		select 'bRQRL', 'RQCo: ' + convert(char(3),i.RQCo) + ' RQID: ' + convert(char(10), i.RQID) + ' RQLine: ' + convert(varchar(20), i.RQLine),
    		i.RQCo, 'C', 'INCo', isnull(d.INCo,''), isnull(i.INCo,''),getdate(), SUSER_SNAME()
    		from inserted i join deleted d on i.RQCo = d.RQCo and i.RQID = d.RQID and i.RQLine = d.RQLine
    		where isnull(i.INCo,0) <> isnull(d.INCo,0)
    	
    	if update(Loc)
    		insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    		select 'bRQRL', 'RQCo: ' + convert(char(3),i.RQCo) + ' RQID: ' + convert(char(10), i.RQID) + ' RQLine: ' + convert(varchar(20), i.RQLine),
    		i.RQCo, 'C', 'Loc', isnull(d.Loc,''), isnull(i.Loc,''),getdate(), SUSER_SNAME()
    		from inserted i join deleted d on i.RQCo = d.RQCo and i.RQID = d.RQID and i.RQLine = d.RQLine
    		where isnull(i.Loc,0) <> isnull(d.Loc,0)
    	
    	if update(ShipLoc)
    		insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    		select 'bRQRL', 'RQCo: ' + convert(char(3),i.RQCo) + ' RQID: ' + convert(char(10), i.RQID) + ' RQLine: ' + convert(varchar(20), i.RQLine),
    		i.RQCo, 'C', 'ShipLoc', isnull(d.ShipLoc,''), isnull(i.ShipLoc,''),getdate(), SUSER_SNAME()
    		from inserted i join deleted d on i.RQCo = d.RQCo and i.RQID = d.RQID and i.RQLine = d.RQLine
    		where isnull(i.ShipLoc,0) <> isnull(d.ShipLoc,0)
    	
    	if update(VendorGroup)
    		insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    		select 'bRQRL', 'RQCo: ' + convert(char(3),i.RQCo) + ' RQID: ' + convert(char(10), i.RQID) + ' RQLine: ' + convert(varchar(20), i.RQLine),
    		i.RQCo, 'C', 'VendorGroup', isnull(d.VendorGroup,''), isnull(i.VendorGroup,''),getdate(), SUSER_SNAME()
    		from inserted i join deleted d on i.RQCo = d.RQCo and i.RQID = d.RQID and i.RQLine = d.RQLine
    		where isnull(i.VendorGroup,0) <> isnull(d.VendorGroup,0)
    	
    	if update(Vendor)
    		insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    		select 'bRQRL', 'RQCo: ' + convert(char(3),i.RQCo) + ' RQID: ' + convert(char(10), i.RQID) + ' RQLine: ' + convert(varchar(20), i.RQLine),
    		i.RQCo, 'C', 'Vendor', isnull(d.Vendor,''), isnull(i.Vendor,''),getdate(), SUSER_SNAME()
    		from inserted i join deleted d on i.RQCo = d.RQCo and i.RQID = d.RQID and i.RQLine = d.RQLine
    		where isnull(i.Vendor,0) <> isnull(d.Vendor,0)
    	
    	if update(VendorMatlId)
    		insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    		select 'bRQRL', 'RQCo: ' + convert(char(3),i.RQCo) + ' RQID: ' + convert(char(10), i.RQID) + ' RQLine: ' + convert(varchar(20), i.RQLine),
    		i.RQCo, 'C', 'VendorMatlId', isnull(d.VendorMatlId,''), isnull(i.VendorMatlId,''),getdate(), SUSER_SNAME()
    		from inserted i join deleted d on i.RQCo = d.RQCo and i.RQID = d.RQID and i.RQLine = d.RQLine
    		where isnull(i.VendorMatlId,0) <> isnull(d.VendorMatlId,0)
    	
    	if update(UnitCost)
    		insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    		select 'bRQRL', 'RQCo: ' + convert(char(3),i.RQCo) + ' RQID: ' + convert(char(10), i.RQID) + ' RQLine: ' + convert(varchar(20), i.RQLine),
    		i.RQCo, 'C', 'UnitCost', isnull(d.UnitCost,0), isnull(i.UnitCost,0),getdate(), SUSER_SNAME()
    		from inserted i join deleted d on i.RQCo = d.RQCo and i.RQID = d.RQID and i.RQLine = d.RQLine
    		where isnull(i.UnitCost,0) <> isnull(d.UnitCost,0)
    	
    	if update(EMCo)
    		insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    		select 'bRQRL', 'RQCo: ' + convert(char(3),i.RQCo) + ' RQID: ' + convert(char(10), i.RQID) + ' RQLine: ' + convert(varchar(20), i.RQLine),
    		i.RQCo, 'C', 'EMCo', isnull(d.EMCo,''), isnull(i.EMCo,''),getdate(), SUSER_SNAME()
    		from inserted i join deleted d on i.RQCo = d.RQCo and i.RQID = d.RQID and i.RQLine = d.RQLine
    		where isnull(i.EMCo,0) <> isnull(d.EMCo,0)
    	
    	if update(WO)
    		insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    		select 'bRQRL', 'RQCo: ' + convert(char(3),i.RQCo) + ' RQID: ' + convert(char(10), i.RQID) + ' RQLine: ' + convert(varchar(20), i.RQLine),
    		i.RQCo, 'C', 'WO', isnull(d.WO,''), isnull(i.WO,''),getdate(), SUSER_SNAME()
    		from inserted i join deleted d on i.RQCo = d.RQCo and i.RQID = d.RQID and i.RQLine = d.RQLine
    		where isnull(i.WO,0) <> isnull(d.WO,0)
    	
    	if update(WOItem)
    		insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    		select 'bRQRL', 'RQCo: ' + convert(char(3),i.RQCo) + ' RQID: ' + convert(char(10), i.RQID) + ' RQLine: ' + convert(varchar(20), i.RQLine),
 
    		i.RQCo, 'C', 'WOItem', isnull(d.WOItem,''), isnull(i.WOItem,''),getdate(), SUSER_SNAME()
    		from inserted i join deleted d on i.RQCo = d.RQCo and i.RQID = d.RQID and i.RQLine = d.RQLine
    		where isnull(i.WOItem,0) <> isnull(d.WOItem,0)
    	
    	if update(EMCType)
    		insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    		select 'bRQRL', 'RQCo: ' + convert(char(3),i.RQCo) + ' RQID: ' + convert(char(10), i.RQID) + ' RQLine: ' + convert(varchar(20), i.RQLine),
    		i.RQCo, 'C', 'EMCType', isnull(d.EMCType,''), isnull(i.EMCType,''),getdate(), SUSER_SNAME()
    		from inserted i join deleted d on i.RQCo = d.RQCo and i.RQID = d.RQID and i.RQLine = d.RQLine
    		where isnull(i.EMCType,0) <> isnull(d.EMCType,0)
    	
    	if update(CostCode)
    		insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    		select 'bRQRL', 'RQCo: ' + convert(char(3),i.RQCo) + ' RQID: ' + convert(char(10), i.RQID) + ' RQLine: ' + convert(varchar(20), i.RQLine),
    		i.RQCo, 'C', 'CostCode', isnull(d.CostCode,''), isnull(i.CostCode,''),getdate(), SUSER_SNAME()
    		from inserted i join deleted d on i.RQCo = d.RQCo and i.RQID = d.RQID and i.RQLine = d.RQLine
    		where isnull(i.CostCode,0) <> isnull(d.CostCode,0)
    	
    	if update(Equip)
    		insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    		select 'bRQRL', 'RQCo: ' + convert(char(3),i.RQCo) + ' RQID: ' + convert(char(10), i.RQID) + ' RQLine: ' + convert(varchar(20), i.RQLine),
    		i.RQCo, 'C', 'Equip', isnull(d.Equip,''), isnull(i.Equip,''),getdate(), SUSER_SNAME()
    		from inserted i join deleted d on i.RQCo = d.RQCo and i.RQID = d.RQID and i.RQLine = d.RQLine
    		where isnull(i.Equip,0) <> isnull(d.Equip,0)
    	
    	if update(PhaseGroup)
    		insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    		select 'bRQRL', 'RQCo: ' + convert(char(3),i.RQCo) + ' RQID: ' + convert(char(10), i.RQID) + ' RQLine: ' + convert(varchar(20), i.RQLine),
    		i.RQCo, 'C', 'PhaseGroup', isnull(d.PhaseGroup,''), isnull(i.PhaseGroup,''),getdate(), SUSER_SNAME()
    		from inserted i join deleted d on i.RQCo = d.RQCo and i.RQID = d.RQID and i.RQLine = d.RQLine
    		where isnull(i.PhaseGroup,0) <> isnull(d.PhaseGroup,0)
    	
    	if update(Phase)
    		insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    		select 'bRQRL', 'RQCo: ' + convert(char(3),i.RQCo) + ' RQID: ' + convert(char(10), i.RQID) + ' RQLine: ' + convert(varchar(20), i.RQLine),
    		i.RQCo, 'C', 'Phase', isnull(d.Phase,''), isnull(i.Phase,''),getdate(), SUSER_SNAME()
    		from inserted i join deleted d on i.RQCo = d.RQCo and i.RQID = d.RQID and i.RQLine = d.RQLine
    		where isnull(i.Phase,0) <> isnull(d.Phase,0)
    	
    	if update(MatlGroup)
    		insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    		select 'bRQRL', 'RQCo: ' + convert(char(3),i.RQCo) + ' RQID: ' + convert(char(10), i.RQID) + ' RQLine: ' + convert(varchar(20), i.RQLine),
    		i.RQCo, 'C', 'MatlGroup', isnull(d.MatlGroup,''), isnull(i.MatlGroup,''),getdate(), SUSER_SNAME()
    		from inserted i join deleted d on i.RQCo = d.RQCo and i.RQID = d.RQID and i.RQLine = d.RQLine
    		where isnull(i.MatlGroup,0) <> isnull(d.MatlGroup,0)
    	
    	if update(Material)
    		insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    		select 'bRQRL', 'RQCo: ' + convert(char(3),i.RQCo) + ' RQID: ' + convert(char(10), i.RQID) + ' RQLine: ' + convert(varchar(20), i.RQLine),
    		i.RQCo, 'C', 'Material', isnull(d.Material,''), isnull(i.Material,''),getdate(), SUSER_SNAME()
    		from inserted i join deleted d on i.RQCo = d.RQCo and i.RQID = d.RQID and i.RQLine = d.RQLine
    		where isnull(i.Material,0) <> isnull(d.Material,0)
    	
    	if update(UM)
    		insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    		select 'bRQRL', 'RQCo: ' + convert(char(3),i.RQCo) + ' RQID: ' + convert(char(10), i.RQID) + ' RQLine: ' + convert(varchar(20), i.RQLine),
    		i.RQCo, 'C', 'UM', isnull(d.UM,''), isnull(i.UM,''),getdate(), SUSER_SNAME()
    		from inserted i join deleted d on i.RQCo = d.RQCo and i.RQID = d.RQID and i.RQLine = d.RQLine
    		where isnull(i.UM,0) <> isnull(d.UM,0)
    	
    	if update(Units)
    		insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    		select 'bRQRL', 'RQCo: ' + convert(char(3),i.RQCo) + ' RQID: ' + convert(char(10), i.RQID) + ' RQLine: ' + convert(varchar(20), i.RQLine),
    		i.RQCo, 'C', 'Units', isnull(d.Units,0), isnull(i.Units,0),getdate(), SUSER_SNAME()
    		from inserted i join deleted d on i.RQCo = d.RQCo and i.RQID = d.RQID and i.RQLine = d.RQLine
    		where isnull(i.Units,0) <> isnull(d.Units,0)
    	
    	if update(CompType)
    		insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    		select 'bRQRL', 'RQCo: ' + convert(char(3),i.RQCo) + ' RQID: ' + convert(char(10), i.RQID) + ' RQLine: ' + convert(varchar(20), i.RQLine),
    		i.RQCo, 'C', 'CompType', isnull(d.CompType,''), isnull(i.CompType,''),getdate(), SUSER_SNAME()
    		from inserted i join deleted d on i.RQCo = d.RQCo and i.RQID = d.RQID and i.RQLine = d.RQLine
    		where isnull(i.CompType,'') <> isnull(d.CompType,'')
    	
    	if update(Component)
    		insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    		select 'bRQRL', 'RQCo: ' + convert(char(3),i.RQCo) + ' RQID: ' + convert(char(10), i.RQID) + ' RQLine: ' + convert(varchar(20), i.RQLine),
    		i.RQCo, 'C', 'Component', isnull(d.Component,''), isnull(i.Component,''),getdate(), SUSER_SNAME()
    		from inserted i join deleted d on i.RQCo = d.RQCo and i.RQID = d.RQID and i.RQLine = d.RQLine
    		where isnull(i.Component,'') <> isnull(d.Component,'')
    
    	if update(ECM)
    		insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    		select 'bRQRL', 'RQCo: ' + convert(char(3),i.RQCo) + ' RQID: ' + convert(char(10), i.RQID) + ' RQLine: ' + convert(varchar(20), i.RQLine),
    		i.RQCo, 'C', 'ECM', isnull(d.ECM,''), isnull(i.ECM,''),getdate(), SUSER_SNAME()
    		from inserted i join deleted d on i.RQCo = d.RQCo and i.RQID = d.RQID and i.RQLine = d.RQLine
    		where isnull(i.ECM,'') <> isnull(d.ECM,'')
    
    	if update(Address)
    		insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    		select 'bRQRL', 'RQCo: ' + convert(char(3),i.RQCo) + ' RQID: ' + convert(char(10), i.RQID) + ' RQLine: ' + convert(varchar(20), i.RQLine),
    		i.RQCo, 'C', 'Address', isnull(d.Address,''), isnull(i.Address,''),getdate(), SUSER_SNAME()
    		from inserted i join deleted d on i.RQCo = d.RQCo and i.RQID = d.RQID and i.RQLine = d.RQLine
    		where isnull(i.Address,'') <> isnull(d.Address,'')
    
    	if update(Attention)
    		insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    		select 'bRQRL', 'RQCo: ' + convert(char(3),i.RQCo) + ' RQID: ' + convert(char(10), i.RQID) + ' RQLine: ' + convert(varchar(20), i.RQLine),
    		i.RQCo, 'C', 'Attention', isnull(d.Attention,''), isnull(i.Attention,''),getdate(), SUSER_SNAME()
    		from inserted i join deleted d on i.RQCo = d.RQCo and i.RQID = d.RQID and i.RQLine = d.RQLine
    		where isnull(i.Attention,'') <> isnull(d.Attention,'')
    
    	if update(City)
    		insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    		select 'bRQRL', 'RQCo: ' + convert(char(3),i.RQCo) + ' RQID: ' + convert(char(10), i.RQID) + ' RQLine: ' + convert(varchar(20), i.RQLine),
    		i.RQCo, 'C', 'City', isnull(d.City,''), isnull(i.City,''),getdate(), SUSER_SNAME()
    		from inserted i join deleted d on i.RQCo = d.RQCo and i.RQID = d.RQID and i.RQLine = d.RQLine
    		where isnull(i.City,'') <> isnull(d.City,'')
    
    	if update(State)
    		insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    		select 'bRQRL', 'RQCo: ' + convert(char(3),i.RQCo) + ' RQID: ' + convert(char(10), i.RQID) + ' RQLine: ' + convert(varchar(20), i.RQLine),
    		i.RQCo, 'C', 'State', isnull(d.State,''), isnull(i.State,''),getdate(), SUSER_SNAME()
    		from inserted i join deleted d on i.RQCo = d.RQCo and i.RQID = d.RQID and i.RQLine = d.RQLine
    		where isnull(i.State,'') <> isnull(d.State,'')
    
    	if update(Zip)
    		insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    		select 'bRQRL', 'RQCo: ' + convert(char(3),i.RQCo) + ' RQID: ' + convert(char(10), i.RQID) + ' RQLine: ' + convert(varchar(20), i.RQLine),
    		i.RQCo, 'C', 'Zip', isnull(d.Zip,''), isnull(i.Zip,''),getdate(), SUSER_SNAME()
    		from inserted i join deleted d on i.RQCo = d.RQCo and i.RQID = d.RQID and i.RQLine = d.RQLine
    		where isnull(i.Zip,'') <> isnull(d.Zip,'')
    
    	if update(Address2)
    		insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    		select 'bRQRL', 'RQCo: ' + convert(char(3),i.RQCo) + ' RQID: ' + convert(char(10), i.RQID) + ' RQLine: ' + convert(varchar(20), i.RQLine),
    		i.RQCo, 'C', 'Address2', isnull(d.Address2,''), isnull(i.Address2,''),getdate(), SUSER_SNAME()
    		from inserted i join deleted d on i.RQCo = d.RQCo and i.RQID = d.RQID and i.RQLine = d.RQLine
    		where isnull(i.Address2,'') <> isnull(d.Address2,'')

    	IF update(Country)  --DC 127387
    		insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    		select 'bRQRL', 'RQCo: ' + convert(char(3),i.RQCo) + ' RQID: ' + convert(char(10), i.RQID) + ' RQLine: ' + convert(varchar(20), i.RQLine),
    		i.RQCo, 'C', 'Country', isnull(d.Country,''), isnull(i.Country,''),getdate(), SUSER_SNAME()
    		from inserted i join deleted d on i.RQCo = d.RQCo and i.RQID = d.RQID and i.RQLine = d.RQLine
    		where isnull(i.Country,'') <> isnull(d.Country,'')
    
    	IF UPDATE(ShipIns)
    		INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, 
    		NewValue, DateTime, UserName)
    		SELECT 'bRQRL', 'RQCo: ' + CONVERT(CHAR(3),i.RQCo) + ' RQID: ' + 
    		CONVERT(CHAR(10), i.RQID) + ' RQLine: ' + CONVERT(VARCHAR(20), i.RQLine),
    		i.RQCo, 'C', 'ShipIns', ISNULL(d.ShipIns,''), ISNULL(i.ShipIns,''), 
    		GETDATE(), SUSER_SNAME()
    		FROM Inserted i JOIN Deleted d ON i.RQCo = d.RQCo AND i.RQID = d.RQID 
    		AND i.RQLine = d.RQLine
    		WHERE ISNULL(i.ShipIns,'') <> ISNULL(d.ShipIns,'')
    	END --If Audit Flag is set in bRQCO
    
	--DC 125594
	EndStatement:

    RETURN
    
    error:
    	SELECT @errmsg = ISNULL(@errmsg,'') + ' - cannot update RQ Item!'
    	RAISERROR(@errmsg, 11, -1);
    	ROLLBACK TRANSACTION


GO
ALTER TABLE [dbo].[bRQRL] ADD CONSTRAINT [biRQRL] PRIMARY KEY CLUSTERED  ([RQCo], [RQID], [RQLine]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bRQRL] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bRQRL].[ECM]'
GO
