CREATE TABLE [dbo].[bGLAS]
(
[GLCo] [dbo].[bCompany] NOT NULL,
[GLAcct] [dbo].[bGLAcct] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[Jrnl] [dbo].[bJrnl] NOT NULL,
[GLRef] [dbo].[bGLRef] NOT NULL,
[SourceCo] [dbo].[bCompany] NOT NULL,
[Source] [dbo].[bSource] NOT NULL,
[NetAmt] [dbo].[bDollar] NOT NULL,
[Adjust] [dbo].[bYN] NULL,
[Purge] [dbo].[bYN] NOT NULL,
[udSource] [varchar] (305) COLLATE Latin1_General_BIN NULL,
[udConv] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[udCGCTable] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[udCGCTableID] [decimal] (12, 0) NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

   /****** Object:  Trigger dbo.btGLASd    Script Date: 8/28/99 9:37:27 AM ******/
CREATE   TRIGGER [dbo].[btGLASd] ON [dbo].[bGLAS]
    FOR DELETE
AS
/*-----------------------------------------------------------------
* Created: ??
* Modified: GG 5/14/98
*           GG 06/06/00 - Removed cursor
*			 MV 06/24/03 - #21567 - improve check for GL Detail
*			AR 2/10/11 143291 - replacing some of trigger code with FKs
*
*	Delete trigger on bGLAS (Acct Summary) used to backout adjustment amounts
*	from bGLYB (Fiscal Year Balances) and non adjustment amounts from
*	bGLBL (Account Balances).
*	Amounts are NOT backed out if Purge flag is set.
*	Delete is rolled back if bGLDT (Detail) exists for the GL Co#, Mth, GL Account,
*	Journal, GL Reference, Source Co#, and Source - must purge first.
*
*/----------------------------------------------------------------
DECLARE @errmsg varchar(255),
	    @numrows int
   
SELECT  @numrows = @@rowcount
IF @numrows = 0 
    RETURN
   
SET nocount ON
   
   /* check for GL Detail - must be purged first */
   /*if exists(select * from bGLDT s, deleted d where s.GLCo = d.GLCo and s.GLAcct = d.GLAcct and
   	s.Mth = d.Mth and s.Jrnl = d.Jrnl and s.GLRef = d.GLRef and s.SourceCo = d.SourceCo and
   	s.Source = d.Source)
   	begin
   	select @errmsg = 'GL Detail exists'
   	goto error
   	end*/
	-- 143291 replaced GLAS constraint wtih FK   
  
   /* back out of Yearly Net Adjustments */
UPDATE  bGLYB
SET     NetAdj = NetAdj - d.NetAmt
FROM    bGLYB y
        JOIN deleted d ON y.GLCo = d.GLCo
                          AND y.FYEMO = d.Mth
                          AND y.GLAcct = d.GLAcct
WHERE   d.Adjust = 'Y'
        AND d.Purge = 'N'
   
   /* back out of Monthly Net Activity */
UPDATE  bGLBL
SET     NetActivity = NetActivity - d.NetAmt,
        Debits = Debits - CASE WHEN d.NetAmt > 0 THEN d.NetAmt
                               ELSE 0
                          END,
        Credits = Credits - CASE WHEN d.NetAmt < 0 THEN ABS(d.NetAmt)
                                 ELSE 0
                            END    -- stored as positive
FROM    bGLBL b
        JOIN deleted d ON b.GLCo = d.GLCo
                          AND b.GLAcct = d.GLAcct
                          AND b.Mth = d.Mth
WHERE   d.Adjust = 'N'
        AND d.Purge = 'N'
   
RETURN
/*
error:
SELECT  @errmsg = @errmsg + ' - cannot delete Account Summary!'
RAISERROR(@errmsg, 11, -1);
ROLLBACK TRANSACTION
*/      
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btGLASi    Script Date: 8/28/99 9:38:21 AM ******/
   CREATE   trigger [dbo].[btGLASi] on [dbo].[bGLAS] for INSERT as
   

/*-----------------------------------------------------------------
    * Created: ??
    * Modified: GG 5/14/98
    *           GG 06/06/00 - Fix to update bGLBL, debits and credits
    *		DC 5/15/03 #20464
    *			AR 2/10/11 143291 - replacing some of trigger code with FKs
    *
    *	This trigger rejects insertion in bGLAS (Acct Summaries) if
    *	any of the following error conditions exist:
    *
    *		Invalid GL Account
    *		Heading Account
    *		Inactive Account
    *		Invalid Journal
    *		Invalid Source Company
    *		Flagged for purge
    *		Adjustments must be posted to  a Fiscal Year ending month
    *		Adjustment flags in GL Reference and Account Summary must
    *			match
    *
    *	Inserts GL Reference if not found.
    *	Inserts or updates GL acct balances.
    */----------------------------------------------------------------
   declare @accttype char(1), @active bYN, @adj bYN, @amt bDollar, @co bCompany, @errmsg varchar(255),
   	@errno int, @glacct bGLAcct, @glco bCompany, @glref bGLRef, @glrefadj bYN, @jrnl bJrnl,
   	@mth bMonth, @numrows int, @purge bYN, @opencursor tinyint, @debit bDollar, @credit bDollar,
   	@refdesc bDesc  -- DC Issue 20464
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   select @opencursor = 0
   
   /* use a cursor to process each inserted row */
   declare bGLAS_insert cursor for
   select GLCo, GLAcct, Mth, Jrnl, GLRef, SourceCo, NetAmt, Adjust, Purge
   from inserted
   
   open bGLAS_insert
   select @opencursor = 1
   
   next_row:
   	fetch next from bGLAS_insert into @glco, @glacct, @mth, @jrnl, @glref,
   		@co, @amt, @adj, @purge
   
   	if @@fetch_status = -1 goto end_row
   	if @@fetch_status <> 0 goto next_row
   
   	/* validate GL Account */
   	select @accttype = AcctType, @active = Active from bGLAC
   		where GLCo = @glco and GLAcct = @glacct
   		
	-- 143291 - replaced by FK now   		
   	if @accttype = 'H'
   		begin
   		select @errmsg = 'Heading Account'
   		goto error
   		end
   	if @active = 'N'
   		begin
   		select @errmsg = 'Inactive Account'
   		goto error
   		end
   
   	/* validate Journal */
   	exec @errno = bspGLJrnlVal @glco, @jrnl, @errmsg output
   	if @errno <> 0 goto error
   
   	/* validate Source Company */
   	exec @errno = bspHQCompanyVal @co, @errmsg output
   	if @errno <> 0 goto error
   
   	/* purge flag must be 'N' */
   	if @purge <> 'N'
   		begin
   		select @errmsg = 'Flagged for purge'
   		goto error
   		end
   
   	/* if adjustment - validate month */
   	if @adj = 'Y'
   		begin
   		if not exists(select * from bGLFY where GLCo = @glco and FYEMO = @mth)
   			begin
   			select @errmsg = 'Adjustments must be posted to  a Fiscal Year ending month'
   			goto error
   			end
   		end
   --  DC ISSUE 20464 --START ---------------------------------
   --  Get the description to insert into bGLRF
   	select top 1 @refdesc = Description
   	from bGLDB
   	where Co = @glco and Mth = @mth and Jrnl = @jrnl and GLRef = @glref
   -- DC -------------- END ---------------------------------------------------
   
   	/* insert GL Reference if not found - check adjustment flags */
   	select @glrefadj = Adjust from bGLRF
   		where GLCo = @glco and Mth = @mth and Jrnl = @jrnl and GLRef = @glref
   	if @@rowcount = 0
   		begin
   		insert bGLRF (GLCo, Mth, Jrnl, GLRef, Description, Adjust, Notes)
   		values (@glco, @mth, @jrnl, @glref, @refdesc, @adj, null)
   		end
   	else
   	if @glrefadj <> @adj
   		begin
   		select @errmsg = 'Adjustment flags in GL Reference and Account Summary must match'
   		goto error
   		end
   
   	/* insert or update GL Balances */
   	if @adj = 'Y'
   		begin
   		update bGLYB
   		set NetAdj = NetAdj + @amt
   			where GLCo = @glco and FYEMO = @mth and GLAcct = @glacct
   		if @@rowcount = 0
   			begin
   			insert bGLYB (GLCo, FYEMO, GLAcct, BeginBal, NetAdj, Notes)
   			values (@glco, @mth, @glacct, 0, @amt, null)
   			end
   		end
   	else
   		begin
   		update bGLBL
   		set NetActivity = NetActivity + @amt,
   		    Debits = Debits + Case when @amt>0 then @amt else 0 end,
   		    Credits = Credits + Case when @amt<0 then abs(@amt) else 0 end
   			where GLCo = @glco and GLAcct = @glacct and Mth = @mth
   		if @@rowcount = 0
   			begin
               select @debit = Case when @amt > 0 then @amt else 0 end
               select @credit = Case when @amt < 0 then abs(@amt) else 0 end
   			insert bGLBL (GLCo, GLAcct, Mth, NetActivity, Debits, Credits)
   			values (@glco, @glacct, @mth, @amt, @debit, @credit)
   			end
   		end
   
   	goto next_row
   
   end_row:
   	close bGLAS_insert
   	deallocate bGLAS_insert
   	select @opencursor = 0
   
   return
   
   error:
   	if @opencursor = 1
   		begin
   		close bGLAS_insert
   
   		deallocate bGLAS_insert
   		end
   
       	select @errmsg = @errmsg + ' - cannot insert Account Summary entry!'
       	RAISERROR(@errmsg, 11, -1);
       	rollback transaction
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btGLASu    Script Date: 8/28/99 9:37:27 AM ******/
   CREATE  trigger [dbo].[btGLASu] on [dbo].[bGLAS] for UPDATE as
   

/*-----------------------------------------------------------------
    * Created: ??
    * Modified: GG 5/14/98
    *
    *	This trigger rejects update in bGLAS (Acct Summary) if any
    *	of the following error conditions exist:
    *
    *		Cannot change GL Company
    *		Cannot change GL Account
    *		Cannot change Month
    *		Cannot change Journal
    *		Cannot change GL Reference
    *		Cannot change Source Company
    *		Cannot change Source
    *		Cannot change Adjustment flag
    *		Missing Fiscal Year Balance entry
    *		Missing Monthly Balance entry
    *	
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @glacct bGLAcct, @glco bCompany, 
   	@glref bGLRef, @mth bMonth, @newadj bYN, @newamt bDollar,
   	@numrows int, @oldadj bYN, @oldamt bDollar, @opencursor tinyint,
   	@validcount int , @count2 int
   
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   select @opencursor = 0 
   
   /*check for changes to keys */
   select @validcount = count(*) from deleted d, inserted i
   	where d.GLCo = i.GLCo and d.GLAcct = i.GLAcct and d.Mth = i.Mth and
   	d.Jrnl = i.Jrnl and d.GLRef = i.GLRef and d.SourceCo = i.SourceCo and d.Source = i.Source
   if @numrows <> @validcount	
   	begin
   	select @errmsg = 'Cannot change GL Company, GL Account, Month, Journal, GL Ref, Source Company, or Source'
   	goto error
   	end
   	
   /* use a cursor to process each updated row */
   declare bGLAS_update cursor for select i.GLCo, i.GLAcct, i.Mth, i.GLRef,
   	OldNetAmt = d.NetAmt, NewNetAmt = i.NetAmt, OldAdjust = d.Adjust, NewAdjust = i.Adjust
   from deleted d, inserted i
   where d.GLCo = i.GLCo and d.GLAcct = i.GLAcct and d.Mth = i.Mth and d.Jrnl = i.Jrnl and
   	d.GLRef = i.GLRef and d.SourceCo = i.SourceCo and d.Source = i.Source
   
   open bGLAS_update
   select @opencursor = 1
   
   next_row:
   	fetch next from bGLAS_update into @glco, @glacct, @mth, @glref, @oldamt, @newamt, @oldadj, @newadj
   
   	if @@fetch_status = -1 goto end_row
   	if @@fetch_status <> 0 goto next_row
   
   	/* check for changes to adjustment flag */
   	if @oldadj <> @newadj
   		begin
   
   		select @errmsg = 'Cannot change Adjustment flag'
   		goto error
   		end
   			
   	/* update Fiscal Year Net Adj or GL Balances */
   	if @newadj = 'Y'
   		begin
   		update bGLYB
   		set NetAdj = NetAdj - @oldamt + @newamt
   		where GLCo = @glco and FYEMO = @mth and GLAcct = @glacct
   		if @@rowcount = 0
   			begin
   			select @errmsg = 'Missing Fiscal Year Balance entry'
   			goto error
   			end
   		end
   	else
   		begin
   		update bGLBL
   		set NetActivity = NetActivity - @oldamt + @newamt,
   		    Debits = Debits - Case when @oldamt>0 then @oldamt else 0 end
                                       + Case when @newamt>0 then @newamt else 0 end,
   		    Credits = Credits - Case when @oldamt<0 then abs(@oldamt) else 0 end 
   				      + case when @newamt<0 then abs(@newamt) else 0 end 
   		where GLCo = @glco and GLAcct = @glacct and Mth = @mth
   		if @@rowcount = 0
   			begin
   			select @errmsg = 'Missing Monthly Balance entry'
   			goto error
   			end 
   		end
   			
   	goto next_row
   
   end_row:	
   	close bGLAS_update
   	deallocate bGLAS_update
   	select @opencursor = 0
   	
   return
   
   error:
   	if @opencursor = 1
   		begin
   		close bGLAS_update
   		deallocate bGLAS_update
   		end
   
   	select @errmsg = @errmsg + ' - cannot update Account Summary entry!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biGLAS] ON [dbo].[bGLAS] ([GLCo], [GLAcct], [Mth], [Jrnl], [GLRef], [SourceCo], [Source]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [viGLAS1] ON [dbo].[bGLAS] ([GLCo], [Mth], [Jrnl], [GLRef]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_bGLAS_Mth] ON [dbo].[bGLAS] ([Mth]) INCLUDE ([GLAcct], [GLCo], [NetAmt]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bGLAS].[Adjust]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bGLAS].[Purge]'
GO
