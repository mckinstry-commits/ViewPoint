SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/************************
   *
   *	Created by ??
   *	Created ??
   *	Used by ?? Reports perhaps?
   *
   *
   *
   ************************/
    
    CREATE  view [dbo].[HRChart] as select HRRM.HRCo,HRRM.HRRef,HRRM.LastName, HRRM.FirstName,HRRM.MiddleName,HRRM.PositionCode,
    	HRPC.ReportLevel,HRPC.ReportPosition
    from dbo.HRRM with (nolock)
    left join dbo.HRPC with (nolock) on HRRM.HRCo=HRPC.HRCo and HRRM.PositionCode=HRPC.PositionCode

GO
GRANT SELECT ON  [dbo].[HRChart] TO [public]
GRANT INSERT ON  [dbo].[HRChart] TO [public]
GRANT DELETE ON  [dbo].[HRChart] TO [public]
GRANT UPDATE ON  [dbo].[HRChart] TO [public]
GRANT SELECT ON  [dbo].[HRChart] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HRChart] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HRChart] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HRChart] TO [Viewpoint]
GO
