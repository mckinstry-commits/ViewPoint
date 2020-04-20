CREATE TABLE [dbo].[bRQQL]
(
[RQCo] [dbo].[bCompany] NOT NULL,
[Quote] [int] NOT NULL,
[QuoteLine] [int] NOT NULL,
[Status] [tinyint] NOT NULL,
[INCo] [dbo].[bCompany] NULL,
[Loc] [dbo].[bLoc] NULL,
[MatlGroup] [dbo].[bGroup] NULL,
[Material] [dbo].[bMatl] NULL,
[Description] [dbo].[bTransDesc] NULL,
[EMCo] [dbo].[bCompany] NULL,
[JCCo] [dbo].[bCompany] NULL,
[Job] [dbo].[bJob] NULL,
[ShipLoc] [dbo].[bShipLoc] NULL,
[VendorGroup] [dbo].[bGroup] NULL,
[Vendor] [dbo].[bVendor] NULL,
[VendorMatlId] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[UM] [dbo].[bUM] NOT NULL,
[Units] [dbo].[bUnits] NOT NULL,
[UnitCost] [dbo].[bUnitCost] NULL,
[ECM] [dbo].[bECM] NULL CONSTRAINT [DF_bRQQL_ECM] DEFAULT ('E'),
[TotalCost] [dbo].[bDollar] NULL CONSTRAINT [DF_bRQQL_TotalCost] DEFAULT ((0)),
[ExpDate] [dbo].[bDate] NULL,
[ReqDate] [dbo].[bDate] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE   TRIGGER [dbo].[btRQQLd] ON [dbo].[bRQQL] FOR DELETE AS
    

/*-----------------------------------------------------------------
    *Created:  	DC  03/02/2004
    *			GWC 09/28/2004
    *Modified: DC 1/9/2009  #130129 - Combine RQ and PO into a single module
    *
    *Delete trigger for bRQQL:
    *	-Delete the Purchase Reviewers associated with the Quote lines being deleted (bRQQR)
    *	-Remove the Quote and Quote line values for the associated RQ Lines (bRQRL)
    * 	-Inserts into HQ Master Audit entry.
    */----------------------------------------------------------------
    DECLARE @errmsg varchar(255), @numrows int, @rqco bCompany, @quote int, @quoteline int 
    
    --Check if any records are being affected
    select @numrows = @@rowcount
    if @numrows = 0 return
    
    SET NOCOUNT ON
    
   IF EXISTS (SELECT h.Locked FROM bRQQH h INNER JOIN Deleted d ON
   h.RQCo = d.RQCo AND h.Quote = d.Quote WHERE h.Locked = 'Y')
   	BEGIN
   	SELECT @errmsg = 'Cannot remove QuoteLines. Quote Header is currently marked as Locked.'
   	GOTO error
   	END  
   
   
    --Check if multiple records are being deleted, if they are, then a cursor will be used
    --to process the different Quote Lines
    IF @numrows <> 1
    	BEGIN
    	--Use a cursor to process all lines
    	DECLARE bcRQQL_delete CURSOR LOCAL FAST_FORWARD FOR
    	SELECT d.RQCo, d.Quote, d.QuoteLine FROM Deleted d
    	
    	OPEN bcRQQL_delete
    	FETCH NEXT FROM bcRQQL_delete INTO @rqco, @quote, @quoteline
    	
    	WHILE (@@FETCH_STATUS = 0)
    		BEGIN
    
    		--Delete the reviewers for this RQQL record
    		Delete bRQQR WHERE RQCo = @rqco AND Quote = @quote AND QuoteLine = @quoteline
    
    		--Update RQRL, remove Quote and QuoteLine values from all RQLines part of the Quote being deleted
    		UPDATE bRQRL SET Quote = NULL, QuoteLine = NULL
    		WHERE RQCo = @rqco AND Quote = @quote AND QuoteLine = @quoteline
    
    		FETCH NEXT FROM bcRQQL_delete INTO @rqco, @quote, @quoteline 
    	    
    		END
    	
    	CLOSE bcRQQL_delete
    	DEALLOCATE bcRQQL_delete
    	END
    ELSE
    	BEGIN
    	SELECT @rqco = d.RQCo, @quote = d.Quote, @quoteline = d.QuoteLine FROM Deleted d
    
    	--Delete the reviewers for this RQQL record
    	Delete bRQQR FROM bRQQR r WHERE r.RQCo = @rqco AND r.Quote = @quote 
    	AND r.QuoteLine = @quoteline
    
    	--Update RQRL, remove Quote and QuoteLine values from all RQLines part of the Quote being deleted
    	UPDATE bRQRL SET Quote = NULL, QuoteLine = NULL
    	WHERE RQCo = @rqco AND Quote = @quote AND QuoteLine = @quoteline
    	END
    
    --Audit Quote Line deletions
    IF EXISTS(SELECT TOP 1 0 FROM Deleted d JOIN bPOCO a ON a.POCo = d.RQCo WHERE a.AuditQuote = 'Y')
    	BEGIN
    	INSERT INTO bHQMA
      	(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	SELECT 'bRQQL', 'RQCo: ' + CONVERT(varchar(3),RQCo) + ' Quote: ' + 
    	CONVERT(varchar(10),Quote) + ' QuoteLine: ' + CONVERT(varchar(10),QuoteLine),
    	RQCo, 'D', NULL, NULL, NULL, GETDATE(), SUSER_SNAME() FROM Deleted d
        
    	IF @@ROWCOUNT <> @numrows
    		BEGIN
    		SELECT @errmsg = 'Unable to update HQ Master Audit.'
    		GOTO error
    		END
    	END
    
    RETURN
    
    error:
    	SELECT @errmsg = @errmsg + ' - cannot delete Quote Line!'
    	RAISERROR(@errmsg, 11, -1);
    	ROLLBACK TRANSACTION
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
   
   
   /****** Object:  Trigger dbo.btRQQLi    Script Date: 3/5/2004 9:56:39 AM ******/
    CREATE            TRIGGER [dbo].[btRQQLi] ON [dbo].[bRQQL] FOR INSERT AS
/*-----------------------------------------------------------------
    *Created:  DC 03/05/2004
    *
    *Modified: DC 1/9/2009  #130129 - Combine RQ and PO into a single module
    *			DC 4/21/10  #132526 - Remove RQCo
    *
    *
    *Insert trigger for Quote Lines
    *	-Rejects insert unless Header record exists
    *	-Inserts into HQ Master Audit entry. 
    *	-Inserts Purchase Reviewers setup
    *	-Inserts Threshold Reviewers setup
    */----------------------------------------------------------------
    
    DECLARE @numrows int, @validcnt int, @errmsg varchar(255), @rqco bCompany,
    @quote int, @quoteline int, @totalcost bDollar, @ecm bECM, @um bUM, @msg varchar(255), @rc int 
    
    --Verity that records have been inserted, or exit the trigger
    SELECT @numrows = @@ROWCOUNT
    IF @numrows = 0 RETURN
    
    SET NOCOUNT ON
    
    --Check Quote Header
    SELECT @validcnt = COUNT(1) FROM bRQQH h WITH (NOLOCK)
    	JOIN Inserted i ON h.RQCo = i.RQCo and h.Quote = i.Quote
    
    	IF @validcnt <> @numrows
    		BEGIN
    		SELECT @errmsg = 'Quote Header does not exist.'
    		GOTO error
    		END
   
   IF EXISTS (SELECT h.Locked FROM bRQQH h INNER JOIN Inserted i ON
   h.RQCo = i.RQCo AND h.Quote = i.Quote WHERE h.Locked = 'Y')
   	BEGIN
   	SELECT @errmsg = 'Cannot insert QuoteLines. Quote Header has been marked as Locked.'
   	GOTO error
   	END  
   
    
    IF @@rowcount <> 1
    	BEGIN
    	--Use a cursor to process all lines
    	DECLARE bcRQQL_insert CURSOR LOCAL FAST_FORWARD FOR
    	SELECT i.RQCo, i.Quote, i.QuoteLine, i.TotalCost, i.ECM, i.UM FROM Inserted i
    	
    	OPEN bcRQQL_insert
    	FETCH NEXT FROM bcRQQL_insert INTO @rqco, @quote, @quoteline, @totalcost, @ecm, @um
    	
    	WHILE (@@FETCH_STATUS = 0)
    		BEGIN
   		 --Insert a default ECM if the current ECM is NULL and the UM is not LS
   		IF @ecm IS NULL AND @um <> 'LS'
   			BEGIN
   			UPDATE bRQQL SET ECM = 'E' WHERE RQCo = @rqco AND Quote = @quote and QuoteLine = @quoteline 
   			END
   
   		--If the UM is LS then grab the Total Cost from the RQ Lines AND insert a NULL for ECM
   		IF @um = 'LS'
   			BEGIN
   			UPDATE bRQQL SET ECM = NULL WHERE RQCo = @rqco AND
   			Quote = @quote AND QuoteLine = @quoteline
   			END
   
    		--Add the Default Reviewers for the Quote 	
    		EXEC @rc = bspRQQuoteReviewerGet @rqco, @quote, @quoteline, @totalcost, @msg
    			
    		IF @rc = 1 
    			BEGIN
    			SELECT @errmsg = ISNULL(@msg,'')
    			GOTO error
    			END
    
    		--Update the Qoute Status
    		EXEC bspRQSetQuoteLineStatus @rqco, @quote, @quoteline, @msg
   
    		FETCH NEXT FROM bcRQQL_insert INTO @rqco, @quote, @quoteline, @totalcost, @ecm, @um 
    	    
    		END
    	
    	CLOSE bcRQQL_insert
    	DEALLOCATE bcRQQL_insert
    	END
    ELSE
    	BEGIN
    	SELECT @rqco = i.RQCo, @quote = i.Quote, @quoteline = i.QuoteLine, 
    		@totalcost = i.TotalCost, @ecm = i.ECM, @um = i.UM FROM Inserted i
    
   	--Insert a default ECM if the current ECM is NULL and the UM is not LS
   	IF @ecm IS NULL AND @um <> 'LS'
   		BEGIN
   		UPDATE bRQQL SET ECM = 'E' WHERE RQCo = @rqco AND Quote = @quote and QuoteLine = @quoteline 
   		END
   
   	--If the UM is LS then grab the Total Cost from the RQ Lines AND insert a NULL for ECM
   	IF @um = 'LS'
   		BEGIN
   		UPDATE bRQQL SET ECM = NULL WHERE RQCo = @rqco AND
   		Quote = @quote AND QuoteLine = @quoteline
   		END
   
   	--Add the Default Reviewers for the Quote 	
    	EXEC @rc = bspRQQuoteReviewerGet @rqco, @quote, @quoteline, @totalcost, @msg
    	
    	--Update the Qoute Status
    	EXEC bspRQSetQuoteLineStatus @rqco, @quote, @quoteline, @msg
    	
   	END 
    
    
    --Add HQ Master Audit entry
    IF EXISTS(SELECT TOP 1 0 FROM INSERTED i JOIN bPOCO c ON c.POCo = i.RQCo where c.AuditRQ = 'Y')
    	BEGIN
    	INSERT INTO bHQMA 
    	(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	SELECT 'bRQQL', 'POCo: ' + CONVERT(varchar(3),RQCo) + ' Quote: ' + 
    	CONVERT(varchar(10),Quote) + ' QuoteLine: ' + CONVERT(varchar(20),QuoteLine),
    	RQCo, 'A', NULL, NULL, NULL, GETDATE(), SUSER_SNAME()
    	FROM Inserted i
        	
    	IF @@ROWCOUNT <> @numrows
    		BEGIN
    		SELECT @errmsg = 'Unable to update HQ Master Audit.'
    		GOTO error
    		END
    	END
    
    RETURN
    
    error:
        SELECT @errmsg = @errmsg +  ' - cannot insert Quote Line!'
        RAISERROR(@errmsg, 11, -1);
        ROLLBACK TRANSACTION
   
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btRQQLu    Script Date: 3/5/2004 10:19:45 AM ******/
   CREATE  TRIGGER [dbo].[btRQQLu] ON [dbo].[bRQQL] FOR UPDATE AS
   

/*-----------------------------------------------------------------
   *Created:  DC 03/02/2004
   *Modified: DC 03/08/2005  -27112
	*			DC 02/27/2008 - 127117 SQL error on PO initialization
	*			DC 12/22/2008 - #130129 - Combine RQ and PO into a single module
   *
   *Update trigger for Quote Lines:
   *	-Rejects updates to key fields
   * 	-Inserts into HQ Master Audit entry. 
   *	-Inserts Threshold Reviewers when appropriate
   *	-Deletes Threshold Reviewers if Units * UnitCost drops below the threshold
   *	-and the status of the review is still at New (1)
   */----------------------------------------------------------------
     
   DECLARE @numrows int, @validcnt int, @errmsg varchar(255), @rqco bCompany, @quote int,
   @quoteline int, @itotalcost bDollar, @dtotalcost bDollar, @msg varchar(255), 
   @istatus int, @dstatus int, @ishiploc varchar(20), @dshiploc varchar(20), @iexpdate bDate, @dexpdate bDate, 
   @vendorgroup bGroup, @ivendor bVendor, @dvendor bVendor, @ivendormatlid varchar(20), @dvendormatlid varchar(20),
   @iunitcost bUnitCost, @dunitcost bUnitCost, @iecm bECM, @decm bECM, @iunits bUnits, @dunits bUnits, @ium bUM, 
   @history varchar(3000), @rc int
    
   SELECT @numrows = @@ROWCOUNT
   IF @numrows = 0 RETURN
   
   SET NOCOUNT ON
   
   --Check for key changes
   SELECT @validcnt = COUNT(1) FROM Deleted d, Inserted i
   WHERE d.RQCo = i.RQCo AND d.Quote = i.Quote AND d.QuoteLine = i.QuoteLine
   
   IF @numrows <> @validcnt
   	BEGIN
   	SELECT @errmsg = 'Cannot change RQ Company, Quote or QuoteLine.'
   	GOTO error
   	END
   
   IF EXISTS (SELECT h.Locked FROM bRQQH h INNER JOIN Inserted i ON
   h.RQCo = i.RQCo AND h.Quote = i.Quote WHERE h.Locked = 'Y')
   	BEGIN
   	IF EXISTS (SELECT l.Quote FROM bRQQL l INNER JOIN Inserted i ON
   	l.RQCo = i.RQCo AND l.Quote = i.Quote AND l.QuoteLine = i.QuoteLine
   	INNER JOIN Deleted d ON l.RQCo = d.RQCo AND l.Quote = d.Quote AND l.QuoteLine = d.QuoteLine
   	WHERE ISNULL(i.INCo,0) <> ISNULL(d.INCo,0) OR ISNULL(i.Loc,0) <> ISNULL(d.Loc,0)
   	OR ISNULL(i.MatlGroup,0) <> ISNULL(d.MatlGroup,0) OR
   	ISNULL(i.Material,0) <> ISNULL(d.Material,0) OR ISNULL(i.Description,'') <> ISNULL(d.Description,'')
   	OR ISNULL(i.EMCo,0) <> ISNULL(d.EMCo,0) OR
   	ISNULL(i.JCCo,0) <> ISNULL(d.JCCo,0) OR ISNULL(i.Job,0) <> ISNULL(d.Job,0) 
   	OR ISNULL(i.ShipLoc,0) <> ISNULL(d.ShipLoc,0) OR ISNULL(i.VendorGroup,0) <> ISNULL(d.VendorGroup,0)
   	OR ISNULL(i.Vendor,0) <> ISNULL(d.Vendor,0) OR ISNULL(i.VendorMatlId,0) <> ISNULL(d.VendorMatlId,0)
   	OR ISNULL(i.UM,0) <> ISNULL(d.UM,0) OR ISNULL(i.Units,0) <> ISNULL(d.Units,0)
   	OR ISNULL(i.UnitCost,0) <> ISNULL(d.UnitCost,0) OR ISNULL(i.ECM,0) <> ISNULL(d.ECM,0)
   	OR ISNULL(i.TotalCost,0) <> ISNULL(d.TotalCost,0) OR 
   	ISNULL(i.ExpDate,0) <> ISNULL(d.ExpDate,0) OR ISNULL(i.ReqDate,0) <> ISNULL(d.ReqDate,0)) 
   		BEGIN
   		SELECT @errmsg = 'Cannot modify QuoteLines. Quote Header has been marked as Locked.'
   		GOTO error
   		END
   	END  
   
   
   --Use a cursor to process all lines
   DECLARE bcRQQL_update CURSOR LOCAL FAST_FORWARD FOR
   SELECT i.RQCo, i.Quote, i.QuoteLine, i.TotalCost, d.TotalCost, i.Status, 
   d.Status, i.ShipLoc, d.ShipLoc, i.ExpDate, d.ExpDate, i.VendorGroup, i.Vendor, d.Vendor, 
   i.VendorMatlId, d.VendorMatlId, i.UnitCost, d.UnitCost, i.ECM, d.ECM, i.Units, d.Units, i.UM
   FROM Inserted i INNER JOIN Deleted d
   ON i.RQCo = d.RQCo AND i.Quote = d.Quote AND i.QuoteLine = d.QuoteLine
   
   OPEN bcRQQL_update
   
   FETCH NEXT FROM bcRQQL_update INTO @rqco, @quote, @quoteline, @itotalcost, 
   @dtotalcost, @istatus, @dstatus, @ishiploc, @dshiploc, @iexpdate, @dexpdate, 
   @vendorgroup, @ivendor, @dvendor, @ivendormatlid, @dvendormatlid, @iunitcost, 
   @dunitcost, @iecm, @decm, @iunits, @dunits, @ium
   
   WHILE (@@FETCH_STATUS = 0)
   	BEGIN
   	IF @ium = 'LS' 
   		BEGIN
   		SELECT @iecm = NULL
   		UPDATE bRQQL SET ECM = NULL WHERE RQCo = @rqco AND Quote = @quote AND 
   			QuoteLine = @quoteline
   		END
   	ELSE
   		BEGIN
   		IF ISNULL(@iunits * (@iunitcost/(SELECT CASE @iecm WHEN 'E' THEN 1 WHEN 'C' THEN 100
   		WHEN 'M' THEN 1000 ELSE 1 END)),0) <> ISNULL(@dtotalcost,0)
   			BEGIN
   			UPDATE bRQQL SET TotalCost = @iunits * (@iunitcost/(SELECT CASE @iecm WHEN 'E' THEN 1 WHEN 'C' THEN 100
   				WHEN 'M' THEN 1000 ELSE 1 END))
   				WHERE RQCo = @rqco AND Quote = @quote AND QuoteLine = @quoteline
   			END
   
   		END
   
   	IF ISNULL(@itotalcost,0) <> ISNULL(@dtotalcost,0) 
   		BEGIN
   
   		--Add Threshold Reviewer if route = Purchase and Total Cost is greater then Threshold amount
   	 	IF EXISTS (SELECT TOP 1 1 FROM POCO WITH (NOLOCK) WHERE Threshold IS NOT NULL AND POCo = @rqco)
   	 		BEGIN
   	 		IF @itotalcost > (SELECT Threshold FROM POCO WITH (NOLOCK) WHERE POCo = @rqco)
   	 			BEGIN
   	 			INSERT RQQR (RQCo, Quote, QuoteLine, Reviewer, AssignedDate, Status)
   		 			SELECT @rqco, @quote, @quoteline, r.ThresholdReviewer, GETDATE(), 0
   		 			FROM POCO r WITH (NOLOCK) WHERE r.POCo = @rqco 
   		 			AND r.ThresholdReviewer IS NOT NULL AND r.ThresholdReviewer 
   		 			NOT IN (SELECT Reviewer FROM RQQR WITH (NOLOCK) WHERE RQCo = @rqco 
   		 			AND Quote = @quote AND QuoteLine = @quoteline)
   	 			END
   	 		END
   		END
   	
   	--If the Statuses are Equal then it's ok, to update the Status
   	--If they are NOT Equal, then they are already being updated so 
   	--don't try and update them again
   	IF @istatus = @dstatus
   		BEGIN
   		--Update the Qoute Status
   		EXEC bspRQSetQuoteLineStatus @rqco, @quote, @quoteline, @msg
   		END
   	
   	IF @ium = 'LS'
   		BEGIN
   		UPDATE bRQRL 
   		SET Vendor = ISNULL(@ivendor, Vendor), 
   		VendorMatlId = ISNULL(@ivendormatlid, VendorMatlId),
   		ECM = NULL,
   		ShipLoc = ISNULL(@ishiploc, ShipLoc), 
   		ExpDate = ISNULL(@iexpdate, ExpDate),
   		TotalCost = @itotalcost,
   		VendorGroup = ISNULL(@vendorgroup, VendorGroup)
   		WHERE RQCo = @rqco AND Quote = @quote AND QuoteLine = @quoteline AND PO IS NULL
   		END
   	ELSE
   		BEGIN
   		UPDATE bRQRL 
   		SET Vendor = ISNULL(@ivendor, Vendor), 
   		VendorMatlId = ISNULL(@ivendormatlid, VendorMatlId),
   		ECM = ISNULL(@iecm, ECM),
   		ShipLoc = ISNULL(@ishiploc, ShipLoc), 
   		ExpDate = ISNULL(@iexpdate, ExpDate), 
   		UnitCost = ISNULL(@iunitcost, UnitCost), 
   		TotalCost = ISNULL(Units * (@iunitcost/(SELECT CASE @iecm 
   							WHEN 'E' THEN 1 WHEN 'C' THEN 100
   							WHEN 'M' THEN 1000 ELSE 1 END)), TotalCost),
   		VendorGroup = ISNULL(@vendorgroup, VendorGroup)
   		WHERE RQCo = @rqco AND Quote = @quote AND QuoteLine = @quoteline AND PO IS NULL
   		END
   
   
   UPDATE bRQQL SET 
   	INCo = (SELECT CASE WHEN (SELECT Count(*) FROM bRQRL n WHERE n.INCo <> 
   		(SELECT Top 1 m.INCo FROM bRQRL m WHERE m.RQCo = @rqco AND Quote = @quote AND
   
   		QuoteLine = @quoteline) AND n.RQCo = @rqco AND n.Quote = @quote AND n.QuoteLine 
   		= @quoteline) = 0 THEN (SELECT TOP 1 m.INCo FROM bRQRL m WHERE m.RQCo = @rqco AND Quote = @quote AND
   		QuoteLine = @quoteline) ELSE NULL END), 
   	Loc = (SELECT CASE WHEN (SELECT Count(*) FROM bRQRL n WHERE n.Loc <> 
   		(SELECT Top 1 m.Loc FROM bRQRL m WHERE m.RQCo = @rqco AND Quote = @quote AND
   		QuoteLine = @quoteline) AND n.RQCo = @rqco AND n.Quote = @quote AND n.QuoteLine 
   		= @quoteline) = 0 THEN (SELECT TOP 1 m.Loc FROM bRQRL m WHERE m.RQCo = @rqco AND Quote = @quote AND
   		QuoteLine = @quoteline) ELSE NULL END), 
   	EMCo = (SELECT CASE WHEN (SELECT Count(*) FROM bRQRL n WHERE n.EMCo <> 
   		(SELECT Top 1 m.EMCo FROM bRQRL m WHERE m.RQCo = @rqco AND Quote = @quote AND
   		QuoteLine = @quoteline) AND n.RQCo = @rqco AND n.Quote = @quote AND n.QuoteLine 
   		= @quoteline) = 0 THEN (SELECT TOP 1 m.EMCo FROM bRQRL m WHERE m.RQCo = @rqco AND Quote = @quote AND
   		QuoteLine = @quoteline) ELSE NULL END), 
   	JCCo = (SELECT CASE WHEN (SELECT Count(*) FROM bRQRL n WHERE n.JCCo <> 
   		(SELECT Top 1 m.JCCo FROM bRQRL m WHERE m.RQCo = @rqco AND Quote = @quote AND
   		QuoteLine = @quoteline) AND n.RQCo = @rqco AND n.Quote = @quote AND n.QuoteLine 
   		= @quoteline) = 0 THEN (SELECT TOP 1 m.JCCo FROM bRQRL m WHERE m.RQCo = @rqco AND Quote = @quote AND
   		QuoteLine = @quoteline) ELSE NULL END),
   	Job = (SELECT CASE WHEN (SELECT Count(*) FROM bRQRL n WHERE n.Job <> 
   		(SELECT Top 1 m.Job FROM bRQRL m WHERE m.RQCo = @rqco AND Quote = @quote AND
   		QuoteLine = @quoteline) AND n.RQCo = @rqco AND n.Quote = @quote AND n.QuoteLine 
   		= @quoteline) = 0 THEN (SELECT TOP 1 m.Job FROM bRQRL m WHERE m.RQCo = @rqco AND Quote = @quote AND
   		QuoteLine = @quoteline) ELSE NULL END),
   	ReqDate = (SELECT Min(ISNULL(ReqDate,'')) FROM bRQRL WHERE RQCo = @rqco AND Quote = @quote
   		AND QuoteLine = @quoteline)
   
   WHERE RQCo = @rqco AND Quote = @quote AND QuoteLine = @quoteline
   
   
   IF @itotalcost < 0  
   	BEGIN
   	UPDATE bRQQL SET TotalCost = 0 WHERE RQCo = @rqco AND Quote = @quote AND 
   	    QuoteLine = @quoteline
   	END
   
   
   
   --Create the history line of the changes being made to the Quote Line
   SELECT @history = '' --Initialize the history variable 
   
   
   IF ISNULL(@istatus, 0) <> ISNULL(@dstatus, 0)
   	BEGIN
   	IF (@istatus = 0 OR @istatus = 1 OR @istatus = 2) AND (@dstatus = 0 OR @dstatus = 1 OR @dstatus = 2)
   		BEGIN
   		SELECT @history = ISNULL(@history,'') + 'Quote Status was changed from "' + 
   		(SELECT CASE @dstatus WHEN 0 THEN 'Open' WHEN 1 THEN 'Ready for Vendor' WHEN 2 Then 'Quoted' END)
    		+ '" to "' + 
   		(SELECT CASE @istatus WHEN 0 THEN 'Open' WHEN 1 THEN 'Ready for Vendor' WHEN 2 Then 'Quoted' END)
   		 + '". '
   		END --If Quote Status was changed
   	END --If Status being changed was Open, ReadyForVendor or Quoted
   
   IF ISNULL(@ishiploc, '') <> ISNULL(@dshiploc, '')
   	BEGIN
   	SELECT @history = ISNULL(@history,'') + 'Ship Location was changed from "' +  
   	ISNULL(@dshiploc, '') + '" to "' + ISNULL(@ishiploc, '') + '". '
   	END --If Ship Location was changed
   
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
   
   IF ISNULL(@iunits, 0) <> ISNULL(@dunits, 0)
   	BEGIN
   	SELECT @history = ISNULL(@history,'') + 'Number of Units was changed from "' +  
   	RTRIM(ISNULL(CONVERT(varchar(30),@dunits), '')) + '" to "' + 
   	RTRIM(ISNULL(CONVERT(varchar(30),@iunits), '')) + '". '
   	END --If Units was changed 	
   
   IF ISNULL(@iunitcost, 0) <> ISNULL(@dunitcost, 0)
   	BEGIN 
   	SELECT @history = ISNULL(@history,'') + 'Unit Cost was changed from "' +  
   	RTRIM(ISNULL(CONVERT(varchar(30), @dunitcost),'')) + '" to "' + 
   	RTRIM(ISNULL(CONVERT(varchar(30), @iunitcost),'')) + '". '
   	END --If Unit Cost was changed
   	
   IF ISNULL(@iecm, '') <> ISNULL(@decm, '')
   	BEGIN
   	SELECT @history = ISNULL(@history,'') + 'ECM was changed from "' +  
   	ISNULL(@decm, '') + '" to "' + ISNULL(@iecm, '') + '". '
   	END --If ECM was changed
   
   IF ISNULL(@itotalcost, 0) <> ISNULL(@dtotalcost, 0)
   	BEGIN
   	SELECT @history = ISNULL(@history,'') + 'Total Cost was changed from "' +  
   	RTRIM(ISNULL(CONVERT(varchar(30), @dtotalcost),'')) + '" to "' + 
   	RTRIM(ISNULL(CONVERT(varchar(30), @itotalcost),'')) + '". '
   	END --If Total Cost was changed
   
   IF ISNULL(@iexpdate, '') <> ISNULL(@dexpdate, '')
   	BEGIN
   	SELECT @history = ISNULL(@history,'') + 'Expected Date was changed from "' + 
   	RTRIM(CONVERT(char(30),ISNULL(@dexpdate, ''))) + '" to "' + 
   	RTRIM(CONVERT(char(30),ISNULL(@iexpdate, ''))) + '". '
   	END --If Expected Date was changed
   
   
   --If changes have been made to the Quote Line then update the Reviewer notes
   --with a log of these changes and update the status for the Reviewer 
   --and Line where appropriate.
   IF @history <> '' 
   	BEGIN
   	--Complete the history line to be added to the reviewer notes
   	SELECT @history = 'The following changes were made to the Quote Line on ' +
   	RTRIM(CONVERT(char(30),GETDATE())) + ':  ' + ISNULL(@history, '') + 
   	'Review status has been reset due to these changes.'
   	
   	--Update the Reviewers notes with what changes have been made
   	--and reset the review status to Open so the reviewer can look
   	--over the changes that have been made to the RQ Line
	--DC #127117 - only update if the Quote Line Status is not 4=Complete
	If @istatus <> 4
	BEGIN
   		UPDATE bRQQR 
		SET Notes = ISNULL(Notes, '') + ISNULL(@history,''), 
			Status = 0 
   		WHERE RQCo = @rqco 
			AND Quote = @quote 
			AND QuoteLine = @quoteline 
			AND Status <> 0  
	END
   	
   	--EXEC bspRQSetQuoteLineStatus @rqco, @quote, @quoteline, @msg
   
   	END -- If History variable contains information
   
   	
   IF @istatus = @dstatus
   	BEGIN
   	--Update the status for the Quote Line
   	EXEC bspRQSetQuoteLineStatus @rqco, @quote, @quoteline, @msg
   	END
   
   FETCH NEXT FROM bcRQQL_update INTO @rqco, @quote, @quoteline, @itotalcost, 
   @dtotalcost, @istatus, @dstatus, @ishiploc, @dshiploc, @iexpdate, @dexpdate, @vendorgroup, @ivendor,
   @dvendor, @ivendormatlid, @dvendormatlid, @iunitcost, @dunitcost, @iecm, @decm, @iunits, @dunits, @ium
   
   END
   
   CLOSE bcRQQL_update
   DEALLOCATE bcRQQL_update
   
   
   
   --Add HQ Master Audit entry
   IF EXISTS(SELECT TOP 1 0 FROM Inserted i JOIN bPOCO c ON c.POCo = i.RQCo WHERE c.AuditQuote = 'Y')
   	BEGIN 
    	--Insert records into HQMA for changes made to audited fields
   	IF UPDATE(MatlGroup)
   		INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		SELECT 'bRQQL', 'RQCo: ' + CONVERT(char(3),i.RQCo) + ' Quote: ' + 
   		CONVERT(char(10), i.Quote) + ' QuoteLine: ' + CONVERT(varchar(10), i.QuoteLine), i.RQCo,
   		'C', 'MatlGroup', ISNULL(d.MatlGroup,''), ISNULL(i.MatlGroup,''), GETDATE(), SUSER_SNAME()
   		FROM Inserted i JOIN Deleted d ON i.RQCo = d.RQCo AND i.Quote = d.Quote AND i.QuoteLine = d.QuoteLine
   		WHERE ISNULL(i.Material,0) <> ISNULL(d.Material,0)
      	
   	IF UPDATE(Material)
   		INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		SELECT 'bRQQL', 'RQCo: ' + CONVERT(char(3),i.RQCo) + ' Quote: ' + 
   		CONVERT(char(10), i.Quote) + ' QuoteLine: ' + CONVERT(varchar(10), i.QuoteLine), i.RQCo,
   		'C', 'Material', ISNULL(d.Material,''), ISNULL(i.Material,''), GETDATE(), SUSER_SNAME()
   		FROM Inserted i JOIN Deleted d ON i.RQCo = d.RQCo AND i.Quote = d.Quote AND i.QuoteLine = d.QuoteLine
   		WHERE ISNULL(i.Material,0) <> ISNULL(d.Material,0)
    
   	IF UPDATE(Loc)
   		INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		SELECT 'bRQQL', 'RQCo: ' + CONVERT(char(3),i.RQCo) + ' Quote: ' + 
   		CONVERT(char(10), i.Quote) + ' QuoteLine: ' + CONVERT(varchar(10), i.QuoteLine), i.RQCo,
   		'C', 'Loc', ISNULL(d.Loc,''), ISNULL(i.Loc,''), GETDATE(), SUSER_SNAME()
   		FROM Inserted i JOIN Deleted d ON i.RQCo = d.RQCo AND i.Quote = d.Quote AND i.QuoteLine = d.QuoteLine
   		WHERE ISNULL(i.Loc,0) <> ISNULL(d.Loc,0)
   
   	IF UPDATE(INCo)
   		INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		SELECT 'bRQQL', 'RQCo: ' + CONVERT(char(3),i.RQCo) + ' Quote: ' + 
   		CONVERT(char(10), i.Quote) + ' QuoteLine: ' + CONVERT(varchar(10), i.QuoteLine), i.RQCo,
   		'C', 'INCo', ISNULL(d.INCo,''), ISNULL(i.INCo,''), GETDATE(), SUSER_SNAME()
   		FROM Inserted i JOIN Deleted d ON i.RQCo = d.RQCo AND i.Quote = d.Quote AND i.QuoteLine = d.QuoteLine
   		WHERE ISNULL(i.INCo,0) <> ISNULL(d.INCo,0)
   
   	IF UPDATE(EMCo)
   		INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		SELECT 'bRQQL', 'RQCo: ' + CONVERT(char(3),i.RQCo) + ' Quote: ' + 
   		CONVERT(char(10), i.Quote) + ' QuoteLine: ' + CONVERT(varchar(10), i.QuoteLine), i.RQCo,
   		'C', 'EMCo', ISNULL(d.EMCo,''), ISNULL(i.EMCo,''), GETDATE(), SUSER_SNAME()
   		FROM Inserted i JOIN Deleted d ON i.RQCo = d.RQCo AND i.Quote = d.Quote AND i.QuoteLine = d.QuoteLine
   		WHERE ISNULL(i.EMCo,0) <> ISNULL(d.EMCo,0)
   
   	IF UPDATE(JCCo)
   		INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		SELECT 'bRQQL', 'RQCo: ' + CONVERT(char(3),i.RQCo) + ' Quote: ' + 
   		CONVERT(char(10), i.Quote) + ' QuoteLine: ' + CONVERT(varchar(10), i.QuoteLine), i.RQCo,
   		'C', 'JCCo', ISNULL(d.JCCo,''), ISNULL(i.JCCo,''), GETDATE(), SUSER_SNAME()
   		FROM Inserted i JOIN Deleted d ON i.RQCo = d.RQCo AND i.Quote = d.Quote AND i.QuoteLine = d.QuoteLine
   		WHERE ISNULL(i.JCCo,0) <> ISNULL(d.JCCo,0)
   
   	IF UPDATE(Job)
   		INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		SELECT 'bRQQL', 'RQCo: ' + CONVERT(char(3),i.RQCo) + ' Quote: ' + 
   		CONVERT(char(10), i.Quote) + ' QuoteLine: ' + CONVERT(varchar(10), i.QuoteLine), i.RQCo,
   		'C', 'Job', ISNULL(d.Job,''), ISNULL(i.Job,''), GETDATE(), SUSER_SNAME()
   		FROM Inserted i JOIN Deleted d ON i.RQCo = d.RQCo AND i.Quote = d.Quote AND i.QuoteLine = d.QuoteLine
   		WHERE ISNULL(i.Job,0) <> ISNULL(d.Job,0)
   
   	IF UPDATE(ShipLoc)
   		INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		SELECT 'bRQQL', 'RQCo: ' + CONVERT(char(3),i.RQCo) + ' Quote: ' + 
   		CONVERT(char(10), i.Quote) + ' QuoteLine: ' + CONVERT(varchar(10), i.QuoteLine), i.RQCo,
   		'C', 'ShipLoc', ISNULL(d.ShipLoc,''), ISNULL(i.ShipLoc,''), GETDATE(), SUSER_SNAME()
   		FROM Inserted i JOIN Deleted d ON i.RQCo = d.RQCo AND i.Quote = d.Quote AND i.QuoteLine = d.QuoteLine
   		WHERE ISNULL(i.ShipLoc,0) <> ISNULL(d.ShipLoc,0)
   
   	IF UPDATE(ExpDate)
   		INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		SELECT 'bRQQL', 'RQCo: ' + CONVERT(char(3),i.RQCo) + ' Quote: ' + 
   		CONVERT(char(10), i.Quote) + ' QuoteLine: ' + CONVERT(varchar(10), i.QuoteLine), i.RQCo,
   		'C', 'ExpDate', ISNULL(d.ExpDate,''), ISNULL(i.ExpDate,''), GETDATE(), SUSER_SNAME()
   		FROM Inserted i JOIN Deleted d ON i.RQCo = d.RQCo AND i.Quote = d.Quote AND i.QuoteLine = d.QuoteLine
   		WHERE ISNULL(i.ExpDate,0) <> ISNULL(d.ExpDate,0)
   
   	IF UPDATE(ReqDate)
   		INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		SELECT 'bRQQL', 'RQCo: ' + CONVERT(char(3),i.RQCo) + ' Quote: ' + 
   		CONVERT(char(10), i.Quote) + ' QuoteLine: ' + CONVERT(varchar(10), i.QuoteLine), i.RQCo,
   		'C', 'ReqDate', ISNULL(d.ReqDate,''), ISNULL(i.ReqDate,''), GETDATE(), SUSER_SNAME()
   		FROM Inserted i JOIN Deleted d ON i.RQCo = d.RQCo AND i.Quote = d.Quote AND i.QuoteLine = d.QuoteLine
   		WHERE ISNULL(i.ReqDate,0) <> ISNULL(d.ReqDate,0)
   
   	IF UPDATE(Description)
   		INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		SELECT 'bRQQL', 'RQCo: ' + CONVERT(char(3),i.RQCo) + ' Quote: ' + 
   		CONVERT(char(10), i.Quote) + ' QuoteLine: ' + CONVERT(varchar(10), i.QuoteLine), i.RQCo,
   		'C', 'Description', ISNULL(d.Description,''), ISNULL(i.Description,''), GETDATE(), SUSER_SNAME()
   		FROM Inserted i JOIN Deleted d ON i.RQCo = d.RQCo AND i.Quote = d.Quote AND i.QuoteLine = d.QuoteLine
   		WHERE ISNULL(i.Description,0) <> ISNULL(d.Description,0)
   
   	IF UPDATE(VendorGroup)
   		INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		SELECT 'bRQQL', 'RQCo: ' + CONVERT(char(3),i.RQCo) + ' Quote: ' + 
   		CONVERT(char(10), i.Quote) + ' QuoteLine: ' + CONVERT(varchar(10), i.QuoteLine), i.RQCo,
   		'C', 'VendorGroup', ISNULL(d.VendorGroup,''), ISNULL(i.VendorGroup,''), GETDATE(), SUSER_SNAME()
   		FROM Inserted i JOIN Deleted d ON i.RQCo = d.RQCo AND i.Quote = d.Quote AND i.QuoteLine = d.QuoteLine
   		WHERE ISNULL(i.VendorGroup,0) <> ISNULL(d.VendorGroup,0)
   
   	IF UPDATE(Vendor)
   		INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		SELECT 'bRQQL', 'RQCo: ' + CONVERT(char(3),i.RQCo) + ' Quote: ' + 
   		CONVERT(char(10), i.Quote) + ' QuoteLine: ' + CONVERT(varchar(10), i.QuoteLine), i.RQCo,
   		'C', 'Vendor', ISNULL(d.Vendor,''), ISNULL(i.Vendor,''), GETDATE(), SUSER_SNAME()
   		FROM Inserted i JOIN Deleted d ON i.RQCo = d.RQCo AND i.Quote = d.Quote AND i.QuoteLine = d.QuoteLine
   		WHERE ISNULL(i.Vendor,0) <> ISNULL(d.Vendor,0)
   
   	IF UPDATE(VendorMatlId)
   		INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		SELECT 'bRQQL', 'RQCo: ' + CONVERT(char(3),i.RQCo) + ' Quote: ' + 
   		CONVERT(char(10), i.Quote) + ' QuoteLine: ' + CONVERT(varchar(10), i.QuoteLine), i.RQCo,
   		'C', 'VendorMatlId', ISNULL(d.VendorMatlId,''), ISNULL(i.VendorMatlId,''), GETDATE(), SUSER_SNAME()
   		FROM Inserted i JOIN Deleted d ON i.RQCo = d.RQCo AND i.Quote = d.Quote AND i.QuoteLine = d.QuoteLine
   		WHERE ISNULL(i.VendorMatlId,0) <> ISNULL(d.VendorMatlId,0)
   
   	IF UPDATE(Units)
   		INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		SELECT 'bRQQL', 'RQCo: ' + CONVERT(char(3),i.RQCo) + ' Quote: ' + 
   		CONVERT(char(10), i.Quote) + ' QuoteLine: ' + CONVERT(varchar(10), i.QuoteLine), i.RQCo,
   		'C', 'Units', ISNULL(d.Units,''), ISNULL(i.Units,''), GETDATE(), SUSER_SNAME()
   		FROM Inserted i JOIN Deleted d ON i.RQCo = d.RQCo AND i.Quote = d.Quote AND i.QuoteLine = d.QuoteLine
   		WHERE ISNULL(i.Units,0) <> ISNULL(d.Units,0)
   
   	IF UPDATE(UnitCost)
   		INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		SELECT 'bRQQL', 'RQCo: ' + CONVERT(char(3),i.RQCo) + ' Quote: ' + 
   		CONVERT(char(10), i.Quote) + ' QuoteLine: ' + CONVERT(varchar(10), i.QuoteLine), i.RQCo,
   		'C', 'UnitCost', CONVERT(char(10), d.UnitCost), CONVERT(char(10), i.UnitCost), GETDATE(), SUSER_SNAME()
   		FROM Inserted i JOIN Deleted d ON i.RQCo = d.RQCo AND i.Quote = d.Quote AND i.QuoteLine = d.QuoteLine
   		WHERE ISNULL(i.UnitCost,0) <> ISNULL(d.UnitCost,0)
   
   	IF UPDATE(ECM)
   		INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		SELECT 'bRQQL', 'RQCo: ' + CONVERT(char(3),i.RQCo) + ' Quote: ' + 
   		CONVERT(char(10), i.Quote) + ' QuoteLine: ' + CONVERT(varchar(10), i.QuoteLine), i.RQCo,
   		'C', 'ECM', ISNULL(d.ECM,''), ISNULL(i.ECM,''), GETDATE(), SUSER_SNAME()
   		FROM Inserted i JOIN Deleted d ON i.RQCo = d.RQCo AND i.Quote = d.Quote AND i.QuoteLine = d.QuoteLine
   		WHERE ISNULL(i.ECM,0) <> ISNULL(d.ECM,0)
   
   	IF UPDATE(UM)
   		INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		SELECT 'bRQQL', 'RQCo: ' + CONVERT(char(3),i.RQCo) + ' Quote: ' + 
   		CONVERT(char(10), i.Quote) + ' QuoteLine: ' + CONVERT(varchar(10), i.QuoteLine), i.RQCo,
   		'C', 'UM', ISNULL(d.UM,''), ISNULL(i.UM,''), GETDATE(), SUSER_SNAME()
   		FROM Inserted i JOIN Deleted d ON i.RQCo = d.RQCo AND i.Quote = d.Quote AND i.QuoteLine = d.QuoteLine
   		WHERE ISNULL(i.UM,0) <> ISNULL(d.UM,0)
   	END
   
   
   RETURN
   
   error:
   	SELECT @errmsg = @errmsg + ' - cannot update Quote Line!'
   	RAISERROR(@errmsg, 11, -1);
   	ROLLBACK TRANSACTION
   
   
   
  
 



GO
ALTER TABLE [dbo].[bRQQL] ADD CONSTRAINT [biRQQL] PRIMARY KEY CLUSTERED  ([RQCo], [Quote], [QuoteLine]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bRQQL] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bRQQL].[ECM]'
GO
