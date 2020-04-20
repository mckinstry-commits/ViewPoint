CREATE TABLE [dbo].[bGLAC]
(
[GLCo] [dbo].[bCompany] NOT NULL,
[GLAcct] [dbo].[bGLAcct] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[AcctType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[SubType] [char] (1) COLLATE Latin1_General_BIN NULL,
[NormBal] [char] (1) COLLATE Latin1_General_BIN NULL,
[InterfaceDetail] [dbo].[bYN] NOT NULL,
[Active] [dbo].[bYN] NOT NULL,
[SummaryAcct] [dbo].[bGLAcct] NOT NULL,
[CashAccrual] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bGLAC_CashAccrual] DEFAULT ('A'),
[CashOffAcct] [dbo].[bGLAcct] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[Part1] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[Part2] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[Part3] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[Part4] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[Part5] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[Part6] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[AllParts] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[CrossRefMemAcct] [dbo].[bGLAcct] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[ReviewerGroup] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[udActive] [char] (1) COLLATE Latin1_General_BIN NULL,
[udSource] [varchar] (305) COLLATE Latin1_General_BIN NULL,
[udConv] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[udCGCTable] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[udCGCTableID] [decimal] (12, 0) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
   
   
   
   /****** Object:  Trigger dbo.btGLACd    Script Date: 8/28/99 9:37:26 AM ******/
     CREATE            trigger [dbo].[btGLACd] on [dbo].[bGLAC] for DELETE as
     

/*-----------------------------------------------------------------
      * Created: 	???
      * Modified: 	GG  07/13/1999
      *			GG  12/03/2001 - #15458 - correct account deletion logic
      *			MV  08/15/2003 - #22020 - delete Part from bGLPI if no longer needed.
      *			GWC 06/29/2004 - #24865 - updated trigger from 5.81 release to the 5.9 db
      *									  (it was lost between releases)
      *									  commented out code for Issue 22020 and introduced
      *									  new code to delete Part from bGLPI if no longer needed.
      *			GP 05/05/2009 - #131185 - added validation for summary accounts and changed GLPI delete.
      *			AR 2/10/2011  - #143291 - adding foreign keys, removing trigger look ups
      *
      *	This trigger rejects delete in bGLAC (GL Accts) if any of
      *	the following error conditions exist:
      *
      *		Detail exists
      *		Non-zero Account Summary exists
      *		Non-zero Monthly Balances exist
      *		Used as an Intercompany Account
      *		Non-zero Monthly Budgets exist
      *		Non-zero Fiscal Year Balances exist
      *		Used in Auto Journal Entries
      *
      *	Adds HQ Master Audit entry if AuditAccts in bGLCO is 'Y'
      */----------------------------------------------------------------
     declare @errmsg varchar(255), @numrows int, @co int, @part varchar (20),
     	@part1 varchar (20),@part2 varchar (20),@part3 varchar (20),@part4 varchar (20),
     	@part5 varchar (20), @part6 varchar (20), @i int
     select @numrows = @@rowcount, @i=1
     if @numrows = 0 return
     set nocount on
		   
     -- check GL Detail
     -- 143291 - replacing check with FK constraint

     -- check for non-zero Account Summary by GL Co#, Account, and Mth
     if exists(select s.GLCo, s.GLAcct, s.Mth, sum(s.NetAmt) from deleted d
     			join bGLAS s on s.GLCo = d.GLCo and s.GLAcct = d.GLAcct
     			group by s.GLCo, s.GLAcct, s.Mth
     			having sum(s.NetAmt) <> 0)
     	begin
     	select @errmsg = 'Non-zero Account Summary exists'
     	goto error
     	end
     /* check for non-zero Monthly Balances */
     if exists(select * from deleted d join bGLBL g on g.GLCo = d.GLCo and g.GLAcct = d.GLAcct
     			where g.NetActivity <> 0)
     	begin
     	select @errmsg = 'Non-zero Monthly Balances exist'
     	goto error
     	end
     	
     /* check Intercompany Accounts */
     -- 143291 - replacing check with FK constraint
     
     /* check Monthly Budgets */
     if exists (select * from deleted d join bGLBD g on g.GLCo = d.GLCo and g.GLAcct = d.GLAcct
     			where g.BudgetAmt <> 0)
     	begin
     	select @errmsg = 'Non-zero Monthly Budgets exist'
     	goto error
     	end
     /* check Fiscal Year Balances */
     if exists (select * from deleted d join bGLYB g on g.GLCo = d.GLCo and g.GLAcct = d.GLAcct
     			where (g.BeginBal <> 0 or g.NetAdj <> 0))
     	begin
     	select @errmsg = 'Non-zero Fiscal Year Balances exist'
     	goto error
     	end
     
     /* check Auto Journal Entries */
     if exists (select * from deleted d,bGLAJ g where g.GLCo = d.GLCo and (g.SourceAcct = d.GLAcct or
     	g.RatioAcct1 = d.GLAcct or g.RatioAcct2 = d.GLAcct or g.PostToGLAcct = d.GLAcct))
     	begin
     	select @errmsg = 'Used in an Auto Journal Entry'
     	goto error
     	end
   	/* 131185 check Summary Accounts */     	
	if exists (select top 1 1 from bGLAC g join deleted d on d.GLCo=g.GLCo and d.GLAcct=g.SummaryAcct
		where d.KeyID <> g.KeyID)
		begin
		select @errmsg = 'GL Account exists as a Summary Account'
		goto error
		end      
     
     -- Account passing the above checks may have Budgets and/or Beginning Balances that must be deleted
     -- remove Budget Detail
     delete bGLBD from deleted d,bGLBD g where g.GLCo = d.GLCo and g.GLAcct = d.GLAcct
     -- remove Budget Revisions
     delete bGLBR from deleted d,bGLBR g where g.GLCo = d.GLCo and g.GLAcct = d.GLAcct
     -- remove Account Summary (should be zero entries only)
     delete bGLAS from deleted d join bGLAS s on s.GLCo = d.GLCo and s.GLAcct = d.GLAcct
     --remove Monthly Balances (should be zero entries only)
     delete bGLBL from deleted d join bGLBL g on g.GLCo = d.GLCo and g.GLAcct = d.GLAcct
     -- remove Beginning Balance (should be zero entries only)
     delete bGLYB from deleted d join bGLYB g on g.GLCo = d.GLCo and g.GLAcct = d.GLAcct
     
    /* GWC: Removed code and added new delete code below.
     -- #22020 - Delete from bGLPI if the deleted rec's Parts are not a part in any other GLAcct . 
     if @numrows = 1	--just in case somehow more than one GLAcct gets deleted.
     begin
     	select @co = GLCo, @part1 = Part1, @part2 =Part2, @part3=Part3,
     		 @part4=Part4, @part5 = Part5, @part6=Part6 from deleted
     	select @part = rtrim(ltrim(@part1))
     	while @i < 7 and isnull(@part,'') <> ''
     	begin
     		--delete this part if no longer used in any other GLAcct's parts
     		if not exists( select top 1 1 from bGLAC WITH (NOLOCK)
     			where GLCo = @co and
     				(rtrim(ltrim(Part1)) = @part or rtrim(ltrim(Part2)) = @part or
     				 rtrim(ltrim(Part3)) = @part or rtrim(ltrim(Part4)) = @part or
     				 rtrim(ltrim(Part5)) = @part or rtrim(ltrim(Part6)) = @part))
     			begin
     			delete from bGLPI where GLCo=@co and PartNo = 1 and rtrim(ltrim(Instance)) = @part
     			end
     		-- get next part to test
     		select @i= @i + 1
     		select @part = case when @i = 2 then @part2 else case when @i=3 then @part3 else
     			 case when @i=4 then @part4 else case when @i= 5 then @part5 else case when @i=6 then @part6
     				else '' end end end end end 
     		-- trim off any leading or trailing spaces
     		if @part is not null select @part = rtrim(ltrim(@part))
     	end
     end 
    */
     
     --#24865: Delete all records in bGLPI that do not have a corresponding Part1 in bGLAC
    -- SELECT @co = GLCo FROM deleted
   
    -- DELETE FROM bGLPI WHERE PartNo = 1 AND GLCo = @co AND Instance NOT IN 
   	--(SELECT DISTINCT p.Instance FROM bGLPI p 
   	--INNER JOIN bGLAC a ON p.GLCo = a.GLCo AND p.Instance = a.Part1
   	--WHERE p.PartNo = 1 AND a.GLCo = @co)
   	
   	--131185
   	delete dbo.bGLPI
   	from dbo.bGLPI i join deleted d on d.GLCo = i.GLCo and d.Part1 = i.Instance and i.PartNo = 1
   	where not exists(select top 1 1 from dbo.bGLAC a where a.GLCo = d.GLCo and a.Part1 = d.Part1)
   
     /* Audit GL Account deletions */
     insert into bHQMA
         (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
     select 'bGLAC', 'GL Acct: ' + d.GLAcct,	d.GLCo, 'D', null, null, null, getdate(), SUSER_SNAME()
     from deleted d, bGLCO c
     where d.GLCo = c.GLCo and c.AuditAccts = 'Y'
     return
     
     error:
     	select @errmsg = isnull(@errmsg,'') +  ' - unable to delete GL Account!'
     	RAISERROR(@errmsg, 11, -1);
     	rollback transaction
     
     
     
     
     
     
     
     
     
    
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*********************************************/
CREATE trigger [dbo].[btGLACi] on [dbo].[bGLAC] for INSERT as
/*-----------------------------------------------------------------
* Created: ????
* Modified: GG     09/29/1998 
*           GG     04/10/2001 - added Account Type and Subledger Type validation
*			 EN     12/27/2001 - issue 15318 - added validation for Cross Ref Memo Acct
*			 allenn 05/14/2002 - issue 17322 - change validation message to include account numbers
*			 allenn 07/03/2002 - issue 17322 - changed condition for validating copying of crossrefmemacct 
*							   	 and fixed initialization of it's variable for the cursor
*      	 danf   09/23/2002 - issue 18657 - added crossrefmemacct to second fetch next to match the first fetch.
*			 MV     02/13/2003 - #20144 rej 1 - added 'copying terminated' to error msg.
*			 danf   03/06/2003 - #20619 - correct insert statement for table GLPI.
*			 GWC    06/23/2004 - #24865 - added ISNULLs so Part1-6 and AllParts columns are populated with correct data.
* 		 	  DANF 03/15/05 - #27294 - Remove scrollable cursor.
*           JRE  07/26/05 - #27905   Use bFRXAcct datatype if exists else bGLAcct
*			GG - 5/2/07 - V6 mods for DD changes
*			GG 02/29/08 - #127031 - fix for bFRXAcct
*			AR 2/4/2011  - #143291 - adding foreign keys, removing trigger look ups
*
*
*	This trigger rejects insertion in bGLAC (GL Acct) if any of
*	the following error conditions exist:
*		Invalid GL Company
*		Invalid Summary Account
*		Cash/Accrual option not used in this GL Company
*		Accrual accounts cannot have offset accounts
*		Invalid Cash Offset Account
*		Missing GL Company
*
*	Adds HQ Master Audit entry.
*/----------------------------------------------------------------
   declare @audit bYN, @ca char(1), @co bCompany, @date bDate, @errmsg varchar(255), @errno int,
   	@field char(30), @glacct bGLAcct, @glco bCompany, @glcoca char(1), @key varchar(60),
   	@new varchar(30), @numrows int, @offacct bGLAcct, @offca char(1), @old varchar(30),
   	@rectype char(1), @sumacct bGLAcct, @tablename char(20), @user bVPUserName,
   	@p1 varchar(4), @p2 varchar(4), @p3 varchar(4),	@p4 varchar(4), @p5 varchar(4), @p6 varchar(4),
   	@s1 tinyint, @s2 tinyint, @s3 tinyint, @s4 tinyint, @s5 tinyint, @start tinyint,
   	@mask varchar(20), @i tinyint, @char char(1), @pno tinyint, @inputtype tinyint, @validcnt int,
   	@crossrefmemacct bGLAcct, @xrefacc bGLAcct, --issue 15318 - added @crossrefmemacct/@xrefacc to declare list
   	@datatype varchar(10) -- issue 27905
   
select @numrows = @@rowcount
if @numrows = 0 return

set nocount on

-- validate Account Type 
--143291 -	 handled by check constraint now

-- validate Subledger Type
--143291 -	 handled by check constraint now
   
/* get mask for GL Account datatype */
-- if bFRXAcct type exists with a non-null mask use it for account parts
select @inputtype = InputType, @mask = InputMask
from dbo.DDDTShared (nolock) where Datatype = 'bFRXAcct'  -- #127031
if @@rowcount = 0 or @mask is null
	begin
	select @inputtype = InputType, @mask = InputMask 
	from dbo.DDDTShared with (nolock) where Datatype = 'bGLAcct' 
	if @@rowcount = 0
		begin
		select @errmsg = 'Missing datatype (bGLAcct) in DD Datatypes'
		goto error
		end
	end
	
if @inputtype = 5	/* hardcoded Input Type */
   	begin
   	select @i = 1, @pno = 1, @s1 = 0, @s2 = 0, @s3 = 0, @s4 = 0, @s5 = 0
   	/* parse GL Account input mask - get each parts # of chars and flag if separator used */
   	while @i < datalength(@mask)
   		begin
   		select @char = substring(@mask,@i,1)
 
   		if @char like '[0-9]'
   			begin
   			if @pno = 1  select @p1 = isnull(@p1,'') + isnull(@char,'')
   			if @pno = 2  select @p2 = isnull(@p2,'') + isnull(@char,'')
   			if @pno = 3  select @p3 = isnull(@p3,'') + isnull(@char,'')
   			if @pno = 4  select @p4 = isnull(@p4,'') + isnull(@char,'')
   			if @pno = 5  select @p5 = isnull(@p5,'') + isnull(@char,'')
   			if @pno = 6  select @p6 = isnull(@p6,'') + isnull(@char,'')
   			end
   		else
   		if @char not like '[0-9,L,R,F]'
   			begin
   			if @char <> 'N'
   				begin
   				if @pno = 1 select @s1 = 1
   				if @pno = 2 select @s2 = 1
   				if @pno = 3 select @s3 = 1
   				if @pno = 4 select @s4 = 1
   				if @pno = 5 select @s5 = 1
   				end
   			select @pno = @pno + 1
   			end
   		select @i = @i + 1
   		end
   	end
   if @numrows = 1
   	select @glco = GLCo, @glacct = GLAcct, @sumacct = SummaryAcct, @ca = CashAccrual,
   		@offacct = CashOffAcct, @crossrefmemacct = CrossRefMemAcct from inserted
   else
   	begin
   	/* use a cursor to process each inserted row */
   	declare bGLAC_insert cursor local fast_forward for select GLCo, GLAcct, SummaryAcct, CashAccrual, CashOffAcct, CrossRefMemAcct from inserted
   	open bGLAC_insert
   	fetch next from bGLAC_insert into @glco, @glacct, @sumacct, @ca, @offacct, @crossrefmemacct --issue 15318 - added @crossrefmemacct
   	if @@fetch_status <> 0
   		begin
   		select @errmsg = 'Cursor error'
   		goto error
   		end
   	end
   insert_check:
   	/* validate GL Company, get CashAccrual and Audit Accounts options */
   	select @glcoca = CashAccrual, @audit = AuditAccts from bGLCO with (nolock) where GLCo = @glco
   	--	 #142311 -- replacing with an FK
   	
   	/* validate Summary Account */
   	if @glacct <> @sumacct
   		begin
   		exec @errno = bspGLAcctVal @glco, @sumacct, @errmsg output
   		if @errno <> 0
   			begin
   			select @errmsg = 'Invalid Summary Account'
   			goto error
   			end
   		end
   	/* validate CashAccrual info */
   	if @glcoca = 'A' and @ca <> 'A'
   		begin
   		select @errmsg = 'This GL Company requires all Accounts to be accrual based'
   		goto error
   		end
   	if @glcoca = 'A' and @offacct is not null
   		begin
   		select @errmsg = 'This GL Company does not use Offset Accounts'
   		goto error
   		end
   	if @ca = 'C' and @offacct is null
   		begin
   		select @errmsg = 'Cash basis accounts require Offset Accounts'
   		goto error
   		end
   	if @offacct = @glacct
   		begin
   		select @errmsg = 'Offset Account cannot match GL Account'
   		goto error
   		end
   	/* if Offset Account is valid, must be different type */
   	if @offacct is not null
   		begin
   		select @offca = CashAccrual from bGLAC with (nolock) where GLCo = @glco and GLAcct = @offacct
   		if @@rowcount = 1
   			begin
   			if @offca = @ca
   				begin
   				select @errmsg = 'Cash accounts must be offset by Accrual'
   				goto error
   				end
   			end
   		end
   	-- issue 15318 - validate Cross Reference Memo Acct
   	-- issue 17322 - change validation message to include account numbers
   	if @crossrefmemacct is not null
   		begin
   		if not exists(select * from bGLAC with (nolock) where GLCo = @glco and GLAcct = @crossrefmemacct)
   		--if @@rowcount = 1
   			begin
               select @errmsg = 'Cross Ref Memo Account ' + convert(varchar(50),@crossrefmemacct) + ' is not valid, see account ' + convert(varchar(50),@glacct)
   			goto error
   			end
   		end
   	/* update GL Account Parts */
   	if @p1 is not null
   		begin
   		update bGLAC set Part1 = substring(@glacct,1,convert(tinyint,@p1)) from bGLAC
   			where GLCo = @glco and GLAcct = @glacct
   		if @@rowcount <> 1 goto parts_update_error
   		select @start = 1 + convert(tinyint,@p1) + @s1
   
                   /* add into GLPI if not exists */
   		if not exists (select * from bGLPI with (nolock) where GLCo = @glco and PartNo = 1
   			and Instance=substring(@glacct,1,convert(tinyint,@p1)))
   			begin
   			insert bGLPI (GLCo, PartNo, Instance, Description)
   			select GLCo, 1, Part1, Description from bGLAC 
   			 where GLCo = @glco and GLAcct = @glacct
   			end
   		end
   
   	if @p2 is not null
   		begin
   		update bGLAC set Part2 = substring(@glacct,@start,convert(tinyint,@p2)) from bGLAC
   			where GLCo = @glco and GLAcct = @glacct
   		if @@rowcount <> 1 goto parts_update_error
   		select @start = @start + convert(tinyint,@p2) + @s2
   		end
   	if @p3 is not null
   		begin
   		update bGLAC set Part3 = substring(@glacct,@start,convert(tinyint,@p3)) from bGLAC
   			where GLCo = @glco and GLAcct = @glacct
   		if @@rowcount <> 1 goto parts_update_error
   		select @start = @start + convert(tinyint,@p3) + @s3
   		end
   	if @p4 is not null
   		begin
   		update bGLAC set Part4 = substring(@glacct,@start,convert(tinyint,@p4)) from bGLAC
   			where GLCo = @glco and GLAcct = @glacct
   		if @@rowcount <> 1 goto parts_update_error
   		select @start = @start + convert(tinyint,@p4) + @s4
   		end
   	if @p5 is not null
   		begin
   		update bGLAC set Part5 = substring(@glacct,@start,convert(tinyint,@p5)) from bGLAC
   			where GLCo = @glco and GLAcct = @glacct
   		if @@rowcount <> 1 goto parts_update_error
   		select @start = @start + convert(tinyint,@p5) + @s5
   		end
   	if @p6 is not null
   		begin
   		update bGLAC set Part6 = substring(@glacct,@start,datalength(@glacct)) from bGLAC
   			where GLCo = @glco and GLAcct = @glacct
   		if @@rowcount <> 1 goto parts_update_error
   		end
   	-- update All Parts to hold GL Account without separation chars
   	update bGLAC set AllParts = isnull(Part1,'') + isnull(Part2,'') + isnull(Part3,'') + isnull(Part4,'') 
   		+ isnull(Part5,'') + isnull(Part6,'')
   		where GLCo = @glco and GLAcct = @glacct
   	if @@rowcount <> 1 goto parts_update_error
   	goto audit_insert
   	parts_update_error:
   		select @errmsg = 'Failed to update GL Account Parts'
   		goto error
   	audit_insert:
   	/* add HQ Master Audit entry */
   	if @audit = 'Y'
   		begin
   		select @tablename = 'bGLAC', @key = 'GL Acct: ' + @glacct, @co = @glco, @rectype = 'A',
   			@field = null, @old = null, @new = null, @date = getdate(), @user = SUSER_SNAME()
   		exec @errno = bspHQMAInsert @tablename,@key, @co,@rectype,@field,@old,@new,@date, @user,
   			@errmsg output
   		if @errno <> 0 goto error
   		end



if @numrows > 1
	begin
	fetch next from bGLAC_insert into @glco, @glacct, @sumacct, @ca, @offacct, @crossrefmemacct
	if @@fetch_status = 0
		goto insert_check
	else
		begin
		close bGLAC_insert
		deallocate bGLAC_insert
		end
	end




   return
   error:
   	if @numrows > 1
   		begin
   		close bGLAC_insert
   		deallocate bGLAC_insert
   		end
       	select @errmsg = isnull(@errmsg,'') + ' - cannot insert GL Account and copying has terminated!'
       	RAISERROR(@errmsg, 11, -1);
       	rollback transaction
   
   
   
   
   
   
   
   
   
   
   
   
   
   
  
 




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  
/****** Object:  Trigger dbo.btGLACu    Script Date: 8/28/99 9:37:27 AM ******/
CREATE trigger [dbo].[btGLACu] on [dbo].[bGLAC] for UPDATE as
/*-----------------------------------------------------------------
 * Created: ????
 * Modified: GG 04/10/01 - added Account Type and Subledger Type validation
 *			 EN 12/27/01 - issue 15318 - added validation for Cross Ref Memo Acct
 *			 EN 1/14/02 - issue 15886 - Cross Ref Memo Acct validation failing ... fixed
 *		allenn 05/14/02 - issue 17322 - change validation message to include account numbers
 *			GG 07/31/06 - #121633 - don't allow change to Heading if GLBL.NetActivity <> 0 in any month, cleaned up validation and auditing
 *			AR 2/4/2011  - #142311 - adding foreign keys and check constraints, removing trigger look ups
 *			CHS	10/31/2011	- #144849 no HQMA was happening.
 *
 *	This trigger rejects update in bGLAC (Accounts) if any of the
 *	following error conditions exist:
 *
 *		Cannot change GL Company
 *		Cannot change GL Account
 *		Invalid Summary Account
 *		Missing GL Company
 *		Cash/Accrual option not used in the GL Company
 *		Accrual accounts cannot have offset accounts
 *		Invalid Cash Offset Account
 *
 *	Adds old and updated values to HQ Master Audit where applicable.
 */----------------------------------------------------------------
DECLARE @errmsg varchar(255),
    @numrows int,
    @validcnt int,
    @validcnt2 int,
    @glacct bGLAcct,
    @crmemacct bGLAcct

SELECT  @numrows = @@rowcount
IF @numrows = 0 RETURN

SET NOCOUNT ON

--check for primary key change
SELECT  @validcnt = COUNT(*)
FROM    deleted d
        JOIN inserted i ON d.GLCo = i.GLCo
                           AND d.GLAcct = i.GLAcct
IF @numrows <> @validcnt 
    BEGIN
        SELECT  @errmsg = 'Cannot change GL Company or GL Account'
        GOTO error
    END
	
-- validate Account Type
IF UPDATE(AcctType) 
    BEGIN
		--#142311 -	 handling type by check constraint now

	-- #121633 - don't allow Account Type change to Heading if GLBL.NetActivity <> 0 in any month
        IF EXISTS ( SELECT TOP 1
                            1
                    FROM    inserted i
                            JOIN bGLBL b ( NOLOCK ) ON b.GLCo = i.GLCo
                                                       AND b.GLAcct = i.GLAcct
                    WHERE   i.AcctType = 'H'
                            AND b.NetActivity <> 0 ) 
            BEGIN
                SELECT  @errmsg = 'Non-zero Net Activity exists.  Cannot change Account Type to Heading.'
                GOTO error
            END
    END
IF UPDATE(AcctType)
    OR UPDATE(CrossRefMemAcct) 
    BEGIN
        IF EXISTS ( SELECT TOP 1
                            1
                    FROM    inserted
                    WHERE   AcctType = 'H'
                            AND CrossRefMemAcct IS NOT NULL ) 
            BEGIN
                SELECT  @errmsg = 'Cross Reference Memo Accounts not allowed on Heading Accounts.'
                GOTO error
            END 
    END
-- validate Subledger Type
--#142311 -	 handled by check constraint now

-- issue 15318 - validate Cross Reference Memo Account -issue 15886 / validation failing ... fixed
-- issue 17322 - change validation message to include account numbers
IF UPDATE(CrossRefMemAcct) 
    BEGIN
        SELECT  @validcnt2 = COUNT(*)
        FROM    inserted
        WHERE   CrossRefMemAcct IS NULL
        SELECT  @validcnt = COUNT(*)
        FROM    inserted i
                JOIN bGLAC a ( NOLOCK ) ON a.GLCo = i.GLCo
                                           AND a.GLAcct = i.CrossRefMemAcct
        IF @validcnt2 + @validcnt <> @numrows 
            BEGIN
                IF @numrows = 1 
                    BEGIN
                        SELECT  @glacct = GLAcct,
                                @crmemacct = CrossRefMemAcct
                        FROM    inserted 
                        SELECT  @errmsg = 'Cross Ref Memo Account:'
                                + @crmemacct + ' is invalid on Account:'
                                + @glacct
                        GOTO error
                    END
                ELSE 
                    BEGIN
                        SELECT  @errmsg = 'Invalid Cross Reference Memo Account.'
                        GOTO error
                    END
            END
    END
 /* validate Summary Account */
SELECT  @validcnt = COUNT(*)
FROM    bGLAC g ( NOLOCK )
        JOIN inserted i ON g.GLCo = i.GLCo
                           AND g.GLAcct = i.SummaryAcct
IF @validcnt <> @numrows 
    BEGIN
        SELECT  @errmsg = 'Invalid Summary Account'
        GOTO error
    END
/* validate CashAccrual info */
IF UPDATE(CashAccrual) 
    BEGIN
        IF EXISTS ( SELECT TOP 1
                            1
                    FROM    bGLCO g ( NOLOCK )
                            JOIN inserted i ON g.GLCo = i.GLCo
                    WHERE   g.CashAccrual = 'A'
                            AND i.CashAccrual <> 'A' ) 
            BEGIN
                SELECT  @errmsg = 'This GL Company requires all Accounts to be accrual based'
                GOTO error
            END
    END
IF UPDATE(CashOffAcct) 
    BEGIN
        IF EXISTS ( SELECT TOP 1
                            1
                    FROM    bGLCO g ( NOLOCK )
                            JOIN inserted i ON g.GLCo = i.GLCo
                    WHERE   g.CashAccrual = 'A'
                            AND i.CashOffAcct IS NOT NULL ) 
            BEGIN
                SELECT  @errmsg = 'This GL Company does not use Offset Accounts'
                GOTO error
            END
        IF EXISTS ( SELECT TOP 1
                            1
                    FROM    inserted
                    WHERE   CashOffAcct = GLAcct ) 
            BEGIN
                SELECT  @errmsg = 'Offset Account cannot match GL Account'
                GOTO error
            END
    END
IF UPDATE(CashOffAcct)
    OR UPDATE(CashAccrual) 
    BEGIN
    /* if Offset Account is valid, must be different type */
        IF EXISTS ( SELECT TOP 1
                            1
                    FROM    bGLAC g ( NOLOCK )
                            JOIN inserted i ON g.GLCo = i.GLCo
                                               AND g.GLAcct = i.CashOffAcct
                    WHERE   g.CashAccrual = i.CashAccrual ) 
            BEGIN
                SELECT  @errmsg = 'Cash accounts must be offset by Accrual'
                GOTO error
            END
        IF EXISTS ( SELECT TOP 1
                            1
                    FROM    inserted
                    WHERE   CashAccrual = 'C'
                            AND CashOffAcct IS NULL ) 
            BEGIN
                SELECT  @errmsg = 'Cash basis accounts require Offset Accounts'
                GOTO error
            END
    END
   
/* check for HQ Master Audit */
IF NOT EXISTS ( SELECT TOP 1
                        1
                FROM    bGLCO g
                JOIN	inserted i ON g.GLCo = i.GLCo
                WHERE	g.AuditAccts = 'Y' ) 
    RETURN


if update(Description)
	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bGLAC', 'GL Acct: ' + i.GLAcct, i.GLCo, 'C', 'Description', d.Description, i.Description,
		getdate(), SUSER_SNAME()
	from inserted i	join deleted d on i.GLCo = d.GLCo and i.GLAcct = d.GLAcct
	join bGLCO g on i.GLCo = g.GLCo
	where isnull(i.Description,'') <> isnull(d.Description,'') and g.AuditAccts = 'Y'
if update(AcctType)
	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bGLAC', 'GL Acct: ' + i.GLAcct, i.GLCo, 'C', 'Account Type', d.AcctType, i.AcctType, 
		getdate(), SUSER_SNAME()
	from inserted i	join deleted d on i.GLCo = d.GLCo and i.GLAcct = d.GLAcct
	join bGLCO g on i.GLCo = g.GLCo
	where i.AcctType <> d.AcctType and g.AuditAccts = 'Y'
if update(SubType)
	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bGLAC', 'GL Acct: ' + i.GLAcct, i.GLCo, 'C','Subledger Type', d.SubType, i.SubType,
		getdate(), SUSER_SNAME()
	from inserted i	join deleted d on i.GLCo = d.GLCo and i.GLAcct = d.GLAcct
	join bGLCO g on i.GLCo = g.GLCo
	where i.SubType <> d.SubType and g.AuditAccts = 'Y'
if update(NormBal)
	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bGLAC', 'GL Acct: ' + i.GLAcct, i.GLCo, 'C', 'Normal Balance', d.NormBal, i.NormBal,
		getdate(), SUSER_SNAME()
	from inserted i	join deleted d on i.GLCo = d.GLCo and i.GLAcct = d.GLAcct
	join bGLCO g on i.GLCo = g.GLCo
	where i.NormBal <> d.NormBal and g.AuditAccts = 'Y'
if update(InterfaceDetail)
	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    select 'bGLAC', 'GL Acct: ' + i.GLAcct, i.GLCo, 'C', 'Interface Detail', d.InterfaceDetail, i.InterfaceDetail,
		getdate(), SUSER_SNAME()
	from inserted i	join deleted d on i.GLCo = d.GLCo and i.GLAcct = d.GLAcct
	join bGLCO g on i.GLCo = g.GLCo
    where  i.InterfaceDetail <> d.InterfaceDetail and g.AuditAccts = 'Y'
if update(Active)
	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    select 'bGLAC', 'GL Acct: ' + i.GLAcct, i.GLCo, 'C', 'Active', d.Active, i.Active,
		getdate(), SUSER_SNAME()
	from inserted i	join deleted d on i.GLCo = d.GLCo and i.GLAcct = d.GLAcct
	join bGLCO g on i.GLCo = g.GLCo
    where i.Active <> d.Active and g.AuditAccts = 'Y'
if update(SummaryAcct)
	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bGLAC', 'GL Acct: ' + i.GLAcct, i.GLCo, 'C', 'Summary Acct', d.SummaryAcct, i.SummaryAcct,
		getdate(), SUSER_SNAME()
	from inserted i	join deleted d on i.GLCo = d.GLCo and i.GLAcct = d.GLAcct
	join bGLCO g on i.GLCo = g.GLCo
	where i.SummaryAcct <> d.SummaryAcct and g.AuditAccts = 'Y'
if update(CashAccrual)
	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bGLAC', 'GL Acct: ' + i.GLAcct, i.GLCo, 'C', 'Cash/Accrual', d.CashAccrual, i.CashAccrual,
		getdate(), SUSER_SNAME()
	from inserted i	join deleted d on i.GLCo = d.GLCo and i.GLAcct = d.GLAcct
	join bGLCO g on i.GLCo = g.GLCo
	where i.CashAccrual <> d.CashAccrual and g.AuditAccts = 'Y'
if update(CashOffAcct)
	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bGLAC', 'GL Acct: ' + i.GLAcct, i.GLCo, 'C', 'Cash Offset Acct', d.CashOffAcct, i.CashOffAcct,
		getdate(), SUSER_SNAME()
	from inserted i	join deleted d on i.GLCo = d.GLCo and i.GLAcct = d.GLAcct
	join bGLCO g on i.GLCo = g.GLCo
	where isnull(i.CashOffAcct,'') <> isnull(d.CashOffAcct,'') and g.AuditAccts = 'Y'
/* Account Parts determined from GL Account, not user changeable, no auditing needed */
if update(CrossRefMemAcct)
	insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bGLAC', 'GL Acct: ' + i.GLAcct, i.GLCo, 'C', 'Cross Ref Memo Acct', d.CrossRefMemAcct, i.CrossRefMemAcct,
		getdate(), SUSER_SNAME()
	from inserted i	join deleted d on i.GLCo = d.GLCo and i.GLAcct = d.GLAcct
	join bGLCO g on i.GLCo = g.GLCo
	where isnull(i.CrossRefMemAcct,'') <> isnull(d.CrossRefMemAcct,'') and g.AuditAccts = 'Y'

return
    error:
    	select @errmsg = @errmsg + ' - cannot update GL Account!'
        	RAISERROR(@errmsg, 11, -1);
        	rollback transaction
    
GO
ALTER TABLE [dbo].[bGLAC] WITH NOCHECK ADD CONSTRAINT [CK_bGLAC_AcctType] CHECK (([AcctType]='P' OR [AcctType]='M' OR [AcctType]='L' OR [AcctType]='I' OR [AcctType]='H' OR [AcctType]='E' OR [AcctType]='C' OR [AcctType]='A'))
GO
ALTER TABLE [dbo].[bGLAC] WITH NOCHECK ADD CONSTRAINT [CK_bGLAC_SubType] CHECK (([SubType]='R' OR [SubType]='P' OR [SubType]='C' OR [SubType]='E' OR [SubType]='I' OR [SubType]='J' OR [SubType]='S'))
GO
ALTER TABLE [dbo].[bGLAC] ADD CONSTRAINT [PK_bGLAC] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [biGLACAcctType] ON [dbo].[bGLAC] ([AcctType]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biGLAC] ON [dbo].[bGLAC] ([GLCo], [GLAcct]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bGLAC] WITH NOCHECK ADD CONSTRAINT [FK_bGLAC_bGLCO_GLCo] FOREIGN KEY ([GLCo]) REFERENCES [dbo].[bGLCO] ([GLCo])
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bGLAC].[InterfaceDetail]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bGLAC].[Active]'
GO
