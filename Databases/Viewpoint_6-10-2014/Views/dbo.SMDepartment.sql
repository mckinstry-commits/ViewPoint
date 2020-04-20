SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE VIEW [dbo].[SMDepartment]
AS

SELECT a.* FROM dbo.vSMDepartment a

/*
SELECT     SMDepartmentID, SMCo, Department, Description, GLCo, 
	EquipCostGLAcct, LaborCostGLAcct, MiscCostGLAcct, MaterialCostGLAcct, 
	EquipRevGLAcct, LaborRevGLAcct, MiscRevGLAcct, MaterialRevGLAcct, 
	EquipCostWIPGLAcct, LaborCostWIPGLAcct, MiscCostWIPGLAcct, MaterialCostWIPGLAcct, 
	EquipRevWIPGLAcct, LaborRevWIPGLAcct, MiscRevWIPGLAcct, MaterialRevWIPGLAcct, 
	UniqueAttchID, Notes, SMDepartmentID AS 'KeyID'
FROM         dbo.vSMDepartment
*/



GO
GRANT SELECT ON  [dbo].[SMDepartment] TO [public]
GRANT INSERT ON  [dbo].[SMDepartment] TO [public]
GRANT DELETE ON  [dbo].[SMDepartment] TO [public]
GRANT UPDATE ON  [dbo].[SMDepartment] TO [public]
GRANT SELECT ON  [dbo].[SMDepartment] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMDepartment] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMDepartment] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMDepartment] TO [Viewpoint]
GO
