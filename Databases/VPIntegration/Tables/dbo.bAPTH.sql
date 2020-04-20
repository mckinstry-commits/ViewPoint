CREATE TABLE [dbo].[bAPTH]
(
[APCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[APTrans] [dbo].[bTrans] NOT NULL,
[VendorGroup] [dbo].[bGroup] NOT NULL,
[Vendor] [dbo].[bVendor] NOT NULL,
[InvId] [char] (10) COLLATE Latin1_General_BIN NULL,
[APRef] [dbo].[bAPReference] NULL,
[Description] [dbo].[bDesc] NULL,
[InvDate] [dbo].[bDate] NOT NULL,
[DiscDate] [dbo].[bDate] NULL,
[DueDate] [dbo].[bDate] NOT NULL,
[InvTotal] [dbo].[bDollar] NOT NULL,
[HoldCode] [dbo].[bHoldCode] NULL,
[PayControl] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[PayMethod] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[CMCo] [dbo].[bCompany] NOT NULL,
[CMAcct] [dbo].[bCMAcct] NULL,
[PrePaidYN] [dbo].[bYN] NOT NULL,
[PrePaidMth] [dbo].[bMonth] NULL,
[PrePaidDate] [dbo].[bDate] NULL,
[PrePaidChk] [dbo].[bCMRef] NULL,
[PrePaidSeq] [tinyint] NULL,
[PrePaidProcYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bAPTH_PrePaidProcYN] DEFAULT ('N'),
[V1099YN] [dbo].[bYN] NOT NULL,
[V1099Type] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[V1099Box] [tinyint] NULL,
[PayOverrideYN] [dbo].[bYN] NOT NULL,
[PayName] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[PayAddress] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[PayCity] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[PayState] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[PayZip] [dbo].[bZip] NULL,
[OpenYN] [dbo].[bYN] NOT NULL,
[InUseMth] [dbo].[bMonth] NULL,
[InUseBatchId] [dbo].[bBatchID] NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[Purge] [dbo].[bYN] NOT NULL,
[InPayControl] [dbo].[bYN] NOT NULL,
[PayAddInfo] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[DocName] [varchar] (128) COLLATE Latin1_General_BIN NULL,
[AddendaTypeId] [tinyint] NULL,
[PRCo] [dbo].[bCompany] NULL,
[Employee] [dbo].[bEmployee] NULL,
[DLcode] [dbo].[bEDLCode] NULL,
[TaxFormCode] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[TaxPeriodEndDate] [dbo].[bDate] NULL,
[AmountType] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Amount] [dbo].[bDollar] NULL,
[AmtType2] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Amount2] [dbo].[bDollar] NULL,
[AmtType3] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Amount3] [dbo].[bDollar] NULL,
[SeparatePayYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bAPTH_SeparatePayYN] DEFAULT ('N'),
[ChkRev] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bAPTH_ChkRev] DEFAULT ('N'),
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[AddressSeq] [tinyint] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[PayCountry] [char] (2) COLLATE Latin1_General_BIN NULL,
[SLKeyID] [bigint] NULL,
[udRetgInvYN] [char] (1) COLLATE Latin1_General_BIN NULL,
[udPaidAmt] [decimal] (12, 2) NULL,
[udYSN] [decimal] (12, 0) NULL,
[udRCCD] [int] NULL,
[udSource] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[udConv] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[udCGCTable] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[udCGCTableID] [decimal] (12, 0) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE  trigger [dbo].[btAPTHd] on [dbo].[bAPTH] for DELETE as
   

/*-----------------------------------------------------------------
    *  Created: EN 11/1/98
    *  Modified: EN 11/1/98
    *				GG 06/21/02 - remove bAPUR records, fixed bHQMA update
	*			MV 04/05/07 - #124090 - fixed HQMA insert
	*			MV 06/01/09 - #133431 - delete attachment per issue #127603
    *
    *  This trigger restricts deletion of any APTH records if
    *  lines exist in APTL.
    *
    *  Adds entry to HQ Master Audit if APCO.AuditPay = 'Y' and
    *  APPH.PurgeYN = 'N'.
    *
    *	Removes Unapproved Invoice Reviewer history from bAPUR
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   -- check for existing Lines
   if exists(select 1 from bAPTL a, deleted d where a.APCo = d.APCo
   		and a.Mth = d.Mth and a.APTrans = d.APTrans)
   	begin
   	select @errmsg = 'Lines exist for this transaction'
   	goto error
   	end
   
   -- remove any Unapproved Invoice Reviewer detail
   delete bAPUR
   from deleted d
   join bAPUR r on d.APCo = r.APCo and d.Mth = r.ExpMonth and d.APTrans = r.APTrans
   
	-- delete attachments
	insert vDMAttachmentDeletionQueue (AttachmentID, UserName, DeletedFromRecord)
          select AttachmentID, suser_name(), 'Y' 
              from bHQAT h join deleted d on h.UniqueAttchID = d.UniqueAttchID                  
              where d.UniqueAttchID is not null    

   /* Audit AP Transaction Header deletions */
   INSERT INTO bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
           SELECT 'bAPTH',' Mth: ' + convert(varchar(8),d.Mth,1)
   		 + ' APTrans: ' + convert(varchar(6),d.APTrans),
             d.APCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
           FROM deleted d
   	JOIN bAPCO c ON d.APCo = c.APCo
			where c.AuditTrans = 'Y' and d.Purge = 'N'
