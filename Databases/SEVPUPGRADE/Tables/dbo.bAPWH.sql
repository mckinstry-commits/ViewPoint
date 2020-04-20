CREATE TABLE [dbo].[bAPWH]
(
[APCo] [dbo].[bCompany] NOT NULL,
[UserId] [dbo].[bVPUserName] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[APTrans] [dbo].[bTrans] NOT NULL,
[PayYN] [dbo].[bYN] NOT NULL,
[UnpaidAmt] [dbo].[bDollar] NOT NULL,
[PayAmt] [dbo].[bDollar] NOT NULL,
[DiscDate] [dbo].[bDate] NULL,
[DueDate] [dbo].[bDate] NULL,
[PayControl] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[PayMethod] [char] (1) COLLATE Latin1_General_BIN NULL,
[CMCo] [dbo].[bCompany] NULL,
[CMAcct] [dbo].[bCMAcct] NULL,
[HoldYN] [dbo].[bYN] NOT NULL,
[VendorGroup] [dbo].[bGroup] NOT NULL,
[Supplier] [dbo].[bVendor] NULL,
[SeparatePayJobYN] [dbo].[bYN] NOT NULL,
[SeparatePaySLYN] [dbo].[bYN] NOT NULL,
[TakeAllDiscYN] [dbo].[bYN] NOT NULL,
[DiscCancelDate] [dbo].[bDate] NULL,
[ManualAddYN] [dbo].[bYN] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[DiscTaken] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bAPWH_DiscTaken] DEFAULT ((0)),
[UniqueAttchID] [uniqueidentifier] NULL,
[DiscOffered] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bAPWH_DiscOffered] DEFAULT ((0)),
[CompliedYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bAPWH_CompliedYN] DEFAULT ('Y'),
[SeparatePayYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bAPWH_SeparatePayYN] DEFAULT ('N'),
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE     trigger [dbo].[btAPWHd] on [dbo].[bAPWH] for DELETE as
    

/*-----------------------------------------------------------------
     *  Created: MV 11/01/01
     *  Modified: EN
     * 			MV 10/18/02 - 18878 quoted identifier cleanup
     *
     *  This trigger cascade deletes detail records in APWD.
     *
     */----------------------------------------------------------------
    declare @errmsg varchar(255), @numrows int, @validcnt int, @apco bCompany,
    	@mth bMonth, @aptrans bTrans, @duedate bDate
   
   
    delete bAPWD from bAPWD a JOIN deleted d ON a.APCo=d.APCo and a.Mth=d.Mth and a.APTrans=d.APTrans
    	where a.APCo=d.APCo and a.Mth=d.Mth and a.APTrans=d.APTrans
   
    /* update InPayControl in APTH to 'N'*/
    update bAPTH set InPayControl = 'N' from bAPTH h join deleted d on h.APCo=d.APCo and h.Mth=d.Mth and h.APTrans=d.APTrans
   
    return
    error:
    	select @errmsg = @errmsg + ' - cannot delete AP Workfile Header!'
        	RAISERROR(@errmsg, 11, -1);
        	rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   
   
   
   
   
   
   
   CREATE                           trigger [dbo].[btAPWHi] on [dbo].[bAPWH] for INSERT as
        

