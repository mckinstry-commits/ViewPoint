SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HQWF] as select a.* From bHQWF a
GO
GRANT SELECT ON  [dbo].[HQWF] TO [public]
GRANT INSERT ON  [dbo].[HQWF] TO [public]
GRANT DELETE ON  [dbo].[HQWF] TO [public]
GRANT UPDATE ON  [dbo].[HQWF] TO [public]
GO
