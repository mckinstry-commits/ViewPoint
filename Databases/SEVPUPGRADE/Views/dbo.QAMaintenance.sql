SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[QAMaintenance]
AS
SELECT     RecordNumber, BatchId, EventType, Priority, ShortText, LongText, Employee, PRCo, Vendor, VendorGroup, Notes, TinyIntegerValue, SmallIntegerValue, IntegerValue, 
                      DecimalValue, PercentageValue, DateValue, MonthValue, SecondDateValue, SecondMonthValue, ECMField, UnitsField, RateField, YesOrNo, WebURL, JobValue, 
                      LocValue
FROM         dbo.vQAMaintenance


GO
GRANT SELECT ON  [dbo].[QAMaintenance] TO [public]
GRANT INSERT ON  [dbo].[QAMaintenance] TO [public]
GRANT DELETE ON  [dbo].[QAMaintenance] TO [public]
GRANT UPDATE ON  [dbo].[QAMaintenance] TO [public]
GO
