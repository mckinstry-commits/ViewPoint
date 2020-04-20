CREATE TABLE [dbo].[bMSSurcharges]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NOT NULL,
[SurchargeSeq] [int] NOT NULL,
[BatchTransType] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bMSSurcharges_BatchTransType] DEFAULT ('A'),
[SurchargeCode] [smallint] NULL,
[SurchargeMaterial] [dbo].[bMatl] NULL,
[SurchargeBasis] [dbo].[bUnits] NULL,
[SurchargeRate] [dbo].[bUnitCost] NULL,
[SurchargeTotal] [dbo].[bDollar] NULL,
[TaxBasis] [dbo].[bDollar] NULL,
[TaxTotal] [dbo].[bDollar] NULL,
[MSTBKeyID] [bigint] NULL,
[MSTDKeyID] [bigint] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[DiscountOffered] [dbo].[bDollar] NULL,
[TaxDiscount] [dbo].[bDollar] NULL,
[UM] [dbo].[bUM] NULL,
[APRef] [dbo].[bAPReference] NULL,
[MatlAPRef] [dbo].[bAPReference] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
   

/*-----------------------------------------------------------------
* Created:		DAN SO 10/27/2009 - Issue: #129350
* Modified:		
*
* NULL bMSTD InUseBatchId's when Surcharge record(s) are deleted
*
*/----------------------------------------------------------------
--CREATE TRIGGER [dbo].[btMSSurchargesd] ON [dbo].[bMSSurcharges] FOR DELETE AS
CREATE TRIGGER [dbo].[btMSSurchargesd] ON [dbo].[bMSSurcharges] FOR DELETE AS


	DECLARE @NumRows	int, 
			@ValidCnt	int,
			@errmsg		varchar(255)
   
   
	SET @NumRows = @@ROWCOUNT
	IF @NumRows = 0 RETURN
   
	SET NOCOUNT ON
      
	-- RESET InUseBatchId --
	UPDATE bMSTD
       SET InUseBatchId = NULL
      FROM Deleted d
      JOIN bMSTD td WITH (NOLOCK) ON td.KeyID = d.MSTDKeyID 
       
   
   RETURN

Error:
   SET @errmsg = @errmsg +  ' - cannot delete MS Surcharge Detail!'
   
   RAISERROR(@errmsg, 11, -1);
   ROLLBACK TRANSACTION

GO
ALTER TABLE [dbo].[bMSSurcharges] ADD CONSTRAINT [CK_bMSSurcharges_BatchTransType] CHECK (([BatchTransType]='A' OR [BatchTransType]='C' OR [BatchTransType]='D'))
GO
ALTER TABLE [dbo].[bMSSurcharges] ADD CONSTRAINT [PK_bMSSurcharges] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
