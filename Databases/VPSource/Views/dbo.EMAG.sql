SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMAG] as select a.* From bEMAG a

GO
GRANT SELECT ON  [dbo].[EMAG] TO [public]
GRANT INSERT ON  [dbo].[EMAG] TO [public]
GRANT DELETE ON  [dbo].[EMAG] TO [public]
GRANT UPDATE ON  [dbo].[EMAG] TO [public]
GO
