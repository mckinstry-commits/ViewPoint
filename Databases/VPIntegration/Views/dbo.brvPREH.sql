SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    view [dbo].[brvPREH] as 
   
   /* Used by VA Datatype security Report by Group/User*/
   
   Select Datatype='bEmployee', PRCo,Employee=Convert(char(6),Employee),
   LastName, FirstName, SortName
    From PREH
   
   Union all
   
   Select Datatype='bHRRef', HRCo,Employee=Convert(char(6),HRRef),
   LastName, FirstName, SortName
    From HRRM

GO
GRANT SELECT ON  [dbo].[brvPREH] TO [public]
GRANT INSERT ON  [dbo].[brvPREH] TO [public]
GRANT DELETE ON  [dbo].[brvPREH] TO [public]
GRANT UPDATE ON  [dbo].[brvPREH] TO [public]
GO
