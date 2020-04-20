CREATE TABLE [dbo].[bGLFY]
(
[GLCo] [dbo].[bCompany] NOT NULL,
[FYEMO] [dbo].[bMonth] NOT NULL,
[BeginMth] [dbo].[bMonth] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[FiscalYear] [smallint] NOT NULL CONSTRAINT [DF_bGLFY_FiscalYear] DEFAULT ((0)),
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
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
 

CREATE  trigger [dbo].[btGLFYd] on [dbo].[bGLFY] for DELETE as
/*-----------------------------------------------------------------
* Created: ??
* Modified: GG 11/28/07 - removed cursor, use ANSI joins
*			AR 2/7/2011  - #142311 - adding foreign keys and check constraints, removing trigger look ups
*
*	This trigger rejects delete in bGLFY (Fiscal Years) if any 
*	of the following error conditions exist:
*
*		Yearly Balance entries exist
*		Budget Revision entries exist
*
*	Delete GL Fiscal Period entries from bGLFP
*/----------------------------------------------------------------
   
declare @numrows int, @errmsg varchar(255)

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on
   
/* check Yearly Balance */
if exists (select top 1 1 from deleted d join dbo.bGLYB g (nolock) on g.GLCo = d.GLCo and g.FYEMO = d.FYEMO)
	begin
   	select @errmsg = 'Beginning and/or Adjustment Balance entries exist'
   	goto error
   	end
/* check Budget Revisions */
--#142311 removing for FK
   	
-- delete Fiscal Periods
delete dbo.bGLFP
from deleted d
join dbo.bGLFP p on p.GLCo = d.GLCo and (p.Mth >= d.BeginMth and p.Mth <= d.FYEMO)

return
   
error:
   	select @errmsg = @errmsg + ' - cannot delete Fiscal Year!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
CREATE   trigger [dbo].[btGLFYi] on [dbo].[bGLFY] for INSERT as
/*-----------------------------------------------------------------
*  Created:  ??
*  Modified:	JRE 09/01/00 - Fixed overlap if inserting multiple records  Issue 10452
*				CMW 14/24/01 - issue # 17058 allow 1 month FY
*				EN 8/13/02 - issue 3441 use new FiscalYear column to fill FiscalYr value in bGLFP
*				GG 03/30/07 - make sure FYEMO and BeginMth use 1st day of month, moved some validation out of cursor
*				AR 2/7/2011  - #142311 - adding foreign keys and check constraints, removing trigger look ups
*				AR 2/19/2011 - #142311 - adding check constraint, removing trigger look ups
*
*	This trigger rejects insertion in bGLFY (Fiscal Years) if any
*	of the following error conditions exist:
*		Fiscal Year Ending Month must come after Beginning Month
*		Less than 1 or more than 12 months in fiscal year
*		Beginning Month overlaps previous year
*		Ending Month overlaps following year
*
*	Inserts GL Fiscal Period entries in bGLFP
*
*/----------------------------------------------------------------
declare @beginmth bMonth, @errmsg varchar(255), @errno int, @fyemo bMonth, @glco bCompany,
	@maxfy bMonth, @validcnt int, @minbeginmth bMonth, @minfy bMonth, @numrows int,
   	@fp tinyint, @fy smallint, @mth bMonth
   
select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

--validate GL Company
--#142311 - removing because of FK

-- make sure FYEMO uses 1st day - added to troubleshoot entries added with improperly formatted Months
 --#142311 - replacing with a check constraints
 /*
if exists(select top 1 1 from inserted where DATEPART(dd , FYEMO)<>1)
	begin
	select @errmsg = 'Fiscal Year Ending month is not correctly formatted - must use first day of month'
	goto error
	end
-- make sure BeginMth uses 1st day - added to troubleshoot entries added with improperly formatted Months
if exists(select top 1 1 from inserted where DATEPART(dd , BeginMth)<>1)
	begin
	select @errmsg = 'Beginning Month is not correctly formatted - must use first day of month'
	goto error
	end
--check FYEMO is equal to or later than Beginning Mth
if exists(select top 1 1 from inserted where FYEMO < BeginMth)
	begin
	select @errmsg = 'Fiscal Year Beginning Month must not come after Ending Month'
    goto error
    end		

--check # of months in Fiscal Year
if exists(select top 1 1 from inserted
			where datediff(month,BeginMth,FYEMO)<1 or datediff(month,BeginMth,FYEMO)>12)
	begin
   	select @errmsg = 'Must have between 1 and 12 months'
   	goto error
   	end
 */	 
-- additional validation requiring cursor 
if @numrows = 1
   	select @glco = GLCo, @fyemo = FYEMO, @beginmth = BeginMth, @fy = FiscalYear from inserted --issue 3441
else
   	begin
   	/* use a cursor to process each inserted row */
   	declare bGLFY_insert cursor for select GLCo, FYEMO, BeginMth, FiscalYear from inserted --issue 3441
   	open bGLFY_insert
   	fetch next from bGLFY_insert into @glco, @fyemo, @beginmth, @fy --issue 3441
   	if @@fetch_status <> 0
   		begin
   		select @errmsg = 'Cursor error'
   		goto error
   		end
   	end
   
insert_check:
   	/* check previous years */
   	select @maxfy = max(FYEMO) from bGLFY where GLCo = @glco and FYEMO < @fyemo
   	if @@rowcount <> 0
   		begin
   		if @maxfy >= @beginmth
   			begin
   			select @errmsg = 'Beginning Month overlaps previous year'
   			goto error
   			end
   		end
   	/* check following years */
   	select @minfy = min(FYEMO) from bGLFY where GLCo = @glco and FYEMO > @fyemo
   	if @@rowcount <> 0  and @minfy is not null -- issue 10452
   		begin
   		select @minbeginmth = BeginMth from bGLFY where GLCo = @glco and FYEMO = @minfy
   		if @fyemo >= @minbeginmth
   			begin
   			select @errmsg = 'Ending Month overlaps following year'
   			goto error
   			end
   		end
   
   	/* add GL Fiscal Period entries */
   	select /*@fy = datepart(year, @fyemo),*/ @fp = 0 --issue 3441 commented out code which extracts @fy from @fyemo because we're now using GLFY_FiscalYear
   	glfp_loop:
   		select @mth = dateadd(month, @fp, @beginmth)
   		select @fp = @fp + 1
   		insert into bGLFP (GLCo, Mth, FiscalPd, FiscalYr)
   			values (@glco, @mth, @fp, @fy)
   		if @mth < @fyemo goto glfp_loop
   
   	if @numrows > 1
   		begin
   		fetch next from bGLFY_insert into @glco, @fyemo, @beginmth, @fy --issue 3441
   		if @@fetch_status = 0
   			goto insert_check
   		else
   			begin
   			close bGLFY_insert
   			deallocate bGLFY_insert
   			end
   		end
   
   return
   
   error:
   	if @numrows > 1
   		begin
   		DECLARE @OpenCursor int
   		SELECT @OpenCursor =  CURSOR_STATUS('local','bGLFY_insert')

		IF @OpenCursor >= 0
		BEGIN	   		
   			close bGLFY_insert
   			deallocate bGLFY_insert
   		END
   		end
   
   	select @errmsg = @errmsg + ' - cannot insert Fiscal Year!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btGLFYu    Script Date: 8/28/99 9:37:30 AM ******/
   CREATE trigger [dbo].[btGLFYu] on [dbo].[bGLFY] for UPDATE as
   

declare @errmsg varchar(255), @fyemo bMonth, @glco bCompany, 
    	@maxfy bMonth, @minbeginmth bMonth, @minfy bMonth,
    	@newbeginmth bMonth, @numrows int, @oldbeginmth bMonth,
    	@opencursor tinyint, @validcount int,
    	@fp tinyint, @oldfy smallint, @newfy smallint, @mth bMonth
    
    /*-----------------------------------------------------------------
     *  Created by:  ??
     *  Modified by EN 8/13/02 - issue 3441 use new FiscalYear column to fill FiscalYr value in bGLFP
     *							 ... also validate that FiscalYear value is unique
     *				EN 10/30/02 issue 3441  read old and new FiscalYear values and check for changes
     *				AR 2/19/2011 - #142311 - adding check constraint, removing trigger look ups
     *
     *	This trigger rejects update in bGLFY (Fiscal Years) if any
     *	of the following error conditions exist:
     *
     *		Cannot change GL Company
     *		Cannot change Fiscal Year ending month
     *		Fiscal Year Ending Month must come after Beginning Month
     *		Less than 2 or more than 12 months in fiscal year
     *		Beginning Month overlaps previous year
     *		Ending Month overlaps following year
     *
     *	Update GL Fiscal Period entries in bGLFP
     *----------------------------------------------------------------*/
    
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
    
    select @opencursor = 0 	/* initialize open cursor flag */
    
    /* check for key changes */
    select @validcount = count(*) from deleted d, inserted i
    	where d.GLCo = i.GLCo and d.FYEMO = i.FYEMO
    if @numrows <> @validcount
    	begin
    	select @errmsg = 'Cannot change GL Company or Fiscal Year ending month'
    	goto error
    	end
    
    --issue 3441 validate FiscalYear - must be unique
    select @validcount = count(*) from bGLFY a join inserted i
    	on a.FiscalYear = i.FiscalYear and a.GLCo = i.GLCo
    if @validcount<>@numrows
    	begin
    	select @errmsg = 'Fiscal Year must be unique'
    	goto error
    	end
    
    if @numrows = 1
    	select @glco = i.GLCo, @fyemo = i.FYEMO, @oldbeginmth = d.BeginMth, @newbeginmth = i.BeginMth,
    			@oldfy = d.FiscalYear, @newfy = i.FiscalYear --issue 3441
    		from deleted d, inserted i
    		where d.GLCo = i.GLCo and d.FYEMO = i.FYEMO
    else
    	begin
    	/* use a cursor to process each updated row */	
    	declare bGLFY_update cursor for select i.GLCo, i.FYEMO, OldBeginMth = d.BeginMth, NewBeginMth = i.BeginMth,
    			OldFiscalYear = d.FiscalYear, NewFiscalYear = i.FiscalYear --issue 3441
    		from deleted d, inserted i
    		where d.GLCo = i.GLCo and d.FYEMO = i.FYEMO
    	open bGLFY_update
    	select @opencursor = 1	/* set open cursor flag */
    	fetch next from bGLFY_update into @glco, @fyemo, @oldbeginmth, @newbeginmth, @oldfy, @newfy --issue 3441
    	if @@fetch_status <> 0
    		begin
    		select @errmsg = 'Cursor error'
    		goto error
    		end
    	end
    
    update_check:
    	/* validate Beginning and Ending Months*/ 
    	 
    	 
    	if @newbeginmth <> @oldbeginmth or @newfy <> @oldfy
    	--#142311 - replacing with a check constraints
    		begin
    			/*
    			if @fyemo <= @newbeginmth
    				begin
    				select @errmsg = 'Fiscal Year Ending Month must come after Beginning Month'
    				goto error
    				end
	    		
    			/* check number of months in year */
    			select @validcount = datediff(month,@newbeginmth,@fyemo)
    			if @validcount < 1 or @validcount > 11
    				begin
    				select @errmsg = 'Must have between 1 and 12 months'
    				goto error
    				end 
    			 */	
    		/* check previous years */
    		select @maxfy = max(FYEMO) from bGLFY where GLCo = @glco and FYEMO < @fyemo
    		if @@rowcount <> 0
    			begin
    			if @maxfy >= @newbeginmth
    				begin
    				select @errmsg = 'Beginning Month overlaps previous year'
    				goto error
    				end
    			end
    		
    		/* check following years */
    		select @minfy = min(FYEMO) from bGLFY where GLCo = @glco and FYEMO > @fyemo
    		if @@rowcount <> 0 
    			begin
    			select @minbeginmth = BeginMth from bGLFY where GLCo = @glco and FYEMO = @minfy
    			if @fyemo >= @minbeginmth
    				begin
    				select @errmsg = 'Ending Month overlaps following year'
    				goto error
    				end
    			end
    		
    		/* delete GL Fiscal Period entries based on old beginning month */
    		delete bGLFP where GLCo = @glco and (Mth >= @oldbeginmth and Mth <= @fyemo)
    			
    
    		/* add GL Fiscal Period entries based on new beginning month */
    		select /*@fy = datepart(year, @fyemo),*/ @fp = 0 --issue 3441 commented out code which extracts @fy from @fyemo because we're now using GLFY_FiscalYear
    		glfp_loop:
    			select @mth = dateadd(month, @fp, @newbeginmth)
    			select @fp = @fp + 1
    			insert into bGLFP (GLCo, Mth, FiscalPd, FiscalYr)
    				values (@glco, @mth, @fp, @newfy)
    			if @mth < @fyemo goto glfp_loop
    		end
    
    	if @numrows > 1
    		begin
    		fetch next from bGLFY_update into @glco, @fyemo, @oldbeginmth, @newbeginmth, @oldfy, @newfy --issue 3441 added @oldfy and @newfy and fixed 2nd param which said @fy but should have been @fyemo
    		if @@fetch_status = 0
    			goto update_check
    		else
    			begin
    			close bGLFY_update
    			deallocate bGLFY_update
    			end
    		end
    	 
    return
    
    error:
    	if @opencursor = 1
    		begin
    		close bGLFY_update
    		deallocate bGLFY_update
    		end
    
    	select @errmsg = @errmsg + ' - cannot update Fiscal Year entry!'
    	RAISERROR(@errmsg, 11, -1);
    	rollback transaction
    
   
   
   
   
  
 



GO
ALTER TABLE [dbo].[bGLFY] ADD CONSTRAINT [CK_bGLFY_BeginMthDayOfMth] CHECK ((datepart(day,[BeginMth])=(1)))
GO
ALTER TABLE [dbo].[bGLFY] ADD CONSTRAINT [CK_bGLFY_FYEMO1to12BeginMth] CHECK ((datediff(month,[BeginMth],[FYEMO])<=(12)))
GO
ALTER TABLE [dbo].[bGLFY] ADD CONSTRAINT [CK_bGLFY_FYEMOFirstDayOfMth] CHECK ((datepart(day,[FYEMO])=(1)))
GO
ALTER TABLE [dbo].[bGLFY] ADD CONSTRAINT [CK_bGLFY_FYEMOgtBeginMth] CHECK (([FYEMO]>=[BeginMth]))
GO
ALTER TABLE [dbo].[bGLFY] ADD CONSTRAINT [CK_bGLFY_FirstDayOfMth] CHECK ((datepart(day,[FYEMO])=(1)))
GO
ALTER TABLE [dbo].[bGLFY] ADD CONSTRAINT [PK_bGLFY] PRIMARY KEY NONCLUSTERED  ([KeyID]) WITH (FILLFACTOR=85, STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biGLFY] ON [dbo].[bGLFY] ([GLCo], [FYEMO]) WITH (FILLFACTOR=85, STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bGLFY] WITH NOCHECK ADD CONSTRAINT [FK_bGLFY_bGLCO_GLCo] FOREIGN KEY ([GLCo]) REFERENCES [dbo].[bGLCO] ([GLCo])
GO
