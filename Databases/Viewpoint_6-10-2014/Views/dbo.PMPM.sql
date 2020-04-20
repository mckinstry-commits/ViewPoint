SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE view [dbo].[PMPM] as select a.* From bPMPM a



GO
GRANT SELECT ON  [dbo].[PMPM] TO [public]
GRANT INSERT ON  [dbo].[PMPM] TO [public]
GRANT DELETE ON  [dbo].[PMPM] TO [public]
GRANT UPDATE ON  [dbo].[PMPM] TO [public]
GRANT SELECT ON  [dbo].[PMPM] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMPM] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMPM] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMPM] TO [Viewpoint]
GO
