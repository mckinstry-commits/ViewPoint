SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.udxrefAPVendor as select a.* From Viewpoint.dbo.budxrefAPVendor a;
GO
GRANT SELECT ON  [dbo].[udxrefAPVendor] TO [public]
GRANT INSERT ON  [dbo].[udxrefAPVendor] TO [public]
GRANT DELETE ON  [dbo].[udxrefAPVendor] TO [public]
GRANT UPDATE ON  [dbo].[udxrefAPVendor] TO [public]
GRANT SELECT ON  [dbo].[udxrefAPVendor] TO [Viewpoint]
GRANT INSERT ON  [dbo].[udxrefAPVendor] TO [Viewpoint]
GRANT DELETE ON  [dbo].[udxrefAPVendor] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[udxrefAPVendor] TO [Viewpoint]
GO
