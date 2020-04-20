CREATE TABLE [dbo].[bRQRR]
(
[RQCo] [dbo].[bCompany] NOT NULL,
[Reviewer] [varchar] (3) COLLATE Latin1_General_BIN NOT NULL,
[RQID] [dbo].[bRQ] NOT NULL,
[RQLine] [dbo].[bItem] NOT NULL,
[AssignedDate] [dbo].[bDate] NOT NULL CONSTRAINT [DF_bRQRR_AssignedDate] DEFAULT (dateadd(day,(0),datediff(day,(0),getdate()))),
[ReviewDate] [dbo].[bDate] NULL,
[Status] [int] NOT NULL CONSTRAINT [DF_bRQRR_Status] DEFAULT ((0)),
[Description] [varchar] (300) COLLATE Latin1_General_BIN NULL,
[Notes] [varchar] (6000) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btRQRRd    Script Date: 3/2/2004 9:59:36 AM ******/
    CREATE    TRIGGER [dbo].[btRQRRd] ON [dbo].[bRQRR] FOR DELETE AS
    

/*-----------------------------------------------------------------
    *Created:  DC 3/2/2004
    *Modified: DC 1/9/2009  #130129 - Combine RQ and PO into a single module
    *
    *The Delete trigger for bRQRR.  
    *	-Inserts a record of the deletion into the HQ Master Audit entry.
    *	-Updates status of bRQRL Line if the deletion of the Reviewer would
    *	 affect that status
    *	-
    */----------------------------------------------------------------
    
    DECLARE @errmsg varchar(255), @numrows int, @rqco bCompany, @rqid bRQ, @rqline bItem,
    @msg varchar(255)
    
    SELECT @numrows = @@rowcount
    IF @numrows = 0 RETURN
    
    SET NOCOUNT ON
    
    --If more than one row is being updated, then a cursor will be needed to process
    --each line
    IF @@rowcount <> 1
    	BEGIN
    	--Use a cursor to process all lines
    	DECLARE bcRQRR_delete CURSOR LOCAL FAST_FORWARD FOR
    	SELECT d.RQCo, d.RQID, d.RQLine FROM Deleted d
    	
    	OPEN bcRQRR_delete
    	FETCH NEXT FROM bcRQRR_delete INTO @rqco, @rqid, @rqline
    	
    	WHILE (@@FETCH_STATUS = 0)
    		BEGIN		
    		--Update the RQ Line Status for the associated RQ Line
    		EXEC bspRQSetRQLineStatus @rqco, @rqid, @rqline, @msg
    
    		FETCH NEXT FROM bcRQRR_delete INTO @rqco, @rqid, @rqline
    		END --While (@@Fetch_Status = 0)
    	
    		--Cleanup and destroy the cursor
    		CLOSE bcRQRR_delete
    		DEALLOCATE bcRQRR_delete
    	END --If @@rowcount <> 1
    ELSE
    	BEGIN	
    	--Update the RQ Line Status for the associated RQ Line
    	SELECT @rqco = RQCo, @rqid = RQID, @rqline = RQLine FROM Deleted
    	EXEC bspRQSetRQLineStatus @rqco, @rqid, @rqline, @msg
    
    	END --Only one record was being updated, no cursor was used
    
    
    
    --Audit RQ Reviewer deletions
    IF EXISTS(SELECT TOP 1 0 FROM Deleted d INNER JOIN bPOCO a ON a.POCo = d.RQCo 
    WHERE a.AuditReview = 'Y')
    	BEGIN
    	INSERT INTO bHQMA
    	(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	SELECT 'bRQRR', 'RQ Co#: ' + CONVERT(varchar(3),RQCo) + ' RQID: ' + 
    	CONVERT(varchar(10),RQID) + ' RQLine: ' + CONVERT(varchar(20),RQLine) + 
    	' Reviewer: ' + convert(varchar(20),Reviewer), RQCo, 'D', NULL, NULL, NULL, GETDATE(), 
    	SUSER_SNAME() FROM Deleted d
        
    	IF @@rowcount <> @numrows
    		BEGIN
    		SELECT @errmsg = 'Unable to update RQ Reviewer Audit'
    		GOTO ERROR
    		END
    	END
    
    RETURN
    
    ERROR:
    	SELECT @errmsg = ISNULL(@errmsg,'') + ' - cannot delete RQ Reviewer!'
    	RAISERROR(@errmsg, 11, -1);
    	ROLLBACK TRANSACTION
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   CREATE     TRIGGER [dbo].[btRQRRi] ON [dbo].[bRQRR] FOR INSERT AS
    

/*-----------------------------------------------------------------
    *Created:  GWC 09/27/2004
    *Modified: DC 1/9/2009  #130129 - Combine RQ and PO into a single module
    *
    *
    *Insert trigger for RQ Line Reviewers
    */----------------------------------------------------------------
    DECLARE @numrows int, @errmsg varchar(255), @rqco bCompany, @rqid bRQ, 
    		@rqline bItem, @msg varchar(255)
    
    SELECT @numrows = @@rowcount
    IF @numrows = 0 RETURN
    
    SET NOCOUNT ON
    
    --If RQLine is already on a Quote, no Reviewers can be added.
    --IF EXISTS (SELECT i.RQCo FROM Inserted i INNER JOIN bRQRL r ON i.RQCo = r.RQCo AND
    --i.RQID = r.RQID AND i.RQLine = r.RQLine WHERE r.Quote IS NOT NULL)
    --	BEGIN
    --	SELECT @errmsg = 'Unable to insert Reviewers. RQ Line is already on a Quote.'
    --	GOTO error
    --	END
    
    --If RQLine is already on a PO, no Reviewers can be added.
    IF EXISTS (SELECT i.RQCo FROM Inserted i INNER JOIN bRQRL r ON i.RQCo = r.RQCo AND
    i.RQID = r.RQID AND i.RQLine = r.RQLine WHERE r.PO IS NOT NULL)
    	BEGIN
    	SELECT @errmsg = 'Unable to insert Reviewers. RQ Line is already on a PO.'
    	GOTO error
    	END
    
    --Use a cursor to process all lines
    DECLARE bcRQRR_insert CURSOR LOCAL FAST_FORWARD FOR
    SELECT i.RQCo, i.RQID, i.RQLine FROM Inserted i
    	
    OPEN bcRQRR_insert
    FETCH NEXT FROM bcRQRR_insert INTO @rqco, @rqid, @rqline
    
    WHILE (@@FETCH_STATUS = 0)
    	BEGIN 	
    	--Update the RQ Line status
    	EXEC bspRQSetRQLineStatus @rqco, @rqid, @rqline, @msg
    	
        FETCH NEXT FROM bcRQRR_insert INTO @rqco, @rqid, @rqline
        END
    
    CLOSE bcRQRR_insert
    DEALLOCATE bcRQRR_insert
    
    --Add HQ Master Audit entry
    IF EXISTS (SELECT TOP 1 0 FROM Inserted i INNER JOIN bPOCO a ON a.POCo = i.RQCo 
    WHERE a.AuditRQ = 'Y')
    	BEGIN
    	INSERT INTO bHQMA
      	(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	SELECT 'bRQRR', 'RQCo: ' + CONVERT(varchar(3),RQCo) + ' RQID: ' + 
    	CONVERT(varchar(10),RQID) + ' RQLine: ' + CONVERT(varchar(20),RQLine),
    	RQCo, 'A', NULL, NULL, NULL, GETDATE(), SUSER_SNAME()
    	FROM Inserted i
        
    	IF @@rowcount <> @numrows
    		BEGIN
    		SELECT @errmsg = 'Unable to update HQ Master Audit'
    		GOTO error
    		END
    	END
    
    RETURN
    
    error:
        SELECT @errmsg = @errmsg +  ' - cannot insert RQ Reviewer!'
        RAISERROR(@errmsg, 11, -1);
        ROLLBACK TRANSACTION
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   /****** Object:  Trigger dbo.btRQRRu    Script Date: 11/10/2004 7:17:39 AM ******/
   
   
   /****** Object:  Trigger dbo.btRQRRu    Script Date: 10/20/2004 8:21:03 AM ******/
   CREATE       TRIGGER [dbo].[btRQRRu] ON [dbo].[bRQRR] FOR UPDATE AS
    

/*-----------------------------------------------------------------
    *Created:  DC  03/04/2004
    *Modified: DC 1/9/2009 #130129 -Combine RQ and PO into a single module
    *
    *Update trigger for RQ Reviewers
    *Rejects changes to key fields
    *Inserts into HQ Master Audit entry. 
    */----------------------------------------------------------------
    DECLARE @numrows int, @validcnt int, @errmsg varchar(255), @istatus as int, 
    @dstatus int, @rqco bCompany, @rqid bRQ, @rqline int, @msg varchar(255)
    
    SELECT @numrows = @@rowcount
    IF @numrows = 0 RETURN
    
    SET NOCOUNT ON
    
    --Don't allow changes if a Key field is being changed
    SELECT @validcnt = COUNT(1) FROM Deleted d, Inserted i
    WHERE d.RQCo = i.RQCo AND d.RQID = i.RQID AND d.RQLine = i.RQLine 
    AND d.Reviewer = i.Reviewer
    
    IF @numrows <> @validcnt
    	BEGIN
    	SELECT @errmsg = 'Cannot change RQ Company, RQID, RQLine, or Reviewer.'
    	GOTO ERROR
    	END --A key field was being changed
    
    --Don't allow changes if the Requistion Line if the PO or PO Lines have been filled in
    --the RQ Line status check should catch this, but just in cas an extra check was added
    IF EXISTS (SELECT i.RQCo FROM inserted i
    				INNER JOIN bRQRL l ON i.RQCo = l.RQCo AND i.RQID = l.RQID AND i.RQLine = l.RQLine
    				WHERE l.PO IS NOT NULL OR l.POItem IS NOT NULL)
    	BEGIN
   	select @errmsg = (SELECT i.RQID FROM inserted i
    				INNER JOIN bRQRL l ON i.RQCo = l.RQCo AND i.RQID = l.RQID AND i.RQLine = l.RQLine
    				WHERE l.PO IS NOT NULL OR l.POItem IS NOT NULL)
   	select @errmsg = @errmsg + char(13)
   	select @errmsg = (SELECT l.PO FROM inserted i
    				INNER JOIN bRQRL l ON i.RQCo = l.RQCo AND i.RQID = l.RQID AND i.RQLine = l.RQLine
    				WHERE l.PO IS NOT NULL OR l.POItem IS NOT NULL)
   	select @errmsg = @errmsg + char(13)
    	SELECT @errmsg = @errmsg + 'Unable to modify the review. The associated RQ Line has already been placed on a PO.'
    	GOTO ERROR
    	END	--If associated RQ Line is already on a PO
    
    --Don't allow changes if the Requistion Line if the Quote or Quote Lines have been filled in
    --the RQ Line status check should catch this, but just in case an extra check was added
   /* IF EXISTS (SELECT r.RQCo FROM bRQRR r WITH (NOLOCK)
    INNER JOIN Inserted i ON r.RQCo = i.RQCo AND r.RQID = i.RQID AND r.RQLine = i.RQLine
    INNER JOIN bRQRL l ON i.RQCo = l.RQCo AND i.RQID = l.RQID AND i.RQLine = l.RQLine
    WHERE Quote IS NOT NULL OR QuoteLine IS NOT NULL)
    	BEGIN
    	SELECT @errmsg = 'Unable to modify the review. The associated RQ Line is on a Quote.'
    	GOTO ERROR
    	END	--If associated RQ Line is already on a Quote
   */
   
    --Don't allow changes to the Review if the Requistion Line that the Review is linked to 
    --does not currently have a status of Open
    --IF EXISTS (SELECT l.Status FROM bRQRR r WITH (NOLOCK) INNER JOIN Inserted i ON 
    --r.RQCo = i.RQCo AND r.RQID = i.RQID AND r.RQLine = i.RQLine INNER JOIN bRQRL l 
    --ON i.RQCo = l.RQCo AND i.RQID = l.RQID AND i.RQLine = l.RQLine WHERE l.Status <> 0)
    --	BEGIN
    --	SELECT @errmsg = 'Unable to modify the review. Associated RQ Line status is not Open.'
    --	GOTO ERROR
    --	END	--If associated RQ Line does not have a status of Open
    
    --If more than one row is being updated, then a cursor will be needed to process
    --each line
    IF @@rowcount <> 1
    	BEGIN
    	--Use a cursor to process all lines
    	DECLARE bcRQRR_update CURSOR LOCAL FAST_FORWARD FOR
    	SELECT i.Status, d.Status, i.RQCo, i.RQID, i.RQLine FROM Deleted d, Inserted i
    	
    	OPEN bcRQRR_update
    	FETCH NEXT FROM bcRQRR_update INTO @istatus, @dstatus, @rqco, @rqid, @rqline
    	
    	WHILE (@@FETCH_STATUS = 0)
    		BEGIN
    		--Set Reviewed Date if Status is being updated, NULL status is returned to NEW
    		--and today's date if the status is being set to anything else.
    		IF ISNULL(@istatus, -1) <> ISNULL(@dstatus, -1)
    			BEGIN
    			IF @istatus = 0 --Open
    				BEGIN
    				UPDATE bRQRR SET ReviewDate = NULL FROM bRQRR r INNER JOIN Inserted i
    				ON i.RQCo = r.RQCo AND i.RQID = r.RQID AND i.RQLine = r.RQLine AND
    				i.Reviewer = r.Reviewer
    				END --Status is being set to Open
    			ELSE IF @istatus = 1 --Approved
    				BEGIN
    				UPDATE bRQRR SET ReviewDate = GETDATE() FROM bRQRR r INNER JOIN Inserted i
    				ON i.RQCo = r.RQCo AND i.RQID = r.RQID AND i.RQLine = r.RQLine AND
    				i.Reviewer = r.Reviewer 
    				END --Status is being set to Approved
    			ELSE IF @istatus = 2 --Denied
    				BEGIN
    				UPDATE bRQRR SET ReviewDate = GETDATE() FROM bRQRR r INNER JOIN Inserted i
    				ON i.RQCo = r.RQCo AND i.RQID = r.RQID AND i.RQLine = r.RQLine AND
    				i.Reviewer = r.Reviewer 
    				END --Status is being set to Denied
    		END --Status is being updated
    	
    		--Update the RQ Line Status for the associated RQ Line
    		EXEC bspRQSetRQLineStatus @rqco, @rqid, @rqline, @msg
    
    		FETCH NEXT FROM bcRQRR_update INTO @istatus, @dstatus, @rqco, @rqid, @rqline
    		END --While (@@Fetch_Status = 0)
    	
    		--Cleanup and destroy the cursor
    		CLOSE bcRQRR_update
    		DEALLOCATE bcRQRR_update
    	END --If @@rowcount <> 1
    ELSE
    	BEGIN
    	--Set Reviewed Date if Status is being updated, NULL status is returned to NEW
    	--and today's date if the status is being set to anything else.
    	SELECT @istatus = i.Status
    	FROM Inserted i INNER JOIN Deleted d ON i.RQCo = d.RQCo AND i.RQID = d.RQID 
    	AND i.RQLine = d.RQLine AND i.Reviewer = d.Reviewer
    	WHERE ISNULL(i.Status,-1) <> ISNULL(d.Status,-1)
    
    	IF ISNULL(@istatus,-1) <> -1 
    		BEGIN
    		IF @istatus = 0 --Open
    			BEGIN
    			UPDATE bRQRR SET ReviewDate = NULL FROM bRQRR r INNER JOIN Inserted i
    			ON i.RQCo = r.RQCo AND i.RQID = r.RQID AND i.RQLine = r.RQLine AND
    			i.Reviewer = r.Reviewer
    			END --Status is being set to Open
    		ELSE IF @istatus = 1 --Approved
    			BEGIN
    			UPDATE bRQRR SET ReviewDate = GETDATE() FROM bRQRR r INNER JOIN Inserted i
    			ON i.RQCo = r.RQCo AND i.RQID = r.RQID AND i.RQLine = r.RQLine AND
    			i.Reviewer = r.Reviewer 
    			END  --Status is being set to Approved
    		ELSE IF @istatus = 2 --Denied
    			BEGIN
    			UPDATE bRQRR SET ReviewDate = GETDATE() FROM bRQRR r INNER JOIN Inserted i
    			ON i.RQCo = r.RQCo AND i.RQID = r.RQID AND i.RQLine = r.RQLine AND
    			i.Reviewer = r.Reviewer 
    			END --Status is being set to Denied
    		END --Status is being updated
    	
    	--Update the RQ Line Status for the associated RQ Line
    	SELECT @rqco = RQCo, @rqid = RQID, @rqline = RQLine FROM Inserted
    	EXEC bspRQSetRQLineStatus @rqco, @rqid, @rqline, @msg
    
    	END --Only one record was being updated, no cursor was used
    
    
    --Add HQ Master Audit entry
    IF EXISTS(SELECT TOP 1 0 FROM Inserted i INNER JOIN bPOCO a ON a.POCo = i.RQCo WHERE a.AuditReview = 'Y')
    	BEGIN 
    	--Insert records into HQMA for changes made to audited fields */
    	if update(ReviewDate)	
    		insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    		select 'bRQRR', 'RQ Co#: ' + convert(varchar(3),i.RQCo) + ' RQID: ' + convert(varchar(10),i.RQID) 
    		+ ' RQLine: ' + convert(varchar(20),i.RQLine) + ' Reviewer: ' + convert(varchar(20),i.Reviewer),
    		i.RQCo, 'C', 'ReviewDate', isnull(d.ReviewDate,''), isnull(i.ReviewDate,''),getdate(), SUSER_SNAME()
    		from inserted i join deleted d on i.RQCo = d.RQCo and i.RQID = d.RQID and i.RQLine = d.RQLine and 
    		i.Reviewer = d.Reviewer
    		where isnull(i.ReviewDate,0) <> isnull(d.ReviewDate,0)
    
    	if update(Status)
    		insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    		select 'bRQRR', 'RQ Co#: ' + convert(varchar(3),i.RQCo) + ' RQID: ' + convert(varchar(10),i.RQID) 
    		+ ' RQLine: ' + convert(varchar(20),i.RQLine) + ' Reviewer: ' + convert(varchar(20),i.Reviewer),
    		i.RQCo, 'C', 'Status', isnull(d.Status,''), isnull(i.Status,''),getdate(), SUSER_SNAME()
    		from inserted i join deleted d on i.RQCo = d.RQCo and i.RQID = d.RQID and i.RQLine = d.RQLine 
    		and i.Reviewer = d.Reviewer
    		where isnull(i.Status,0) <> isnull(d.Status,0)
    
    	if update(Description)
    		insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    		select 'bRQRR', 'RQ Co#: ' + convert(varchar(3),i.RQCo) + ' RQID: ' + convert(varchar(10),i.RQID) 
    		+ ' RQLine: ' + convert(varchar(20),i.RQLine) + ' Reviewer: ' + convert(varchar(20),i.Reviewer),
    		i.RQCo, 'C', 'Description', isnull(d.Description,''), isnull(i.Description,''),getdate(), SUSER_SNAME()
    		from inserted i join deleted d on i.RQCo = d.RQCo and i.RQID = d.RQID and i.RQLine = d.RQLine 
    		and i.Reviewer = d.Reviewer
    		where isnull(i.Description,0) <> isnull(d.Description,0)
    	END
    
    RETURN
    
    ERROR:
    	SELECT @errmsg = ISNULL(@errmsg,'') + ' - cannot update RQ Reviewer!'
    	RAISERROR(@errmsg, 11, -1);
    	ROLLBACK TRANSACTION
   
   
   
   
   
   
   
  
 



GO
ALTER TABLE [dbo].[bRQRR] ADD CONSTRAINT [biRQRR] PRIMARY KEY CLUSTERED  ([RQCo], [RQID], [RQLine], [Reviewer]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bRQRR] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
