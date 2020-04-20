SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO









CREATE VIEW [dbo].[SMStandardItemDefaultDetail]
AS
SELECT a.* FROM dbo.vSMStandardItemDefaultDetail a

GO
GRANT SELECT ON  [dbo].[SMStandardItemDefaultDetail] TO [public]
GRANT INSERT ON  [dbo].[SMStandardItemDefaultDetail] TO [public]
GRANT DELETE ON  [dbo].[SMStandardItemDefaultDetail] TO [public]
GRANT UPDATE ON  [dbo].[SMStandardItemDefaultDetail] TO [public]
GO