--   	JOIN bAPTH h ON d.APCo = h.APCo and d.Mth = h.Mth and d.APTrans = h.APTrans
--           where c.AuditTrans = 'Y' and h.Purge = 'N'
   
   return
   
   error:
   	select @errmsg = @errmsg + ' - cannot delete AP Transaction Header!'
       	RAISERROR(@errmsg, 11, -1);
       	rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE trigger [dbo].[btAPTHi] on [dbo].[bAPTH] for INSERT as
/*-----------------------------------------------------------------
* Created:		EN	10/29/1998
* Modified:		EN	10/29/1998
*				EN	04/14/2000	- CMAcct validation not allowing for null value
*				DANF 10/23/2001 - Update for 1099 box 1-18
*				MV	10/18/2002	- 18878 quoted identifier cleanup.
*				GF	08/12/2003	- issue #22112 - performance
*				MV	03/11/2008	- #issue 127347 International addresses
*				GG	06/06/2008	- #128324 - fixed State/Country validation
*				KK	01/17/2012	- TK-11581 Added "S"(Credit Service) as an acceptable value for PayMethod
*				CHS	05/30/2012	- B-08928 make 1099 changes to Australia
*
*
* Validates APCo, Vendor, HoldCode, PayMethod, CMCo, and CMAcct.
* Prepaid info must be null if PrePaidYN = 'N'.
* Validates 1099 info.
* If flagged for auditing transactions, inserts HQ Master Audit entry.
*/----------------------------------------------------------------
DECLARE @errmsg varchar(255), 
	    @validcnt int, 
	    @validcnt2 int, 
	    @nullcnt int, 
	    @numrows int
   
SELECT @numrows = @@rowcount
IF @numrows = 0 RETURN
SET NOCOUNT ON
   
-- validate AP Company
SELECT @validcnt = COUNT(*) FROM bAPCO c WITH(NOLOCK) JOIN inserted i ON c.APCo = i.APCo
IF @validcnt <> @numrows
BEGIN
	SELECT @errmsg = 'Invalid AP Company'
	GOTO error
END

-- validate Vendor
SELECT @validcnt = COUNT(*) FROM bAPVM v with (nolock)
JOIN inserted i ON v.VendorGroup = i.VendorGroup AND v.Vendor = i.Vendor
IF @validcnt <> @numrows
BEGIN
	SELECT @errmsg = 'Invalid Vendor'
	GOTO error
END

-- validate HoldCode
SELECT @nullcnt = COUNT(*) FROM inserted WHERE HoldCode IS NULL
SELECT @validcnt = COUNT(*) FROM bHQHC h WITH(NOLOCK) JOIN inserted i ON h.HoldCode = i.HoldCode
IF @nullcnt + @validcnt <> @numrows
BEGIN
	SELECT @errmsg = 'Invalid Hold Code'
	GOTO error
END

-- validate PayMethod
SELECT @validcnt = COUNT(*) FROM inserted WHERE PayMethod = 'C' OR PayMethod = 'E' OR PayMethod = 'S'
IF @validcnt <> @numrows
BEGIN
	SELECT @errmsg = 'Invalid Payment Method'
	GOTO error
END

-- validate CMCo
SELECT @validcnt = COUNT(*) FROM bCMCO c with (nolock) JOIN inserted i ON c.CMCo = i.CMCo
IF @validcnt <> @numrows
BEGIN
	SELECT @errmsg = 'Invalid CM Company'
	GOTO error
END

-- validate CMAcct
SELECT @validcnt = COUNT(*) FROM inserted where CMAcct IS NOT NULL

SELECT @validcnt2 = COUNT(*) FROM bCMAC a with (nolock)
JOIN inserted i ON a.CMCo = i.CMCo AND a.CMAcct = i.CMAcct where i.CMAcct IS NOT NULL
IF @validcnt <> @validcnt2
BEGIN
	SELECT @errmsg = 'Invalid CM Account'
	GOTO error
END

SELECT @validcnt = COUNT(*) FROM inserted i
WHERE i.PrePaidYN = 'N' AND (i.PrePaidMth IS NOT NULL 
						  OR i.PrePaidDate IS NOT NULL
						  OR i.PrePaidChk IS NOT NULL
						  OR i.PrePaidSeq IS NOT NULL)
