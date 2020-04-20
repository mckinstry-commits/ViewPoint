CREATE TABLE [dbo].[MckTempFixedRates]
(
[JCCo] [float] NULL,
[RateTemplate] [float] NULL,
[Seq] [float] NULL,
[PRCo] [float] NULL,
[Craft] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[Class] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[Shift] [float] NULL,
[EarnFactor] [float] NULL,
[Employee] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[OldRate] [float] NULL,
[NewRate] [float] NULL
) ON [PRIMARY]
GO
