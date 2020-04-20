CREATE TABLE [dbo].[bCMST]
(
[CMCo] [dbo].[bCompany] NOT NULL,
[CMAcct] [dbo].[bCMAcct] NOT NULL,
[StmtDate] [dbo].[bDate] NOT NULL,
[BegBal] [dbo].[bDollar] NOT NULL,
[WorkBal] [dbo].[bDollar] NOT NULL,
[StmtBal] [dbo].[bDollar] NOT NULL,
[Status] [tinyint] NOT NULL,
[LstUploadDate] [dbo].[bDate] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btCMSTd    Script Date: 8/28/99 9:37:06 AM ******/
   CREATE  trigger [dbo].[btCMSTd] on [dbo].[bCMST] for DELETE as
   

/*-----------------------------------------------------------------
    *	This trigger rejects delete in bCMST (CM Statement Control) if any of
    *	the following error condition exists:
    *
    *		CMDT entry exists
    */----------------------------------------------------------------
   
   declare @errmsg varchar(255) 
   
   if @@rowcount = 0 return 
   set nocount on
   
   /* check for corresponding entries in CMDT */
   if exists (select * from deleted d, bCMDT g
   		where g.CMCo = d.CMCo and g.CMAcct = d.CMAcct and g.StmtDate = d.StmtDate)
   
   	begin
   	select @errmsg = 'CM Detail entries exist'
   	goto error
   	end
   
   return
   
   error:
   	select @errmsg = @errmsg +  ' - unable to delete CM Statement!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
/****** Object:  Trigger dbo.btCMSTi    Script Date: 8/28/99 9:37:06 AM ******/
/************************************************************************
* CREATED:	 
* MODIFIED:		AR 12/2/2010  - #142311 - adding foreign keys, removing trigger look ups
*
* Purpose: 	This trigger rejects insertion in bCMST (CM Statement Control) if any of
*			the following error conditions exist:
*
*		Invalid CMCo -- Now handled by FK 142311
*		Invalid CMAcct -- Now handled by FK 142311
*		StmtDate earlier than any preceding
*		Status = Closed
*		Prior Statment with Status = Open exists

* returns 1 and error msg if failed
*
*************************************************************************/
CREATE  TRIGGER [dbo].[btCMSTi] ON [dbo].[bCMST]
    FOR INSERT
AS
DECLARE @audit bYN,
    @ca char(1),
    @co bCompany,
    @date bDate,
    @errmsg varchar(255),
    @errno int,
    @field char(30),
    @cmacct bCMAcct,
    @cmco bCompany,
    @glacct bGLAcct,
    @glco bCompany,
    @key varchar(60),
    @new varchar(30),
    @numrows int,
    @old varchar(30),
    @rectype char(1),
    @status tinyint,
    @stmtdate bDate,
    @tablename char(20),
    @user bVPUserName,
    @validcount int
   
SELECT  @numrows = @@rowcount
IF @numrows = 0 
    RETURN
SET nocount ON
   
IF @numrows > 1 
    BEGIN
        SELECT  @errmsg = 'Cannot add more than one Statement at a time'
        GOTO error
    END
   

SELECT  @cmco = CMCo,
        @cmacct = CMAcct,
        @stmtdate = StmtDate,
        @status = Status
FROM    inserted
   
   /* verify StmtDate is later than all existing StmtDates */
SELECT  @validcount = COUNT(*)
FROM    bCMST
WHERE   StmtDate > @stmtdate
        AND CMCo = @cmco
        AND CMAcct = @cmacct
IF @validcount <> 0 
    BEGIN
        SELECT  @errmsg = 'Statement Date entered must be later than all current Statement Dates on file for this CM Co/Acct'
        GOTO error
    END
   
   /* verify Status = open (where open = 0)*/
IF @status <> 0 
    BEGIN
        SELECT  @errmsg = 'Status for new Statement must be Open'
        GOTO error
    END
   
   /* verify no prior record exists with Status = open (where open = 0) */
SELECT  @validcount = COUNT(*)
FROM    bCMST
WHERE   Status = 0
        AND CMCo = @cmco
        AND CMAcct = @cmacct
        AND StmtDate <> @stmtdate
IF @validcount <> 0 
    BEGIN
        SELECT  @errmsg = 'Prior Statement with Open Status exists for this CM Co/Acct'
        GOTO error
    END
   
RETURN
   
error:
SELECT  @errmsg = @errmsg + ' - cannot insert CM Statement!'
RAISERROR(@errmsg, 11, -1);
ROLLBACK TRANSACTION
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

 
  
   
   
   
   
   /****** Object:  Trigger dbo.btCMSTu    Script Date: 8/28/99 9:37:06 AM ******/
   CREATE  trigger [dbo].[btCMSTu] on [dbo].[bCMST] for UPDATE as
   
   

declare @audit bYN, @cmacct bCMAcct, @date bDate,
   	@errmsg varchar(255), @errno int, @field char(30), 
   	@glco bCompany, 
   	@cmco bCompany,
   	@stmtdate bDate,
   	@numrows int, 
   	@rectype char(1),
   	@status tinyint ,
   	@stmtbal bDollar,
   	@validcount int,
   	@workbal bDollar
   
   /*-----------------------------------------------------------------
    *	This trigger rejects update in bCMST (CM Statement Comtrol) if 
    *	any of the following error conditions exist:
    *
    *		Cannot change CM Company
    *		Cannot change CM Account
    *		Cannot change StmtDate
    *		More than one record with Status = Open
    *		Updating to Closed Statement with Working Bal <> Ending Bal
	*
	*	Modified:  mh 5/16/06 - 120220
    *		
    */----------------------------------------------------------------
   
   select @numrows = @@rowcount
   if @numrows = 0 return 
   set nocount on
   
   select @validcount = count(*) from deleted d, inserted i
   	where d.CMCo = i.CMCo and d.CMAcct = i.CMAcct and d.StmtDate = i.StmtDate
   if @numrows <> @validcount
   
   	begin
   	select @errmsg = 'Cannot change CM Company, CM Account, or Statement Date' 
   	goto error
   	end
   	
   if @numrows = 1
   	select @cmco = CMCo, @cmacct = CMAcct, @workbal = WorkBal, @stmtbal = StmtBal,
   		@status = Status from inserted
   else 
   	begin	
   	declare bCMST_update cursor for select CMCo = i.CMCo, CMAcct = i.CMAcct, 
   		WorkBal = i.WorkBal, StmtBal = i.StmtBal, Status = i.Status
   		from inserted i
   	open bCMST_update
   	fetch next from bCMST_update into @cmco, @cmacct, @workbal, @stmtbal, @status
   	if @@fetch_status <> 0
   		begin
   		select @errmsg = 'Cursor error'
   		goto error
   		end 
   	end	
   
   update_check:
   	/* reject if Status column is touched by update and either of the following 
   	 * 	two conditions exist:
   	 *	1. more than one open statement would exist for same cmco and cmacct
   	 *	(Status open = 0) */
   		if update(Status)
   		  begin
   			select @validcount = count(*) from bCMST where CMCo = @cmco 
   				and CMAcct = @cmacct and Status = 0
   			if @validcount > 1
   			begin
   			select @errmsg = 'An Open Statement already exists on file for this CM Company/Acct'
   			goto error
   			end
   	
   	  /*	2. working bal <> ending bal if setting to closed (Status closed = 1) */
   		     if @workbal <> @stmtbal and @status = 1
   			begin
   			   select @errmsg = 'You cannot close a Statement that has not been balanced'
   			   goto error
   			end
   		end
   
   		if @numrows > 1
   			begin
			--Issue 120220 - missing @status from the fetch next.  mh 5/16/06
   			--fetch next from bCMST_update into @cmco, @cmacct, @workbal, @stmtbal
			fetch next from bCMST_update into @cmco, @cmacct, @workbal, @stmtbal, @status
   			if @@fetch_status = 0
   				goto update_check
   
   
   			else
   				begin
   				close bCMST_update
   				deallocate bCMST_update
   				end
   			end
   
   
   return
   
   error:
       	select @errmsg = @errmsg + ' - cannot update CM Statement!'
       	RAISERROR(@errmsg, 11, -1);
       	rollback transaction
   
   
  
 




GO
ALTER TABLE [dbo].[bCMST] WITH NOCHECK ADD CONSTRAINT [CK_bCMST_CMAcct] CHECK (([CMAcct]>(0) AND [CMAcct]<(10000)))
GO
ALTER TABLE [dbo].[bCMST] ADD CONSTRAINT [PK_bCMST_KeyID] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biCMST] ON [dbo].[bCMST] ([CMCo], [CMAcct], [StmtDate]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bCMST] WITH NOCHECK ADD CONSTRAINT [FK_bCMST_bCMAC_CMCoCMAcct] FOREIGN KEY ([CMCo], [CMAcct]) REFERENCES [dbo].[bCMAC] ([CMCo], [CMAcct])
GO
ALTER TABLE [dbo].[bCMST] NOCHECK CONSTRAINT [FK_bCMST_bCMAC_CMCoCMAcct]
GO
