CREATE TABLE [dbo].[bARRT]
(
[ARCo] [dbo].[bCompany] NOT NULL,
[RecType] [tinyint] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[Abbrev] [char] (5) COLLATE Latin1_General_BIN NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[GLARAcct] [dbo].[bGLAcct] NOT NULL,
[GLRevAcct] [dbo].[bGLAcct] NULL,
[GLRetainAcct] [dbo].[bGLAcct] NULL,
[GLDiscountAcct] [dbo].[bGLAcct] NULL,
[GLWriteOffAcct] [dbo].[bGLAcct] NULL,
[GLFinChgAcct] [dbo].[bGLAcct] NULL,
[GLFCWriteOffAcct] [dbo].[bGLAcct] NULL,
[GLARFCRecvAcct] [dbo].[bGLAcct] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   /****** Object:  Trigger dbo.btARRTd    Script Date: 8/28/99 9:37:02 AM ******/
   CREATE trigger [dbo].[btARRTd] ON [dbo].[bARRT] for DELETE as
   

declare @errmsg varchar(255), @validcnt int
   /*-----------------------------------------------------------------
    *	This trigger rejects delete in bARRT (AR RecType Master)
    *	 IF the following error condition EXISTS:
    *
    *		entries exist in ARTL,ARTH,ARBH, ARBL
    *
    *
    *      CJW 5/5/97
    *----------------------------------------------------------------*/
   declare  @errno   int, @numrows int
   SELECT @numrows = @@rowcount
   IF @numrows = 0 return
   set nocount on
   begin
   /*--------------------------------------*/
   /* check ARTL */
   /*--------------------------------------*/
   IF EXISTS (SELECT * FROM deleted
        JOIN bARTL
         ON bARTL.ARCo = deleted.ARCo and bARTL.RecType = deleted.RecType)
       BEGIN
               SELECT @errmsg = 'Entries exist in AR Transaction Lines'
               goto error
       END
   /*--------------------------------------*/
   /* check ARTH */
   /*--------------------------------------*/
   IF EXISTS(SELECT * FROM deleted
      JOIN bARTH ON bARTH.ARCo = deleted.ARCo and bARTH.RecType = deleted.RecType)
      BEGIN
           SELECT @errmsg = 'Entries exist in AR Transaction Header'
          goto error
      END
   /*--------------------------------------*/
   /* check ARBL */
   /*--------------------------------------*/
   IF EXISTS(SELECT * FROM deleted
      JOIN bARBL
         ON bARBL.Co = deleted.ARCo and bARBL.RecType = deleted.RecType)
      BEGIN
          SELECT @errmsg = 'Entries exist in ARBL'
          goto error
       END
   /*--------------------------------------*/
   /* check ARBL */
   /*--------------------------------------*/
   IF EXISTS(SELECT * FROM deleted
      JOIN bARBL
         ON bARBL.Co = deleted.ARCo and bARBL.RecType = deleted.RecType)
      BEGIN
          SELECT @errmsg = 'Entries exist in ARBL'
          goto error
       END
   /*--------------------------------------*/
   /* Audit inserts */
   /*--------------------------------------*/
   INSERT INTO bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
           SELECT 'bARRT','Receivable Type:' + isnull(convert(varchar(3),deleted.RecType),''),
             deleted.ARCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
           FROM deleted
   	JOIN bARCO ON deleted.ARCo=bARCO.ARCo
           where bARCO.AuditRecType='Y'
   return
   error:
       SELECT @errmsg = @errmsg + ' - cannot delete RecType!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   end
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   /****** Object:  Trigger dbo.btARRTi    Script Date: 8/28/99 9:37:03 AM ******/
   CREATE trigger [dbo].[btARRTi] on [dbo].[bARRT] for INSERT as
   

/*-----------------------------------------------------------------
   *  CREATED BY:	Unknown
   *  MODIFIED BY:	TJL  01/31/02	Issue #15759, Added column GLFCWriteOffAcct
   *		TJL  02/27/02 - Issue #14171, Added column GLARFCRecvAcct
   *		TJL	 04/25/02 - Issue #16112, Rewrite validation for all updated GLAccts
   *
   *
   *	This trigger rejects delete in bARRT (AR Receivable Types)
   *	 IF the following error condition exists:
   *
   *		check for valid ARCO - company
   *		check for valid ARRT - Abbreviation
   *		check for valid GLAC - Subledger code, Active, Account Type on all GL accounts
   */
   declare @errmsg varchar(255), @validcnt int, @errno int, @numrows int,  @nullcnt int
   SELECT @numrows = @@rowcount
   IF @numrows = 0 return
   SET nocount on
   BEGIN
   /*----------------------------*/
   /* validate AR Company number */
   SELECT @validcnt = count(*) 
   FROM bARCO j
   JOIN inserted i ON j.ARCo = i.ARCo
   IF @validcnt <> @numrows
   	BEGIN
   	SELECT @errmsg = 'Invalid AR Company'
   	GOTO error
   	END
   /*----------------------------*/
   /* validate Receivable Type   */
   SELECT @validcnt = count(*) 
   FROM bARRT a
   JOIN inserted i ON a.ARCo = i.ARCo and a.RecType = i.RecType
   IF @validcnt <> @numrows
   	BEGIN
   	SELECT @errmsg = 'Duplicate Receivable Type'
   	GOTO error
   	END
   /*----------------------------*/
   /* validate Abbreviation   */
   SELECT @nullcnt = count(*) FROM inserted i where i.Abbrev is null
   SELECT @validcnt = count(*) 
   FROM bARRT a
   JOIN inserted i ON a.ARCo = i.ARCo and a.Abbrev = i.Abbrev
   IF (@validcnt + @nullcnt) <> @numrows
   	BEGIN
   	SELECT @errmsg = 'Duplicate Abbreviation'
   	GOTO error
   	END
   
   /************** Validate GL Accounts *****************/
   /* validate GL AR Account  */
   /*----------------------------*/
   if (select count(*) from inserted i where i.GLARAcct is not null)<> 0
   	begin
   	/* Though Viewpoint inserts only one record at a time and this process would be
   	   skipped via the statement above if this acct were null, this @nullcnt would be
   	   valid if multiple records were inserted using 3rd party stuff.  @nullcnt +
   	   @validcnt must always be the same as @numrows from inserted table.  (Again
   	   this is 1 row when using the Viewpoint RecType module) */
   	select @nullcnt = count(*) from inserted i where i.GLARAcct is null
   
   	/* Account must be a valid account in bGLAC */
   	SELECT @validcnt = count(*) 
   	FROM bGLAC a
   	JOIN inserted i ON a.GLCo = i.GLCo and a.GLAcct = i.GLARAcct
   	IF (@validcnt + @nullcnt) <> @numrows
   		BEGIN
   		SELECT @errmsg = 'Invalid GL Account'
   		GOTO error
   		END
   	/* validate Account Type - can't be a header */
   	SELECT @validcnt = count(*) 
   	FROM bGLAC a
   	JOIN inserted i ON a.GLCo = i.GLCo and a.GLAcct = i.GLARAcct
   	WHERE a.AcctType<>'H'
   	IF (@validcnt + @nullcnt) <> @numrows
   		BEGIN
   		SELECT @errmsg = 'GL AR Account is a heading account'
   		GOTO error
   		END
   	/* validate if account is active  */
   	SELECT @validcnt = count(*) 
   	FROM bGLAC a
   	JOIN inserted i ON a.GLCo = i.GLCo and a.GLAcct = i.GLARAcct
   	WHERE a.Active<>'N'
   	IF (@validcnt + @nullcnt) <> @numrows
   		BEGIN
   		SELECT @errmsg = 'GL AR Account is inactive'
   		GOTO error
   		END
   	/* validate GLAC SubType - must be R or null  */
   	SELECT @validcnt = count(*) 
   	FROM bGLAC a
   	JOIN inserted i ON a.GLCo = i.GLCo and a.GLAcct = i.GLARAcct
   	WHERE a.SubType = 'R' or a.SubType is null
   	IF (@validcnt + @nullcnt) <> @numrows
   		BEGIN
   		SELECT @errmsg = 'Invalid subtype on GL AR Account'
   		GOTO error
   		END
   	end	-- GL AR Account validation
   
   /* validate GL Rev Account  */
   /*----------------------------*/
   if (select count(*) from inserted i where i.GLRevAcct is not null) <> 0
   	begin
   	/* Though Viewpoint inserts only one record at a time and this process would be
   	   skipped via the statement above if this acct were null, this @nullcnt would be
   	   valid if multiple records were inserted using 3rd party stuff.  @nullcnt +
   	   @validcnt must always be the same as @numrows from inserted table.  (Again
   	   this is 1 row when using the Viewpoint RecType module) */
   	select @nullcnt = count(*) from inserted i where i.GLRevAcct is null
   
   	/* Account must be a valid account in bGLAC */
   	SELECT @validcnt = count(*) 
   	FROM bGLAC a
   	JOIN inserted i ON a.GLCo = i.GLCo and a.GLAcct = i.GLRevAcct
   	IF (@validcnt + @nullcnt) <> @numrows
   		BEGIN
   		SELECT @errmsg = 'Invalid GL Rev Account'
   		GOTO error
   		END
   	/* validate Account Type - can't be a header */
   	SELECT @validcnt = count(*) 
   	FROM bGLAC a
   	JOIN inserted i ON a.GLCo = i.GLCo and a.GLAcct = i.GLRevAcct
   	WHERE a.AcctType<>'H'
   	IF (@validcnt + @nullcnt) <> @numrows
   		BEGIN
   		SELECT @errmsg = 'GL Rev Account is a heading account'
   		GOTO error
   		END
   	/* validate if account is active  */
   	SELECT @validcnt = count(*) 
   	FROM bGLAC a
   	JOIN inserted i ON a.GLCo = i.GLCo and a.GLAcct = i.GLRevAcct
   	WHERE a.Active<>'N'
   	IF (@validcnt + @nullcnt) <> @numrows
   		BEGIN
   		SELECT @errmsg = 'GL Rev Account is is inactive'
   		GOTO error
   		END
   	/* validate GLAC SubType - must be null */
   	SELECT @validcnt = count(*) 
   	FROM bGLAC a
   	JOIN inserted i ON a.GLCo = i.GLCo and a.GLAcct = i.GLRevAcct
   	WHERE a.SubType is null
   	IF (@validcnt + @nullcnt) <> @numrows
   		BEGIN
   		SELECT @errmsg = 'Invalid subtype on GL Rev Account'
   		GOTO error
   		END
   	end		-- GL Revenue Acct validation
   
   /* validate GL Retainage Account  */
   /*----------------------------*/
   if (select count(*) from inserted i where i.GLRetainAcct is not null) <> 0
   	begin
   	/* Though Viewpoint inserts only one record at a time and this process would be
   	   skipped via the statement above if this acct were null, this @nullcnt would be
   	   valid if multiple records were inserted using 3rd party stuff.  @nullcnt +
   	   @validcnt must always be the same as @numrows from inserted table.  (Again
   	   this is 1 row when using the Viewpoint RecType module) */
   	select @nullcnt = count(*) from inserted i where i.GLRetainAcct is null
   
   	/* Account must be a valid account in bGLAC */
   	SELECT @validcnt = count(*) 
   	FROM bGLAC a
   	JOIN inserted i ON a.GLCo = i.GLCo and a.GLAcct = i.GLRetainAcct
   	IF (@validcnt + @nullcnt) <> @numrows
   		BEGIN
   		SELECT @errmsg = 'Invalid GL Retainage Account'
   		GOTO error
   		END
   	/* validate Account Type - can't be a header */
   	SELECT @validcnt = count(*) 
   	FROM bGLAC a
   	JOIN inserted i ON a.GLCo = i.GLCo and a.GLAcct = i.GLRetainAcct
   	WHERE a.AcctType<>'H'
   	IF (@validcnt + @nullcnt) <> @numrows
   		BEGIN
   		SELECT @errmsg = 'GL Retainage Account is a heading account'
   		GOTO error
   		END
   	/* validate if account is active  */
   	SELECT @validcnt = count(*) 
   	FROM bGLAC a
   	JOIN inserted i ON a.GLCo = i.GLCo and a.GLAcct = i.GLRetainAcct
   	WHERE a.Active<>'N'
   	IF (@validcnt + @nullcnt) <> @numrows
   		BEGIN
   		SELECT @errmsg = 'GL Retainage Account is is inactive'
   		GOTO error
   		END
   	/* validate GLAC SubType - must be R or null  */
   	SELECT @validcnt = count(*) 
   	FROM bGLAC a
   	JOIN inserted i ON a.GLCo = i.GLCo and a.GLAcct = i.GLRetainAcct
   	WHERE a.SubType = 'R' or a.SubType is null
   	IF (@validcnt + @nullcnt) <> @numrows
   		BEGIN
   		SELECT @errmsg = 'Invalid subtype on GL Retainage Account'
   		GOTO error
   		END
   	end		-- End GL AR Retainage Acct validation
   
   /* validate GL Discount Account  */
   /*----------------------------*/
   if (select count(*) from inserted i where i.GLDiscountAcct is not null) <> 0
   	begin
   	/* Though Viewpoint inserts only one record at a time and this process would be
   	   skipped via the statement above if this acct were null, this @nullcnt would be
   	   valid if multiple records were inserted using 3rd party stuff.  @nullcnt +
   	   @validcnt must always be the same as @numrows from inserted table.  (Again
   	   this is 1 row when using the Viewpoint RecType module) */
   	select @nullcnt = count(*) from inserted i where i.GLDiscountAcct is null
   
   	/* Account must be a valid account in bGLAC */
   	SELECT @validcnt = count(*) 
   	FROM bGLAC a
   	JOIN inserted i ON a.GLCo = i.GLCo and a.GLAcct = i.GLDiscountAcct
   	IF (@validcnt + @nullcnt) <> @numrows
   		BEGIN
   		SELECT @errmsg = 'Invalid GL Discount Account'
   		GOTO error
   		END
   	/* validate Account Type - can't be a header */
   	SELECT @validcnt = count(*) 
   	FROM bGLAC a
   	JOIN inserted i ON a.GLCo = i.GLCo and a.GLAcct = i.GLDiscountAcct
   	WHERE a.AcctType<>'H'
   	IF (@validcnt + @nullcnt) <> @numrows
   		BEGIN
   		SELECT @errmsg = 'GL Discount Account is a heading account'
   		GOTO error
   		END
   	/* validate if account is active  */
   	SELECT @validcnt = count(*) 
   	FROM bGLAC a
   	JOIN inserted i ON a.GLCo = i.GLCo and a.GLAcct = i.GLDiscountAcct
   	WHERE a.Active<>'N'
   	IF (@validcnt + @nullcnt) <> @numrows
   		BEGIN
   		SELECT @errmsg = 'GL Discount Account is is inactive'
   		GOTO error
   		END
   	/* validate GLAC SubType - must be null  */
   	SELECT @validcnt = count(*) 
   	FROM bGLAC a
   	JOIN inserted i ON a.GLCo = i.GLCo and a.GLAcct = i.GLDiscountAcct
   	WHERE a.SubType is null
   	IF (@validcnt + @nullcnt) <> @numrows
   		BEGIN
   		SELECT @errmsg = 'Invalid subtype on GL Discount Account'
   		GOTO error
   		END
   	end		-- End GL AR Discount Acct validation
   
   /* validate GL WriteOff Account  */
   /*----------------------------*/
   if (select count(*) from inserted i where i.GLWriteOffAcct is not null) <> 0
   	begin
   	/* Though Viewpoint inserts only one record at a time and this process would be
   	   skipped via the statement above if this acct were null, this @nullcnt would be
   	   valid if multiple records were inserted using 3rd party stuff.  @nullcnt +
   	   @validcnt must always be the same as @numrows from inserted table.  (Again
   	   this is 1 row when using the Viewpoint RecType module) */
   	select @nullcnt = count(*) from inserted i where i.GLWriteOffAcct is null
   
   	/* Account must be a valid account in bGLAC */
   	SELECT @validcnt = count(*) 
   	FROM bGLAC a
   	JOIN inserted i ON a.GLCo = i.GLCo and a.GLAcct = i.GLWriteOffAcct
   	IF (@validcnt + @nullcnt) <> @numrows
   		BEGIN
   		SELECT @errmsg = 'Invalid GL Write Off Account'
   		GOTO error
   		END
   	/* validate Account Type - can't be a header */
   	SELECT @validcnt = count(*) 
   	FROM bGLAC a
   	JOIN inserted i ON a.GLCo = i.GLCo and a.GLAcct = i.GLWriteOffAcct
   	WHERE a.AcctType<>'H'
   	IF (@validcnt + @nullcnt) <> @numrows
   		BEGIN
   		SELECT @errmsg = 'GL Write Off Account is a heading account'
   		GOTO error
   		END
   	/* validate if account is active  */
   	SELECT @validcnt = count(*) 
   	FROM bGLAC a
   	JOIN inserted i ON a.GLCo = i.GLCo and a.GLAcct = i.GLWriteOffAcct
   	WHERE a.Active<>'N'
   	IF (@validcnt + @nullcnt) <> @numrows
   		BEGIN
   		SELECT @errmsg = 'GL Write Off Account is is inactive'
   		GOTO error
   		END
   	/* validate GLAC SubType - must be null  */
   	SELECT @validcnt = count(*) 
   	FROM bGLAC a
   	JOIN inserted i ON a.GLCo = i.GLCo and a.GLAcct = i.GLWriteOffAcct
   	WHERE a.SubType is null
   	IF (@validcnt + @nullcnt) <> @numrows
   		BEGIN
   		SELECT @errmsg = 'Invalid subtype on GL Write Off Account'
   		GOTO error
   		END
   	end		-- End GL AR WriteOff Acct validation
   
   /* validate GL FinChgAcct Account  */
   /*----------------------------*/
   if (select count(*) from inserted i where i.GLFinChgAcct is not null) <> 0
   	begin
   	/* Though Viewpoint inserts only one record at a time and this process would be
   	   skipped via the statement above if this acct were null, this @nullcnt would be
   	   valid if multiple records were inserted using 3rd party stuff.  @nullcnt +
   	   @validcnt must always be the same as @numrows from inserted table.  (Again
   	   this is 1 row when using the Viewpoint RecType module) */
   	select @nullcnt = count(*) from inserted i where i.GLFinChgAcct is null
   
   	/* Account must be a valid account in bGLAC */
   	SELECT @validcnt = count(*) 
   	FROM bGLAC a
   	JOIN inserted i ON a.GLCo = i.GLCo and a.GLAcct = i.GLFinChgAcct
   	IF (@validcnt + @nullcnt) <> @numrows
   		BEGIN
   		SELECT @errmsg = 'Invalid GL Finance Account'
   		GOTO error
   		END
   	/* validate Account Type - can't be a header */
   	SELECT @validcnt = count(*) 
   	FROM bGLAC a
   	JOIN inserted i ON a.GLCo = i.GLCo and a.GLAcct = i.GLFinChgAcct
   	WHERE a.AcctType<>'H'
   	IF (@validcnt + @nullcnt) <> @numrows
   		BEGIN
   		SELECT @errmsg = 'GL Finance Account is a heading account'
   		GOTO error
   		END
   	/* validate if account is active  */
   	SELECT @validcnt = count(*) 
   	FROM bGLAC a
   	JOIN inserted i ON a.GLCo = i.GLCo and a.GLAcct = i.GLFinChgAcct
   	WHERE a.Active<>'N'
   	IF (@validcnt + @nullcnt) <> @numrows
   		BEGIN
   		SELECT @errmsg = 'GL Finance Account is is inactive'
   		GOTO error
   		END
   	/* validate GLAC SubType - must be null */
   	SELECT @validcnt = count(*) 
   	FROM bGLAC a
   	JOIN inserted i ON a.GLCo = i.GLCo and a.GLAcct = i.GLFinChgAcct
   	WHERE a.SubType is null
   	IF (@validcnt + @nullcnt) <> @numrows
   		BEGIN
   		SELECT @errmsg = 'Invalid subtype on GL Finance Account'
   		GOTO error
   		END
   	end		-- End GL AR Finance Charge Revenue Acct validation
   
   /* validate GL Finance Charge Receivable Account  */
   /*------------------------------------------------*/
   if (select count(*) from inserted i where i.GLARFCRecvAcct is not null) <> 0
   	begin
   	/* Though Viewpoint inserts only one record at a time and this process would be
   	   skipped via the statement above if this acct were null, this @nullcnt would be
   	   valid if multiple records were inserted using 3rd party stuff.  @nullcnt +
   	   @validcnt must always be the same as @numrows from inserted table.  (Again
   	   this is 1 row when using the Viewpoint RecType module) */
   	select @nullcnt = count(*) from inserted i where i.GLARFCRecvAcct is null
   
   	/* Account must be a valid account in bGLAC */
   	SELECT @validcnt = count(*) 
   	FROM bGLAC a
   	JOIN inserted i ON a.GLCo = i.GLCo and a.GLAcct = i.GLARFCRecvAcct
   	IF (@validcnt + @nullcnt) <> @numrows
   		BEGIN
   		SELECT @errmsg = 'Invalid GL Finance Charge Receivable Account'
   		GOTO error
   		END
   	/* validate Account Type - can't be a header */
   	SELECT @validcnt = count(*) 
   	FROM bGLAC a
   	JOIN inserted i ON a.GLCo = i.GLCo and a.GLAcct = i.GLARFCRecvAcct
   	WHERE a.AcctType<>'H'
   	IF (@validcnt + @nullcnt) <> @numrows
   		BEGIN
   		SELECT @errmsg = 'GL Finance Charge Receivable Account is a heading account'
   		GOTO error
   		END
   	/* validate if account is active  */
   	SELECT @validcnt = count(*) 
   	FROM bGLAC a
   	JOIN inserted i ON a.GLCo = i.GLCo and a.GLAcct = i.GLARFCRecvAcct
   	WHERE a.Active<>'N'
   	IF (@validcnt + @nullcnt) <> @numrows
   		BEGIN
   		SELECT @errmsg = 'GL Finance Charge Receivable Account is inactive'
   		GOTO error
   		END
   	/* validate GLAC SubType - must be R or null  */
   	SELECT @validcnt = count(*) 
   	FROM bGLAC a
   	JOIN inserted i ON a.GLCo = i.GLCo and a.GLAcct = i.GLARFCRecvAcct
   	WHERE a.SubType = 'R' or a.SubType is null
   	IF (@validcnt + @nullcnt) <> @numrows
   		BEGIN
   		SELECT @errmsg = 'Invalid subtype on GL Finance Charge Receivable Account'
   		GOTO error
   		END
   	end		-- End GL AR Finance Charge Receivable Acct validation
   
   /* validate GLFC WriteOff Account  */
   /*----------------------------*/
   if (select count(*) from inserted i where i.GLFCWriteOffAcct is not null) <> 0
   	begin
   	/* Though Viewpoint inserts only one record at a time and this process would be
   	   skipped via the statement above if this acct were null, this @nullcnt would be
   	   valid if multiple records were inserted using 3rd party stuff.  @nullcnt +
   	   @validcnt must always be the same as @numrows from inserted table.  (Again
   	   this is 1 row when using the Viewpoint RecType module) */
   	select @nullcnt = count(*) from inserted i where i.GLFCWriteOffAcct is null
   
   	/* Account must be a valid account in bGLAC */
   	SELECT @validcnt = count(*) 
   	FROM bGLAC a
   	JOIN inserted i ON a.GLCo = i.GLCo and a.GLAcct = i.GLFCWriteOffAcct
   	IF (@validcnt + @nullcnt) <> @numrows
   		BEGIN
   		SELECT @errmsg = 'Invalid GLFC Write Off Account'
   		GOTO error
   		END
   	/* validate Account Type - can't be a header */
   	SELECT @validcnt = count(*) 
   	FROM bGLAC a
   	JOIN inserted i ON a.GLCo = i.GLCo and a.GLAcct = i.GLFCWriteOffAcct
   	WHERE a.AcctType<>'H'
   	IF (@validcnt + @nullcnt) <> @numrows
   		BEGIN
   		SELECT @errmsg = 'GLFC Write Off Account is a heading account'
   		GOTO error
   		END
   	/* validate if account is active  */
   	SELECT @validcnt = count(*) 
   	FROM bGLAC a
   	JOIN inserted i ON a.GLCo = i.GLCo and a.GLAcct = i.GLFCWriteOffAcct
   	WHERE a.Active<>'N'
   	IF (@validcnt + @nullcnt) <> @numrows
   		BEGIN
   		SELECT @errmsg = 'GLFC Write Off Account is is inactive'
   		GOTO error
   		END
   	/* validate GLAC SubType - must be null  */
   	SELECT @validcnt = count(*) 
   	FROM bGLAC a
   	JOIN inserted i ON a.GLCo = i.GLCo and a.GLAcct = i.GLFCWriteOffAcct
   	WHERE a.SubType is null
   	IF (@validcnt + @nullcnt) <> @numrows
   		BEGIN
   		SELECT @errmsg = 'Invalid subtype on GLFC Write Off Account'
   		GOTO error
   		END
   	end		-- End GL AR Finance Charge WriteOff Acct validation
   /*************End Validation of GL Accounts  *******************/
   
   /* Audit inserts */
   INSERT INTO bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   SELECT 'bARRT','AR Co#: ' + isnull(convert(char(3), inserted.ARCo),'')
   		 + ' Receivable Type: ' + isnull(convert(varchar(3),inserted.RecType),''), inserted.ARCo, 'A',
   		NULL, NULL, NULL, getdate(), SUSER_SNAME() FROM inserted, bARCO
   		where inserted.ARCo=bARCO.ARCo and bARCO.AuditRecType='Y'
   return
   error:
       SELECT @errmsg = @errmsg +  ' - cannot insert Receivable Type!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   END
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   /****** Object:  Trigger dbo.btARRTu    Script Date: 8/28/99 9:37:03 AM ******/
   CREATE  trigger [dbo].[btARRTu] on [dbo].[bARRT] for UPDATE as
   

/****************************************************************************
   *
   *  Created : 	cjw  5/5/97
   *  Modified: 	cjw  5/5/97
   *		TJL  01/31/02 - Issue #15759,  Added column GLFCWriteOffAcct
   *		TJL  02/27/02 - Issue #14171,  Added column GLARFCRecvAcct	
   *		TJL	 04/25/02 - Issue #16112, Add validation for all GLAccts  
   *		TJL 12/29/04 - Issue #26488, Not auditing some fields going from NULL to Something or Something to NULL
   *
   *	Check that Abbrev is not duplicated
   *	Check that Company has not been changed.
   *	check for valid GLAC - Subledger code, Active, Account Type on all GL accounts
   *	Update Audit HQMA Table
   *
   *
   *****************************************************************************/
   declare @errmsg varchar(255), @validcnt int, @errno int, @numrows int,  @nullcnt int
   SELECT @numrows = @@rowcount
   IF @numrows = 0 return
   SET nocount on
   BEGIN
   /*----------------------------*/
   SELECT @validcnt=count(*) 
   from inserted i
   JOIN deleted d on i.ARCo=d.ARCo and i.RecType=d.RecType
   IF @validcnt <> @numrows
   	BEGIN
   	SELECT @errmsg = 'Changes to ARCo or RecType are not allowed'
   	GOTO error
   	END
   /*----------------------------*/
   /* validate Abbreviation   */
   SELECT @nullcnt = count(*) FROM inserted i where i.Abbrev is null
   SELECT @validcnt = count(*) 
   FROM bARRT a
   JOIN inserted i ON a.ARCo = i.ARCo and a.Abbrev = i.Abbrev
   IF (@validcnt + @nullcnt) <> @numrows
   	BEGIN
   	SELECT @errmsg = 'Duplicate Abbreviation'
   	GOTO error
   	END
   
   /*----------------------------*/
   /************** Validate GL Accounts *****************/
   /* validate GL AR Account  */
   /*----------------------------*/
   if (select count(*) from inserted i where i.GLARAcct is not null)<> 0
   	begin
   	/* Though Viewpoint inserts only one record at a time and this process would be
   	   skipped via the statement above if this acct were null, this @nullcnt would be
   	   valid if multiple records were inserted using 3rd party stuff.  @nullcnt +
   	   @validcnt must always be the same as @numrows from inserted table.  (Again
   	   this is 1 row when using the Viewpoint RecType module) */
   	select @nullcnt = count(*) from inserted i where i.GLARAcct is null
   
   	/* Account must be a valid account in bGLAC */
   	SELECT @validcnt = count(*) 
   	FROM bGLAC a
   	JOIN inserted i ON a.GLCo = i.GLCo and a.GLAcct = i.GLARAcct
   	IF (@validcnt + @nullcnt) <> @numrows
   		BEGIN
   		SELECT @errmsg = 'Invalid GL Account'
   		GOTO error
   		END
   	/* validate Account Type - can't be a header */
   	SELECT @validcnt = count(*) 
   	FROM bGLAC a
   	JOIN inserted i ON a.GLCo = i.GLCo and a.GLAcct = i.GLARAcct
   	WHERE a.AcctType<>'H'
   	IF (@validcnt + @nullcnt) <> @numrows
   		BEGIN
   		SELECT @errmsg = 'GL AR Account is a heading account'
   		GOTO error
   		END
   	/* validate if account is active  */
   	SELECT @validcnt = count(*) 
   	FROM bGLAC a
   	JOIN inserted i ON a.GLCo = i.GLCo and a.GLAcct = i.GLARAcct
   	WHERE a.Active<>'N'
   	IF (@validcnt + @nullcnt) <> @numrows
   		BEGIN
   		SELECT @errmsg = 'GL AR Account is inactive'
   		GOTO error
   		END
   	/* validate GLAC SubType - must be R or null  */
   	SELECT @validcnt = count(*) 
   	FROM bGLAC a
   	JOIN inserted i ON a.GLCo = i.GLCo and a.GLAcct = i.GLARAcct
   	WHERE a.SubType = 'R' or a.SubType is null
   	IF (@validcnt + @nullcnt) <> @numrows
   		BEGIN
   		SELECT @errmsg = 'Invalid subtype on GL AR Account'
   		GOTO error
   		END
   	end	-- GL AR Account validation
   
   /* validate GL Rev Account  */
   /*----------------------------*/
   if (select count(*) from inserted i where i.GLRevAcct is not null) <> 0
   	begin
   	/* Though Viewpoint inserts only one record at a time and this process would be
   	   skipped via the statement above if this acct were null, this @nullcnt would be
   	   valid if multiple records were inserted using 3rd party stuff.  @nullcnt +
   	   @validcnt must always be the same as @numrows from inserted table.  (Again
   	   this is 1 row when using the Viewpoint RecType module) */
   	select @nullcnt = count(*) from inserted i where i.GLRevAcct is null
   
   	/* Account must be a valid account in bGLAC */
   	SELECT @validcnt = count(*) 
   	FROM bGLAC a
   	JOIN inserted i ON a.GLCo = i.GLCo and a.GLAcct = i.GLRevAcct
   	IF (@validcnt + @nullcnt) <> @numrows
   		BEGIN
   		SELECT @errmsg = 'Invalid GL Rev Account'
   		GOTO error
   		END
   	/* validate Account Type - can't be a header */
   	SELECT @validcnt = count(*) 
   	FROM bGLAC a
   	JOIN inserted i ON a.GLCo = i.GLCo and a.GLAcct = i.GLRevAcct
   	WHERE a.AcctType<>'H'
   	IF (@validcnt + @nullcnt) <> @numrows
   		BEGIN
   		SELECT @errmsg = 'GL Rev Account is a heading account'
   		GOTO error
   		END
   	/* validate if account is active  */
   	SELECT @validcnt = count(*) 
   	FROM bGLAC a
   	JOIN inserted i ON a.GLCo = i.GLCo and a.GLAcct = i.GLRevAcct
   	WHERE a.Active<>'N'
   	IF (@validcnt + @nullcnt) <> @numrows
   		BEGIN
   		SELECT @errmsg = 'GL Rev Account is is inactive'
   		GOTO error
   		END
   	/* validate GLAC SubType - must be null */
   	SELECT @validcnt = count(*) 
   	FROM bGLAC a
   	JOIN inserted i ON a.GLCo = i.GLCo and a.GLAcct = i.GLRevAcct
   	WHERE a.SubType is null
   	IF (@validcnt + @nullcnt) <> @numrows
   		BEGIN
   		SELECT @errmsg = 'Invalid subtype on GL Rev Account'
   		GOTO error
   		END
   	end		-- GL Revenue Acct validation
   
   /* validate GL Retainage Account  */
   /*----------------------------*/
   if (select count(*) from inserted i where i.GLRetainAcct is not null) <> 0
   	begin
   	/* Though Viewpoint inserts only one record at a time and this process would be
   	   skipped via the statement above if this acct were null, this @nullcnt would be
   	   valid if multiple records were inserted using 3rd party stuff.  @nullcnt +
   	   @validcnt must always be the same as @numrows from inserted table.  (Again
   	   this is 1 row when using the Viewpoint RecType module) */
   	select @nullcnt = count(*) from inserted i where i.GLRetainAcct is null
   
   	/* Account must be a valid account in bGLAC */
   	SELECT @validcnt = count(*) 
   	FROM bGLAC a
   	JOIN inserted i ON a.GLCo = i.GLCo and a.GLAcct = i.GLRetainAcct
   	IF (@validcnt + @nullcnt) <> @numrows
   		BEGIN
   		SELECT @errmsg = 'Invalid GL Retainage Account'
   		GOTO error
   		END
   	/* validate Account Type - can't be a header */
   	SELECT @validcnt = count(*) 
   	FROM bGLAC a
   	JOIN inserted i ON a.GLCo = i.GLCo and a.GLAcct = i.GLRetainAcct
   	WHERE a.AcctType<>'H'
   	IF (@validcnt + @nullcnt) <> @numrows
   		BEGIN
   		SELECT @errmsg = 'GL Retainage Account is a heading account'
   		GOTO error
   		END
   	/* validate if account is active  */
   	SELECT @validcnt = count(*) 
   	FROM bGLAC a
   	JOIN inserted i ON a.GLCo = i.GLCo and a.GLAcct = i.GLRetainAcct
   	WHERE a.Active<>'N'
   	IF (@validcnt + @nullcnt) <> @numrows
   		BEGIN
   		SELECT @errmsg = 'GL Retainage Account is is inactive'
   		GOTO error
   		END
   	/* validate GLAC SubType - must be R or null  */
   	SELECT @validcnt = count(*) 
   	FROM bGLAC a
   	JOIN inserted i ON a.GLCo = i.GLCo and a.GLAcct = i.GLRetainAcct
   	WHERE a.SubType = 'R' or a.SubType is null
   	IF (@validcnt + @nullcnt) <> @numrows
   		BEGIN
   		SELECT @errmsg = 'Invalid subtype on GL Retainage Account'
   		GOTO error
   		END
   	end		-- End GL AR Retainage Acct validation
   
   /* validate GL Discount Account  */
   /*----------------------------*/
   if (select count(*) from inserted i where i.GLDiscountAcct is not null) <> 0
   	begin
   	/* Though Viewpoint inserts only one record at a time and this process would be
   	   skipped via the statement above if this acct were null, this @nullcnt would be
   	   valid if multiple records were inserted using 3rd party stuff.  @nullcnt +
   	   @validcnt must always be the same as @numrows from inserted table.  (Again
   	   this is 1 row when using the Viewpoint RecType module) */
   	select @nullcnt = count(*) from inserted i where i.GLDiscountAcct is null
   
   	/* Account must be a valid account in bGLAC */
   	SELECT @validcnt = count(*) 
   	FROM bGLAC a
   	JOIN inserted i ON a.GLCo = i.GLCo and a.GLAcct = i.GLDiscountAcct
   	IF (@validcnt + @nullcnt) <> @numrows
   		BEGIN
   
   		SELECT @errmsg = 'Invalid GL Discount Account'
   		GOTO error
   		END
   	/* validate Account Type - can't be a header */
   	SELECT @validcnt = count(*) 
   	FROM bGLAC a
   	JOIN inserted i ON a.GLCo = i.GLCo and a.GLAcct = i.GLDiscountAcct
   	WHERE a.AcctType<>'H'
   	IF (@validcnt + @nullcnt) <> @numrows
   		BEGIN
   		SELECT @errmsg = 'GL Discount Account is a heading account'
   		GOTO error
   		END
   	/* validate if account is active  */
   	SELECT @validcnt = count(*) 
   	FROM bGLAC a
   	JOIN inserted i ON a.GLCo = i.GLCo and a.GLAcct = i.GLDiscountAcct
   	WHERE a.Active<>'N'
   	IF (@validcnt + @nullcnt) <> @numrows
   		BEGIN
   		SELECT @errmsg = 'GL Discount Account is is inactive'
   		GOTO error
   		END
   	/* validate GLAC SubType - must be null  */
   	SELECT @validcnt = count(*) 
   	FROM bGLAC a
   	JOIN inserted i ON a.GLCo = i.GLCo and a.GLAcct = i.GLDiscountAcct
   	WHERE a.SubType is null
   	IF (@validcnt + @nullcnt) <> @numrows
   		BEGIN
   		SELECT @errmsg = 'Invalid subtype on GL Discount Account'
   		GOTO error
   		END
   	end		-- End GL AR Discount Acct validation
   
   /* validate GL WriteOff Account  */
   /*----------------------------*/
   if (select count(*) from inserted i where i.GLWriteOffAcct is not null) <> 0
   	begin
   	/* Though Viewpoint inserts only one record at a time and this process would be
   	   skipped via the statement above if this acct were null, this @nullcnt would be
   	   valid if multiple records were inserted using 3rd party stuff.  @nullcnt +
   	   @validcnt must always be the same as @numrows from inserted table.  (Again
   	   this is 1 row when using the Viewpoint RecType module) */
   	select @nullcnt = count(*) from inserted i where i.GLWriteOffAcct is null
   
   	/* Account must be a valid account in bGLAC */
   	SELECT @validcnt = count(*) 
   	FROM bGLAC a
   	JOIN inserted i ON a.GLCo = i.GLCo and a.GLAcct = i.GLWriteOffAcct
   	IF (@validcnt + @nullcnt) <> @numrows
   		BEGIN
   		SELECT @errmsg = 'Invalid GL Write Off Account'
   		GOTO error
   		END
   	/* validate Account Type - can't be a header */
   	SELECT @validcnt = count(*) 
   	FROM bGLAC a
   	JOIN inserted i ON a.GLCo = i.GLCo and a.GLAcct = i.GLWriteOffAcct
   	WHERE a.AcctType<>'H'
   	IF (@validcnt + @nullcnt) <> @numrows
   		BEGIN
   		SELECT @errmsg = 'GL Write Off Account is a heading account'
   		GOTO error
   		END
   	/* validate if account is active  */
   	SELECT @validcnt = count(*) 
   	FROM bGLAC a
   	JOIN inserted i ON a.GLCo = i.GLCo and a.GLAcct = i.GLWriteOffAcct
   	WHERE a.Active<>'N'
   	IF (@validcnt + @nullcnt) <> @numrows
   		BEGIN
   		SELECT @errmsg = 'GL Write Off Account is is inactive'
   		GOTO error
   		END
   	/* validate GLAC SubType - must be null  */
   	SELECT @validcnt = count(*) 
   	FROM bGLAC a
   	JOIN inserted i ON a.GLCo = i.GLCo and a.GLAcct = i.GLWriteOffAcct
   	WHERE a.SubType is null
   	IF (@validcnt + @nullcnt) <> @numrows
   		BEGIN
   		SELECT @errmsg = 'Invalid subtype on GL Write Off Account'
   		GOTO error
   		END
   	end		-- End GL AR WriteOff Acct validation
   
   /* validate GL FinChgAcct Account  */
   /*----------------------------*/
   if (select count(*) from inserted i where i.GLFinChgAcct is not null) <> 0
   	begin
   	/* Though Viewpoint inserts only one record at a time and this process would be
   	   skipped via the statement above if this acct were null, this @nullcnt would be
   	   valid if multiple records were inserted using 3rd party stuff.  @nullcnt +
   	   @validcnt must always be the same as @numrows from inserted table.  (Again
   	   this is 1 row when using the Viewpoint RecType module) */
   	select @nullcnt = count(*) from inserted i where i.GLFinChgAcct is null
   
   	/* Account must be a valid account in bGLAC */
   	SELECT @validcnt = count(*) 
   	FROM bGLAC a
   	JOIN inserted i ON a.GLCo = i.GLCo and a.GLAcct = i.GLFinChgAcct
   	IF (@validcnt + @nullcnt) <> @numrows
   		BEGIN
   		SELECT @errmsg = 'Invalid GL Finance Account'
   		GOTO error
   		END
   	/* validate Account Type - can't be a header */
   	SELECT @validcnt = count(*) 
   	FROM bGLAC a
   	JOIN inserted i ON a.GLCo = i.GLCo and a.GLAcct = i.GLFinChgAcct
   	WHERE a.AcctType<>'H'
   	IF (@validcnt + @nullcnt) <> @numrows
   		BEGIN
   		SELECT @errmsg = 'GL Finance Account is a heading account'
   		GOTO error
   		END
   	/* validate if account is active  */
   	SELECT @validcnt = count(*) 
   	FROM bGLAC a
   	JOIN inserted i ON a.GLCo = i.GLCo and a.GLAcct = i.GLFinChgAcct
   	WHERE a.Active<>'N'
   	IF (@validcnt + @nullcnt) <> @numrows
   		BEGIN
   		SELECT @errmsg = 'GL Finance Account is is inactive'
   		GOTO error
   		END
   	/* validate GLAC SubType - must be null */
   	SELECT @validcnt = count(*) 
   	FROM bGLAC a
   	JOIN inserted i ON a.GLCo = i.GLCo and a.GLAcct = i.GLFinChgAcct
   	WHERE a.SubType is null
   	IF (@validcnt + @nullcnt) <> @numrows
   		BEGIN
   		SELECT @errmsg = 'Invalid subtype on GL Finance Account'
   		GOTO error
   		END
   	end		-- End GL AR Finance Charge Revenue Acct validation
   
   /* validate GL Finance Charge Receivable Account  */
   /*------------------------------------------------*/
   if (select count(*) from inserted i where i.GLARFCRecvAcct is not null) <> 0
   	begin
   	/* Though Viewpoint inserts only one record at a time and this process would be
   	   skipped via the statement above if this acct were null, this @nullcnt would be
   	   valid if multiple records were inserted using 3rd party stuff.  @nullcnt +
   	   @validcnt must always be the same as @numrows from inserted table.  (Again
   	   this is 1 row when using the Viewpoint RecType module) */
   	select @nullcnt = count(*) from inserted i where i.GLARFCRecvAcct is null
   
   	/* Account must be a valid account in bGLAC */
   	SELECT @validcnt = count(*) 
   	FROM bGLAC a
   	JOIN inserted i ON a.GLCo = i.GLCo and a.GLAcct = i.GLARFCRecvAcct
   	IF (@validcnt + @nullcnt) <> @numrows
   		BEGIN
   		SELECT @errmsg = 'Invalid GL Finance Charge Receivable Account'
   		GOTO error
   		END
   	/* validate Account Type - can't be a header */
   	SELECT @validcnt = count(*) 
   	FROM bGLAC a
   	JOIN inserted i ON a.GLCo = i.GLCo and a.GLAcct = i.GLARFCRecvAcct
   	WHERE a.AcctType<>'H'
   	IF (@validcnt + @nullcnt) <> @numrows
   		BEGIN
   		SELECT @errmsg = 'GL Finance Charge Receivable Account is a heading account'
   		GOTO error
   		END
   	/* validate if account is active  */
   	SELECT @validcnt = count(*) 
   	FROM bGLAC a
   	JOIN inserted i ON a.GLCo = i.GLCo and a.GLAcct = i.GLARFCRecvAcct
   	WHERE a.Active<>'N'
   	IF (@validcnt + @nullcnt) <> @numrows
   		BEGIN
   		SELECT @errmsg = 'GL Finance Charge Receivable Account is inactive'
   		GOTO error
   		END
   	/* validate GLAC SubType - must be R or null  */
   	SELECT @validcnt = count(*) 
   	FROM bGLAC a
   	JOIN inserted i ON a.GLCo = i.GLCo and a.GLAcct = i.GLARFCRecvAcct
   	WHERE a.SubType = 'R' or a.SubType is null
   	IF (@validcnt + @nullcnt) <> @numrows
   		BEGIN
   		SELECT @errmsg = 'Invalid subtype on GL Finance Charge Receivable Account'
   		GOTO error
   		END
   	end		-- End GL AR Finance Charge Receivable Acct validation
   
   /* validate GLFC WriteOff Account  */
   /*----------------------------*/
   if (select count(*) from inserted i where i.GLFCWriteOffAcct is not null) <> 0
   	begin
   	/* Though Viewpoint inserts only one record at a time and this process would be
   	   skipped via the statement above if this acct were null, this @nullcnt would be
   	   valid if multiple records were inserted using 3rd party stuff.  @nullcnt +
   	   @validcnt must always be the same as @numrows from inserted table.  (Again
   	   this is 1 row when using the Viewpoint RecType module) */
   	select @nullcnt = count(*) from inserted i where i.GLFCWriteOffAcct is null
   
   	/* Account must be a valid account in bGLAC */
   	SELECT @validcnt = count(*) 
   	FROM bGLAC a
   	JOIN inserted i ON a.GLCo = i.GLCo and a.GLAcct = i.GLFCWriteOffAcct
   	IF (@validcnt + @nullcnt) <> @numrows
   		BEGIN
   		SELECT @errmsg = 'Invalid GLFC Write Off Account'
   		GOTO error
   		END
   	/* validate Account Type - can't be a header */
   	SELECT @validcnt = count(*) 
   	FROM bGLAC a
   	JOIN inserted i ON a.GLCo = i.GLCo and a.GLAcct = i.GLFCWriteOffAcct
   	WHERE a.AcctType<>'H'
   	IF (@validcnt + @nullcnt) <> @numrows
   		BEGIN
   		SELECT @errmsg = 'GLFC Write Off Account is a heading account'
   		GOTO error
   		END
   	/* validate if account is active  */
   	SELECT @validcnt = count(*) 
   	FROM bGLAC a
   	JOIN inserted i ON a.GLCo = i.GLCo and a.GLAcct = i.GLFCWriteOffAcct
   	WHERE a.Active<>'N'
   	IF (@validcnt + @nullcnt) <> @numrows
   		BEGIN
   		SELECT @errmsg = 'GLFC Write Off Account is is inactive'
   		GOTO error
   		END
   	/* validate GLAC SubType - must be null  */
   	SELECT @validcnt = count(*) 
   	FROM bGLAC a
   	JOIN inserted i ON a.GLCo = i.GLCo and a.GLAcct = i.GLFCWriteOffAcct
   	WHERE a.SubType is null
   	IF (@validcnt + @nullcnt) <> @numrows
   		BEGIN
   		SELECT @errmsg = 'Invalid subtype on GLFC Write Off Account'
   		GOTO error
   		END
   	end		-- End GL AR Finance Charge WriteOff Acct validation
   /*************End Validation of GL Accounts  *******************/
   
   /*----------------------------*/
   /* Audit inserts */
   IF UPDATE(Description)
   BEGIN
   INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   SELECT 'bARRT','AR Co#: ' + isnull(convert(char(3), i.ARCo),'') + ' RecType: ' + isnull(convert(char(3), i.RecType),''), i.ARCo, 'C',
   	'Description',  d.Description, i.Description, getdate(), SUSER_SNAME()
   FROM inserted i
   JOIN deleted d  ON d.ARCo=i.ARCo  AND d.RecType=i.RecType
   JOIN  bARCO ON i.ARCo=bARCO.ARCo and bARCO.AuditRecType='Y'
   WHERE isnull(d.Description, '') <> isnull(i.Description, '')
   END
   
   IF UPDATE(Abbrev)
   BEGIN
   INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   SELECT 'bARRT','AR Co#: ' + isnull(convert(char(3), i.ARCo),'') + ' RecType: ' + isnull(convert(char(3), i.RecType),''), i.ARCo, 'C',
   	'Abbrev',  d.Abbrev, i.Abbrev, getdate(), SUSER_SNAME()
   FROM inserted i
   JOIN deleted d  ON d.ARCo=i.ARCo  AND d.RecType=i.RecType
   JOIN  bARCO ON i.ARCo=bARCO.ARCo and bARCO.AuditRecType='Y'
   WHERE isnull(d.Abbrev, '') <> isnull(i.Abbrev, '')
   END
   
   IF UPDATE(GLCo)
   BEGIN
   INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   SELECT 'bARRT','AR Co#: ' + isnull(convert(char(3), i.ARCo),'') + ' RecType: ' + isnull(convert(char(3), i.RecType),''), i.ARCo, 'C',
   	'GLCo', convert(varchar(3), d.GLCo), convert(varchar(3),i.GLCo), getdate(), SUSER_SNAME()
   FROM inserted i
   JOIN deleted d  ON d.ARCo=i.ARCo  AND d.RecType=i.RecType
   JOIN  bARCO ON i.ARCo=bARCO.ARCo and bARCO.AuditRecType='Y'
   WHERE isnull(d.GLCo, 0) <> isnull(i.GLCo, 0)
   END
   
   IF UPDATE(GLARAcct)
   BEGIN
   INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   SELECT 'bARRT','AR Co#: ' + isnull(convert(char(3), i.ARCo),'') + ' RecType: ' + isnull(convert(char(3), i.RecType),''), i.ARCo, 'C',
   	'GLARAcct',  d.GLARAcct, i.GLARAcct, getdate(), SUSER_SNAME()
   FROM inserted i
   JOIN deleted d  ON d.ARCo=i.ARCo  AND d.RecType=i.RecType
   JOIN  bARCO ON i.ARCo=bARCO.ARCo and bARCO.AuditRecType='Y'
   WHERE isnull(d.GLARAcct, '') <> isnull(i.GLARAcct, '')
   END
   
   IF UPDATE(GLRevAcct)
   BEGIN
   INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   SELECT 'bARRT','AR Co#: ' + isnull(convert(char(3), i.ARCo),'') + ' RecType: ' + isnull(convert(char(3), i.RecType),''), i.ARCo, 'C',
   	'GLRevAcct', d.GLRevAcct, i.GLRevAcct, getdate(), SUSER_SNAME()
   FROM inserted i
   JOIN deleted d  ON d.ARCo=i.ARCo  AND d.RecType=i.RecType
   JOIN  bARCO ON i.ARCo=bARCO.ARCo and bARCO.AuditRecType='Y'
   WHERE isnull(d.GLRevAcct, '') <> isnull(i.GLRevAcct, '')
   END
   
   IF UPDATE(GLRetainAcct)
   BEGIN
   INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   SELECT 'bARRT','AR Co#: ' + isnull(convert(char(3), i.ARCo),'') + ' RecType: ' + isnull(convert(char(3), i.RecType),''), i.ARCo, 'C',
   	'GLRetainAcct', d.GLRetainAcct, i.GLRetainAcct, getdate(), SUSER_SNAME()
   FROM inserted i
   JOIN deleted d  ON d.ARCo=i.ARCo  AND d.RecType=i.RecType
   JOIN  bARCO ON i.ARCo=bARCO.ARCo and bARCO.AuditRecType='Y'
   WHERE isnull(d.GLRetainAcct, '') <> isnull(i.GLRetainAcct, '')
   END
   
   IF UPDATE(GLDiscountAcct)
   BEGIN
   INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   SELECT 'bARRT','AR Co#: ' + isnull(convert(char(3), i.ARCo),'') + ' RecType: ' + isnull(convert(char(3), i.RecType),''), i.ARCo, 'C',
   	'GLDiscountAcct',  d.GLDiscountAcct, i.GLDiscountAcct, getdate(), SUSER_SNAME()
   FROM inserted i
   JOIN deleted d  ON d.ARCo=i.ARCo  AND d.RecType=i.RecType
   JOIN  bARCO ON i.ARCo=bARCO.ARCo and bARCO.AuditRecType='Y'
   WHERE isnull(d.GLDiscountAcct, '') <> isnull(i.GLDiscountAcct, '')
   END
   
   IF UPDATE(GLWriteOffAcct)
   BEGIN
   INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   SELECT 'bARRT','AR Co#: ' + isnull(convert(char(3), i.ARCo),'') + ' RecType: ' + isnull(convert(char(3), i.RecType),''), i.ARCo, 'C',
   	'GLWriteOffAcct',  d.GLWriteOffAcct,i.GLWriteOffAcct, getdate(), SUSER_SNAME()
   FROM inserted i
   JOIN deleted d  ON d.ARCo=i.ARCo  AND d.RecType=i.RecType
   JOIN  bARCO ON i.ARCo=bARCO.ARCo and bARCO.AuditRecType='Y'
   WHERE isnull(d.GLWriteOffAcct, '') <> isnull(i.GLWriteOffAcct, '')
   END
   
   IF UPDATE(GLFinChgAcct)
   BEGIN
   INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   SELECT 'bARRT','AR Co#: ' + isnull(convert(char(3), i.ARCo),'') + ' RecType: ' + isnull(convert(char(3), i.RecType),''), i.ARCo, 'C',
   	'GLFinChgAcct',  d.GLFinChgAcct, i.GLFinChgAcct, getdate(), SUSER_SNAME()
   FROM inserted i
   JOIN deleted d  ON d.ARCo=i.ARCo  AND d.RecType=i.RecType
   JOIN  bARCO ON i.ARCo=bARCO.ARCo and bARCO.AuditRecType='Y'
   WHERE isnull(d.GLFinChgAcct, '') <> isnull(i.GLFinChgAcct, '')
   END
   
   IF UPDATE(GLARFCRecvAcct)
   BEGIN
   INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   SELECT 'bARRT','AR Co#: ' + isnull(convert(char(3), i.ARCo),'') + ' RecType: ' + isnull(convert(char(3), i.RecType),''), i.ARCo, 'C',
   	'GLARFCRecvAcct', d.GLARFCRecvAcct, i.GLARFCRecvAcct, getdate(), SUSER_SNAME()
   FROM inserted i
   JOIN deleted d  ON d.ARCo=i.ARCo  AND d.RecType=i.RecType
   JOIN  bARCO ON i.ARCo=bARCO.ARCo and bARCO.AuditRecType='Y'
   WHERE isnull(d.GLARFCRecvAcct, '') <> isnull(i.GLARFCRecvAcct, '')
   END
   
   IF UPDATE(GLFCWriteOffAcct)
   BEGIN
   INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   SELECT 'bARRT','AR Co#: ' + isnull(convert(char(3), i.ARCo),'') + ' RecType: ' + isnull(convert(char(3), i.RecType),''), i.ARCo, 'C',
   	'GLFCWriteOffAcct',  d.GLFCWriteOffAcct,i.GLFCWriteOffAcct, getdate(), SUSER_SNAME()
   FROM inserted i
   JOIN deleted d  ON d.ARCo=i.ARCo  AND d.RecType=i.RecType
   JOIN  bARCO ON i.ARCo=bARCO.ARCo and bARCO.AuditRecType='Y'
   WHERE isnull(d.GLFCWriteOffAcct, '') <> isnull(i.GLFCWriteOffAcct, '')
   END
   
   return
   error:
       SELECT @errmsg = @errmsg +  ' -  cannot update RecType!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   END
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biARRT] ON [dbo].[bARRT] ([ARCo], [RecType]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bARRT] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
