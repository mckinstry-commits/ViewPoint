SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO












CREATE VIEW [dbo].[SMWorkOrderPOHD]
AS
SELECT a.* FROM dbo.vSMWorkOrderPOHD a












GO
GRANT SELECT ON  [dbo].[SMWorkOrderPOHD] TO [public]
GRANT INSERT ON  [dbo].[SMWorkOrderPOHD] TO [public]
GRANT DELETE ON  [dbo].[SMWorkOrderPOHD] TO [public]
GRANT UPDATE ON  [dbo].[SMWorkOrderPOHD] TO [public]
GO
