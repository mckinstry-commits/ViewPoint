SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[IMTD] as select a.* From bIMTD a

GO
GRANT SELECT ON  [dbo].[IMTD] TO [public]
GRANT INSERT ON  [dbo].[IMTD] TO [public]
GRANT DELETE ON  [dbo].[IMTD] TO [public]
GRANT UPDATE ON  [dbo].[IMTD] TO [public]
GO
