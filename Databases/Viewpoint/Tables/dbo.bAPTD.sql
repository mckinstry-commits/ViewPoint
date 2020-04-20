CREATE TABLE [dbo].[bAPTD]
(
[APCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[APTrans] [dbo].[bTrans] NOT NULL,
[APLine] [smallint] NOT NULL,
[APSeq] [tinyint] NOT NULL,
[PayType] [tinyint] NOT NULL,
[Amount] [dbo].[bDollar] NOT NULL,
[DiscOffer] [dbo].[bDollar] NOT NULL,
[DiscTaken] [dbo].[bDollar] NOT NULL,
[DueDate] [dbo].[bDate] NOT NULL,
[Status] [tinyint] NOT NULL,
[PaidMth] [dbo].[bMonth] NULL,
[PaidDate] [dbo].[bDate] NULL,
[CMCo] [dbo].[bCompany] NULL,
[CMAcct] [dbo].[bCMAcct] NULL,
[PayMethod] [char] (1) COLLATE Latin1_General_BIN NULL,
[CMRef] [dbo].[bCMRef] NULL,
[CMRefSeq] [tinyint] NULL,
[EFTSeq] [smallint] NULL,
[VendorGroup] [dbo].[bGroup] NULL,
[Supplier] [dbo].[bVendor] NULL,
[PayCategory] [int] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[GSTtaxAmt] [dbo].[bDollar] NULL,
[TotTaxAmount] [dbo].[bDollar] NULL,
[AuditYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bAPTD_AuditYN] DEFAULT ('Y'),
[OldGSTtaxAmt] [dbo].[bDollar] NULL CONSTRAINT [DF_bAPTD_OldGSTtaxAmt] DEFAULT ((0)),
[ExpenseGST] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bAPTD_ExpenseGST] DEFAULT ('N'),
[PSTtaxAmt] [dbo].[bDollar] NULL,
[OldPSTtaxAmt] [dbo].[bDollar] NULL,
[udYSN] [decimal] (12, 0) NULL,
[udRCCD] [int] NULL,
[udTotalChkAmt] [numeric] (12, 2) NULL,
[udMultiPay] [char] (1) COLLATE Latin1_General_BIN NULL,
[udRetgHistory] [char] (1) COLLATE Latin1_General_BIN NULL,
[udSource] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[udConv] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[udCGCTable] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[udCGCTableID] [decimal] (12, 0) NULL
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biAPTD] ON [dbo].[bAPTD] ([APCo], [Mth], [APTrans], [APLine], [APSeq]) WITH (FILLFACTOR=85, STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [biAPTDCMRef] ON [dbo].[bAPTD] ([CMRef]) WITH (FILLFACTOR=85, STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bAPTD] ([KeyID]) WITH (FILLFACTOR=85, STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btAPTDd    Script Date: 8/28/99 9:36:57 AM ******/
   CREATE   trigger [dbo].[btAPTDd] on [dbo].[bAPTD] for DELETE as
   

/*-----------------------------------------------------------------
    * Created :  EN 11/1/98
    * Modified : EN 11/1/98
    *			  MV 10/18/02 - 18878 quoted identifier cleanup.
    *			  GF 08/12/2003 - issue #22112 - performance
    *
    *	This trigger restricts deletion of any APTD records if 
    *	lines or detail exist in APHD.
    *
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int, @apco bCompany,
   		@mth bMonth, @aptrans bTrans, @duedate bDate
   
   select @numrows = @@rowcount
   if @numrows = 0 return 
   set nocount on
   
   
   if exists(select 1 from bAPHD a with (nolock), deleted d where a.APCo=d.APCo and a.Mth=d.Mth
   	and a.APTrans=d.APTrans and a.APLine=d.APLine and a.APSeq=d.APSeq)
   	begin
   	select @errmsg='Hold Detail exists for this transaction detail.'
   	goto error
   	end
   
   
   return
   
   
   
   
   error:
   	select @errmsg = @errmsg + ' - cannot delete AP Transaction Detail!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btAPTDi    Script Date: 8/28/99 9:36:57 AM ******/
   CREATE   trigger [dbo].[btAPTDi] on [dbo].[bAPTD] for INSERT as
   

/*-----------------------------------------------------------------
    * Created By:  EN 10/29/98
    * Modified By: EN 10/29/98
    *				GG 10/24/00 - fixed Pay Type and Supplier validation
    *				GF 08/12/2003 - issue #22112 - performance
    *				MV 02/17/04 - #18769 Pay Category
    *
    * Reject if entry in bAPTL does not exist.
    * If flagged for auditing recurring invoices, inserts HQ Master Audit entry.
    */----------------------------------------------------------------
   
   declare @errmsg varchar(255), @validcnt int, @numrows int, @nullcnt int
   
   select @numrows = @@rowcount, @errmsg=''
   if @numrows = 0 return
   set nocount on
   
   -- check Transaction Line 
   SELECT @validcnt = count(*) FROM bAPTL h with (nolock)
   JOIN inserted i ON h.APCo = i.APCo and h.Mth = i.Mth and h.APTrans = i.APTrans and h.APLine = i.APLine
   IF @validcnt <> @numrows
   	BEGIN
   	SELECT @errmsg = 'Transaction Line does not exist'
   	GOTO error
   	END
   
   -- validate Pay Type
   SELECT @validcnt = count(*) FROM bAPTL h with (nolock)
   JOIN inserted i ON h.APCo = i.APCo and h.Mth = i.Mth and h.APTrans = i.APTrans and h.APLine = i.APLine
   WHERE h.PayType = i.PayType
   		 or ((i.PayCategory is null and i.PayType in (select c.RetPayType from bAPCO c with (nolock) where c.APCo=i.APCo))
   			 or (i.PayCategory is not null and i.PayType in 
   				(select c.RetPayType from bAPPC c with (nolock) where c.APCo=i.APCo and c.PayCategory = i.PayCategory)))
   				
   IF @validcnt <> @numrows
   	BEGIN
   	SELECT @errmsg = 'Pay Type must match Line Pay Type or Retainage Pay Type'
   	GOTO error
   	END
   	
   SELECT @validcnt = count(*) FROM inserted i
   WHERE (i.Status = 1 or i.Status = 2)
   	and (i.PaidMth is not null or i.PaidDate is not null or i.CMCo is not null or i.PayMethod is not null
   		or i.CMRef is not null or i.CMRefSeq is not null or
   	(i.EFTSeq is not null and exists(select * from bAPTH h with (nolock) where h.APCo=i.APCo and h.Mth=i.Mth
   		and h.APTrans=i.APTrans and h.PayMethod='E')))
   if @validcnt <> 0
   	BEGIN
   	SELECT @errmsg = 'Entry must not contain any payment information'
   	GOTO error
   	END
   
   SELECT @validcnt = count(*) FROM inserted i
   	WHERE i.Status = 3
   	and (i.PaidMth is null or i.PaidDate is null or i.CMCo is null or i.PayMethod is null
   		or i.CMRef is null or i.CMRefSeq is null or
   	(i.EFTSeq is null and exists(select * from bAPTH h with (nolock) where h.APCo=i.APCo and h.Mth=i.Mth
   		and h.APTrans=i.APTrans and h.PayMethod='E')))
   if @validcnt <> 0
   	BEGIN
   	SELECT @errmsg = 'Entry must contain payment information'
   	GOTO error
   	END
   
   SELECT @validcnt = count(*) FROM inserted i
   	WHERE i.Status = 4
   	and (i.PaidMth is null or i.PaidDate is null or i.CMCo is not null or i.PayMethod is not null
   		or i.CMRef is not null or i.CMRefSeq is not null or
   	(i.EFTSeq is not null and exists(select * from bAPTH h with (nolock) where h.APCo=i.APCo and h.Mth=i.Mth
   		and h.APTrans=i.APTrans and h.PayMethod='E')))
   if @validcnt <> 0
   	BEGIN
   	SELECT @errmsg = 'Entry must contain paid month and paid date but not other payment information'
   	GOTO error
   	END
   
   -- validate Supplier
   select @nullcnt = count(*) from inserted i where i.Supplier is null
   
   select @validcnt = count(*)  from bAPVM v with (nolock)
   join inserted i on v.VendorGroup = i.VendorGroup and v.Vendor = i.Supplier
   if @validcnt + @nullcnt <> @numrows
   	BEGIN
   	SELECT @errmsg = 'Invalid supplier'
   	GOTO error
   	END
   
   
   
   return
   
   
   
   error:
       SELECT @errmsg = @errmsg +  ' - cannot insert AP Transaction Detail!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   
   
   
   
   
   
   /****** Object:  Trigger btAPTDu    Script Date: 8/28/99 9:36:57 AM ******/
   
      CREATE                      trigger [dbo].[btAPTDu] on [dbo].[bAPTD] for UPDATE as
      

/*-----------------------------------------------------------------
       *	Created : 10/30/98 EN
       *	Modified : 1/11/98 kb
       *		   1/20/00 GH - Added 'If update (PayType)' to PayType validation - see call #1048519
       *		  12/10/01 MV - Issue 14160 - update hold flag in APWD when status changes in APTD
       *		  1/03/02 GG - fix bAPWD update
       *		  3/6/02 MV - update hold flag in APWD when status changes in APTD
       *            4/10/2 kb - issue #15848
       *            6/13/2 kb - issue #14160 remmed out code that was updating APWD,
       *                it appeared the code was not needed and was causing an 
       *                error with an open cursor bcAPWD
       *		  10/17/02 - #19029 set pay flag to 'Y' in bAPWD whe status changes.
       *		  10/18/02 - 18878 quoted identifier cleanup.
   	*		  02/17/04 MV - #18769 Pay Category 
       *			03/12/04 ES - #23061 isnull wrapping
       *			04/12/04 MV - #22940 don't update PayYN to 'Y' if out of compliance.
		*			MV 04/03/09 - #133073 - (nolock)
		*			MV 11/10/11 - TK-09243 - update bAPWD.Amount when bAPTD.Amount is updated

       *	This trigger rejects update in bAPTD (Payment Trans Detail)
       *	if any of the following error conditions exist:
       *
       *		Cannot change Co
       *		Cannot change Mth
       *		Cannot change APTrans
       *		Cannot change APLine
       *		Cannot change APSeq
       *
       *	Validate same as in insert trigger.
       */----------------------------------------------------------------
      declare @errmsg varchar(255), @numrows int, @validcnt int, @status tinyint
   
      select @numrows = @@rowcount
      if @numrows = 0 return
   
      set nocount on
   
      /*select @errmsg = convert(varchar(5),@validcnt) + ' - ' + convert(varchar(5),@numrows)goto error */
      /* verify primary key not changed */
     /* select @validcnt = count(*) from deleted d, inserted i
      	where d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
      	and d.APLine = i.APLine and d.APSeq = i.APSeq
   
      if @numrows <> @validcnt*/
      if update(APCo) or update(Mth) or update(APTrans) or update(APLine) or update(APSeq)
      	begin
      	select @errmsg = 'Cannot change Primary Key'
      	goto error
      	end
   
   
      /* check Transaction Line */
      if update(APCo) or update(Mth) or update(APTrans) or update(APLine)
       begin
      SELECT @validcnt = count(*) FROM bAPTL h (nolock)
      	JOIN inserted i ON h.APCo = i.APCo and h.Mth = i.Mth
      		and h.APTrans = i.APTrans and h.APLine = i.APLine
      IF @validcnt <> @numrows
      	BEGIN
      	SELECT @errmsg = 'Transaction Line does not exist' + isnull(convert(varchar(5),@validcnt), '') --#23061
      	GOTO error
      	END
       end
   
   
      if update(PayType)
         	begin
         SELECT @validcnt = count(*) FROM bAPTL h (nolock)
         	JOIN inserted i ON h.APCo = i.APCo and h.Mth = i.Mth
         		and h.APTrans = i.APTrans and h.APLine = i.APLine
         	WHERE h.PayType = i.PayType
   		 	 or ((i.PayCategory is null and i.PayType in (select c.RetPayType from bAPCO c (nolock) where c.APCo=i.APCo))
   			 	  or (i.PayCategory is not null and i.PayType in(select c.RetPayType
   						 from bAPPC c (nolock) where c.APCo=i.APCo and c.PayCategory = i.PayCategory)))
   
         		--or exists(select * from bAPCO c where c.APCo=i.APCo and c.RetPayType=i.PayType)
         IF @validcnt <> @numrows
         	BEGIN
         	SELECT @errmsg = 'Pay type must match Line pay type or retainage pay type' + isnull(convert(varchar(5),@validcnt), '') --#23061
         	GOTO error
         	END
         	end
   
     /* Update APWD if Status changes */
    if update (Status)
     	BEGIN
     	update bAPWD
    	set HoldYN = case i.Status when 1 then 'N' when 2 then 'Y' else d.HoldYN end,
    	PayYN = case i.Status when 1 then
   				case h.CompliedYN when 'N' then
   					case h.PayYN when 'Y' then 'Y' else 'N' end else 'Y' end when 2 then 'N' else d.PayYN end  	
    	from bAPWD d (nolock) join inserted i on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
    		and d.APLine = i.APLine and d.APSeq = i.APSeq
   		join bAPWH h (nolock) on d.APCo=h.APCo and d.Mth=h.Mth and d.APTrans=h.APTrans	--#22940
   --  	PayYN = case i.Status when 1 then 'Y' when 2 then 'N' else d.PayYN end 	--19020 
   -- 	--PayYN = case i.Status when 1 then d.PayYN  when 2 then 'N' else d.PayYN end 
   --  	from bAPWD d join inserted i on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
   --  		and d.APLine = i.APLine and d.APSeq = i.APSeq
    	END
   	
       if update(Status) or update(PaidMth) or update(PaidDate) or update(CMCo)
         or update(PayMethod) or update(CMRef) or update(CMRefSeq) or update(EFTSeq)
           begin
          SELECT @validcnt = count(*) FROM inserted i
          	WHERE (i.Status = 1 or i.Status = 2)
          	and (i.PaidMth is not null or i.PaidDate is not null or i.CMCo is not null or i.PayMethod is not null
          	and i.CMRef is not null or i.CMRefSeq is not null or
          	(i.EFTSeq is not null and exists(select * from bAPTH h where h.APCo=i.APCo and h.Mth=i.Mth
          	and h.APTrans=i.APTrans and h.PayMethod='E')))
      if @validcnt <> 0
          	BEGIN
          	SELECT @errmsg = 'Entry must not contain any payment information' + isnull(convert(varchar(5),@validcnt), '') --#23061
          	GOTO error
          	END
   
          SELECT @validcnt = count(*) FROM inserted i
          	WHERE i.Status = 3
          	and (i.PaidMth is null or i.PaidDate is null or i.CMCo is null or i.PayMethod is null
          		or i.CMRef is null or i.CMRefSeq is null or
          	(i.EFTSeq is null and i.PayMethod='E'))
          if @validcnt <> 0
          	BEGIN
          	SELECT @errmsg = 'Entry must contain payment information'
          	GOTO error
          	END
   
          SELECT @validcnt = count(*) FROM inserted i
          	WHERE i.Status = 4
          	and (i.PaidMth is null or i.CMCo is not null or i.PayMethod is not null
          		or i.CMRef is not null or i.CMRefSeq is not null or
          	(i.EFTSeq is not null and exists(select * from bAPTH h where h.APCo=i.APCo and h.Mth=i.Mth
          		and h.APTrans=i.APTrans and h.PayMethod='E')))
          if @validcnt <> 0
          	BEGIN
          	SELECT @errmsg = 'Entry must contain paid month but not other payment information'
          	GOTO error
          	END

		  		
           end
   
       if update(VendorGroup) or update(Supplier)
           begin
          SELECT @validcnt = count(*) FROM inserted i
          	WHERE i.Supplier is not null
          	and not exists(select * from bAPVM v where v.VendorGroup=i.VendorGroup and
          		v.Vendor=i.Supplier)
          if @validcnt <> 0
          	BEGIN
          	SELECT @errmsg = 'Invalid supplier'
          	GOTO error
          	END
           end
           
       IF UPDATE(Amount)
       BEGIN
		UPDATE dbo.bAPWD SET Amount=i.Amount
		FROM inserted i 
		JOIN dbo.bAPWD d ON d.APCo = i.APCo and d.Mth = i.Mth
  			and d.APTrans = i.APTrans and d.APLine = i.APLine and d.APSeq=i.APSeq 
       END
   
      return
   
   
      error:
      	select @errmsg = @errmsg + ' - cannot update Transaction Detail!'
          	RAISERROR(@errmsg, 11, -1);
          	rollback transaction
   
   
   
   
   
   
   
   
   
   
   
  
 





GO

EXEC sp_bindrule N'[dbo].[brCMAcct]', N'[dbo].[bAPTD].[CMAcct]'
GO
