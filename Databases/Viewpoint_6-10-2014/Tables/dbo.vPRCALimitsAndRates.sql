CREATE TABLE [dbo].[vPRCALimitsAndRates]
(
[KeyID] [int] NOT NULL IDENTITY(1, 1),
[EffectiveDate] [dbo].[bDate] NOT NULL,
[CPPDednMaxPensionEarnAmt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_vPRCALimitsAndRates_CPPDednMaxPensionEarnAmt] DEFAULT ((0)),
[CPPDednAnnualExemptAmt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_vPRCALimitsAndRates_CPPDednAnnualExemptAmt] DEFAULT ((0)),
[CPPDednCalcRate] [dbo].[bUnitCost] NOT NULL CONSTRAINT [DF_vPRCALimitsAndRates_CPPDednCalcRate] DEFAULT ((0)),
[CPPDednCalcLimitAmt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_vPRCALimitsAndRates_CPPDednCalcLimitAmt] DEFAULT ((0)),
[EIDednMaxInsureEarnAmt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_vPRCALimitsAndRates_EIDednMaxInsureEarnAmt] DEFAULT ((0)),
[EIDednCalcRate] [dbo].[bUnitCost] NOT NULL CONSTRAINT [DF_vPRCALimitsAndRates_EIDednCalcRate] DEFAULT ((0)),
[EIDednCalcLimitAmt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_vPRCALimitsAndRates_EIDednCalcLimitAmt] DEFAULT ((0))
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPRCALimitsAndRates] ADD CONSTRAINT [PK_vPRCALimitsAndRates] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [IX_vPRCALimitsAndRates_EffectiveDate] ON [dbo].[vPRCALimitsAndRates] ([EffectiveDate]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
