SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HQCountry] as select a.* From bHQCountry a
GO
GRANT SELECT ON  [dbo].[HQCountry] TO [public]
GRANT INSERT ON  [dbo].[HQCountry] TO [public]
GRANT DELETE ON  [dbo].[HQCountry] TO [public]
GRANT UPDATE ON  [dbo].[HQCountry] TO [public]
GO