IF @validcnt <> 0
BEGIN
	SELECT @errmsg = 'Prepaid info must be null if not prepaid'
	GOTO error
END

-- CHS	05/30/2012	- B-08928 make 1099 changes to Australia
SELECT @validcnt = COUNT(*) 
FROM inserted i
JOIN dbo.bHQCO c (NOLOCK) ON c.HQCo = i.APCo	-- join to get Default Country
WHERE i.V1099YN = 'Y' 
	AND NOT EXISTS(SELECT * FROM bAPTT t WITH(NOLOCK) WHERE t.V1099Type=i.V1099Type)
	AND c.DefaultCountry <> 'AU'
IF @validcnt <> 0
BEGIN
	SELECT @errmsg = 'Invalid 1099 type'
	GOTO error
END

-- CHS	05/30/2012	- B-08928 make 1099 changes to Australia
SELECT @validcnt = COUNT(*) 
FROM inserted i
JOIN dbo.bHQCO c (NOLOCK) ON c.HQCo = i.APCo	-- join to get Default Country
WHERE i.V1099YN = 'Y' 
	AND (i.V1099Box < 1 or i.V1099Box > 18)
	AND c.DefaultCountry <> 'AU'
IF @validcnt <> 0
BEGIN
	SELECT @errmsg = '1099 box # must be 1 through 18'
	GOTO error
END

-- validate Country 
SELECT @validcnt = COUNT(1)
FROM dbo.bHQCountry c (NOLOCK) 
JOIN inserted i ON i.PayCountry = c.Country
SELECT @nullcnt = COUNT(1) FROM inserted WHERE PayCountry IS NULL
IF @validcnt + @nullcnt <> @numrows
BEGIN
	SELECT @errmsg = 'Invalid Pay Country'
	GOTO error
END

-- validate Country/State combinations
SELECT @validcnt = COUNT(1) -- Country/State combos are unique
FROM inserted i
JOIN dbo.bHQCO c (NOLOCK) ON c.HQCo = i.APCo	-- join to get Default Country
JOIN dbo.bHQST s (NOLOCK) ON ISNULL(i.PayCountry,c.DefaultCountry) = s.Country AND i.PayState = s.State
SELECT @nullcnt = COUNT(1) FROM inserted WHERE PayState IS NULL
IF @validcnt + @nullcnt <> @numrows
BEGIN
	SELECT @errmsg = 'Invalid Pay Country and State combination'
	GOTO error
END

-- Audit inserts
INSERT INTO bHQMA
   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
SELECT 'bAPTH',' Mth: ' + convert(varchar(8), i.Mth,1)
	 + ' APTrans: ' + convert(varchar(6), i.APTrans), i.APCo, 'A',
	NULL, NULL, NULL, getdate(), SUSER_SNAME() FROM inserted i
	JOIN bAPCO c  WITH (NOLOCK) ON c.APCo = i.APCo
	WHERE i.APCo = c.APCo AND c.AuditTrans = 'Y'

RETURN

error:
SELECT @errmsg = @errmsg +  ' - cannot insert AP Transaction Header!'
RAISERROR(@errmsg, 11, -1);
ROLLBACK TRANSACTION
   
  
 


GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE trigger [dbo].[btAPTHu] on [dbo].[bAPTH] for UPDATE as
/*-----------------------------------------------------------------
* Created:  10/30/98 EN
* Modified: 12/02/98 KB
*			03/08/99 JRE - added if update()
*           EN 01/22/00 - insert bHQMA if PayAddInfo is changed
*           EN 4/14/00 - CMAcct validation not allowing for null value
*           DANF 10/23/00 - Added 1099 1-18
*			MV 03/19/03 - #17124 new Transaction fields added to HQMA audit.
*			MV 04/17/03 - #17124 rej 1 fix
*			JIME 11/03/04  - #26016 add if updates and change count(*) to if exists
*			MV 03/11/08 - #127347 International addresses
*			GG 06/06/08 - #128324 Fixed State/Country validation
*			MV 09/08/08 - #129741 Isnull wrapped HoldCode audit
*			JonathanP 01/09/08 - #128879 - Added code to skip procedure if only UniqueAttachID changed.
*			GP 06/06/10 - #135813 changed bSL to varchar(30)
*			GP 07/27/11 - TK-07144 changed bPO to varchar(30)
*			KK 01/17/12 - TK-11581 Added "S"(Credit Service) as an acceptable value for PayMethod
*			KK 02/19/12 - TK-12973 Removed validation check on CM Account to allow any value
*				CHS	05/30/2012	- B-08928 make 1099 changes to Australia
*
*	This trigger rejects update in bAPTH (Trans Header)
*	if any of the following error conditions exist:
*
*		Cannot change Co
*		Cannot change Mth
*		Cannot change APTrans
*
*	Validate same as in insert trigger.
*	Insert bHQMA entries for changed values if AuditTrans='Y' in bAPCO.
*/----------------------------------------------------------------
DECLARE @errmsg varchar(255), 
		@numrows int, 
		@validcnt int, 
		@validcnt2 int, 
		@nullcnt int,
		@apco bCompany, 
		@linetype tinyint, 
		@jcco bCompany, 
		@job bJob, 
		@phasegroup bGroup, 
   		@phase bPhase, 
   		@jcctype bJCCType, 
   		@inco bCompany, 
   		@loc bLoc, 
   		@matlgroup bGroup, 
   		@material bMatl, 
   		@emco bCompany, 
   		@equip bEquip, 
   		@emgroup bGroup, 
   		@costcode bCostCode, 
   		@emctype bEMCType, 
   		@wo bWO, 
   		@woitem bItem, 
   		@po varchar(30), 
   		@poitem bItem, 
   		@itemtype tinyint,
   		@sl varchar(30), 
   		@slitem bItem
 
