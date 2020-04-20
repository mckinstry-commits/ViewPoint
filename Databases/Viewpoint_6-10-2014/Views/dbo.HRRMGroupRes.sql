SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
/**************************
*
*	Created By: Dan Sochacki
*	Created: 12/14/2007
*	Modified: MarkH 04/15/08 - 127827. Eliminating the FullName portion.  Can get 
*						that by joining up to HRRMName
*
*	Purpose:  Return HRRef and Full name 
*				of people in PTO Groups.
*
*
***************************/
   
	--CREATE VIEW [dbo].[HRRMGroupRes]
	CREATE VIEW [dbo].[HRRMGroupRes]
	AS
	SELECT HRCo, PTOAppvrGrp, HRRef
	  --ISNULL(LastName, '') + ', ' + ISNULL(FirstName, '') + ', ' + ISNULL(MiddleName, '') AS FullName
	  FROM dbo.HRRM WITH (NOLOCK)


   
   
   
   
  
 



GO
GRANT SELECT ON  [dbo].[HRRMGroupRes] TO [public]
GRANT INSERT ON  [dbo].[HRRMGroupRes] TO [public]
GRANT DELETE ON  [dbo].[HRRMGroupRes] TO [public]
GRANT UPDATE ON  [dbo].[HRRMGroupRes] TO [public]
GRANT SELECT ON  [dbo].[HRRMGroupRes] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HRRMGroupRes] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HRRMGroupRes] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HRRMGroupRes] TO [Viewpoint]
GO
