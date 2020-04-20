SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMCT] as select a.* From bEMCT a
GO
GRANT SELECT ON  [dbo].[EMCT] TO [public]
GRANT INSERT ON  [dbo].[EMCT] TO [public]
GRANT DELETE ON  [dbo].[EMCT] TO [public]
GRANT UPDATE ON  [dbo].[EMCT] TO [public]
GO