/*-----------------------------------------------------------------
         *	Created : 11/5/01 MV
         *	Modified : kb 5/13/2 - issue #14160
     	*				kb 7/24/2 - issue #18064 - need to update APTH when inserting APWH
     						because user may have changed stuff while inserting
         *			  MV 10/18/02 - 18878 quoted identifier cleanup
     	*				MV 07/15/03 - #21605 don't update APWD and APTD with due date in APWD
         *				MV 02/04/04 - #23530 update due date in bAPWD and bAPTD if manual add
		 *				MV 04/26/07 - #122337 - set detail complied based on APCO flags
         *	This trigger rejects insert in bAPWH (Workfile Header)
         *	if any of the following error conditions exist:
         *
         *		Cannot change Co
         *		Cannot change Mth
         *		Cannot change APTrans
         *		Invalid payment method
         *		Invalid CMAcct
         *		APWH workfile record already exists
         *		no open detail to pay
         *
         */----------------------------------------------------------------
        declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int, @nullcnt int,@manual bYN,
       	 @apco bCompany, @mth bDate, @aptrans bTrans, @apline int, @apseq int,@openAddDetail int,@status int,
       	 @discoffer bDollar, @disctaken bDollar, @duedate bDate, @supplier bVendor, @userid varchar (30),
       	 @payyn bYN, @holdyn bYN, @manualyn bYN, @amount bDollar, @vendorgroup bGroup,@compliedyn bYN,
		 @DontAllowPaySL bYN, @DontAllowPayPO bYN,@DontAllowPayAllinv bYN,@linetype int 
     
        select @numrows = @@rowcount
        if @numrows = 0 return
        set nocount on
     
       -- validate record doesn't already exist
           select @validcnt = count(*) from bAPWH h with(nolock)
             join inserted i on h.APCo=i.APCo and h.Mth=i.Mth and
       	  h.APTrans=i.APTrans where h.UserId <> i.UserId
       	if @validcnt > 0
           	BEGIN
           	SELECT @errmsg 'Header record already exists'
           	GOTO error
           	END
      
       -- check if there are lines to pay
       if not exists (select top 1 1 from bAPTD d with (nolock) join inserted i 
      	on d.APCo=i.APCo and d.Mth=i.Mth and d.APTrans=i.APTrans
       	and d.Status<3)
       	BEGIN
       	SELECT @errmsg = 'There is no detail open to pay.'
       	GOTO error
       	END
     
       /* If header rec is a manual add, set the amounts to zero so the detail insert trigger doesn't add
       	the amounts in twice*/
       if exists (select top 1 1 from inserted where ManualAddYN='Y')
       	BEGIN
       	update bAPWH set PayAmt = 0, UnpaidAmt = 0 from bAPWH h
       	 join inserted i on h.APCo=i.APCo and h.Mth=i.Mth and h.APTrans=i.APTrans
		
       	-- create Workfile detail records for manual add
       	declare bcAddDetail cursor LOCAL FAST_FORWARD for
              select d.APCo,d.Mth,d.APTrans,d.APLine,APSeq,DiscOffer,d.DiscTaken,i.DueDate/*d.DueDate #23530*/,
    		  d.Supplier,d.Status,i.UserId, d.Amount, l.LineType
              from inserted i 
			  join bAPTD d with (nolock) on d.APCo=i.APCo and d.Mth=i.Mth and d.APTrans=i.APTrans
			  join bAPTL l with (nolock) on l.APCo=i.APCo and l.Mth=i.Mth and l.APTrans=i.APTrans 
              where d.Status < 3
     
              open bcAddDetail
              select @openAddDetail = 1
       	AddNext:
                  fetch next from bcAddDetail into @apco, @mth, @aptrans, @apline,@apseq,@discoffer,@disctaken,
       		@duedate, @supplier, @status, @userid, @amount, @linetype
                  if @@fetch_status <> 0 goto bcAddDetail_end
       	   select @validcnt = count(*) from bAPWD where APCo=@apco and Mth=@mth and
       			APTrans=@aptrans and APLine=@apline and APSeq=@apseq
       		if @validcnt = 0
     
       		BEGIN
			--set payyn flag and holdyn based on hold status
       		if @status=1 select @payyn='Y',@holdyn='N'
       		if @status=2 select @payyn='N', @holdyn='Y'
			
     		select @vendorgroup = VendorGroup from bAPTH with (nolock) where APCo = @apco
     		  and Mth = @mth and APTrans = @aptrans 

			--get apco flags for setting payyn
			select @DontAllowPaySL = SLAllowPayYN, @DontAllowPayPO = POAllowPayYN, @DontAllowPayAllinv=AllAllowPayYN
			from APCO with (nolock) where APCo = @apco
			-- set complied flag
			select @compliedyn = dbo.vfAPWDCompliedYN(@apco,@mth,@aptrans,@userid,@apline)
			-- set payyn flag based on complied status
			if (@compliedyn = 'N' and (@linetype <> 6 and @linetype<>7 ) and @DontAllowPayAllinv = 'Y') or
 				(@compliedyn = 'N' and @linetype = 6 and @DontAllowPayPO = 'Y') or
				(@compliedyn = 'N' and @linetype = 7 and @DontAllowPaySL = 'Y')
				select @payyn='N'
			-- create APWD rec 
       		insert into bAPWD (APCo, UserId, Mth, APTrans, APLine, APSeq, HoldYN, PayYN,
       			DiscOffered, DiscTaken, DueDate, Supplier, Amount, VendorGroup, CompliedYN)
       		values (@apco, @userid, @mth, @aptrans, @apline, @apseq, @holdyn, @payyn, isnull(@discoffer,0),
       			isnull(@disctaken,0), @duedate, @supplier, @amount, @vendorgroup,@compliedyn)
       		END
    		-- #23530 update bAPTD with due date from bAPWH 
    		update bAPTD set DueDate = i.DueDate From inserted i JOIN bAPTD d 
    	   	ON d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
    	   	WHERE d.APCo = i.APCo and d.Mth = i.Mth	and d.APTrans = i.APTrans
    	   	and d.Status<3
     
       	    goto AddNext
     
       	bcAddDetail_end:
                  close bcAddDetail
                  deallocate bcAddDetail
       	END
     
       /* Update InPayControl to 'Y' in APTH*/
       update bAPTH set InPayControl = 'Y', PayMethod = i.PayMethod, 
     	PayControl = i.PayControl, DiscDate = i.DiscDate,
     	DueDate = i.DueDate, CMAcct = i.CMAcct from bAPTH h
         join inserted i on h.APCo=i.APCo and h.Mth=i.Mth
         and h.APTrans=i.APTrans
     
     	update bAPTH set Notes = w.Notes from  inserted i 
     	  join bAPTH h  on h.APCo = i.APCo and h.Mth = i.Mth and h.APTrans = i.APTrans
     	  join bAPWH w  on w.APCo = i.APCo and w.Mth = i.Mth and w.APTrans = i.APTrans
     	  where h.APCo = i.APCo and h.Mth = i.Mth and h.APTrans = i.APTrans
      
     	--21605 
       	/*update bAPTD set DueDate = i.DueDate From bAPTD d JOIN inserted i
       	ON d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
       	WHERE d.APCo = i.APCo and d.Mth = i.Mth	and d.APTrans = i.APTrans
       	and d.Status<3 --update only open and onhold detail
      
       	update bAPWD set DueDate = i.DueDate From bAPWD d JOIN inserted i
       	ON d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans
       	WHERE d.APCo = i.APCo and d.Mth = i.Mth	and d.APTrans = i.APTrans*/
      
        return
        error:
        	select @errmsg = @errmsg + ' - cannot insert Transaction Header!'
            	RAISERROR(@errmsg, 11, -1);
            	rollback transaction
       	if @openAddDetail = 1
                  begin
           	   close bcAddDetail
                  deallocate bcAddDetail
                  end
     
     
     
     
     
     
     
     
    
    
    
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE trigger [dbo].[btAPWHu] on [dbo].[bAPWH] for UPDATE as
/*-----------------------------------------------------------------
* Created:	MV - 11/5/01 MV
* Modified:	kb 06/07/02 - #14160 - was updating APTL supplier if supplier in APWH changed, should do APTD not APTL
*			MV 10/18/02 - #18878 - quoted identifier cleanup
*			KK 01/17/12 - TK-11581 Added "S"(Credit Service) as an acceptable value for PayMethod
*			KK 02/19/12 - TK-12973 Removed validation check on CM Account to allow any value
*
*	This trigger rejects update in bAPWH (Workfile Header)
*	if any of the following error conditions exist:
*
*		Cannot change Co
*		Cannot change Mth
*		Cannot change APTrans
*
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
		@holdyn bYN,
		@payyn bYN,
		@phasegroup bGroup, 
		@phase bPhase, 
		@jcctype bJCCType

SELECT @numrows = @@rowcount
IF @numrows = 0 RETURN
SET NOCOUNT ON
    
/* verify primary key not changed */
IF UPDATE(APCo) OR UPDATE(Mth) or UPDATE(APTrans)
BEGIN
	SELECT @validcnt = COUNT(*) from deleted d, inserted i
  	WHERE d.APCo = i.APCo AND d.Mth = i.Mth AND d.APTrans = i.APTrans
 	IF @numrows <> @validcnt
  	BEGIN
  		SELECT @errmsg = 'Cannot change Primary Key'
 	 	GOTO error
  	END
