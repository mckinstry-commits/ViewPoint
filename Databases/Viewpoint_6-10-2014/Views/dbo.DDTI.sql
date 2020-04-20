SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  view [dbo].[DDTI]
  as
  select * from vDDTI

GO
GRANT SELECT ON  [dbo].[DDTI] TO [public]
GRANT INSERT ON  [dbo].[DDTI] TO [public]
GRANT DELETE ON  [dbo].[DDTI] TO [public]
GRANT UPDATE ON  [dbo].[DDTI] TO [public]
GRANT SELECT ON  [dbo].[DDTI] TO [Viewpoint]
GRANT INSERT ON  [dbo].[DDTI] TO [Viewpoint]
GRANT DELETE ON  [dbo].[DDTI] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[DDTI] TO [Viewpoint]
GO
