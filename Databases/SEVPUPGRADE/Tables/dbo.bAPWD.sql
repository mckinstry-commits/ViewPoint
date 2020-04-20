CREATE TABLE [dbo].[bAPWD]
(
[APCo] [dbo].[bCompany] NOT NULL,
[UserId] [dbo].[bVPUserName] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[APTrans] [dbo].[bTrans] NOT NULL,
[APLine] [smallint] NOT NULL,
[APSeq] [tinyint] NOT NULL,
[HoldYN] [dbo].[bYN] NOT NULL,
[PayYN] [dbo].[bYN] NOT NULL,
[DiscOffered] [dbo].[bDollar] NOT NULL,
[DiscTaken] [dbo].[bDollar] NOT NULL,
[DueDate] [dbo].[bDate] NULL,
[Supplier] [dbo].[bVendor] NULL,
[VendorGroup] [dbo].[bGroup] NULL,
[Amount] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bAPWD_Amount] DEFAULT ((0)),
[UniqueAttchID] [uniqueidentifier] NULL,
[CompliedYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bAPWD_CompliedYN] DEFAULT ('Y'),
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   CREATE            trigger [dbo].[btAPWDd] on [dbo].[bAPWD] for DELETE as
     

/*-----------------------------------------------------------------
      *	Created : MV 11/5/01
      *	Modified : MV 2/1/5/02 - added update to APWH for DiscTaken
      * 		   MV 3/6/02 - added update to APWH for DiscOffered
      *            kb 5/13/2 - issue #14160
      *            kb 5/22/2 - issue #14160
      *				kb 7/30/2 - issue #18096 to not update discounts to APTD
      *				unless user either pays trans or makes change manually or 
      *				says they want to
      *			 MV 10/18/02 - 18878 quoted identifier cleanup
      *
      *	This trigger updates the corresponding APWH record when
      *	detail is deleted from APWD.
      *
      */----------------------------------------------------------------
     declare @errmsg varchar(255),@amount bDollar,
     	@holdyn bYN, @payyn bYN,@opencursor int,
     	@apco int, @userid varchar (30), @mth bDate,
     	@aptrans int, @apline int, @seq int, @disctaken bDollar,
        @discoffered bDollar, @validcnt int, @validcnt2 int
   
     set nocount on
   
     /* adjust header record only if it still exists */
   
       declare bcAPWDdelete cursor for
        select APCo, UserId, Mth,APTrans, APLine, APSeq,
          HoldYN, PayYN, Amount, DiscTaken, DiscOffered from deleted
   
        -- open APWD delete cursor
        open bcAPWDdelete
        select @opencursor = 1
   
        -- loop through all rows in update cursor
        APWDdelete_loop:
            fetch next from bcAPWDdelete into @apco, @userid, @mth, @aptrans, @apline, @seq,
              @holdyn,	@payyn, @amount, @disctaken, @discoffered
   
             if @@fetch_status = -1 goto delete_end
   
             if exists(select * from dbo.bAPWH (nolock) where APCo=@apco and Mth=@mth and APTrans=@aptrans)
               BEGIN
   
         	Update bAPWH set
     		UnpaidAmt = h.UnpaidAmt - case when @payyn = 'Y' then 0 else @amount end,
     		PayAmt = h.PayAmt - case when @payyn='Y' then @amount else 0 end,
     		DiscTaken = h.DiscTaken - case when @payyn='Y' then
           @disctaken else 0 end, DiscOffered = h.DiscOffered - @discoffered 
     		FROM bAPWH h WHERE h.APCo=@apco and h.Mth=@mth and h.APTrans=@aptrans 
   
             END
     -- if the remaining detail transactions are all onhold, reset flags in APWH
   
       SELECT @validcnt = count(*) FROM bAPWD h with (nolock) where h.APCo = @apco
         and h.Mth = @mth and h.APTrans = @aptrans and h.HoldYN = 'Y'
   
      SELECT @validcnt2 = count(*) FROM bAPWD h with (nolock)
       where h.APCo = @apco and h.Mth = @mth and h.APTrans = @aptrans
      IF @validcnt = @validcnt2 and @validcnt > 0
       begin
       Update bAPWH  set HoldYN = 'Y', PayYN = 'N' from bAPWH h
     	  where h.APCo = @apco and h.Mth = @mth and h.APTrans = @aptrans
       end
      else
       begin
       Update bAPWH  set HoldYN = 'N' from bAPWH h
     	  where h.APCo = @apco and h.Mth = @mth and h.APTrans = @aptrans
       end
      if exists(SELECT * FROM bAPWD h with (nolock) where h.APCo = @apco
         and h.Mth = @mth and h.APTrans = @aptrans and h.PayYN = 'Y')
           begin
           Update bAPWH  set PayYN = 'Y' from bAPWH h
         	  where h.APCo = @apco and h.Mth = @mth and h.APTrans = @aptrans
           end
   
     goto APWDdelete_loop
   
     delete_end:
     	if @opencursor=1
                begin
                close bcAPWDdelete
                deallocate bcAPWDdelete
             select @opencursor = 0
                end
   
   
   
   
     --Update PayYN flag in APWH if all remaining workfile detail records are now PayYN='N' and APWH PayYN = 'Y'.
     if not exists (select * FROM bAPWD t JOIN deleted d ON t.APCo=d.APCo and t.UserId=d.UserId and
     		t.Mth=d.Mth and t.APTrans=d.APTrans WHERE t.PayYN = 'Y')
     	BEGIN
     	Update bAPWH set PayYN = 'N'
     	FROM bAPWH h join deleted d on h.APCo=d.APCo and h.UserId=d.UserId and h.Mth=d.Mth
     	and h.APTrans=d.APTrans WHERE h.PayYN='Y'
     	END
   
   
     return
   
     error:
     	if @opencursor = 1
             	begin
         		close bcAPWDdelete
         		deallocate bcAPWDdelete
         		end
     	select @errmsg = @errmsg + ' - cannot delete AP Workfile Detail!'
         	RAISERROR(@errmsg, 11, -1);
         	rollback transaction
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   CREATE                                        trigger [dbo].[btAPWDi] on [dbo].[bAPWD] for INSERT as
       

