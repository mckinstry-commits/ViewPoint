SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE View [dbo].[vrvHQCO_User]

/*******
 Created Date:  7/21/09 DH
 Modified Date:

 Usage:  This view returns the current user and HQ Company.  It is intended
         for Crystal Report writers to use in customized reports to return the login name
         of the current user running the report.  View should be linked to HQCO view
         in copied/modified reports.

******/
       

as

Select
HQCo,
Suser_sname() as UserName

From HQCO
GO
GRANT SELECT ON  [dbo].[vrvHQCO_User] TO [public]
GRANT INSERT ON  [dbo].[vrvHQCO_User] TO [public]
GRANT DELETE ON  [dbo].[vrvHQCO_User] TO [public]
GRANT UPDATE ON  [dbo].[vrvHQCO_User] TO [public]
GO
