SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMWF] as select a.* From bEMWF a
GO
GRANT SELECT ON  [dbo].[EMWF] TO [public]
GRANT INSERT ON  [dbo].[EMWF] TO [public]
GRANT DELETE ON  [dbo].[EMWF] TO [public]
GRANT UPDATE ON  [dbo].[EMWF] TO [public]
GO
