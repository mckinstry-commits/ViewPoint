SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.VCContactTypes
AS
SELECT     ContactTypeID, Name, Description, Static, ClientModified
FROM         dbo.pContactTypes

GO
GRANT SELECT ON  [dbo].[VCContactTypes] TO [public]
GRANT INSERT ON  [dbo].[VCContactTypes] TO [public]
GRANT DELETE ON  [dbo].[VCContactTypes] TO [public]
GRANT UPDATE ON  [dbo].[VCContactTypes] TO [public]
GO