END
    
/* validate PayMethod */
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

--/* validate CMAcct */
--IF UPDATE(CMAcct)
--BEGIN
--	SELECT @validcnt = COUNT(*) FROM inserted WHERE CMAcct IS NOT NULL
--	SELECT @validcnt2 = COUNT(*) FROM bCMAC a
--	JOIN inserted i ON a.CMCo = i.CMCo AND a.CMAcct = i.CMAcct WHERE i.CMAcct IS NOT NULL
--	IF @validcnt <> @validcnt2
--	BEGIN
--		SELECT @errmsg = 'Invalid CM account'
--		GOTO error
--	END
--END
    
/* validate Supplier */
IF UPDATE (Supplier)
BEGIN
	SELECT @validcnt = COUNT(*) FROM bAPVM v
	JOIN inserted i ON v.VendorGroup = i.VendorGroup AND v.Vendor = i.Supplier
	SELECT @validcnt2 = COUNT(*) FROM inserted i WHERE i.Supplier IS NOT NULL
	IF @validcnt <> @validcnt2
	BEGIN
		SELECT @errmsg = 'Invalid Supplier'
		GOTO error
	END
	-- update supplier in APWD
	UPDATE bAPWD SET Supplier = i.Supplier 
	FROM bAPWD d JOIN inserted i ON d.APCo = i.APCo 
								AND d.Mth = i.Mth
								AND d.APTrans = i.APTrans
