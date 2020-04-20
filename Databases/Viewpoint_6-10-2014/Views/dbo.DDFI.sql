SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  view [dbo].[DDFI] as
select a.* From vDDFI a

GO
GRANT SELECT ON  [dbo].[DDFI] TO [public]
GRANT INSERT ON  [dbo].[DDFI] TO [public]
GRANT DELETE ON  [dbo].[DDFI] TO [public]
GRANT UPDATE ON  [dbo].[DDFI] TO [public]
GRANT SELECT ON  [dbo].[DDFI] TO [Viewpoint]
GRANT INSERT ON  [dbo].[DDFI] TO [Viewpoint]
GRANT DELETE ON  [dbo].[DDFI] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[DDFI] TO [Viewpoint]
GO
