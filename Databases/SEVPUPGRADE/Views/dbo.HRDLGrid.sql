SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view dbo.HRDLGrid
as
/*Created this view to get around a limitation
I was having with standards.  The header keys
of HR Resource License Endorsements are 
HRRM.HRRef and HRRM.LicState.  The problem
is LicState does not exist in HRDL and standards
assumes it does.  Need to alias HRDL.State to 
HRDL.LicState in order for standards to apply 
the where clause correctly.  Using the HRDL
view as the base to preserve security. */

SELECT     HRCo, HRRef, State as [LicState], LicCodeType, LicCode
FROM         dbo.HRDL
GO
GRANT SELECT ON  [dbo].[HRDLGrid] TO [public]
GRANT INSERT ON  [dbo].[HRDLGrid] TO [public]
GRANT DELETE ON  [dbo].[HRDLGrid] TO [public]
GRANT UPDATE ON  [dbo].[HRDLGrid] TO [public]
GO
