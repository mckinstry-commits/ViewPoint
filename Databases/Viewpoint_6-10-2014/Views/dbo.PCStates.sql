SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[PCStates] as select a.* From vPCStates a

GO
GRANT SELECT ON  [dbo].[PCStates] TO [public]
GRANT INSERT ON  [dbo].[PCStates] TO [public]
GRANT DELETE ON  [dbo].[PCStates] TO [public]
GRANT UPDATE ON  [dbo].[PCStates] TO [public]
GRANT SELECT ON  [dbo].[PCStates] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PCStates] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PCStates] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PCStates] TO [Viewpoint]
GO