SELECT @numrows = @@rowcount
IF @numrows = 0 RETURN

SET NOCOUNT ON

--If the only column that changed was UniqueAttachID, then skip validation.        
IF dbo.vfOnlyColumnUpdated(COLUMNS_UPDATED(), 'bAPTH', 'UniqueAttchID') = 1
BEGIN 
	goto Trigger_Skip
END    

-- verify primary key not changed
IF UPDATE(APCo) 
OR UPDATE(Mth) 
OR UPDATE(APTrans)
BEGIN
	SELECT @validcnt = COUNT(*) FROM deleted d, inserted i
	WHERE d.APCo = i.APCo AND d.Mth = i.Mth AND d.APTrans = i.APTrans
	IF @numrows <> @validcnt
	BEGIN
		SELECT @errmsg = 'Cannot change Primary Key'
		GOTO error
	END
END
   
-- validate Vendor
IF UPDATE (Vendor)
BEGIN
   	SELECT @validcnt = COUNT(*) FROM bAPVM v WITH(NOLOCK)
    JOIN inserted i ON v.VendorGroup = i.VendorGroup AND v.Vendor = i.Vendor
    IF @validcnt <> @numrows
    BEGIN
    	SELECT @errmsg = 'Invalid Vendor'
    	GOTO error
    END
END
   
   -- validate HoldCode
IF UPDATE(HoldCode)
BEGIN
   	SELECT @nullcnt = COUNT(*) FROM inserted 
   	WHERE HoldCode IS NULL
   	SELECT @validcnt = COUNT(*) FROM bHQHC h WITH(NOLOCK)
    JOIN inserted i ON ISNULL(h.HoldCode,'') = ISNULL(i.HoldCode,'')
    WHERE i.HoldCode IS NOT NULL
    IF @nullcnt + @validcnt <> @numrows
    BEGIN
    	SELECT @errmsg = 'Invalid Hold Code'
    	GOTO error
	END
END
   
   -- validate PayMethod
IF UPDATE(PayMethod)
BEGIN
   	SELECT @validcnt = COUNT(*) FROM inserted 
   	WHERE PayMethod = 'C' OR PayMethod = 'E' OR PayMethod = 'S'
    IF @validcnt <> @numrows
    BEGIN
		SELECT @errmsg = 'Invalid payment method'
    	GOTO error
    END
END
   
   -- validate CMCo
IF UPDATE(CMCo)
BEGIN
   	SELECT @validcnt = COUNT(*) FROM bCMCO c WITH(NOLOCK) 
   	JOIN inserted i ON c.CMCo = i.CMCo
    IF @validcnt <> @numrows
    BEGIN
		SELECT @errmsg = 'Invalid CM company'
		GOTO error
   END
END
   
---- validate CMAcct
--IF UPDATE(CMAcct)
-- 	begin
--    SELECT @validcnt = COUNT(*) FROM inserted where CMAcct is not null
--	SELECT @validcnt2 = COUNT(*) FROM bCMAC a with (nolock)
-- 	JOIN inserted i ON a.CMCo = i.CMCo and a.CMAcct = i.CMAcct where i.CMAcct is not null
-- 	IF @validcnt <> @validcnt2
-- 		BEGIN
-- 		SELECT @errmsg = 'Invalid CM account'
-- 		GOTO error
-- 		END
-- 	end
    	
-- validate PayState/PayCountry
IF UPDATE(PayState) OR UPDATE(PayCountry)
BEGIN
	SELECT @validcnt = COUNT(1) FROM dbo.bHQCountry c WITH(NOLOCK) 
	JOIN inserted i ON i.PayCountry = c.Country
	SELECT @nullcnt = COUNT(1) FROM inserted WHERE PayCountry IS NULL
	IF @validcnt + @nullcnt <> @numrows
	BEGIN
		SELECT @errmsg = 'Invalid Pay Country'
		GOTO error
	END
	-- validate Country/State combinations
	SELECT @validcnt = COUNT(1) -- Country/State combos are unique
	FROM inserted i
	JOIN dbo.bHQCO c (NOLOCK) ON c.HQCo = i.APCo	-- join to get Default Country
	JOIN dbo.bHQST s (NOLOCK) ON ISNULL(i.PayCountry,c.DefaultCountry) = s.Country AND i.PayState = s.State
	SELECT @nullcnt = COUNT(1) FROM inserted 
	WHERE PayState IS NULL
	IF @validcnt + @nullcnt <> @numrows
	BEGIN
		SELECT @errmsg = 'Invalid Pay Country and State combination'
		GOTO error
	END
