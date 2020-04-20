CREATE TABLE [dbo].[bEMDP]
(
[EMCo] [dbo].[bCompany] NOT NULL,
[Equipment] [dbo].[bEquip] NOT NULL,
[Asset] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[DeprMethod] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[DBFactor] [dbo].[bRate] NULL,
[FirstMonth] [dbo].[bMonth] NOT NULL,
[NoMonthsToDepr] [smallint] NOT NULL,
[TtlToDepr] [dbo].[bDollar] NOT NULL,
[MonthDisposed] [dbo].[bMonth] NULL,
[PurchasePrice] [dbo].[bDollar] NULL,
[ResidualValue] [dbo].[bDollar] NULL,
[SalePrice] [dbo].[bDollar] NULL,
[AccumDeprAcct] [dbo].[bGLAcct] NULL,
[DeprExpAcct] [dbo].[bGLAcct] NULL,
[DeprAssetAcct] [dbo].[bGLAcct] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UseResidualVal] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bEMDP_UseResidualVal] DEFAULT ('N'),
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
 
  
   
   
   
   
   CREATE   trigger [dbo].[btEMDPd] on [dbo].[bEMDP] for Delete
    as
    

/**************************************************************
    * Created: 1/27/00 ae
    * Last Modified:  3/6/00 ae -added HQMA audits.
    *				 TV 02/11/04 - 23061 added isnulls	 
    *  This trigger deletes related records in EMDS.
    *
    **************************************************************/
    declare @errmsg varchar(255), @validcnt int, @validcnt2 int,@errno int, @numrows int, @nullcnt int,@rcode int,
    	@emco bCompany,
    	@equipment bEquip,
    	@asset varchar(20)
   
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
   
    select @emco=EMCo from deleted
    select @equipment=Equipment from deleted
    select @asset=Asset from deleted
   
    delete from EMDS where EMCo = @emco and Equipment = @equipment and Asset = @asset
   
   
   /* Audit inserts */
   
   insert into bHQMA select 'bEMDP', 'EM Company: ' + convert(char(3),d.EMCo) + ' Equipment: ' + convert(varchar(10),d.Equipment) +
    	' Asset: ' + convert(varchar(20),d.Asset),
    	d.EMCo, 'D', null, null, null, getdate(), SUSER_SNAME()
    	from deleted d,  EMCO e
       where e.EMCo = d.EMCo and e.AuditAsset = 'Y'
   
   
    Return
    error:
    select @errmsg = (isnull(@errmsg,'') + ' - cannot delete depreciation schedule! ')
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btEMDPi    Script Date: 8/28/99 9:37:18 AM ******/
   CREATE   trigger [dbo].[btEMDPi] on [dbo].[bEMDP] for insert as
   

/*--------------------------------------------------------------
    *
    *  Insert trigger for EMDP
    *  Created By:  ae  03/03/00
    *  Modified by: TV 02/11/04 - 23061 added isnulls
    *
    *
    *--------------------------------------------------------------*/
    /***  basic declares for SQL Triggers ****/
   declare @numrows int, @oldnumrows int, @errmsg varchar(255), @bemsg varchar(15),
           @errno tinyint, @audit bYN, @validcnt int, @nullcnt int,
           @rcode int
   
   
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
   
   /* Audit inserts */
   if not exists (select * from inserted i, EMCO e
    	where i.EMCo = e.EMCo and e.AuditAsset = 'Y')
    	return
   
   
   insert into bHQMA select 'bEMDP', 'EM Company: ' + convert(char(3),i.EMCo) + ' Equipment: ' + convert(varchar(10),i.Equipment) +
    	' Asset: ' + convert(varchar(20),i.Asset),
    	i.EMCo, 'A', '', null, null, getdate(), SUSER_SNAME()
    	from inserted i,  EMCO e
       where e.EMCo = i.EMCo and e.AuditAsset = 'Y'
   
   return
   
   error:
      select @errmsg = isnull(@errmsg,'') + ' - cannot insert into EMDP'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   /****** Object:  Trigger dbo.btEMDPu  ******/
   CREATE    trigger [dbo].[btEMDPu] on [dbo].[bEMDP] for update as
   
    

