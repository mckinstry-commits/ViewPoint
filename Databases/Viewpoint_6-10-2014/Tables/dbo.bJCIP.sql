CREATE TABLE [dbo].[bJCIP]
(
[JCCo] [dbo].[bCompany] NOT NULL,
[Contract] [dbo].[bContract] NOT NULL,
[Item] [dbo].[bContractItem] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[OrigContractAmt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJCIP_OrigContractAmt] DEFAULT ((0)),
[OrigContractUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_bJCIP_OrigContractUnits] DEFAULT ((0)),
[OrigUnitPrice] [dbo].[bUnitCost] NOT NULL CONSTRAINT [DF_bJCIP_OrigUnitPrice] DEFAULT ((0)),
[ContractAmt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJCIP_ContractAmt] DEFAULT ((0)),
[ContractUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_bJCIP_ContractUnits] DEFAULT ((0)),
[CurrentUnitPrice] [dbo].[bUnitCost] NOT NULL CONSTRAINT [DF_bJCIP_CurrentUnitPrice] DEFAULT ((0)),
[BilledUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_bJCIP_BilledUnits] DEFAULT ((0)),
[BilledAmt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJCIP_BilledAmt] DEFAULT ((0)),
[ReceivedAmt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJCIP_ReceivedAmt] DEFAULT ((0)),
[CurrentRetainAmt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJCIP_CurrentRetainAmt] DEFAULT ((0)),
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
ALTER TABLE [dbo].[bJCIP] WITH NOCHECK ADD CONSTRAINT [CK_bJCIP_ProjPlug] CHECK (([ProjPlug]='Y' OR [ProjPlug]='N'))
GO
CREATE UNIQUE CLUSTERED INDEX [biJCIP] ON [dbo].[bJCIP] ([JCCo], [Contract], [Item], [Mth]) WITH (FILLFACTOR=85, STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO
