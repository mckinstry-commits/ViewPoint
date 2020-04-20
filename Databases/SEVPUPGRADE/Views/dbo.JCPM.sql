SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JCPM] as select a.* From bJCPM a
GO
GRANT SELECT ON  [dbo].[JCPM] TO [public]
GRANT INSERT ON  [dbo].[JCPM] TO [public]
GRANT DELETE ON  [dbo].[JCPM] TO [public]
GRANT UPDATE ON  [dbo].[JCPM] TO [public]
GO
