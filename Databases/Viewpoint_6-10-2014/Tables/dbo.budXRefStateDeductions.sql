CREATE TABLE [dbo].[budXRefStateDeductions]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[DLCode] [dbo].[bEDLCode] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[VPCODE] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[CGCCODE] [numeric] (3, 0) NULL,
[FITADDONYN] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[CGC_ERCCD] [varchar] (1) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
