SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[INAG] as select a.* From bINAG a

GO
GRANT SELECT ON  [dbo].[INAG] TO [public]
GRANT INSERT ON  [dbo].[INAG] TO [public]
GRANT DELETE ON  [dbo].[INAG] TO [public]
GRANT UPDATE ON  [dbo].[INAG] TO [public]
GO
