CREATE TABLE [dbo].[bMSPA]
(
[MSCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[Loc] [dbo].[bLoc] NOT NULL,
[MatlGroup] [dbo].[bGroup] NOT NULL,
[Material] [dbo].[bMatl] NOT NULL,
[INTransType] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[BatchSeq] [int] NOT NULL,
[OldNew] [tinyint] NOT NULL,
[MSTrans] [dbo].[bTrans] NULL,
[SaleDate] [dbo].[bDate] NOT NULL,
[SellTrnsfrLoc] [dbo].[bLoc] NULL,
[UM] [dbo].[bUM] NOT NULL,
[Units] [dbo].[bUnits] NOT NULL,
[UnitCost] [dbo].[bUnitCost] NOT NULL,
[ECM] [dbo].[bECM] NOT NULL,
[TotalCost] [dbo].[bDollar] NOT NULL,
[UnitPrice] [dbo].[bUnitCost] NOT NULL,
[PECM] [dbo].[bECM] NOT NULL,
[TotalPrice] [dbo].[bDollar] NOT NULL,
[INTrans] [dbo].[bTrans] NULL,
[FinishMatl] [dbo].[bMatl] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
/*-----------------------------------------------------------------
*  Created By:  DAN SO 04/26/2010 - ISSUE: #139080 - Testing
*  Modified By:	
*
*/----------------------------------------------------------------
    
    
   CREATE TRIGGER [dbo].[btMSPAi] ON [dbo].[bMSPA] FOR INSERT 
   --CREATE TRIGGER [dbo].[btMSPAi] ON [dbo].[bMSPA] FOR INSERT 
   
   AS
   
   declare @errmsg varchar(MAX), @validcnt int, @numrows int,
			@MSCo bCompany,
			@Mth bMonth,
			@BatchId bBatchID,
			@Loc bLoc,
			@MatlGroup bGroup,
			@Material bMatl,
			@INTransType varchar(10),
			@BatchSeq int,
			@OldNew tinyint,
			@Units bUnits
			
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   SELECT @MSCo = MSCo, @Mth = Mth, @BatchId = BatchId, @Loc = Loc,
			@MatlGroup = MatlGroup, @Material = Material, @INTransType = INTransType,
			@BatchSeq = BatchSeq, @OldNew = OldNew
	FROM Inserted
   
   SET @errmsg = '@MSCo: ' + cast(@MSCo as varchar(10)) + char(10) +
					'@Mth:  ' + cast(@Mth as varchar(12)) + char(10) +
					'@BatchId: ' + cast(@BatchId as varchar(10)) + char(10) +
					'@Loc: ' + cast(@Loc as varchar(10)) + char(10) +
					'@MatlGroup: ' +  cast(@MatlGroup as varchar(10)) + char(10) +
					'@Material: ' +  cast(@Material as varchar(10)) + char(10) +
					'@INTransType: ' +  cast(@INTransType as varchar(10))+ char(10) +
					'@BatchSeq: ' + cast(@BatchSeq as varchar(10)) + char(10) +
					'@OldNew: ' + cast(@OldNew as varchar(10)) + char(10) +
					'@Units: ' + isnull(cast(@Units as varchar(10)), 'NA') + char(10) 
   
   --GOTO error

   
   return
   
   error:
       SELECT @errmsg = @errmsg +  ' - cannot insert MSPA issue!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biMSPA] ON [dbo].[bMSPA] ([MSCo], [Mth], [BatchId], [Loc], [MatlGroup], [Material], [INTransType], [BatchSeq], [OldNew]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bMSPA].[ECM]'
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bMSPA].[PECM]'
GO
