SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[INPB] as select a.* From bINPB a
GO
GRANT SELECT ON  [dbo].[INPB] TO [public]
GRANT INSERT ON  [dbo].[INPB] TO [public]
GRANT DELETE ON  [dbo].[INPB] TO [public]
GRANT UPDATE ON  [dbo].[INPB] TO [public]
GRANT SELECT ON  [dbo].[INPB] TO [Viewpoint]
GRANT INSERT ON  [dbo].[INPB] TO [Viewpoint]
GRANT DELETE ON  [dbo].[INPB] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[INPB] TO [Viewpoint]
GO
