SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   view [dbo].[DDSG] as select * from vDDSG

GO
GRANT SELECT ON  [dbo].[DDSG] TO [public]
GRANT INSERT ON  [dbo].[DDSG] TO [public]
GRANT DELETE ON  [dbo].[DDSG] TO [public]
GRANT UPDATE ON  [dbo].[DDSG] TO [public]
GO
