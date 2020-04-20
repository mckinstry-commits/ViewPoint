CREATE TABLE [dbo].[bMSIX]
(
[MSCo] [dbo].[bCompany] NOT NULL,
[MSInv] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[APSeq] [smallint] NOT NULL,
[SaleType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[JCCo] [dbo].[bCompany] NULL,
[Job] [dbo].[bJob] NULL,
[PhaseGroup] [dbo].[bGroup] NULL,
[Phase] [dbo].[bPhase] NULL,
[JCCType] [dbo].[bJCCType] NULL,
[INCo] [dbo].[bCompany] NULL,
[ToLoc] [dbo].[bLoc] NULL,
[MatlGroup] [dbo].[bGroup] NOT NULL,
[Material] [dbo].[bMatl] NOT NULL,
[UM] [dbo].[bUM] NOT NULL,
[MatlUnits] [dbo].[bUnits] NOT NULL,
[UnitPrice] [dbo].[bUnitCost] NOT NULL,
[ECM] [dbo].[bECM] NOT NULL,
[MatlTotal] [dbo].[bDollar] NOT NULL,
[HaulTotal] [dbo].[bDollar] NOT NULL,
[TaxGroup] [dbo].[bGroup] NULL,
[TaxCode] [dbo].[bTaxCode] NULL,
[TaxBasis] [dbo].[bDollar] NOT NULL,
[TaxTotal] [dbo].[bDollar] NOT NULL
) ON [PRIMARY]
ALTER TABLE [dbo].[bMSIX] ADD
CONSTRAINT [CK_bMSIX_ECM] CHECK (([ECM]='E' OR [ECM]='C' OR [ECM]='M'))
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE trigger [dbo].[btMSIXi] on [dbo].[bMSIX] for INSERT as
   

/*--------------------------------------------------------------
    * Created: GG 08/14/01
    * Modified: 
    *
    * Insert trigger for MS Intercompany Invoice Detail
    *
    *--------------------------------------------------------------*/
   
   declare @numrows int, @errmsg varchar(255), @validcnt int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   -- check for Intercompany Invoice header
   select @validcnt = count(*)
   from bMSII m with (nolock) 
   join inserted i on m.MSCo = i.MSCo and m.MSInv = i.MSInv
   if @validcnt <> @numrows
       begin
   	select @errmsg = 'MS Intercompany Invoice Header does not exist'
   	goto error
   	end
   
   
   return
   
   
   
   error:
       select @errmsg = @errmsg + ' - cannot insert MS Intercompany detail entry'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biMSIX] ON [dbo].[bMSIX] ([MSCo], [MSInv], [APSeq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bMSIX].[ECM]'
GO
