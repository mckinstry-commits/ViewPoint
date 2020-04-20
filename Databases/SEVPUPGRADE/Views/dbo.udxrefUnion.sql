SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.udxrefUnion as select a.* From Viewpoint.dbo.budxrefUnion a;
GO
GRANT REFERENCES ON  [dbo].[udxrefUnion] TO [public]
GRANT SELECT ON  [dbo].[udxrefUnion] TO [public]
GRANT INSERT ON  [dbo].[udxrefUnion] TO [public]
GRANT DELETE ON  [dbo].[udxrefUnion] TO [public]
GRANT UPDATE ON  [dbo].[udxrefUnion] TO [public]
GO
