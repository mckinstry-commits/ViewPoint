SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE VIEW [dbo].[APT5018Payment] 
AS 
SELECT a.* FROM vAPT5018Payment a



GO
GRANT SELECT ON  [dbo].[APT5018Payment] TO [public]
GRANT INSERT ON  [dbo].[APT5018Payment] TO [public]
GRANT DELETE ON  [dbo].[APT5018Payment] TO [public]
GRANT UPDATE ON  [dbo].[APT5018Payment] TO [public]
GRANT SELECT ON  [dbo].[APT5018Payment] TO [Viewpoint]
GRANT INSERT ON  [dbo].[APT5018Payment] TO [Viewpoint]
GRANT DELETE ON  [dbo].[APT5018Payment] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[APT5018Payment] TO [Viewpoint]
GO