/*-----------------------------------------------------------------
        *	Created : 11/8/01 MV
        *	Modified : MV 2/15/02 added disctaken amt to APWH
        *		   MV 3/6/02 added discoffered amt to APWH
        *          kb 5/14/2 - issue #14160
        *          kb 5/22/2 - issue #14160
        *          kb 5/28/2 - issue #14160
   	 * 			kb 7/24/2 - issue #18064 - need to update APTH when inserting APWH
   						because user may have changed stuff while inserting
       *			kb 7/30/2 - issue #18096 to not update discounts to APTD
     	*				unless user either pays trans or makes change manually or 
   	*				says they want to
   	*		 MV 10/18/02 - 18878 quoted identifier cleanup
   	*		ES 03/12/04 - #23061 isnull wrapping
   	*		MV 04/08/04 - #22940 don't update header payflag to Y if not in compliance/ performance enhancements
        *
        *	This trigger updates bAPWH (Payment Workfile Header)
        *	if inserted PayYN = Y
        *
        *
        */----------------------------------------------------------------
       declare @errmsg varchar(255), @numrows int, @validcnt int, @amount bDollar,
       	@vendorgroup bGroup, @supplier bVendor, @validcnt2 int, @onhold bYN,
      	@unpaidamt bDollar, @holdyn bYN, @payyn bYN, @opencursor int, @apco int,
      	@userid varchar(30), @mth bDate, @aptrans int, @apline int, @seq int,
        @disctaken bDollar, @discoffered bDollar, @cancelifdiscdate bDate, @discdate bDate,
		@compliedyn bYN
   
       select @numrows = @@rowcount
       if @numrows = 0 return
   
       set nocount on
   
       /* check Workfile Header */
       SELECT @validcnt = count(*) FROM bAPWH h
       	JOIN inserted i ON h.APCo = i.APCo and h.Mth = i.Mth
       		and h.APTrans = i.APTrans
       IF @validcnt <> @numrows
      	BEGIN
       	SELECT @errmsg = 'Workfile Header does not exist' + isnull(convert(varchar(5),@validcnt), '')
       	GOTO error
           	END
   
     declare bcAPWD cursor for
         select APCo, UserId, Mth,APTrans, APLine, APSeq, HoldYN, PayYN, Supplier, Amount,
     DiscTaken, DiscOffered, VendorGroup, CompliedYN from inserted
   
         -- open APWD inserted cursor
         open bcAPWD
         select @opencursor = 1
   
         -- loop through all rows in update cursor
         APWDinsert_loop:
             fetch next from bcAPWD into @apco, @userid, @mth, @aptrans, @apline, @seq, @holdyn,
      	@payyn, @supplier, @amount, @disctaken, @discoffered, @vendorgroup, @compliedyn
   
              if @@fetch_status = -1 goto insert_end
   
      -- get count of all detail recs
      SELECT @validcnt2 = count(*) FROM bAPWD h with (nolock)
       where h.APCo = @apco and h.Mth = @mth and h.APTrans = @aptrans

	  -- get count of on hold detail recs
      SELECT @validcnt = count(*) FROM bAPWD h with (nolock) where h.APCo = @apco and h.Mth = @mth
      	and h.APTrans = @aptrans and h.HoldYN = 'Y'

	  -- Update onhold flag in APWH if all workfile detail records are on hold.
      IF @validcnt = @validcnt2 and @validcnt > 0
       BEGIN
       Update bAPWH  set HoldYN = 'Y', PayYN = 'N' from bAPWH h
     	  where h.APCo = @apco and h.Mth = @mth and h.APTrans = @aptrans
     	END
      else
       begin
       Update bAPWH  set HoldYN = 'N' from bAPWH h
 		where h.APCo = @apco and h.Mth = @mth and h.APTrans = @aptrans
       end

	  -- if any detail is out-of-compliance update APWH.CompliedYN to 'N'
	  IF exists(select 1 FROM bAPWD h with (nolock) where h.APCo = @apco and h.Mth = @mth
      	and h.APTrans = @aptrans and h.CompliedYN='N')
       BEGIN
       select @compliedyn='N'
     	END
  
      Update bAPWH set
        UnpaidAmt = h.UnpaidAmt + case when @payyn= 'N' then @amount else 0 end,
        PayAmt = h.PayAmt + case when @payyn = 'Y' then @amount else 0 end,
        PayYN = case when @payyn = 'Y' then 'Y' else h.PayYN end,
	    CompliedYN = @compliedyn,
        DiscTaken = h.DiscTaken + case when @payyn = 'Y' then 
   	  case when ManualAddYN = 'Y' then 0 else @disctaken end else 0 end,
        DiscOffered = h.DiscOffered + case when @payyn = 'Y' then
   	  case when ManualAddYN = 'Y' then 0 else @discoffered end else 0 end
        FROM bAPWH h where h.APCo = @apco and h.Mth = @mth and h.APTrans = @aptrans
   
     	select @cancelifdiscdate = DiscCancelDate, @discdate = t.DiscDate
   	  from bAPWH w with (nolock) join bAPTH t with (nolock) on t.APCo=w.APCo and t.Mth=w.Mth and t.APTrans=w.APTrans
   	  where w.APCo = @apco and w.Mth = @mth and w.APTrans = @aptrans
   
   	/*now update APTD cause if made changes while inserting these need to go to APTD too*/
      	update bAPTD set DiscOffer = i.DiscOffered, DiscTaken = case when @cancelifdiscdate
   	 is null then i.DiscTaken else d.DiscTaken end,
   	  DueDate = i.DueDate, Supplier = @supplier, VendorGroup=@vendorgroup
   	 from bAPTD d with (nolock)
   	  JOIN inserted i on d.APCo=i.APCo and
     	  d.Mth=i.Mth and d.APTrans=i.APTrans and d.APLine=i.APLine and d.APSeq=i.APSeq
   	  where d.APCo = @apco and d.Mth = @mth and d.APTrans = @aptrans 
   	  and d.APLine = @apline and d.APSeq = @seq
   
      goto APWDinsert_loop
   
      insert_end:
      	if @opencursor=1
              begin
                 close bcAPWD
                 deallocate bcAPWD
                 select @opencursor = 0
                 end
   
       return
   
       error:
       if @opencursor=1
              begin
                 close bcAPWD
                 deallocate bcAPWD
                 select @opencursor = 0
                 end
       	select @errmsg = @errmsg + ' - cannot insert in Workfile Detail!'
           	RAISERROR(@errmsg, 11, -1);
           	rollback transaction
   
   
   
   
   
   
   
   
   
   
   
   
   
   
  
 




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   
   
   
   
   
   
   
   CREATE                                     trigger [dbo].[btAPWDu] on [dbo].[bAPWD] for UPDATE as
      