END

/* Updates to PayYN field are handled in bspAPWHUpdatePayYN in APPayWorkfile form. */

/* update fields in APTH */
IF UPDATE (PayMethod)
BEGIN
	UPDATE bAPTH SET PayMethod = i.PayMethod FROM bAPTH h JOIN inserted i
	ON h.APCo = i.APCo AND h.Mth = i.Mth AND h.APTrans = i.APTrans
	WHERE h.APCo = i.APCo AND h.Mth = i.Mth	AND h.APTrans = i.APTrans
END

IF UPDATE(PayControl)
BEGIN
	UPDATE bAPTH SET PayControl = i.PayControl FROM bAPTH h JOIN inserted i
	ON h.APCo = i.APCo AND h.Mth = i.Mth AND h.APTrans = i.APTrans
	WHERE h.APCo = i.APCo AND h.Mth = i.Mth	AND h.APTrans = i.APTrans
END

IF UPDATE(DiscDate)
BEGIN
	UPDATE bAPTH set DiscDate = i.DiscDate FROM bAPTH h JOIN inserted i
	ON h.APCo = i.APCo AND h.Mth = i.Mth AND h.APTrans = i.APTrans
	WHERE h.APCo = i.APCo AND h.Mth = i.Mth	AND h.APTrans = i.APTrans
END

IF UPDATE(DueDate)
BEGIN
	UPDATE bAPTH set DueDate = i.DueDate FROM bAPTH h JOIN inserted i
	ON h.APCo = i.APCo AND h.Mth = i.Mth AND h.APTrans = i.APTrans
	WHERE h.APCo = i.APCo AND h.Mth = i.Mth	AND h.APTrans = i.APTrans

	UPDATE bAPTD set DueDate = i.DueDate From bAPTD d JOIN inserted i
	ON d.APCo = i.APCo AND d.Mth = i.Mth AND d.APTrans = i.APTrans
	WHERE d.APCo = i.APCo AND d.Mth = i.Mth	AND d.APTrans = i.APTrans
		and d.Status<3 --update only open and onhold detail

	UPDATE bAPWD SET DueDate = i.DueDate FROM bAPWD d JOIN inserted i
	ON d.APCo = i.APCo AND d.Mth = i.Mth AND d.APTrans = i.APTrans
	WHERE d.APCo = i.APCo AND d.Mth = i.Mth	AND d.APTrans = i.APTrans
END

/* if update(Supplier)
BEGIN
update bAPTD set Supplier = i.Supplier FROM bAPTD h JOIN inserted i
ON h.APCo = i.APCo and h.Mth = i.Mth and h.APTrans = i.APTrans
WHERE h.APCo = i.APCo and h.Mth = i.Mth	and h.APTrans = i.APTrans
END*/

IF UPDATE(CMAcct)
BEGIN
	UPDATE bAPTH SET CMAcct = i.CMAcct FROM bAPTH h JOIN inserted i
	ON h.APCo = i.APCo AND h.Mth = i.Mth AND h.APTrans = i.APTrans
	WHERE h.APCo = i.APCo AND h.Mth = i.Mth	AND h.APTrans = i.APTrans
END

IF UPDATE(Notes)
BEGIN
	UPDATE bAPTH SET Notes = w.Notes FROM  inserted i 
	JOIN bAPTH h ON h.APCo = i.APCo AND h.Mth = i.Mth AND h.APTrans = i.APTrans
	JOIN bAPWH w ON w.APCo = i.APCo AND w.Mth = i.Mth AND w.APTrans = i.APTrans
	WHERE h.APCo = i.APCo AND h.Mth = i.Mth AND h.APTrans = i.APTrans
END

RETURN

error:
SELECT @errmsg = @errmsg + ' - cannot update Payment Workfile Header!'
RAISERROR(@errmsg, 11, -1);
ROLLBACK TRANSACTION
GO
CREATE UNIQUE CLUSTERED INDEX [biAPWH] ON [dbo].[bAPWH] ([APCo], [Mth], [APTrans]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [biAPWH_UserId] ON [dbo].[bAPWH] ([APCo], [UserId]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bAPWH] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPWH].[PayYN]'
GO
EXEC sp_bindrule N'[dbo].[brCMAcct]', N'[dbo].[bAPWH].[CMAcct]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPWH].[HoldYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPWH].[SeparatePayJobYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPWH].[SeparatePaySLYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPWH].[TakeAllDiscYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPWH].[ManualAddYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPWH].[CompliedYN]'
GO