END

--#26016
IF UPDATE(PrePaidMth) 
OR UPDATE(PrePaidDate) 
OR UPDATE(PrePaidChk)
OR UPDATE(PrePaidSeq)
BEGIN
   	IF EXISTS (SELECT 1 FROM inserted i WHERE i.PrePaidYN = 'N'
   	AND (i.PrePaidMth IS NOT NULL 
   		OR i.PrePaidDate IS NOT NULL 
   		OR i.PrePaidChk IS NOT NULL 
   		OR i.PrePaidSeq IS NOT NULL))
    BEGIN
		SELECT @errmsg = 'Prepaid info must be null if not prepaid'
		GOTO error
    END
END
   
--#26016 --CHS	05/30/2012	- B-08928 make 1099 changes to Australia 
IF UPDATE(V1099YN) OR UPDATE(V1099Type)
BEGIN
   	IF EXISTS(SELECT 1 
   				FROM inserted i
					JOIN dbo.bHQCO c (NOLOCK) ON c.HQCo = i.APCo	-- join to get Default Country   				
				WHERE i.V1099YN = 'Y'
					AND c.DefaultCountry <> 'AU'
					AND NOT EXISTS(SELECT * FROM bAPTT t WHERE t.V1099Type=i.V1099Type))

   	BEGIN
    	SELECT @errmsg = 'Invalid 1099 type'
		GOTO error
	END
END
   
--#26016 --CHS	05/30/2012	- B-08928 make 1099 changes to Australia 
IF UPDATE(V1099YN) OR UPDATE(V1099Box)
BEGIN
	IF EXISTS(SELECT 1 
				FROM inserted i
					JOIN dbo.bHQCO c (NOLOCK) ON c.HQCo = i.APCo	-- join to get Default Country
    			WHERE V1099YN = 'Y' 
					AND c.DefaultCountry <> 'AU'    			
    				AND (V1099Box < 1 or V1099Box > 18))
    BEGIN
		SELECT @errmsg = '1099 box # must be 1 through 18'
    	GOTO error
    END