/*--------------------------------------------------------------
     *
     *  Update trigger for EMDP
     *  Created By:  ae 03/3/00
     *  Modified by: JM 11-01-02 Ref Issue 18796 - Added condition to add HQMA record for new GLCo column.
     *				  TV 02/11/04 - 23061 added isnulls
     *--------------------------------------------------------------*/
   
     /***  basic declares for SQL Triggers ****/
    declare @numrows int, @oldnumrows int, @errmsg varchar(255), @bemsg varchar(15),
            @errno tinyint, @audit bYN, @validcnt int, @nullcnt int,
            @rcode int
   
     select @numrows = @@rowcount
     if @numrows = 0 return
     set nocount on
   
    /* Audit inserts */
    if not exists (select * from inserted i, EMCO e
    	where i.EMCo = e.EMCo and e.AuditAsset = 'Y')
    	return
   
   if update(Description)
   begin
   insert into bHQMA select 'bEMDP', 'EM Company: ' + convert(char(3),i.EMCo) + ' Equipment: ' + convert(varchar(10),i.Equipment) +
    	' Asset: ' + convert(varchar(20),i.Asset),
    	i.EMCo, 'C', 'Description', d.Description, i.Description, getdate(), SUSER_SNAME()
    	from inserted i, deleted d, EMCO e
    	where i.EMCo = d.EMCo and i.Equipment = d.Equipment and i.Asset = d.Asset
       and e.EMCo = i.EMCo and e.AuditAsset = 'Y'
   end
   
   if update(DeprMethod)
   begin
   insert into bHQMA select 'bEMDP', 'EM Company: ' + convert(char(3),i.EMCo) + ' Equipment: ' + convert(varchar(10),i.Equipment) +
    	' Asset: ' + convert(varchar(20),i.Asset),
    	i.EMCo, 'C', 'DeprMethod', d.DeprMethod, i.DeprMethod, getdate(), SUSER_SNAME()
    	from inserted i, deleted d, EMCO e
    	where i.EMCo = d.EMCo and i.Equipment = d.Equipment and i.Asset = d.Asset
       and e.EMCo = i.EMCo and e.AuditAsset = 'Y'
   end
   
   if update(DBFactor)
   begin
   insert into bHQMA select 'bEMDP', 'EM Company: ' + convert(char(3),i.EMCo) + ' Equipment: ' + convert(varchar(10),i.Equipment) +
    	' Asset: ' + convert(varchar(20),i.Asset),
    	i.EMCo, 'C', 'DBFactor', d.DBFactor, i.DBFactor, getdate(), SUSER_SNAME()
    	from inserted i, deleted d, EMCO e
    	where i.EMCo = d.EMCo and i.Equipment = d.Equipment and i.Asset = d.Asset
       and e.EMCo = i.EMCo and e.AuditAsset = 'Y'
   end
   
   if update(FirstMonth)
   begin
   insert into bHQMA select 'bEMDP', 'EM Company: ' + convert(char(3),i.EMCo) + ' Equipment: ' + convert(varchar(10),i.Equipment) +
    	' Asset: ' + convert(varchar(20),i.Asset),
    	i.EMCo, 'C', 'FirstMonth', d.FirstMonth, i.FirstMonth, getdate(), SUSER_SNAME()
    	from inserted i, deleted d, EMCO e
    	where i.EMCo = d.EMCo and i.Equipment = d.Equipment and i.Asset = d.Asset
       and e.EMCo = i.EMCo and e.AuditAsset = 'Y'
   end
   
   if update(NoMonthsToDepr)
   begin
   insert into bHQMA select 'bEMDP', 'EM Company: ' + convert(char(3),i.EMCo) + ' Equipment: ' + convert(varchar(10),i.Equipment) +
    	' Asset: ' + convert(varchar(20),i.Asset),
    	i.EMCo, 'C', 'NoMonthsToDepr', d.NoMonthsToDepr, i.NoMonthsToDepr, getdate(), SUSER_SNAME()
    	from inserted i, deleted d, EMCO e
    	where i.EMCo = d.EMCo and i.Equipment = d.Equipment and i.Asset = d.Asset
       and e.EMCo = i.EMCo and e.AuditAsset = 'Y'
   end
   
   if update(TtlToDepr)
   begin
   insert into bHQMA select 'bEMDP', 'EM Company: ' + convert(char(3),i.EMCo) + ' Equipment: ' + convert(varchar(10),i.Equipment) +
    	' Asset: ' + convert(varchar(20),i.Asset),
    	i.EMCo, 'C', 'TtlToDepr', d.TtlToDepr, i.TtlToDepr, getdate(), SUSER_SNAME()
    	from inserted i, deleted d, EMCO e
    	where i.EMCo = d.EMCo and i.Equipment = d.Equipment and i.Asset = d.Asset
       and e.EMCo = i.EMCo and e.AuditAsset = 'Y'
   end
   
   if update(MonthDisposed)
   begin
   insert into bHQMA select 'bEMDP', 'EM Company: ' + convert(char(3),i.EMCo) + ' Equipment: ' + convert(varchar(10),i.Equipment) +
    	' Asset: ' + convert(varchar(20),i.Asset),
    	i.EMCo, 'C', 'MonthDisposed', d.MonthDisposed, i.MonthDisposed, getdate(), SUSER_SNAME()
    	from inserted i, deleted d, EMCO e
    	where i.EMCo = d.EMCo and i.Equipment = d.Equipment and i.Asset = d.Asset
       and e.EMCo = i.EMCo and e.AuditAsset = 'Y'
   end
   
   if update(PurchasePrice)
   begin
   insert into bHQMA select 'bEMDP', 'EM Company: ' + convert(char(3),i.EMCo) + ' Equipment: ' + convert(varchar(10),i.Equipment) +
    	' Asset: ' + convert(varchar(20),i.Asset),
    	i.EMCo, 'C', 'PurchasePrice', d.PurchasePrice, i.PurchasePrice, getdate(), SUSER_SNAME()
    	from inserted i, deleted d, EMCO e
    	where i.EMCo = d.EMCo and i.Equipment = d.Equipment and i.Asset = d.Asset
       and e.EMCo = i.EMCo and e.AuditAsset = 'Y'
   end
   
   if update(ResidualValue)
   begin
   insert into bHQMA select 'bEMDP', 'EM Company: ' + convert(char(3),i.EMCo) + ' Equipment: ' + convert(varchar(10),i.Equipment) +
    	' Asset: ' + convert(varchar(20),i.Asset),
    	i.EMCo, 'C', 'ResidualValue', d.ResidualValue, i.ResidualValue, getdate(), SUSER_SNAME()
    	from inserted i, deleted d, EMCO e
    	where i.EMCo = d.EMCo and i.Equipment = d.Equipment and i.Asset = d.Asset
       and e.EMCo = i.EMCo and e.AuditAsset = 'Y'
   end
   
   if update(SalePrice)
   begin
   insert into bHQMA select 'bEMDP', 'EM Company: ' + convert(char(3),i.EMCo) + ' Equipment: ' + convert(varchar(10),i.Equipment) +
    	' Asset: ' + convert(varchar(20),i.Asset),
    	i.EMCo, 'C', 'SalePrice', d.SalePrice, i.SalePrice, getdate(), SUSER_SNAME()
    	from inserted i, deleted d, EMCO e
    	where i.EMCo = d.EMCo and i.Equipment = d.Equipment and i.Asset = d.Asset
       and e.EMCo = i.EMCo and e.AuditAsset = 'Y'
   end
   
   if update(AccumDeprAcct)
   begin
   insert into bHQMA select 'bEMDP', 'EM Company: ' + convert(char(3),i.EMCo) + ' Equipment: ' + convert(varchar(10),i.Equipment) +
    	' Asset: ' + convert(varchar(20),i.Asset),
    	i.EMCo, 'C', 'AccumDeprAcct', d.AccumDeprAcct, i.AccumDeprAcct, getdate(), SUSER_SNAME()
    	from inserted i, deleted d, EMCO e
    	where i.EMCo = d.EMCo and i.Equipment = d.Equipment and i.Asset = d.Asset
       and e.EMCo = i.EMCo and e.AuditAsset = 'Y'
   end
   
   if update(DeprExpAcct)
   begin
   insert into bHQMA select 'bEMDP', 'EM Company: ' + convert(char(3),i.EMCo) + ' Equipment: ' + convert(varchar(10),i.Equipment) +
    	' Asset: ' + convert(varchar(20),i.Asset),
    	i.EMCo, 'C', 'DeprExpAcct', d.DeprExpAcct, i.DeprExpAcct, getdate(), SUSER_SNAME()
    	from inserted i, deleted d, EMCO e
    	where i.EMCo = d.EMCo and i.Equipment = d.Equipment and i.Asset = d.Asset
       and e.EMCo = i.EMCo and e.AuditAsset = 'Y'
   end
   
   if update(DeprAssetAcct)
   begin
   insert into bHQMA select 'bEMDP', 'EM Company: ' + convert(char(3),i.EMCo) + ' Equipment: ' + convert(varchar(10),i.Equipment) +
    	' Asset: ' + convert(varchar(20),i.Asset),
    	i.EMCo, 'C', 'DeprAssetAcct', d.DeprAssetAcct, i.DeprAssetAcct, getdate(), SUSER_SNAME()
    	from inserted i, deleted d, EMCO e
    	where i.EMCo = d.EMCo and i.Equipment = d.Equipment and i.Asset = d.Asset
       and e.EMCo = i.EMCo and e.AuditAsset = 'Y'
   end
   
   if update(GLCo)
   begin
   insert into bHQMA select 'bEMDP', 'EM Company: ' + convert(char(3),i.EMCo) + ' Equipment: ' + convert(varchar(10),i.Equipment) +
    	' Asset: ' + convert(varchar(20),i.Asset),
    	i.EMCo, 'C', 'GLCo', d.GLCo, i.GLCo, getdate(), SUSER_SNAME()
    	from inserted i, deleted d, EMCO e
    	where i.EMCo = d.EMCo and i.Equipment = d.Equipment and i.Asset = d.Asset
       and e.EMCo = i.EMCo and e.AuditAsset = 'Y'
   end
   
    return
   
    error:
       select @errmsg = isnull(@errmsg,'') + ' - cannot update EMDP'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
   
   
   
  
 



GO
ALTER TABLE [dbo].[bEMDP] ADD CONSTRAINT [PK_bEMDP] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [IX_bEMDP_EMCoEquipmentAsset] ON [dbo].[bEMDP] ([EMCo], [Equipment], [Asset]) WITH (FILLFACTOR=80) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bEMDP].[UseResidualVal]'
GO
