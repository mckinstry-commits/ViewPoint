CREATE TABLE [dbo].[bJCIP]
(
[JCCo] [dbo].[bCompany] NOT NULL,
[Contract] [dbo].[bContract] NOT NULL,
[Item] [dbo].[bContractItem] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[OrigContractAmt] [dbo].[bDollar] NOT NULL,
[OrigContractUnits] [dbo].[bUnits] NOT NULL,
[OrigUnitPrice] [dbo].[bUnitCost] NOT NULL,
[ContractAmt] [dbo].[bDollar] NOT NULL,
[ContractUnits] [dbo].[bUnits] NOT NULL,
[CurrentUnitPrice] [dbo].[bUnitCost] NOT NULL,
[BilledUnits] [dbo].[bUnits] NOT NULL,
[BilledAmt] [dbo].[bDollar] NOT NULL,
[ReceivedAmt] [dbo].[bDollar] NOT NULL,
[CurrentRetainAmt] [dbo].[bDollar] NOT NULL,
[BilledTax] [dbo].[bDollar] NULL,
[ProjUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_bJCIP_ProjUnits] DEFAULT ((0)),
[ProjDollars] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJCIP_ProjDollars] DEFAULT ((0)),
[ProjPlug] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJCIP_ProjPlug] DEFAULT ('N'),
[udSource] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[udConv] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[udCGCTable] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[udCGCTableID] [decimal] (12, 0) NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   /****** Object:  Trigger dbo.btJCIPi    Script Date: 8/28/99 9:37:45 AM ******/
   CREATE TRIGGER [dbo].[btJCIPi] ON [dbo].[bJCIP] FOR insert AS
   

/**************************************************************
    * Created By:	JRE
    * Modified By: GF 10/28/2004 - issue #25828 performance
    *
    *
    *
    * This trigger rejects insert in bJCIP (JC Item Period)
    * if the following error condition exists:
    *
    *		Invalid JCCI
    *
    **************************************************************/
   declare @errmsg varchar(255), @validcnt int, @numrows int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   -- -- -- check if Contract Item exists
   select @validcnt = count(*) from inserted i 
   join bJCCI d with (nolock) on d.JCCo = i.JCCo and i.Contract=d.Contract and i.Item=d.Item
   if @validcnt <> @numrows 
   	begin
   	select @errmsg = 'Contract item does not exist'
   	goto error
   	end
   
   
   return
   
   
   error:
   	select @errmsg = isnull(@errmsg,'') +  ' - cannot insert Item Period!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   /****** Object:  Trigger dbo.btJCIPu    Script Date: 8/28/99 9:37:45 AM ******/
   CREATE TRIGGER [dbo].[btJCIPu] ON [dbo].[bJCIP] FOR update AS
   

/**************************************************************
    * Created By:	JRE
    * Modified By:	GF 10/28/2004 - issue #25828 performance
    *
    *
    *
    * This trigger rejects update in bJCIP (JC Item Period)
    * if the following error condition exists:
    *
    *		Invalid JCCI
    *
    **************************************************************/
   declare @errmsg varchar(255), @validcnt int, @numrows int, @nullcnt int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   
   -- -- -- check if Contract Item exists
   select @validcnt = count(*) from inserted i 
   join bJCCI d with (nolock) on d.JCCo = i.JCCo and i.Contract=d.Contract and i.Item=d.Item
   if @validcnt <> @numrows 
   	begin
   	select @errmsg = 'Contract item does not exist'
   	goto error
   	end
   
   return
   
   
   error:
       select @errmsg = isnull(@errmsg,'') +  ' - cannot update Item Period! '
       RAISERROR(@errmsg, 11, -1);
       rollback transaction                                                         
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biJCIP] ON [dbo].[bJCIP] ([JCCo], [Contract], [Item], [Mth]) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCIP].[OrigContractAmt]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCIP].[OrigContractUnits]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCIP].[OrigUnitPrice]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCIP].[ContractAmt]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCIP].[ContractUnits]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCIP].[CurrentUnitPrice]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCIP].[BilledUnits]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCIP].[BilledAmt]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCIP].[ReceivedAmt]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCIP].[CurrentRetainAmt]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJCIP].[ProjPlug]'
GO
