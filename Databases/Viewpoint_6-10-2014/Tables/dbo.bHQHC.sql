CREATE TABLE [dbo].[bHQHC]
(
[HoldCode] [dbo].[bHoldCode] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
   /****** Object:  Trigger dbo.btHQHCu    Script Date: 8/28/99 9:37:34 AM ******/
   CREATE    trigger [dbo].[btHQHCd] on [dbo].[bHQHC] for DELETE as
/*-----------------------------------------------------------------
	*  Modified TRL 02/10/10  Issue 137736 added APVH
	*
     *	This trigger rejects delete in bHQHC (HQ Hold Codes) if the 
    *	following error condition exists:
    *
    *		Hold Code exists in APTH, APHB, SLHD, POHD, APVH
    *
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int,@usecount int,@holdcode bHoldCode
   
   /* initialize */
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   
   if @numrows > 1
   begin
   	--numrows > 1 then need cursor
   	declare HCCursor cursor for select HoldCode from deleted
   	open HCCursor
   	fetch next from HCCursor into @holdcode
   	while @@Fetch_Status = 0
   	begin
		
		--Check for use in APVH  Issue 137736
		select @usecount = count(*) from bAPVH h where h.HoldCode=@holdcode
   		if @usecount <> 0 
   		begin
   			select @errmsg = 'Hold Code ' + @holdcode + ' in use in AP Vendor Codes.'
   			goto error
   		end
   		
    		--Check for use in APTH 
   		select @usecount = count(*) from bAPTH h where h.HoldCode=@holdcode
   		if @usecount <> 0 
   		begin
   			select @errmsg = 'Hold Code ' + @holdcode + ' in use in AP Entry.'
   			goto error
   		end
   	
   		--Check for use in APHB 
   		select @usecount = count(*) from bAPHB h where h.HoldCode=@holdcode
   		if @usecount <> 0 
   		begin
   			select @errmsg = 'Hold Code ' + @holdcode + ' in use in AP Entry.'
   			goto error
   		end
   
   		--Check for use in POHD 
   		select @usecount = count(*) from bPOHD h where h.HoldCode=@holdcode
   		if @usecount <> 0 
   		begin
   			select @errmsg = 'Hold Code ' + @holdcode + ' in use in PO Entry.'
   			goto error
   		end
   
   		--Check for use in SLHD 
   		select @usecount = count(*) from bSLHD h where h.HoldCode=@holdcode
   		if @usecount <> 0 
   		begin
   			select @errmsg = 'Hold Code ' + @holdcode + ' in use in SL Entry.'
   			goto error
   		end
   
   	fetch next from HCCursor into @holdcode
   	end
   end
   else
   begin
   	--numrows <> 0 and is not >1, only 1 row
   	
  	--Check for use in APVH  Issue 137736
   	select @usecount = count(*) from deleted d join bAPVH h on d.HoldCode=h.HoldCode
   	if @usecount <> 0 
   	begin
   		select @errmsg = 'Hold Code in use in AP Vendor Codes.'
   		goto error
   	end 
   
   	--Check for use in APTH 
   	select @usecount = count(*) from deleted d join bAPTH h on d.HoldCode=h.HoldCode
   	if @usecount <> 0 
   	begin
   		select @errmsg = 'Hold Code in use in AP Entry.'
   		goto error
   	end
   
   	--Check for use in APHB 
   	select @usecount = count(*) from deleted d join bAPHB h on d.HoldCode=h.HoldCode
   	if @usecount <> 0 
   	begin
   		select @errmsg = 'Hold Code in use in AP Entry.'
   		goto error
   	end
   
   	--Check for use in POHD 
   	select @usecount = count(*) from deleted d join bPOHD h on d.HoldCode=h.HoldCode
   	if @usecount <> 0 
   	begin
   		select @errmsg = 'Hold Code in use in PO Entry.'
   		goto error
   	end
   
   	--Check for use in SLHD 
   	select @usecount = count(*) from deleted d join bSLHD h on d.HoldCode=h.HoldCode
   	if @usecount <> 0 
   	begin
   		select @errmsg = 'Hold Code in use in SL Entry.'
   		goto error
   	end
   
   end
   
   return
   
   error:
   		
   	select @errmsg = @errmsg + ' - cannot delete HQ Hold Code!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
  
 




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btHQHCu    Script Date: 8/28/99 9:37:34 AM ******/
   CREATE  trigger [dbo].[btHQHCu] on [dbo].[bHQHC] for UPDATE as
   

declare @errmsg varchar(255), @numrows int, @validcount int
   
   /*-----------------------------------------------------------------
    *	This trigger rejects update in bHQHC (HQ Hold Codes) if the 
    *	following error condition exists:
    *
    *		Cannot change HQ Hold Code
    *
    */----------------------------------------------------------------
   
   /* initialize */
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   /* reject key changes */
   select @validcount = count(*) from deleted d, inserted i
   	where d.HoldCode = i.HoldCode
   if @numrows <> @validcount
   	begin
   	select @errmsg = 'Cannot change HQ Hold Code'
   	goto error
   	end
   
   return
   
   error:
   		
   	select @errmsg = @errmsg + ' - cannot update HQ Hold Code!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biHQHC] ON [dbo].[bHQHC] ([HoldCode]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHQHC] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
