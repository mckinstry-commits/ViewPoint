CREATE TABLE [dbo].[bHRBI]
(
[HRCo] [dbo].[bCompany] NOT NULL,
[BenefitCode] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[EDLType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[EDLCode] [dbo].[bEDLCode] NOT NULL,
[Frequency] [dbo].[bFreq] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[BenefitOption] [smallint] NOT NULL CONSTRAINT [DF_bHRBI_BenefitOption] DEFAULT ((1)),
[OldRate] [dbo].[bUnitCost] NULL,
[NewRate] [dbo].[bUnitCost] NULL,
[EffectiveDate] [dbo].[bDate] NULL,
[UpdatedYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bHRBI_UpdatedYN] DEFAULT ('N')
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		MH 7/31/2008
-- Create date: 7/31/2008
-- Description:	Insert Trigger for bHRBI
-- =============================================
CREATE Trigger [dbo].[btHRBIi] on [dbo].[bHRBI] for insert
AS 

BEGIN

	declare @errmsg varchar(255), @numrows int, @validcnt int

	SET NOCOUNT ON

	if not exists(select 1 from inserted i join bHRCO h on i.HRCo = h.HRCo where h.AuditBenefitsYN = 'Y')
	begin
		return
	end

	insert bHQMA select 'bHRBI', 'HRCo: ' + convert(char(3), isnull(i.HRCo, '')) + 
	' BenefitCode: ' + convert(varchar(10), isnull(i.BenefitCode, '')) + ' EDLType: ' + convert(char(1), isnull(i.EDLType,'')) + 
	' EDLCode: ' + convert(varchar(6), isnull(i.EDLCode, '')) + ' BenefitOption: ' + convert(varchar(6), isnull(i.BenefitOption, '')),
	i.HRCo, 'A', '', null, null, getdate(), suser_sname()
	from inserted i
	join bHRCO h on i.HRCo = h.HRCo and h.AuditBenefitsYN = 'Y'

END


GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		MH
-- Create date: 7/31/2008
-- Modified:  10/1/2008 - expanded conversion of oldrate/newrate from varchar(9) to varchar(20)
-- Description:	Update Trigger for bHRBI
-- =============================================
CREATE Trigger [dbo].[btHRBIu] on [dbo].[bHRBI] for update
AS 


BEGIN
	
    declare @numrows int, @errmsg varchar(255), @audit bYN, @rcode int

	select @numrows = @@rowcount
	if @numrows = 0 return

	set nocount on

	/*Insert HQMA records*/

	--Frequency
	if update(Frequency)
		insert bHQMA select 'bHRBI', 'HRCo: ' + convert(char(3), isnull(i.HRCo, '')) + 
		' BenefitCode: ' + convert(varchar(10), isnull(i.BenefitCode, '')) + ' EDLType: ' + convert(char(1), isnull(i.EDLType,'')) + 
		' EDLCode: ' + convert(varchar(6), isnull(i.EDLCode, '')) + ' BenefitOption: ' + convert(varchar(6), isnull(i.BenefitOption, '')),
		i.HRCo, 'C', 'Frequency', convert(varchar(10), d.Frequency), convert(varchar(10), i.Frequency), getdate(), suser_sname()
		from inserted i
		join deleted d on i.HRCo = d.HRCo and i.BenefitCode = d.BenefitCode and i.EDLType = d.EDLType and i.EDLCode = d.EDLCode and i.BenefitOption = d.BenefitOption
		join bHRCO h on i.HRCo = h.HRCo and h.AuditBenefitsYN = 'Y'
		where i.Frequency <> d.Frequency

	--OldRate
	if update(OldRate)
		insert bHQMA select 'bHRBI', 'HRCo: ' + convert(char(3), isnull(i.HRCo, '')) + 
		' BenefitCode: ' + convert(varchar(10), isnull(i.BenefitCode, '')) + ' EDLType: ' + convert(char(1), isnull(i.EDLType,'')) + 
		' EDLCode: ' + convert(varchar(6), isnull(i.EDLCode, '')) + ' BenefitOption: ' + convert(varchar(6), isnull(i.BenefitOption, '')),
		i.HRCo, 'C', 'OldRate', convert(varchar, d.OldRate), convert(varchar, i.OldRate), getdate(), suser_sname()
		from inserted i
		join deleted d on i.HRCo = d.HRCo and i.BenefitCode = d.BenefitCode and i.EDLType = d.EDLType and i.EDLCode = d.EDLCode and i.BenefitOption = d.BenefitOption
		join bHRCO h on i.HRCo = h.HRCo and h.AuditBenefitsYN = 'Y'
		where i.OldRate <> d.OldRate

	--NewRate
	if update(NewRate)
		insert bHQMA select 'bHRBI', 'HRCo: ' + convert(char(3), isnull(i.HRCo, '')) + 
		' BenefitCode: ' + convert(varchar(10), isnull(i.BenefitCode, '')) + ' EDLType: ' + convert(char(1), isnull(i.EDLType,'')) + 
		' EDLCode: ' + convert(varchar(6), isnull(i.EDLCode, '')) + ' BenefitOption: ' + convert(varchar(6), isnull(i.BenefitOption, '')),
		i.HRCo, 'C', 'NewRate', convert(varchar, d.NewRate), convert(varchar, i.NewRate), getdate(), suser_sname()
		from inserted i
		join deleted d on i.HRCo = d.HRCo and i.BenefitCode = d.BenefitCode and i.EDLType = d.EDLType and i.EDLCode = d.EDLCode and i.BenefitOption = d.BenefitOption
		join bHRCO h on i.HRCo = h.HRCo and h.AuditBenefitsYN = 'Y'
		where i.NewRate <> d.NewRate

	--EffectiveDate
	if update(EffectiveDate)
		insert bHQMA select 'bHRBI', 'HRCo: ' + convert(char(3), isnull(i.HRCo, '')) + 
		' BenefitCode: ' + convert(varchar(10), isnull(i.BenefitCode, '')) + ' EDLType: ' + convert(char(1), isnull(i.EDLType,'')) + 
		' EDLCode: ' + convert(varchar(6), isnull(i.EDLCode, '')) + ' BenefitOption: ' + convert(varchar(6), isnull(i.BenefitOption, '')),
		i.HRCo, 'C', 'EffectiveDate', convert(varchar(9), d.EffectiveDate), convert(varchar(9), i.EffectiveDate), getdate(), suser_sname()
		from inserted i
		join deleted d on i.HRCo = d.HRCo and i.BenefitCode = d.BenefitCode and i.EDLType = d.EDLType and i.EDLCode = d.EDLCode and i.BenefitOption = d.BenefitOption
		join bHRCO h on i.HRCo = h.HRCo and h.AuditBenefitsYN = 'Y'
		where i.EffectiveDate <> d.EffectiveDate

	--UpdatedYN
	if update(UpdatedYN)
		insert bHQMA select 'bHRBI', 'HRCo: ' + convert(char(3), isnull(i.HRCo, '')) + 
		' BenefitCode: ' + convert(varchar(10), isnull(i.BenefitCode, '')) + ' EDLType: ' + convert(char(1), isnull(i.EDLType,'')) + 
		' EDLCode: ' + convert(varchar(6), isnull(i.EDLCode, '')) + ' BenefitOption: ' + convert(varchar(6), isnull(i.BenefitOption, '')),
		i.HRCo, 'C', 'UpdatedYN', convert(varchar(9), d.UpdatedYN), convert(varchar(9), i.UpdatedYN), getdate(), suser_sname()
		from inserted i
		join deleted d on i.HRCo = d.HRCo and i.BenefitCode = d.BenefitCode and i.EDLType = d.EDLType and i.EDLCode = d.EDLCode and i.BenefitOption = d.BenefitOption
		join bHRCO h on i.HRCo = h.HRCo and h.AuditBenefitsYN = 'Y'
		where i.UpdatedYN <> d.UpdatedYN
	
END



GO
CREATE UNIQUE CLUSTERED INDEX [biHRBI] ON [dbo].[bHRBI] ([HRCo], [BenefitCode], [EDLType], [EDLCode], [BenefitOption]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHRBI] ([KeyID]) ON [PRIMARY]
GO