/*-----------------------------------------------------------------
       *	Created : 11/02/01 MV
       *	Modified : 2/15/02 MV Added update to APWH for changes to DiscTaken
       *		   3/6/02 MV added update to APWH for changes to DiscOffered
       *           5/13/2 kb - issue #14160
       *           5/22/2 kb - issue #14160
       *          kb 5/28/2 - issue #14160
       *				kb 7/30/2 - issue #18096 to not update discounts to APTD
     	*				unless user either pays trans or makes change manually or 
   	*				says they want to
       *			MV 10/18/02 - 18878 quoted identifier cleanup
       *			MV 07/06/04 - #24958 - update disctaken, discoffered in bAPWH if disc <> 0
       *	This trigger rejects update in bAPWD (Payment Workfile Detail)
       *	if any of the following error conditions exist:
       *
       *		Cannot change Co
       *		Cannot change Mth
       *		Cannot change APTrans
       *		Cannot change APLine
       *		Cannot change APSeq
       *
       *
       */----------------------------------------------------------------
      declare @errmsg varchar(255), @numrows int, @validcnt int, @amount bDollar,
      	@vendorgroup bGroup, @supplier bVendor, @validcnt2 int, @onhold bYN,
     	@unpaidamt bDollar, @holdyn bYN, @payyn bYN, @opencursor int, @apco int,
     	@userid varchar(30), @mth bDate, @aptrans int, @apline int, @seq int
   
      select @numrows = @@rowcount
      if @numrows = 0 return
   
      set nocount on
   
      if update(APCo) or update(Mth) or update(APTrans) or update(APLine) or update(APSeq)
      	begin
      	select @errmsg = 'Cannot change Primary Key'
      	goto error
      	end
   
     declare bcAPWD cursor for
        select APCo, UserId, Mth,APTrans, APLine, APSeq, HoldYN, PayYN,
        Supplier, VendorGroup from inserted
   
        -- open APWD inserted cursor
        open bcAPWD
        select @opencursor = 1
   
        -- loop through all rows in update cursor
        APWDupdate_loop:
            fetch next from bcAPWD into @apco, @userid, @mth, @aptrans, @apline, @seq, @holdyn,
     	@payyn, @supplier, @vendorgroup
   
             if @@fetch_status = -1 goto update_end
   
     -- if pay flag is changed update unpaid and paid amounts in APWH
     if update(PayYN)
         BEGIN
         Update bAPWH set
     		UnpaidAmt = h.UnpaidAmt - case when i.PayYN='Y' then t.Amount else -t.Amount end,
     		PayAmt = h.PayAmt + case when i.PayYN='Y' then t.Amount else -t.Amount end,
           DiscTaken = h.DiscTaken + case when i.PayYN = 'Y' then 
   		  i.DiscTaken else -i.DiscTaken end,
           DiscOffered = h.DiscOffered + case when i.PayYN = 'Y' then 
   		  i.DiscOffered else -i.DiscOffered end
     		FROM bAPWH h JOIN inserted i ON h.APCo = i.APCo and h.Mth = i.Mth and h.APTrans = i.APTrans
     	  	JOIN bAPTD t on t.APCo = i.APCo and t.Mth = i.Mth and t.APTrans = i.APTrans and t.APLine = i.APLine
     	  	and t.APSeq = i.APSeq
           JOIN deleted d on d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans = i.APTrans and d.APLine = i.APLine
     	  	and d.APSeq = i.APSeq
     		where h.APCo = @apco and h.Mth = @mth and h.APTrans = @aptrans and i.APLine=@apline and i.APSeq=@seq
           and d.PayYN <> i.PayYN
         END
   
    -- if Amount is updated, adjust Amount in APWH
    if update (Amount)
     	BEGIN
     	update bAPWH set
    	PayAmt = case w.PayYN when 'Y' then ((h.PayAmt- d.Amount) + i.Amount)else h.PayAmt end,
    	UnpaidAmt = case w.PayYN when 'N' then ((h.UnpaidAmt - d.Amount) + i.Amount) else h.UnpaidAmt end
    	from bAPWH h join inserted i on h.APCo = i.APCo and h.Mth = i.Mth and h.APTrans = i.APTrans
    	join deleted d on d.APCo=i.APCo and d.Mth=i.Mth and d.APTrans=i.APTrans and d.APLine=i.APLine
    	and d.APSeq=i.APSeq
    	join bAPWD w on w.APCo=i.APCo and d.Mth=i.Mth and w.APTrans=i.APTrans and w.APLine=i.APLine
    	and w.APSeq=i.APSeq
    	END
   
     -- do rest of updates
     if update(DiscOffered)
  
     	BEGIN
         	update bAPTD set DiscOffer = i.DiscOffered from bAPTD d JOIN inserted i on d.APCo=i.APCo and
   
     		d.Mth=i.Mth and d.APTrans=i.APTrans and d.APLine=i.APLine and d.APSeq=i.APSeq
           		where d.APCo = @apco and d.Mth = @mth and d.APTrans = @aptrans and d.APLine = @apline
           		and d.APSeq = @seq
   
     	--backout DiscOffered in header if deleted detail is paidyn='Y', Holdyn='N' and DiscOffered > 0
     	Update bAPWH set DiscOffered = (isnull(h.DiscOffered,0) - isnull(d.DiscOffered,0))
     		FROM bAPWH h JOIN deleted d ON h.APCo = d.APCo and h.Mth = d.Mth and h.APTrans = d.APTrans
     		Where d.APCo=@apco and d.Mth=@mth and d.APTrans=@aptrans and d.APLine=@apline and
     		d.APSeq=@seq and d.DiscOffered <> 0 --#24958
     	--update DiscOffered in header if inserted detail is paidyn='Y', Holdyn='N' and DiscOffered > 0
     	Update bAPWH set DiscOffered = (isnull(h.DiscOffered,0) + isnull(i.DiscOffered,0))
     		FROM bAPWH h JOIN inserted i ON h.APCo = i.APCo and h.Mth = i.Mth and h.APTrans = i.APTrans
     		Where i.APCo=@apco and i.Mth=@mth and i.APTrans=@aptrans and i.APLine=@apline and
     		i.APSeq=@seq and i.DiscOffered <>0 --#24958
     	END
   
     if update(DiscTaken)
     	BEGIN
     	Update bAPTD set DiscTaken = case when DiscCancelDate is null then isnull(i.DiscTaken,0)
   	  else d.DiscTaken end
   	  FROM bAPTD d JOIN inserted i on d.APCo=i.APCo and
     	  d.Mth=i.Mth and d.APTrans=i.APTrans and d.APLine=i.APLine and d.APSeq=i.APSeq
   	  left join bAPWH h on h.APCo = i.APCo and h.Mth = i.Mth and h.APTrans = i.APTrans 
     	  where d.APCo = @apco and d.Mth = @mth and d.APTrans=@aptrans and d.APLine=@apline
         and d.APSeq=@seq
   
     	--backout DiscTaken in header if deleted detail is paidyn='Y', Holdyn='N' and DiscTaken > 0
     	Update bAPWH set DiscTaken = (isnull(h.DiscTaken,0) - isnull(d.DiscTaken,0))
     		FROM bAPWH h JOIN deleted d ON h.APCo = d.APCo and h.Mth = d.Mth and h.APTrans = d.APTrans
     		Where d.APCo=@apco and d.Mth=@mth and d.APTrans=@aptrans and d.APLine=@apline and
     		d.APSeq=@seq and d.PayYN='Y' and d.HoldYN='N' and d.DiscTaken <> 0 --#24958
     	--update DiscTaken in header if inserted detail is paidyn='Y', Holdyn='N' and DiscTaken > 0
     	Update bAPWH set DiscTaken = (isnull(h.DiscTaken,0) + isnull(i.DiscTaken,0))
     		FROM bAPWH h JOIN inserted i ON h.APCo = i.APCo and h.Mth = i.Mth and h.APTrans = i.APTrans
     		Where i.APCo=@apco and i.Mth=@mth and i.APTrans=@aptrans and i.APLine=@apline and
     		i.APSeq=@seq and i.PayYN='Y'and i.HoldYN='N' and i.DiscTaken <>0 --#24958
   
     	END
   
     if update(DueDate)
     	BEGIN
     	Update bAPTD set DueDate = i.DueDate
     		FROM bAPTD d JOIN inserted i ON d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans=i.APTrans
     		and d.APLine=i.APLine and d.APSeq=i.APSeq where d.APCo=@apco and d.Mth=@mth and d.APTrans=@aptrans
     		and d.APLine=@apline and d.APSeq=@seq
     	END
   
     if update(Supplier)
     	BEGIN
     	if @supplier is not null
     		begin
     		select @validcnt = count(*) from bAPVM where Vendor = @supplier and VendorGroup = @vendorgroup
     		if @validcnt = 0
     			BEGIN
     			SELECT @errmsg = 'Supplier does not exist'
     			GOTO error
     	     		END
     		end
     	Update bAPTD set Supplier = @supplier, VendorGroup=@vendorgroup
     		FROM bAPTD d JOIN inserted i ON d.APCo = i.APCo and d.Mth = i.Mth and d.APTrans=i.APTrans
     		and d.APLine=i.APLine and d.APSeq=i.APSeq where d.APCo=@apco and d.Mth=@mth and d.APTrans=@aptrans
     		and d.APLine=@apline and d.APSeq=@seq
     	END
   
     -- Update onhold flag in APWH.
     SELECT @validcnt = count(*) FROM bAPWD h where h.APCo = @apco and h.Mth = @mth
     	and h.APTrans = @aptrans and h.HoldYN = 'Y'
   
     SELECT @validcnt2 = count(*) FROM bAPWD h where h.APCo = @apco and h.Mth = @mth
 
     	and h.APTrans = @aptrans
     	IF @validcnt = @validcnt2
     	    BEGIN
     		Update bAPWH  set HoldYN = 'Y', PayYN = 'N' FROM bAPWH h where h.APCo = @apco
     		and h.Mth = @mth and h.APTrans = @aptrans and h.HoldYN='N'
      	    END
     	ELSE
     	    BEGIN
     		Update bAPWH  set HoldYN = 'N' FROM bAPWH h where h.APCo = @apco
     		and h.Mth = @mth and h.APTrans = @aptrans and h.HoldYN='Y'
      	    END
   
     --Update PayYN flag in APWH if all workfile detail records are now PayYN='N' and APWH PayYN = 'Y'.
     SELECT @validcnt = count(*) FROM bAPWD h where h.APCo = @apco and h.Mth = @mth
     	and h.APTrans = @aptrans and h.PayYN = 'N'
   
     SELECT @validcnt2 = count(*) FROM bAPWD h where h.APCo = @apco and h.Mth = @mth
     	and h.APTrans = @aptrans
     	IF @validcnt = @validcnt2
     	    BEGIN
     		Update bAPWH  set PayYN = 'N' FROM bAPWH h where h.APCo = @apco
     		and h.Mth = @mth and h.APTrans = @aptrans and h.PayYN='Y'
      	    END
       else
     	    BEGIN
     		Update bAPWH  set PayYN = 'Y' FROM bAPWH h where h.APCo = @apco
     		and h.Mth = @mth and h.APTrans = @aptrans and h.PayYN='N' 
      	    END
   
     goto APWDupdate_loop
   
     update_end:
     	if @opencursor=1
                begin
                close bcAPWD
                deallocate bcAPWD
                select @opencursor = 0
                end
   
   
      return
   
      error:
      	if @opencursor = 1
             	begin
         		close bcAPWD
         		deallocate bcAPWD
         		end
     	select @errmsg = @errmsg + ' - cannot update Workfile Detail!'
          	RAISERROR(@errmsg, 11, -1);
          	rollback transaction
   
   
   
   
   
   
   
   
   
   
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biAPWD] ON [dbo].[bAPWD] ([APCo], [Mth], [APTrans], [APLine], [APSeq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [biAPWD_UserId] ON [dbo].[bAPWD] ([APCo], [UserId]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bAPWD] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPWD].[HoldYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPWD].[PayYN]'
GO
