SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[VCUserContactInfo]
as

SELECT * FROM pUserContactInfo WITH (NOLOCK)


GO
GRANT SELECT ON  [dbo].[VCUserContactInfo] TO [public]
GRANT INSERT ON  [dbo].[VCUserContactInfo] TO [public]
GRANT DELETE ON  [dbo].[VCUserContactInfo] TO [public]
GRANT UPDATE ON  [dbo].[VCUserContactInfo] TO [public]
GO