END 
   
   
   -- Check bAPCO to see if auditing transaction. If not done.
   if not exists(select * from inserted i join bAPCO c with (nolock) on i.APCo=c.APCo where c.AuditTrans = 'Y')
   	return
   
   -- Insert records into HQMA for changes made to audited fields
   if update(VendorGroup)
   	insert into bHQMA select 'bAPTH', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6),i.APTrans), i.APCo, 'C',
    	'VendorGroup', convert(varchar(3),d.VendorGroup), convert(varchar(3),i.VendorGroup), getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
    	and d.VendorGroup <> i.VendorGroup and a.AuditTrans = 'Y'
   
   if update (Vendor)
    insert into bHQMA select 'bAPTH', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans), i.APCo, 'C',
    	'Vendor', convert(varchar(6),d.Vendor), convert(varchar(6),i.Vendor), getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where  d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
    	 and d.Vendor <> i.Vendor and a.AuditTrans = 'Y'
   
   if update(InvId)
    insert into bHQMA select 'bAPTH', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans), i.APCo, 'C',
    	'InvId', d.InvId, i.InvId, getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where   d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
    	 and d.InvId <> i.InvId and a.AuditTrans = 'Y'
   
   if update(APRef)
    insert into bHQMA select 'bAPTH', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans), i.APCo, 'C',
    	'APRef', d.APRef, i.APRef, getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where  d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
    	 and d.APRef <> i.APRef and a.AuditTrans = 'Y'
   
   if update(Description)
    insert into bHQMA select 'bAPTH', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans), i.APCo, 'C',
    	'Description', d.Description, i.Description, getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where  d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
    	 and d.Description <> i.Description and a.AuditTrans = 'Y'
   
    if update(InvDate)
    insert into bHQMA select 'bAPTH', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans), i.APCo, 'C',
    	'InvDate', convert(char(8),d.InvDate), convert(char(8),i.InvDate), getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where  d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
    	 and d.InvDate <> i.InvDate and a.AuditTrans = 'Y'
   
   if update(DiscDate)
    insert into bHQMA select 'bAPTH', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans), i.APCo, 'C',
    	'DiscDate', convert(char(8),d.DiscDate), convert(char(8),i.DiscDate), getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        join bAPCO a with (nolock) on a.APCo = i.APCo
   
    	where  d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
    	 and d.DiscDate <> i.DiscDate and a.AuditTrans = 'Y'
   
   if update(DueDate)
    insert into bHQMA select 'bAPTH', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans), i.APCo, 'C',
    	'DueDate', convert(char(8),d.DueDate), convert(char(8),i.DueDate), getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where  d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
    	 and d.DueDate <> i.DueDate and a.AuditTrans = 'Y'
   
   if update(InvTotal)
    insert into bHQMA select 'bAPTH', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans), i.APCo, 'C',
    	'InvTotal', convert(varchar(16),d.InvTotal), convert(varchar(16),i.InvTotal), getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where  d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
    	 and d.InvTotal <> i.InvTotal and a.AuditTrans = 'Y'
   
   if update(HoldCode)
    insert into bHQMA select 'bAPTH', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans), i.APCo, 'C',
    	'HoldCode',d.HoldCode, i.HoldCode, getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where  d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
    	 and isnull(d.HoldCode,'') <> isnull(i.HoldCode,'') and a.AuditTrans = 'Y'
   
   if update(PayControl)
    insert into bHQMA select 'bAPTH', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans), i.APCo, 'C',
    	'PayControl', d.PayControl, i.PayControl, getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
    	 and  d.PayControl <> i.PayControl and a.AuditTrans = 'Y'
   
    if update(PayMethod)
    insert into bHQMA select 'bAPTH', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans), i.APCo, 'C',
    	'PayMethod', d.PayMethod, i.PayMethod, getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
    	 and d.PayMethod <> i.PayMethod and a.AuditTrans = 'Y'
   
   if update(CMCo)
    insert into bHQMA select 'bAPTH', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans), i.APCo, 'C',
    	'CMCo', convert(varchar(3),d.CMCo), convert(varchar(3),i.CMCo), getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where  d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
    	 and d.CMCo <> i.CMCo and a.AuditTrans = 'Y'
   
    if update(CMAcct)
    insert into bHQMA select 'bAPTH', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans), i.APCo, 'C',
    	'CMAcct', convert(varchar(4),d.CMAcct), convert(varchar(4),i.CMAcct), getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where  d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
    	 and d.CMAcct <> i.CMAcct and a.AuditTrans = 'Y'
   
    if update(PrePaidYN)
    insert into bHQMA select 'bAPTH', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans), i.APCo, 'C',
    	'PrePaidYN', d.PrePaidYN, i.PrePaidYN, getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where  d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
    	 and d.PrePaidYN <> i.PrePaidYN and a.AuditTrans = 'Y'
   
    if update(PrePaidMth)
    insert into bHQMA select 'bAPTH', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans), i.APCo, 'C',
    	'PrePaidMth', convert(char(8),d.PrePaidMth), convert(char(8),i.PrePaidMth), getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where  d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
    	 and d.PrePaidMth <> i.PrePaidMth and a.AuditTrans = 'Y'
   
   if update(PrePaidDate)
    insert into bHQMA select 'bAPTH', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans), i.APCo, 'C',
    	'PrePaidDate', convert(char(8),d.PrePaidDate), convert(char(8),i.PrePaidDate), getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where  d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
    	 and d.PrePaidDate <> i.PrePaidDate and a.AuditTrans = 'Y'
   
   if update(PrePaidChk)
    insert into bHQMA select 'bAPTH', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans), i.APCo, 'C',
    	'PrePaidChk', d.PrePaidChk, i.PrePaidChk, getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where  d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
    	 and d.PrePaidChk <> i.PrePaidChk and a.AuditTrans = 'Y'
   
   if update(PrePaidSeq)
    insert into bHQMA select 'bAPTH', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans), i.APCo, 'C',
    	'PrePaidSeq', convert(varchar(3),d.PrePaidSeq), convert(varchar(3),i.PrePaidSeq), getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where  d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
    	 and d.PrePaidSeq <> i.PrePaidSeq and a.AuditTrans = 'Y'
   
   if update(PrePaidProcYN)
    insert into bHQMA select 'bAPTH', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans), i.APCo, 'C',
    	'PrePaidProcYN', d.PrePaidProcYN, i.PrePaidProcYN, getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where  d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
    	 and d.PrePaidProcYN <> i.PrePaidProcYN and a.AuditTrans = 'Y'
   
   if update(V1099YN)
    insert into bHQMA select 'bAPTH', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans), i.APCo, 'C',
    	'V1099YN', d.V1099YN, i.V1099YN, getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where  d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
    	 and d.V1099YN <> i.V1099YN and a.AuditTrans = 'Y'
   
   if update(V1099Type)
    insert into bHQMA select 'bAPTH', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans), i.APCo, 'C',
    	'V1099Type', d.V1099Type, i.V1099Type, getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where  d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
    	 and d.V1099Type <> i.V1099Type and a.AuditTrans = 'Y'
   
   if update(V1099Box)
    insert into bHQMA select 'bAPTH', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans), i.APCo, 'C',
    	'V1099Box', convert(varchar(3),d.V1099Box), convert(varchar(3),i.V1099Box), getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where  d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
    	 and d.V1099Box <> i.V1099Box and a.AuditTrans = 'Y'
   
   if update(PayOverrideYN)
    insert into bHQMA select 'bAPTH', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans), i.APCo, 'C',
    	'PayOverrideYN', d.PayOverrideYN, i.PayOverrideYN, getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where  d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
    	 and d.PayOverrideYN <> i.PayOverrideYN and a.AuditTrans = 'Y'
   
   if update(PayName)
    insert into bHQMA select 'bAPTH', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans), i.APCo, 'C',
    	'PayName', d.PayName, i.PayName, getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where  d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
    	 and d.PayName <> i.PayName and a.AuditTrans = 'Y'
   
   if update(PayAddInfo)
    insert into bHQMA select 'bAPTH', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans), i.APCo, 'C',
    	'PayAddInfo', d.PayAddInfo, i.PayAddInfo, getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where  d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
    	 and d.PayAddInfo <> i.PayAddInfo and a.AuditTrans = 'Y'
   
   if update(PayAddress)
    insert into bHQMA select 'bAPTH', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans), i.APCo, 'C',
    	'PayAddress', d.PayAddress, i.PayAddress, getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where  d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
    	 and d.PayAddress <> i.PayAddress and a.AuditTrans = 'Y'
   
   if update(PayCity)
    insert into bHQMA select 'bAPTH', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans), i.APCo, 'C',
    	'PayCity', d.PayCity, i.PayCity, getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
    	 and d.PayCity <> i.PayCity and a.AuditTrans = 'Y'
   
   if update(PayState)
    insert into bHQMA select 'bAPTH', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans), i.APCo, 'C',
    	'PayState', d.PayState,i.PayState, getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
    	 and  d.PayState <> i.PayState and a.AuditTrans = 'Y'
   
   if update(PayZip)
    insert into bHQMA select 'bAPTH', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans), i.APCo, 'C',
    	'PayZip', d.PayZip, i.PayZip, getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
    	 and  d.PayZip <> i.PayZip and a.AuditTrans = 'Y'

	if update(PayCountry)
    insert into bHQMA select 'bAPTH', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans), i.APCo, 'C',
    	'PayCountry', d.PayCountry, i.PayCountry, getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
    	 and  d.PayCountry <> i.PayCountry and a.AuditTrans = 'Y'
   
   if update(OpenYN)
    insert into bHQMA select 'bAPTH', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans), i.APCo, 'C',
    	'OpenYN', d.OpenYN, i.OpenYN, getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where  d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
    	 and d.OpenYN <> i.OpenYN and a.AuditTrans = 'Y'
   
   if update(InUseMth)
    insert into bHQMA select 'bAPTH', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans), i.APCo, 'C',
    	'InUseMth', convert(char(8),d.InUseMth), convert(char(8),i.InUseMth), getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where  d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
    	 and d.InUseMth <> i.InUseMth and a.AuditTrans = 'Y'
   
   if update(InUseBatchId)
    insert into bHQMA select 'bAPTH', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans), i.APCo, 'C',
    	'InUseBatchId', convert(varchar(6),d.InUseBatchId), convert(varchar(6),i.InUseBatchId), getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where  d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
    	 and d.InUseBatchId <> i.InUseBatchId and a.AuditTrans = 'Y'
   
   if update(BatchId)
    insert into bHQMA select 'bAPTH', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans), i.APCo, 'C',
    	'BatchId', convert(varchar(6),d.BatchId), convert(varchar(6),i.BatchId), getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where  d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
    	 and d.BatchId <> i.BatchId and a.AuditTrans = 'Y'
   
   if Update(Purge)
    insert into bHQMA select 'bAPTH', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans), i.APCo, 'C',
    	'Purge', d.Purge, i.Purge, getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where  d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
    	 and d.Purge <> i.Purge and a.AuditTrans = 'Y'
   
   if update(InPayControl)
    insert into bHQMA select 'bAPTH', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans), i.APCo, 'C',
    	'InPayControl', d.InPayControl, i.InPayControl, getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where  d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
    	 and d.InPayControl <> i.InPayControl and a.AuditTrans = 'Y'
   
   if update(PRCo)
    insert into bHQMA select 'bAPTH', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans), i.APCo, 'C',
    	'PR Company', d.PRCo, i.PRCo, getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where  d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
    	 and d.PRCo <> i.PRCo and a.AuditTrans = 'Y'
   
   if update(Employee)
    insert into bHQMA select 'bAPTH', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans), i.APCo, 'C',
    	'Employee', d.Employee, i.Employee, getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where  d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
    	 and d.Employee <> i.Employee and a.AuditTrans = 'Y'
   
   if update(DLcode)
    insert into bHQMA select 'bAPTH', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans), i.APCo, 'C',
    	'DL Code', d.DLcode, i.DLcode, getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where  d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
    	 and d.DLcode <> i.DLcode and a.AuditTrans = 'Y'
   
   if update(TaxFormCode)
    insert into bHQMA select 'bAPTH', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans), i.APCo, 'C',
    	'Tax Form Code', d.TaxFormCode, i.TaxFormCode, getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where  d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
    	 and d.TaxFormCode <> i.TaxFormCode and a.AuditTrans = 'Y'
   
   if update(TaxPeriodEndDate)
    insert into bHQMA select 'bAPTH', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans), i.APCo, 'C',
    	'Tax Period End Date', d.TaxPeriodEndDate, i.TaxPeriodEndDate, getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where  d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
    	 and d.TaxPeriodEndDate <> i.TaxPeriodEndDate and a.AuditTrans = 'Y'
   
   if update(AmountType)
    insert into bHQMA select 'bAPTH', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans), i.APCo, 'C',
    	'Tax Amount Type', d.AmountType, i.AmountType, getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where  d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
    	 and d.AmountType <> i.AmountType and a.AuditTrans = 'Y'
   
   if update(Amount)
    insert into bHQMA select 'bAPTH', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans), i.APCo, 'C',
    	'Tax Amount', d.Amount, i.Amount, getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where  d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
    	 and d.Amount <> i.Amount and a.AuditTrans = 'Y'
   
   if update(AmtType2)
    insert into bHQMA select 'bAPTH', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans), i.APCo, 'C',
    	'Tax Amount Type 2', d.AmtType2, i.AmtType2, getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where  d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
    	 and d.AmtType2 <> i.AmtType2 and a.AuditTrans = 'Y'
   
   if update(Amount2)
    insert into bHQMA select 'bAPTH', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans), i.APCo, 'C',
    	'Tax Amount 2', d.Amount2, i.Amount2, getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where  d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
    	 and d.Amount2 <> i.Amount2 and a.AuditTrans = 'Y'
   
   if update(AmtType3)
    insert into bHQMA select 'bAPTH', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans), i.APCo, 'C',
    	'Tax Amount Type 32', d.AmtType3, i.AmtType3, getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where  d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
    	 and d.AmtType3 <> i.AmtType3 and a.AuditTrans = 'Y'
   
   if update(Amount3)
    insert into bHQMA select 'bAPTH', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans), i.APCo, 'C',
    	'Tax Amount 3', d.Amount3, i.Amount3, getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where  d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
    	 and d.Amount3 <> i.Amount3 and a.AuditTrans = 'Y'
   
   if update(SeparatePayYN)
    insert into bHQMA select 'bAPTH', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans), i.APCo, 'C',
    	'Separate Pay', d.SeparatePayYN, i.SeparatePayYN, getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where  d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
    	 and d.SeparatePayYN <> i.SeparatePayYN and a.AuditTrans = 'Y'
   
   if update(AddressSeq)
    insert into bHQMA select 'bAPTH', ' Mth: ' + convert(char(8), i.Mth,1)
    		 + ' APTrans: ' + convert(varchar(6), i.APTrans), i.APCo, 'C',
    	'Addtl Address Seq #', d.AddressSeq, i.AddressSeq, getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
        join bAPCO a with (nolock) on a.APCo = i.APCo
    	where  d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
    	 and d.AddressSeq <> i.AddressSeq and a.AuditTrans = 'Y'
   
   
Trigger_Skip:   
   
   return        
   
   error:
    	select @errmsg = @errmsg + ' - cannot update Transaction Header!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biAPTH] ON [dbo].[bAPTH] ([APCo], [Mth], [APTrans]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [biAPTHOpen] ON [dbo].[bAPTH] ([APCo], [Mth], [OpenYN]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [biAPTHPrePaidForCheckPrint] ON [dbo].[bAPTH] ([APCo], [PrePaidMth], [PrePaidChk]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bAPTH] ([KeyID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_bAPTH_SLKeyID] ON [dbo].[bAPTH] ([SLKeyID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [biAPTHAttach] ON [dbo].[bAPTH] ([UniqueAttchID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [biAPTHVendor ] ON [dbo].[bAPTH] ([Vendor], [VendorGroup], [APRef]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brCMAcct]', N'[dbo].[bAPTH].[CMAcct]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPTH].[PrePaidYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPTH].[PrePaidProcYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPTH].[V1099YN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPTH].[PayOverrideYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPTH].[OpenYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPTH].[Purge]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPTH].[InPayControl]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPTH].[SeparatePayYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPTH].[ChkRev]'
GO
