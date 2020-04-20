CREATE TABLE [dbo].[bJCSI]
(
[SIRegion] [varchar] (6) COLLATE Latin1_General_BIN NOT NULL,
[SICode] [varchar] (16) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[UM] [dbo].[bUM] NOT NULL,
[MUM] [dbo].[bUM] NULL,
[UnitPrice] [dbo].[bUnitCost] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btJCSId    Script Date: 8/28/99 9:37:48 AM ******/
   CREATE  trigger [dbo].[btJCSId] on [dbo].[bJCSI] for DELETE as
   

declare @errmsg varchar(255), @validcnt int 
   
   /*-----------------------------------------------------------------
    *	This trigger rejects delete in bJCSI (JC Std Item Codes)
    *	if the following error condition exists:
    *
    *		entries exist in JCCI.SIRegion
    *		entries exist in JCCI.SICode
    *           MOD JRE 11/05/99  - need to check both SIRegion and SICode
    */
   
   declare  @errno   int, @numrows int
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   begin
   
     /* check JCCI.SIRegion and JCCI.SICode*/
     if exists(select * from deleted, bJCCI
     	where bJCCI.SIRegion = deleted.SIRegion and bJCCI.SICode = deleted.SICode)
     	begin
     	  select @errmsg = 'SI Code entries exist in JC Contract Items'
     	  goto error
     	end
   
   return
   
   error:
       select @errmsg = @errmsg + ' - cannot delete JC Std Item Code!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction                                                         
   end
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btJCSIi    Script Date: 8/28/99 9:37:48 AM ******/
   CREATE  trigger [dbo].[btJCSIi] on [dbo].[bJCSI] for update as
   

declare @errmsg varchar(255), @validcnt int, @msgstart char(12)
   
   /*-----------------------------------------------------------------
    * JRE 9/1/97
    * modified 2/7/98
    * can't change primary key,  validates UM & MUM to HQUM
    *-----------------------------------------------------------------*/
    
   declare  @errno int, @numrows int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   if @numrows > 1
   	select @msgstart = 'At least 1 '
   else
   	select @msgstart = ''
   
   begin
   	select @validcnt = count(*) from bHQUM h
   		join inserted i on h.UM=i.UM
   	if @validcnt <> @numrows 
   		begin
   		select @errmsg = 'Invalid UM'
   		goto error
   		end
   
   	select @validcnt = count(*) from bHQUM h
   		join inserted i on h.UM=i.UM
   	if @validcnt <> @numrows 
   		begin
   		select @errmsg = 'Invalid MUM'
   		goto error
   		end
   
   return
   
   error:
       select @errmsg = @errmsg + ' - cannot insert Std Item Code!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction                                                         
   end
   
   
   
  
 



GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bJCSI] ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biJCIC] ON [dbo].[bJCSI] ([SIRegion], [SICode]) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCSI].[UnitPrice]'
GO
