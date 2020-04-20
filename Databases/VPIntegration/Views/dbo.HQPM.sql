SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HQPM] as select a.* From bHQPM a

GO
GRANT SELECT ON  [dbo].[HQPM] TO [public]
GRANT INSERT ON  [dbo].[HQPM] TO [public]
GRANT DELETE ON  [dbo].[HQPM] TO [public]
GRANT UPDATE ON  [dbo].[HQPM] TO [public]
GO
