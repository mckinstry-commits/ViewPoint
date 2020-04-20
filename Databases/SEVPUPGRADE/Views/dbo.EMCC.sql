SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMCC] as select a.* From bEMCC a
GO
GRANT SELECT ON  [dbo].[EMCC] TO [public]
GRANT INSERT ON  [dbo].[EMCC] TO [public]
GRANT DELETE ON  [dbo].[EMCC] TO [public]
GRANT UPDATE ON  [dbo].[EMCC] TO [public]
GO
