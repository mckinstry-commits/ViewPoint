CREATE TABLE [dbo].[bRQQR]
(
[RQCo] [dbo].[bCompany] NOT NULL,
[Quote] [int] NOT NULL,
[QuoteLine] [int] NOT NULL,
[Reviewer] [varchar] (3) COLLATE Latin1_General_BIN NOT NULL,
[AssignedDate] [dbo].[bDate] NOT NULL,
[ReviewDate] [dbo].[bDate] NULL,
[Status] [int] NOT NULL,
[Description] [varchar] (300) COLLATE Latin1_General_BIN NULL,
[Notes] [varchar] (6000) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
ALTER TABLE [dbo].[bRQQR] ADD 
CONSTRAINT [biRQQR] PRIMARY KEY CLUSTERED  ([RQCo], [Quote], [QuoteLine], [Reviewer]) WITH (FILLFACTOR=90) ON [PRIMARY]
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bRQQR] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE  TRIGGER [dbo].[btRQQRd] ON [dbo].[bRQQR] FOR DELETE AS
    

/*-----------------------------------------------------------------
    *Created:	GWC 09/28/2004
    *Modified: DC 1/9/2009  #130129 - Combine RQ and PO into a single module
    *
    *The Delete trigger for bRQQR.  
    *	-Inserts a record of the deletion into the HQ Master Audit entry.
    *	-Updates status of bRQRL Line if the deletion of the Reviewer would
    *	 affect that status
    *	-
    */----------------------------------------------------------------
    DECLARE @errmsg varchar(255), @numrows int, @rqco bCompany, @quote int, @quoteline int,
    @msg varchar(255)
    
    SELECT @numrows = @@rowcount
    IF @numrows = 0 RETURN
    
    SET NOCOUNT ON
    
    --If more than one row is being updated, then a cursor will be needed to process
    --each line
    IF @numrows <> 1
    	BEGIN
    	--Use a cursor to process all lines
    	DECLARE bcRQQR_delete CURSOR LOCAL FAST_FORWARD FOR
    	SELECT d.RQCo, d.Quote, d.QuoteLine FROM Deleted d
    	
    	OPEN bcRQQR_delete
    	FETCH NEXT FROM bcRQQR_delete INTO @rqco, @quote, @quoteline
    	
    	WHILE (@@FETCH_STATUS = 0)
    		BEGIN		
    		--Update the RQ Line Status for the associated RQ Line
    		EXEC bspRQSetQuoteLineStatus @rqco, @quote, @quoteline, @msg
    
    		FETCH NEXT FROM bcRQQR_delete INTO @rqco, @quote, @quoteline
    		END --While (@@Fetch_Status = 0)
    	
    		--Cleanup and destroy the cursor
    		CLOSE bcRQQR_delete
    		DEALLOCATE bcRQQR_delete
    	END --If @@rowcount <> 1
    ELSE
    	BEGIN	
    	--Update the RQ Line Status for the associated RQ Line
    	SELECT @rqco = RQCo, @quote = Quote, @quoteline = QuoteLine FROM Deleted
    	EXEC bspRQSetQuoteLineStatus @rqco, @quote, @quoteline, @msg
    
    	END --Only one record was being updated, no cursor was used
    
    
    
    --Audit RQ Reviewer deletions
    IF EXISTS(SELECT TOP 1 0 FROM Deleted d INNER JOIN bPOCO a ON a.POCo = d.RQCo 
    WHERE a.AuditReview = 'Y')
    	BEGIN
    	INSERT INTO bHQMA
    	(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	SELECT 'bRQQR', 'RQ Co#: ' + CONVERT(varchar(3),RQCo) + ' Quote: ' + 
    	CONVERT(varchar(10),Quote) + ' QuoteLine: ' + CONVERT(varchar(20),QuoteLine) + 
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
 
  
   
   
   
   
   CREATE   TRIGGER [dbo].[btRQQRi] ON [dbo].[bRQQR] FOR INSERT AS
    

/*-----------------------------------------------------------------
    *Created:	GWC 09/27/2004
    *Modified:	 DC 1/9/2009 #130129 - Combine RQ and PO into a single module
    *
    *Insert trigger for RQ Quote Reviewers
    */----------------------------------------------------------------
    DECLARE @numrows int, @errmsg varchar(255), @rqco bCompany, @quote int, 
    		@quoteline int, @msg varchar(255)
    
    SELECT @numrows = @@rowcount
    IF @numrows = 0 RETURN
    
    SET NOCOUNT ON
    
    --Quote status is Completed
    --IF EXISTS (SELECT i.RQCo FROM Inserted i INNER JOIN bRQQL l ON i.RQCo = l.RQCo AND
    --i.Quote = l.Quote AND i.QuoteLine = l.QuoteLine AND l.Status = 4)
    --	BEGIN
    --	SELECT @errmsg = 'Unable to insert Reviewers. Quote status is Completed'
    --	GOTO error
    --	END
    
    --Quote status is Denied
    --IF EXISTS (SELECT i.RQCo FROM Inserted i INNER JOIN bRQQL l ON i.RQCo = l.RQCo AND
    --i.Quote = l.Quote AND i.QuoteLine = l.QuoteLine AND l.Status = 4)
    --	BEGIN
    --	SELECT @errmsg = 'Unable to insert Reviewers. Quote status is Denied'
    --	GOTO error
    --	END
    
    IF @numrows <> 1
    	BEGIN
    	--Use a cursor to process all lines
    	DECLARE bcRQQR_insert CURSOR LOCAL FAST_FORWARD FOR
    	SELECT i.RQCo, i.Quote, i.QuoteLine FROM Inserted i
    
    	OPEN bcRQQR_insert
    	FETCH NEXT FROM bcRQQR_insert INTO @rqco, @quote, @quoteline
    
    	WHILE (@@FETCH_STATUS = 0)
    		BEGIN 	
    		--Update the RQ Line status
    		EXEC bspRQSetQuoteLineStatus @rqco, @quote, @quoteline, @msg
    	
        	FETCH NEXT FROM bcRQQR_insert INTO @rqco, @quote, @quoteline
        	END
    
    	CLOSE bcRQQR_insert
    	DEALLOCATE bcRQQR_insert
    	END
    ELSE
    	BEGIN
    	SELECT @rqco = i.RQCo, @quote = i.Quote, @quoteline = i.QuoteLine FROM Inserted i
    	--Update the RQ Line status
    	EXEC bspRQSetQuoteLineStatus @rqco, @quote, @quoteline, @msg
    	END
    
    --Add HQ Master Audit entry
    IF EXISTS (SELECT TOP 1 0 FROM Inserted i INNER JOIN bPOCO a ON a.POCo = i.RQCo 
    WHERE a.AuditRQ = 'Y')
    	BEGIN
    	INSERT INTO bHQMA
      	(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	SELECT 'bRQRR', 'RQCo: ' + CONVERT(varchar(3),RQCo) + ' Quote: ' + 
    	CONVERT(varchar(10),Quote) + ' QuoteLine: ' + CONVERT(varchar(20),QuoteLine),
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
 
  
   
   
   
   CREATE   TRIGGER [dbo].[btRQQRu] ON [dbo].[bRQQR] FOR UPDATE AS
    

/*-----------------------------------------------------------------
    *Created:	GWC  09/28/2004
    *Modified: DC 1/9/2009 #130129 - Combine RQ and PO into a single module
    *
    *Update trigger for Quote Reviewers
    *	-Rejects changes to key fields
    *	-Inserts into HQ Master Audit entry. 
    */----------------------------------------------------------------
    DECLARE @numrows int, @validcnt int, @errmsg varchar(255), @istatus as int, 
    @dstatus int, @rqco int, @quote int, @quoteline int, @msg varchar(255)
    
    SELECT @numrows = @@rowcount
    IF @numrows = 0 RETURN
    
    SET NOCOUNT ON
    
    --Don't allow changes if a Key field is being changed
    SELECT @validcnt = COUNT(1) FROM Deleted d, Inserted i
    WHERE d.RQCo = i.RQCo AND d.Quote = i.Quote AND d.QuoteLine = i.QuoteLine 
    AND d.Reviewer = i.Reviewer
    
    IF @numrows <> @validcnt
    	BEGIN
    	SELECT @errmsg = 'Cannot change RQ Company, Quote, QuoteLine, or Reviewer.'
    	GOTO ERROR
    	END --A key field was being changed
    
    --Don't allow changes to the Review if the Quote Line that the Review is linked to 
    --has a status of completed
    IF EXISTS (SELECT l.Status FROM bRQQR r WITH (NOLOCK) INNER JOIN Inserted i ON 
    r.RQCo = i.RQCo AND r.Quote = i.Quote AND r.QuoteLine = i.QuoteLine 
    INNER JOIN bRQQL l ON i.RQCo = l.RQCo AND i.Quote = l.Quote AND i.QuoteLine = l.QuoteLine WHERE l.Status = 4)
    	BEGIN
    	SELECT @errmsg = 'Unable to modify the review. Quote Line status is Completed.'
    	GOTO ERROR
    	END	--If associated RQ Line does not have a status of Denied
    
    --Don't allow changes to the Review if the Quote Line that the Review is linked to 
    --has a status of Denied
    --IF EXISTS (SELECT l.Status FROM bRQQR r WITH (NOLOCK) INNER JOIN Inserted i ON 
    --r.RQCo = i.RQCo AND r.Quote = i.Quote AND r.QuoteLine = i.QuoteLine INNER JOIN bRQQL l 
    --ON i.RQCo = l.RQCo AND i.Quote = l.Quote AND i.QuoteLine = l.QuoteLine WHERE l.Status = 5)
    --	BEGIN
    --	SELECT @errmsg = 'Unable to modify the review. Quote Line status is Denied.'
    --	GOTO ERROR
    --	END	--If associated RQ Line does not have a status of Denied
    
    --If more than one row is being updated, then a cursor will be needed to process
    --each line
    IF @@rowcount <> 1
    	BEGIN
    	--Use a cursor to process all lines
    	DECLARE bcRQQR_update CURSOR LOCAL FAST_FORWARD FOR
    	SELECT i.Status, d.Status, i.RQCo, i.Quote, i.QuoteLine FROM Deleted d, Inserted i
    	
    	OPEN bcRQQR_update
    	FETCH NEXT FROM bcRQQR_update INTO @istatus, @dstatus, @rqco, @quote, @quoteline
    	
    	WHILE (@@FETCH_STATUS = 0)
    		BEGIN
    		--Set Reviewed Date if Status is being updated, NULL status is returned to NEW
    		--and today's date if the status is being set to anything else.
    		IF ISNULL(@istatus, -1) <> ISNULL(@dstatus, -1)
    			BEGIN
    			IF @istatus = 0 --Open
    				BEGIN
    				UPDATE bRQQR SET ReviewDate = NULL FROM bRQQR r INNER JOIN Inserted i
    				ON i.RQCo = r.RQCo AND i.Quote = r.Quote AND i.QuoteLine = r.QuoteLine AND
    				i.Reviewer = r.Reviewer
    				END --Status is being set to Open
    			ELSE IF @istatus = 1 --Approved
    				BEGIN
    				UPDATE bRQQR SET ReviewDate = GETDATE() FROM bRQQR r INNER JOIN Inserted i
    				ON i.RQCo = r.RQCo AND i.Quote = r.Quote AND i.QuoteLine = r.QuoteLine AND
    				i.Reviewer = r.Reviewer 
    				END --Status is being set to Approved
    			ELSE IF @istatus = 2 --Denied
    				BEGIN
    				UPDATE bRQQR SET ReviewDate = GETDATE() FROM bRQQR r INNER JOIN Inserted i
    				ON i.RQCo = r.RQCo AND i.Quote = r.Quote AND i.QuoteLine = r.QuoteLine AND
    				i.Reviewer = r.Reviewer 
    				END --Status is being set to Denied
    		END --Status is being updated
    	
    		--Update the RQ Line Status for the associated RQ Line
    		EXEC bspRQSetQuoteLineStatus @rqco, @quote, @quoteline, @msg
    
    		FETCH NEXT FROM bcRQQR_update INTO @istatus, @dstatus, @rqco, @quote, @quoteline
    		END --While (@@Fetch_Status = 0)
    	
    		--Cleanup and destroy the cursor
    		CLOSE bcRQQR_update
    		DEALLOCATE bcRQQR_update
    	END --If @@rowcount <> 1
    ELSE
    	BEGIN
    	--Set Reviewed Date if Status is being updated, NULL status is returned to NEW
    
    	--and today's date if the status is being set to anything else.
    	SELECT @istatus = i.Status
    	FROM Inserted i INNER JOIN Deleted d ON i.RQCo = d.RQCo AND i.Quote = d.Quote 
    	AND i.QuoteLine = d.QuoteLine AND i.Reviewer = d.Reviewer
    	WHERE ISNULL(i.Status,-1) <> ISNULL(d.Status,-1)
    
    	IF ISNULL(@istatus,-1) <> -1 
    		BEGIN
    		IF @istatus = 0 --Open
    			BEGIN
    			UPDATE bRQQR SET ReviewDate = NULL FROM bRQQR r INNER JOIN Inserted i
    			ON i.RQCo = r.RQCo AND i.Quote = r.Quote AND i.QuoteLine = r.QuoteLine AND
    			i.Reviewer = r.Reviewer
    			END --Status is being set to Open
    		ELSE IF @istatus = 1 --Approved
    			BEGIN
    			UPDATE bRQQR SET ReviewDate = GETDATE() FROM bRQQR r INNER JOIN Inserted i
    			ON i.RQCo = r.RQCo AND i.Quote = r.Quote AND i.QuoteLine = r.QuoteLine AND
    			i.Reviewer = r.Reviewer 
    			END  --Status is being set to Approved
    		ELSE IF @istatus = 2 --Denied
    			BEGIN
    			UPDATE bRQQR SET ReviewDate = GETDATE() FROM bRQQR r INNER JOIN Inserted i
    			ON i.RQCo = r.RQCo AND i.Quote = r.Quote AND i.QuoteLine = r.QuoteLine AND
    			i.Reviewer = r.Reviewer 
    			END --Status is being set to Denied
    		END --Status is being updated
    	
    	--Update the RQ Line Status for the associated RQ Line
    	SELECT @rqco = RQCo, @quote = Quote, @quoteline = QuoteLine FROM Inserted
    	EXEC bspRQSetQuoteLineStatus @rqco, @quote, @quoteline, @msg
    
    	END --Only one record was being updated, no cursor was used
    
    
    --Add HQ Master Audit entry
    IF EXISTS(SELECT TOP 1 0 FROM Inserted i INNER JOIN bPOCO a ON a.POCo = i.RQCo WHERE a.AuditReview = 'Y')
    	BEGIN 
    	--Insert records into HQMA for changes made to audited fields */
    	if update(ReviewDate)	
    		insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    		select 'bRQQR', 'RQ Co#: ' + convert(varchar(3),i.RQCo) + ' Quote: ' + convert(varchar(10),i.Quote) 
    		+ ' QuoteLine: ' + convert(varchar(20),i.QuoteLine) + ' Reviewer: ' + convert(varchar(20),i.Reviewer),
    		i.RQCo, 'C', 'ReviewDate', isnull(d.ReviewDate,''), isnull(i.ReviewDate,''),getdate(), SUSER_SNAME()
    		from inserted i join deleted d on i.RQCo = d.RQCo and i.Quote = d.Quote and i.QuoteLine = d.QuoteLine and 
    		i.Reviewer = d.Reviewer
    		where isnull(i.ReviewDate,0) <> isnull(d.ReviewDate,0)
    
    	if update(Status)
    		insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    		select 'bRQQR', 'RQ Co#: ' + convert(varchar(3),i.RQCo) + ' Quote: ' + convert(varchar(10),i.Quote) 
    		+ ' QuoteLine: ' + convert(varchar(20),i.QuoteLine) + ' Reviewer: ' + convert(varchar(20),i.Reviewer),
    		i.RQCo, 'C', 'Status', isnull(d.Status,''), isnull(i.Status,''),getdate(), SUSER_SNAME()
    		from inserted i join deleted d on i.RQCo = d.RQCo and i.Quote = d.Quote and i.QuoteLine = d.QuoteLine 
    		and i.Reviewer = d.Reviewer
    		where isnull(i.Status,0) <> isnull(d.Status,0)
    
    	if update(Description)
    		insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    		select 'bRQQR', 'RQ Co#: ' + convert(varchar(3),i.RQCo) + ' Quote: ' + convert(varchar(10),i.Quote) 
    		+ ' QuoteLine: ' + convert(varchar(20),i.QuoteLine) + ' Reviewer: ' + convert(varchar(20),i.Reviewer),
    		i.RQCo, 'C', 'Description', isnull(d.Description,''), isnull(i.Description,''),getdate(), SUSER_SNAME()
    		from inserted i join deleted d on i.RQCo = d.RQCo and i.Quote = d.Quote and i.QuoteLine = d.QuoteLine 
    		and i.Reviewer = d.Reviewer
    		where isnull(i.Description,0) <> isnull(d.Description,0)
    	END
    
    RETURN
    
    ERROR:
    	SELECT @errmsg = ISNULL(@errmsg,'') + ' - cannot update Quote Reviewer!'
    	RAISERROR(@errmsg, 11, -1);
    	ROLLBACK TRANSACTION
   
   
   
  
 



GO
